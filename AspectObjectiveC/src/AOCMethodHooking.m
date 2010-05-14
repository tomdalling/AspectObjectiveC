
#import "AOCMethodHooking.h"
#import "AOCError.h"
#import "ffi.h"
#include <objc/runtime.h>
#include "AOCFFIInvocation.h"
#include "NSScanner+AOCObjcTypeScanning.h"

#ifndef FFI_CLOSURES
#   error "libffi closures are not supported for the current architecture"
#endif

static NSMutableDictionary* g_closureBySelectorByClass = nil;

struct _AOCClosureInfo {
    ffi_closure* closure;
    IMP originalImp;
    BOOL isRunning;
    BOOL shouldFreeAfterRun;
    AOCMethodInvocationHook installedHook;
    void* context;
};


#pragma mark -
#pragma mark Private function declarations

NSString* _AOCStructNameFromType(const char* structType);

ffi_closure* _AOCHookClosureAlloc(NSMethodSignature* sig, IMP originalImp, AOCMethodInvocationHook hook, void* context, NSError** outError);
ffi_closure* _AOCHookClosureInit(ffi_closure* closure, ffi_cif* cif, ffi_type* argTypes[], NSMethodSignature* sig, IMP originalImp, AOCMethodInvocationHook hook, void* context, NSError** outError);
void         _AOCHookClosureFree(ffi_closure* closure);
BOOL         _AOCSetCIFArgTypes(ffi_type* argTypeList[], NSMethodSignature* sig, NSError** outError);
ffi_type*    _AOCFFITypeAlloc(const char* type);
void         _AOCFFITypeFree(ffi_type* structType);
ffi_type*    _AOCFFIStructTypeAlloc(const char* structTypeStr);
BOOL         _AOCMallocElementsForStructType(const char* structType, ffi_type*** outElements);
NSArray*     _AOCElementTypeStringsForStruct(const char* structTypeStr);

NSMutableDictionary* _AOCGetClosuresBySelector(Class cls, BOOL createIfNeeded);
ffi_closure*         _AOCGetClosure(Class cls, SEL selector);
void                 _AOCSetClosure(ffi_closure* closure, Class cls, SEL selector);

void _AOCHookClosureImp(ffi_cif* cif, void* result, void** args, void* userdata);

#pragma mark -
#pragma mark Private function definitions

NSString* _AOCStructNameFromType(const char* structType)
{
    if(structType[0] != _C_STRUCT_B)
        return nil; //not a struct type
    
    NSString* structName = nil;
    NSScanner* scanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:structType]];
    [scanner scanString:@"{" intoString:nil];
    [scanner scanUpToString:@"=" intoString:&structName];
    
    return structName;
}

ffi_closure* _AOCHookClosureAlloc(NSMethodSignature* sig, IMP originalImp, AOCMethodInvocationHook hook, void* context, NSError** outError)
{
    NSCParameterAssert(sig != nil);
    NSCParameterAssert(hook != NULL);
    
    ffi_cif* cif = malloc(sizeof(ffi_cif));
    ffi_type** argTypes = malloc(sizeof(ffi_type) * [sig numberOfArguments]);
    ffi_closure* closure = NULL;
    
    closure = _AOCHookClosureInit(closure, cif, argTypes, sig, originalImp, hook, context, outError);
    if(closure == NULL){
        free(argTypes);
        free(cif);
    }
    return closure;
}
        
ffi_closure* _AOCHookClosureInit(ffi_closure* closure, ffi_cif* cif, ffi_type* argTypes[], NSMethodSignature* sig, IMP originalImp, AOCMethodInvocationHook hook, void* context, NSError** outError)
{   
    NSCParameterAssert(cif != NULL);
    NSCParameterAssert(argTypes != NULL);
    NSCParameterAssert(sig != nil);
    NSCParameterAssert(hook != NULL);
    
    void (*closureMeth)(id, SEL, id) = (void (*)(id, SEL, id))closure;
    
    if(!_AOCSetCIFArgTypes(argTypes, sig, outError))
        return NULL;
    
    closure = ffi_closure_alloc(sizeof(ffi_closure), (void**)&closureMeth);
    if(closure == NULL)
        return NULL;
    
    ffi_status status = FFI_OK;
    ffi_type* returnType = _AOCFFITypeAlloc([sig methodReturnType]);
    if(returnType == NULL){
        AOCSetError(outError, @"AOC can not handle method return type", nil);
        return NULL;
    }
        
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
    userData->installedHook = hook;
    userData->isRunning = NO;
    userData->shouldFreeAfterRun = NO;
    userData->context = context;
    
    status = ffi_prep_closure_loc(closure, cif, _AOCHookClosureImp, userData, closureMeth);
    if(status != FFI_OK)
        return NULL;
        
    return closure;
}

void _AOCHookClosureFree(ffi_closure* closure)
{
    NSUInteger i = 0;
    for(i = 0; i < closure->cif->nargs; ++i){
        _AOCFFITypeFree(closure->cif->arg_types[i]);
    }
    _AOCFFITypeFree(closure->cif->rtype);
    free(closure->cif->arg_types);
    free(closure->cif);
    free(closure->user_data);
    ffi_closure_free(closure);
}

BOOL _AOCSetCIFArgTypes(ffi_type* argTypeList[], NSMethodSignature* sig, NSError** outError)
{
    NSUInteger argIdx = 0;
    for(argIdx = 0; argIdx < [sig numberOfArguments]; ++argIdx){
        argTypeList[argIdx] = _AOCFFITypeAlloc([sig getArgumentTypeAtIndex:argIdx]);
        if(argTypeList[argIdx] == NULL){
            AOCSetError(outError, [NSString stringWithFormat:@"AOC can not handle the type of argument number %i", ((int)argIdx) - 1], nil);
            return NO;
        }
    }
    
    return YES;
}

ffi_type* _AOCFFITypeAlloc(const char* type)
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
            
        case _C_STRUCT_B: return _AOCFFIStructTypeAlloc(type);
            
        default:
            NSLog(@"unhandled type \"%s\"", type);
            return NULL;
    }
}

void _AOCFFITypeFree(ffi_type* structType)
{
    if(structType == NULL)
        return;
    if(structType->type != FFI_TYPE_STRUCT)
        return; //base case
    
    size_t elementIdx = 0;
    ffi_type* elementType = NULL;
    while((elementType = structType->elements[elementIdx]) != NULL) {
        if(elementType->type == FFI_TYPE_STRUCT){
            _AOCFFITypeFree(elementType); //recurse
        }
        ++elementIdx;
    }
    
    free(structType->elements);
    free(structType);
}

ffi_type* _AOCFFIStructTypeAlloc(const char* structTypeStr)
{
    ffi_type* structType = (ffi_type*)malloc(sizeof(ffi_type));
    structType->size = 0;
    structType->alignment = 0;
    structType->type = FFI_TYPE_STRUCT;
    BOOL didWork = _AOCMallocElementsForStructType(structTypeStr, &(structType->elements));
    
    if(didWork){
        return structType;
    } else {
        _AOCFFITypeFree(structType);
        return NULL;
    }
}

BOOL _AOCMallocElementsForStructType(const char* structType, ffi_type*** outElements)
{
    NSCParameterAssert(outElements != NULL);
    NSCParameterAssert(structType != NULL);
    
    NSArray* structElementStrs = _AOCElementTypeStringsForStruct(structType);
    if(structElementStrs == nil || [structElementStrs count] <= 0)
        return NO;
    
    NSUInteger numElements = [structElementStrs count];    
    *outElements = (ffi_type**)malloc(sizeof(void*) * (numElements + 1));
    (*outElements)[numElements] = NULL; //null terminated
    
    NSUInteger i = 0;
    for(i = 0; i < numElements; ++i){
        NSString* typeStr = [structElementStrs objectAtIndex:i];
        ffi_type* type = _AOCFFITypeAlloc([typeStr UTF8String]);
        (*outElements)[i] = type;
        if(type == NULL){
            return NO;
        }
    }
    
    return YES;
}

NSArray* _AOCElementTypeStringsForStruct(const char* structTypeStr)
{
    NSString* structTypeNSStr = [NSString stringWithUTF8String:structTypeStr];
    NSScanner* scanner = [NSScanner scannerWithString:structTypeNSStr];
    NSMutableArray* elementTypes = [NSMutableArray array];
    
    if(![scanner scanString:@"{" intoString:nil])
        return nil;
    if(![scanner scanUpToString:@"=" intoString:nil])
        return nil;
    if(![scanner scanString:@"=" intoString:nil])
        return nil;
    
    while(YES){
        if([scanner scanString:@"}" intoString:nil]){
            return elementTypes;
        }
        
        NSString* nextElement = nil;
        if([scanner scanObjcType:&nextElement]){
            [elementTypes addObject:nextElement];
        } else {
            return nil;
        }
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
    
    if(info->installedHook == NULL){
        ffi_call(cif, FFI_FN(info->originalImp), result, args);
        return;
    }
 
    info->isRunning = YES;
    info->shouldFreeAfterRun = NO;
    
    AOCFFIInvocation* inv = [[AOCFFIInvocation alloc] initWithCif:cif arguments:args imp:info->originalImp];
    info->installedHook(inv, info->context);
    if(result != NULL && cif->rtype != &ffi_type_void){
        [inv getReturnValue:result];
    }
    [inv release]; inv = nil;
    
    if(info->shouldFreeAfterRun)
        _AOCHookClosureFree(info->closure);
}

#pragma mark -
#pragma mark Public functions

BOOL AOCInstallHook(AOCMethodInvocationHook hook, void* context, Class cls, SEL selector, NSError** outError)
{
    NSCParameterAssert(cls != NULL);
    NSCParameterAssert(selector != NULL);
    NSCParameterAssert(hook != NULL);
    
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
    
    if(AOCIsHookInstalled(cls, selector)){
        AOCSetError(outError, @"Hook already installed", nil);
        return NO;
    }
    
    ffi_closure* hookClosure = _AOCHookClosureAlloc(sig, method_getImplementation(method), hook, context, outError);
    if(hookClosure == NULL)
        return NO;
    
    method_setImplementation(method, (IMP)hookClosure);
    _AOCSetClosure(hookClosure, cls, selector);
    
    return YES;
}

AOCMethodInvocationHook AOCGetInstalledHook(Class cls, SEL selector, void** outContext)
{
    NSCParameterAssert(cls != NULL);
    NSCParameterAssert(selector != NULL);
    
    ffi_closure* closure = _AOCGetClosure(cls, selector);
    if(closure == NULL)
        return NULL;
    
    struct _AOCClosureInfo* info = (struct _AOCClosureInfo*)closure->user_data;
    if(outContext)
        *outContext = info->context;
    
    return info->installedHook;
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
