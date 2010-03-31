
#import "AOCMethodHooking.h"
#import "AOCError.h"
#import "ffi.h"
#include <objc/runtime.h>
#include "AOCFFIInvocation.h"

#ifndef FFI_CLOSURES
#   error "libffi closures are not supported for the current architecture"
#endif

static NSMutableDictionary* g_closureBySelectorByClass = nil;
static AOCMethodInvocationHook g_globalInvocationHook = NULL;

struct _AOCClosureInfo {
    ffi_closure* closure;
    IMP originalImp;
    BOOL isRunning;
    BOOL shouldFreeAfterRun;
};

#pragma mark -
#pragma mark Private function declarations

NSArray* _AOCSupportedScalarReturnTypes();
NSArray* _AOCSupportedScalarArgumentTypes();
BOOL     _AOCScalarTypeIsInArray(const char* scalarType, NSArray* array);
BOOL     _AOCReturnTypeIsSupported(const char* returnType);
BOOL     _AOCArgumentTypeIsSupported(const char* argumentType);
BOOL     _AOCCanInstallHook(NSMethodSignature* sig, NSError** outError);

ffi_closure* _AOCHookClosureAlloc(NSMethodSignature* sig, IMP originalImp);
ffi_closure* _AOCHookClosureInit(ffi_closure* closure, ffi_cif* cif, ffi_type* argTypes[], NSMethodSignature* sig, IMP originalImp);
void         _AOCHookClosureFree(ffi_closure* closure);
void         _AOCSetCIFArgTypes(ffi_type* argTypes[], NSMethodSignature* sig);
ffi_type*    _AOCFFITypeForType(const char* type);

NSMutableDictionary* _AOCGetClosuresBySelector(Class cls, BOOL createIfNeeded);
ffi_closure*         _AOCGetClosure(Class cls, SEL selector);
void                 _AOCSetClosure(ffi_closure* closure, Class cls, SEL selector);

void _AOCHookClosureImp(ffi_cif* cif, void* result, void** args, void* userdata);

#pragma mark -
#pragma mark Private function definitions

NSArray* _AOCSupportedScalarReturnTypes()
{
    return [_AOCSupportedScalarArgumentTypes() arrayByAddingObject:[NSNumber numberWithChar:_C_VOID]];
}

NSArray* _AOCSupportedScalarArgumentTypes()
{
    return [NSArray arrayWithObjects:
            [NSNumber numberWithChar:_C_ID],
            [NSNumber numberWithChar:_C_CLASS],
            [NSNumber numberWithChar:_C_SEL],
            [NSNumber numberWithChar:_C_CHR],
            [NSNumber numberWithChar:_C_UCHR],
            [NSNumber numberWithChar:_C_SHT],
            [NSNumber numberWithChar:_C_USHT],
            [NSNumber numberWithChar:_C_INT],
            [NSNumber numberWithChar:_C_UINT],
            [NSNumber numberWithChar:_C_LNG],
            [NSNumber numberWithChar:_C_ULNG],
            [NSNumber numberWithChar:_C_LNG_LNG],
            [NSNumber numberWithChar:_C_ULNG_LNG],
            [NSNumber numberWithChar:_C_FLT],
            [NSNumber numberWithChar:_C_DBL],
            [NSNumber numberWithChar:_C_PTR],
            [NSNumber numberWithChar:_C_CHARPTR],
            nil];
}

BOOL _AOCScalarTypeIsInArray(const char* scalarType, NSArray* array)
{
    NSCParameterAssert(scalarType != NULL);
    NSCParameterAssert(array != nil);
    
    if(scalarType[0] == '\0')
        return NO;
    
    NSNumber* scalarTypeNum = [NSNumber numberWithChar:scalarType[0]];
    return [array containsObject:scalarTypeNum];
}

BOOL _AOCReturnTypeIsSupported(const char* returnType)
{
    return _AOCScalarTypeIsInArray(returnType, _AOCSupportedScalarReturnTypes());
}

BOOL _AOCArgumentTypeIsSupported(const char* argumentType)
{
    return _AOCScalarTypeIsInArray(argumentType, _AOCSupportedScalarArgumentTypes());
}

BOOL _AOCCanInstallHook(NSMethodSignature* sig, NSError** outError)
{
    NSCParameterAssert(sig != nil);
    
    if(!_AOCReturnTypeIsSupported([sig methodReturnType])){
        AOCSetError(outError, [NSString stringWithFormat:@"Return type \"%s\" is not supported", [sig methodReturnType]], nil);
        return NO;
    }

    NSUInteger argIdx = 0;
    for(argIdx = 0; argIdx < [sig numberOfArguments]; ++argIdx){
        if(!_AOCArgumentTypeIsSupported([sig getArgumentTypeAtIndex:argIdx])){
            AOCSetError(outError, [NSString stringWithFormat:@"Argument at index %u of type \"%s\" is not supported", (unsigned int)argIdx, [sig getArgumentTypeAtIndex:argIdx]], nil);
            return NO;
        }
    }
        
    return YES;
}

ffi_closure* _AOCHookClosureAlloc(NSMethodSignature* sig, IMP originalImp)
{
    NSCParameterAssert(sig != nil);
    
    ffi_cif* cif = malloc(sizeof(ffi_cif));
    ffi_type** argTypes = malloc(sizeof(ffi_type) * [sig numberOfArguments]);
    ffi_closure* closure = NULL;
    
    closure = _AOCHookClosureInit(closure, cif, argTypes, sig, originalImp);
    if(closure == NULL){
        free(argTypes);
        free(cif);
    }
    return closure;
}
        
ffi_closure* _AOCHookClosureInit(ffi_closure* closure, ffi_cif* cif, ffi_type* argTypes[], NSMethodSignature* sig, IMP originalImp)
{   
    NSCParameterAssert(cif != NULL);
    NSCParameterAssert(argTypes != NULL);
    NSCParameterAssert(sig != nil);
    
    void (*closureMeth)(id, SEL, id) = (void (*)(id, SEL, id))closure;
    
    _AOCSetCIFArgTypes(argTypes, sig);
    
    closure = ffi_closure_alloc(sizeof(ffi_closure), (void**)&closureMeth);
    if(closure == NULL)
        return NULL;
    
    ffi_status status = FFI_OK;
    ffi_type* returnType = _AOCFFITypeForType([sig methodReturnType]);
    if(returnType == NULL)
        return NULL;
        
    status = ffi_prep_cif(cif,
                          FFI_DEFAULT_ABI,
                          [sig numberOfArguments],
                          returnType,
                          argTypes);
    if(status != FFI_OK)
        return NULL;
    
    struct _AOCClosureInfo * userData = malloc(sizeof(struct _AOCClosureInfo));
    userData->closure = closure;
    userData->originalImp = originalImp;
    userData->isRunning = NO;
    userData->shouldFreeAfterRun = NO;
    
    status = ffi_prep_closure_loc(closure, cif, _AOCHookClosureImp, userData, closureMeth);
    if(status != FFI_OK)
        return NULL;
        
    return closure;
}

void _AOCHookClosureFree(ffi_closure* closure)
{
    free(closure->cif->arg_types);
    free(closure->cif);
    free(closure->user_data);
    ffi_closure_free(closure);
}

void _AOCSetCIFArgTypes(ffi_type* argTypeList[], NSMethodSignature* sig)
{
    NSUInteger argIdx = 0;
    for(argIdx = 0; argIdx < [sig numberOfArguments]; ++argIdx){
        ffi_type* argType = _AOCFFITypeForType([sig getArgumentTypeAtIndex:argIdx]);
        if(argType == NULL)
            return;
        argTypeList[argIdx] = argType;
    }
}

ffi_type* _AOCFFITypeForType(const char* type)
{
    NSCParameterAssert(type != NULL);
    NSCParameterAssert(type[0] != '\0');
    
    switch(type[0]){
        case _C_ID:
        case _C_CLASS:
        case _C_SEL:
        case _C_PTR:
        case _C_CHARPTR:
            return &ffi_type_pointer;
            
        case _C_CHR: return &ffi_type_schar;
        case _C_UCHR: return &ffi_type_uchar;
        case _C_SHT: return &ffi_type_sshort;
        case _C_USHT: return &ffi_type_ushort;
        case _C_INT: return &ffi_type_sint;
        case _C_UINT: return &ffi_type_uint;
        case _C_LNG: return &ffi_type_slong;
        case _C_ULNG: return &ffi_type_ulong;
        case _C_LNG_LNG: return &ffi_type_sint64;
        case _C_ULNG_LNG: return &ffi_type_uint64;
        case _C_FLT: return &ffi_type_float;
        case _C_DBL: return &ffi_type_double;
        case _C_VOID: return &ffi_type_void;
            
        default:
            NSLog(@"unhandled type \"%s\"", type);
            return NULL;
    }
}

NSMutableDictionary* _AOCGetClosuresBySelector(Class cls, BOOL createIfNeeded)
{
    if(g_closureBySelectorByClass == nil){
        if(createIfNeeded){
            g_closureBySelectorByClass = [NSMutableDictionary new];
        } else {
            return NULL;
        }
    }
    
    NSMutableDictionary* closuresBySel = [g_closureBySelectorByClass objectForKey:NSStringFromClass(cls)];
    if(closuresBySel == nil && createIfNeeded){
        closuresBySel = [NSMutableDictionary dictionary];
        [g_closureBySelectorByClass setObject:closuresBySel forKey:NSStringFromClass(cls)];
    }
    
    return closuresBySel;
}

ffi_closure* _AOCGetClosure(Class cls, SEL selector)
{
    NSDictionary* closuresBySel = _AOCGetClosuresBySelector(cls, NO);
    if(closuresBySel == nil)
        return NULL;
    
    NSValue* closureVal = [closuresBySel objectForKey:NSStringFromSelector(selector)];
    if(closureVal == nil)
        return nil;
    else
        return (ffi_closure*)[closureVal pointerValue];
}

void _AOCSetClosure(ffi_closure* closure, Class cls, SEL selector)
{
    NSMutableDictionary* closuresBySel = _AOCGetClosuresBySelector(cls, YES);
    NSString* selectorKey = NSStringFromSelector(selector);
    
    NSValue* oldClosureVal = [closuresBySel objectForKey:selectorKey];
    if(oldClosureVal != nil){
        ffi_closure* oldClosure = [oldClosureVal pointerValue];
        struct _AOCClosureInfo* info = (struct _AOCClosureInfo*)oldClosure->user_data;
        if(info->isRunning){
            info->shouldFreeAfterRun = YES;
        } else {
            _AOCHookClosureFree(oldClosure);
        }
    }
    
    if(closure == NULL){
        [closuresBySel removeObjectForKey:selectorKey];
    } else {
        NSValue* newClosureVal = [NSValue valueWithPointer:closure];
        [closuresBySel setObject:newClosureVal forKey:selectorKey];
    }
}

void _AOCHookClosureImp(ffi_cif* cif, void* result, void** args, void* userdata)
{
    struct _AOCClosureInfo* info = (struct _AOCClosureInfo*)userdata;
    
    if(g_globalInvocationHook == NULL){
        ffi_call(cif, FFI_FN(info->originalImp), result, args);
        return;
    }
 
    info->isRunning = YES;
    info->shouldFreeAfterRun = NO;
    
    AOCFFIInvocation* inv = [[AOCFFIInvocation alloc] initWithCif:cif arguments:args imp:info->originalImp];
    g_globalInvocationHook(inv);
    if(result != NULL && cif->rtype != &ffi_type_void){
        [inv getReturnValue:result];
    }
    [inv release]; inv = nil;
    
    if(info->shouldFreeAfterRun)
        _AOCHookClosureFree(info->closure);
}

#pragma mark -
#pragma mark Public functions

BOOL AOCInstallHook(Class cls, SEL selector, NSError** outError)
{
    NSCParameterAssert(cls != NULL);
    NSCParameterAssert(selector != NULL);
    
    Method method = class_getInstanceMethod(cls, selector);
    if(method == NULL){
        AOCSetError(outError, [NSString stringWithFormat:@"Class %@ does not have an instance method %@", NSStringFromClass(cls), NSStringFromSelector(selector)], nil);
        return NO;
    }
    
    NSMethodSignature* sig = [cls instanceMethodSignatureForSelector:selector];
    if(sig == nil){
        AOCSetError(outError, [NSString stringWithFormat:@"Class %@ returned nil for instanceMethodSignatureForSelector:@selector(%@)", NSStringFromClass(cls), NSStringFromSelector(selector)], nil);
        return NO;
    }
    
    if(!_AOCCanInstallHook(sig, outError))
        return NO;

    if(AOCIsHookInstalled(cls, selector)){
        AOCSetError(outError, NSLocalizedString(@"Hook already installed", nil), nil);
        return NO;
    }
    
    ffi_closure* hookClosure = _AOCHookClosureAlloc(sig, method_getImplementation(method));
    NSCAssert(hookClosure != NULL, @"This should always return non-null");
    
    method_setImplementation(method, (IMP)hookClosure);
    _AOCSetClosure(hookClosure, cls, selector);
    
    return YES;
}

void AOCUninstallHook(Class cls, SEL selector)
{
    NSCParameterAssert(cls != NULL);
    NSCParameterAssert(selector != NULL);
    
    ffi_closure* closure = _AOCGetClosure(cls, selector);
    if(closure == NULL)
        return;
    
    Method method = class_getInstanceMethod(cls, selector);
    if(method == NULL){
        NSLog(@"Instance method \"%@\" doesn't exist on class \"%@\"", NSStringFromSelector(selector), NSStringFromClass(cls));
        return;
    }

    struct _AOCClosureInfo* info = (struct _AOCClosureInfo*)closure->user_data;
    method_setImplementation(method, info->originalImp);
    _AOCSetClosure(NULL, cls, selector);
}

BOOL AOCIsHookInstalled(Class cls, SEL selector)
{
    return (_AOCGetClosure(cls, selector) != NULL);
}

AOCMethodInvocationHook AOCGlobalInvocationHook()
{
    return g_globalInvocationHook;
}

void AOCSetGlobalInvocationHook(AOCMethodInvocationHook hook)
{
    g_globalInvocationHook = hook;
}
