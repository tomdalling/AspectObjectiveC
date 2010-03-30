
#import "AOCMethodHooking.h"
#import "AOCError.h"
#import "ffi.h"
#include <objc/runtime.h>
#include <sys/mman.h>

#ifndef FFI_CLOSURES
#   error "libffi closures are not supported for the current architecture"
#endif

static AOCMethodInvocationHook g_globalInvocationHook = NULL;

static NSString* const _AOC_BACKUP_SEL_PREFIX = @"__AOC_actual_imp_of_";
static IMP const _AOC_INVALID_IMP = (IMP)((void*)0xDEADBEEF);

#pragma mark -
#pragma mark Private functions declaration

SEL _AOCBackupSelForSel(SEL selector);
BOOL _AOCCanInstallHookForMethodSig(NSMethodSignature* methodSig, NSError** outError);
IMP _AOCHookImpForActualImp(IMP actualImp);
void _AOCHookImpGuts(id self, SEL _cmd, NSInvocation* inv);
NSInvocation* _AOCInvocationFromVargs(id self, SEL _cmd, va_list vl);
void _AOCSetInvocationArgFromVargs(NSInvocation* inv, NSMethodSignature* ms, va_list vl, int argIndex);
BOOL _AOCCreateOrRevalidateBackupMethod(Class cls, SEL selector, NSError** outError);
BOOL _AOCDoesValidBackupMethodExist(Class cls, SEL selector);
void _AOCInvalidateBackupMethod(Class cls, SEL selector);
void _AOCSetImpFromBackupMethod(Class cls, SEL selector);

#pragma mark -
#pragma mark Hook IMPs for supported return types

void _AOCHookImp(ffi_cif* cif, void* result, void** args, void* userdata)
{
    NSLog(@"It begins!!!!!!!!!!!!!!!!!");
    id self = *((id*)args[0]);
    SEL _cmd = *((SEL*)args[1]);
    void (*actualImp)(id,SEL,id) = (void (*)(id,SEL,id))userdata;
    
    NSLog(@"\tactualImp = %p", actualImp);
    NSLog(@"\tself = %p", self);
    NSLog(@"\t_cmd = %p", _cmd);
    
    actualImp(self, _cmd, nil);
    NSLog(@"ran actual!");
    
    
    NSLog(@"<%p %@> %@", self, [self className], NSStringFromSelector(_cmd));
}

#pragma mark -
#pragma mark Private functions definition

SEL _AOCBackupSelForSel(SEL selector)
{
    NSCParameterAssert(selector != NULL);
    return NSSelectorFromString([_AOC_BACKUP_SEL_PREFIX stringByAppendingString:NSStringFromSelector(selector)]);
}

BOOL _AOCCanInstallHookForMethodSig(NSMethodSignature* methodSig, NSError** outError)
{
    //TODO: here
    
    return YES;
}

IMP _AOCHookImpForActualImp(IMP actualImp)
{
    ffi_cif* cif = malloc(sizeof(ffi_cif));
    ffi_closure *closure;
    void (*boundMethod)(id, SEL, id);
    void (*actualMethod)(id, SEL, id) = (void (*)(id, SEL, id))actualImp;
    ffi_type** arg_types = malloc(sizeof(ffi_type)*3);
    ffi_status status;
    
    arg_types[0] = &ffi_type_pointer;
    arg_types[1] = &ffi_type_pointer;
    arg_types[2] = &ffi_type_pointer;
    
    if ((closure = ffi_closure_alloc(sizeof(ffi_closure), (void**)&boundMethod)) == NULL)
    {
        NSLog(@"error A");
    }
    
    // Prepare the ffi_cif structure.
    if ((status = ffi_prep_cif(cif, FFI_DEFAULT_ABI,
                               3, &ffi_type_void, arg_types)) != FFI_OK)
    {
        NSLog(@"error B");
    }
    
    // Prepare the ffi_closure structure.
    if ((status = ffi_prep_closure_loc(closure, cif, _AOCHookImp, (void*)actualImp, (void*)boundMethod)) != FFI_OK)
    {
        NSLog(@"error C");
    }
    
    NSLog(@"closure = %p", closure);
    NSLog(@"%p for %p", boundMethod, actualImp);
    boundMethod(nil, NULL, nil);
    NSLog(@"Done");
    actualMethod(nil, NULL, nil);
    NSLog(@"Done2");
    return (IMP)boundMethod;
    
    // The closure is now ready to be executed, and can be saved for later
    // execution if desired.
    
//    Invoke the closure.
//    result = ((unsigned char(*)(float, unsigned int))closure)(42, 5.1);
//    
//    // Free the memory associated with the closure.
//    if (munmap(closure, sizeof(closure)) == -1)
//    {
//        // Check errno and handle the error.
//    }
//    
//    return 0;
}

void _AOCHookImpGuts(id self, SEL _cmd, NSInvocation* inv)
{
    SEL backupSel = _AOCBackupSelForSel(_cmd);
    Method mthd = class_getInstanceMethod([self class], _cmd);
    Method backupMthd = class_getInstanceMethod([self class], backupSel);
    NSCAssert(mthd && backupMthd, @"");
    IMP backupImp = method_getImplementation(backupMthd);
    IMP hookImp = method_getImplementation(mthd);
    
    //put the original IMP back in before invocation
    method_setImplementation(mthd, backupImp);

    if(g_globalInvocationHook == NULL){
        [inv invoke];
    } else {
        g_globalInvocationHook(inv);
    }

    //see if hook was uninstalled during invocation.
    //if so leave the original IMP in, otherwise put the hook IMP back in
    if(AOCIsHookInstalled([self class], _cmd)){
        method_setImplementation(mthd, hookImp);
    }
}

NSInvocation* _AOCInvocationFromVargs(id self, SEL _cmd, va_list vl)
{
    NSMethodSignature* ms = [self methodSignatureForSelector:_cmd];
    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:ms];
    [inv setSelector:_cmd];
    [inv setTarget:self];
    
    int numArgs = [ms numberOfArguments];
    int i;
    for (i=2; i < numArgs; ++i) {
        _AOCSetInvocationArgFromVargs(inv, ms, vl, i);
    }
    
    return inv;
}

void _AOCSetInvocationArgFromVargs(NSInvocation* inv, NSMethodSignature* ms, va_list vl, int argIndex)
{
    const char* argType = [ms getArgumentTypeAtIndex:argIndex];
    NSCAssert(argType[0] != 0,@"");
    
    switch(argType[0]){
#        define ARGT(TYPECHAR, TYPE) \
            case TYPECHAR:{ \
                TYPE arg = va_arg(vl, TYPE); \
                [inv setArgument:&arg atIndex:argIndex];\
            break;}\

            ARGT(_C_ID, id);
            ARGT(_C_CLASS, Class);
            ARGT(_C_SEL, SEL);
            ARGT(_C_CHR, int); //char is promoted to int with va_arg
            ARGT(_C_UCHR, unsigned int); //char is promoted to int with va_arg
            ARGT(_C_SHT, int); //short is promoted to int with va_arg
            ARGT(_C_USHT, unsigned int); //short is promoted to int with va_arg
            ARGT(_C_INT, int);
            ARGT(_C_UINT, unsigned int);
            ARGT(_C_LNG, long);
            ARGT(_C_ULNG, unsigned long);
            ARGT(_C_LNG_LNG, long long);
            ARGT(_C_ULNG_LNG, unsigned long long);
            ARGT(_C_FLT, double); //float is promoted to double with va_arg
            ARGT(_C_DBL, double);
            ARGT(_C_BOOL, int); //_Bool is promoted to int with va_arg
            ARGT(_C_PTR, void*);
            ARGT(_C_CHARPTR, char*);
        default:
            NSLog(@"Can't handle arg type: %s", argType);
    }
}

BOOL _AOCCreateOrRevalidateBackupMethod(Class cls, SEL selector, NSError** outError)
{
    Method realMethod = class_getInstanceMethod(cls, selector);
    NSCAssert(realMethod != NULL, @"");
    
    SEL backupSel = _AOCBackupSelForSel(selector);
    Method backupMethod = class_getInstanceMethod(cls, backupSel);
    if(backupMethod == nil){
        class_addMethod(cls, backupSel, method_getImplementation(realMethod), method_getTypeEncoding(realMethod));
        return YES;
    }
    
    NSCAssert(strcmp(method_getTypeEncoding(realMethod), method_getTypeEncoding(backupMethod)) == 0, @"");
    if(method_getImplementation(backupMethod) == _AOC_INVALID_IMP){
        method_setImplementation(backupMethod, method_getImplementation(realMethod));
        return YES;
    }
    
    AOCSetError(outError, NSLocalizedString(@"Can't create backup method", @""), NSLocalizedString(@"Backup method already exists", @""));
    return NO;
}

BOOL _AOCDoesValidBackupMethodExist(Class cls, SEL selector)
{
    SEL backupSel = _AOCBackupSelForSel(selector);
    Method backupMethod = class_getInstanceMethod(cls, backupSel);
    if(backupMethod == NULL)
        return NO;
    
    if(method_getImplementation(backupMethod) == _AOC_INVALID_IMP)
        return NO;
    
    return YES;
}

void _AOCInvalidateBackupMethod(Class cls, SEL selector)
{
    SEL backupSel = _AOCBackupSelForSel(selector);
    Method backupMethod = class_getInstanceMethod(cls, backupSel);
    if(backupMethod == NULL)
        return;
    
    method_setImplementation(backupMethod, _AOC_INVALID_IMP);
}

void _AOCSetImpFromBackupMethod(Class cls, SEL selector)
{
    Method realMethod = class_getInstanceMethod(cls, selector);
    Method backupMethod = class_getInstanceMethod(cls, _AOCBackupSelForSel(selector));
    NSCAssert(backupMethod != NULL && realMethod != NULL, @"");
    method_exchangeImplementations(realMethod, backupMethod);
}

#pragma mark -
#pragma mark Public functions

BOOL AOCInstallHook(Class cls, SEL selector, NSError** outError)
{
    NSCParameterAssert(cls != NULL);
    NSCParameterAssert(selector != NULL);
    
    Method mthd = class_getInstanceMethod(cls, selector);
    IMP hookImp = _AOCHookImpForActualImp(method_getImplementation(mthd));
    method_setImplementation(mthd, hookImp);
    
    return YES;
}

void AOCUninstallHook(Class cls, SEL selector)
{
    NSCParameterAssert(cls != NULL);
    NSCParameterAssert(selector != NULL);
    
    if(!AOCIsHookInstalled(cls, selector))
        return;
    
    _AOCSetImpFromBackupMethod(cls, selector);
    _AOCInvalidateBackupMethod(cls, selector);
}

BOOL AOCIsHookInstalled(Class cls, SEL selector)
{
    if(cls == NULL || selector == NULL)
        return NO;
    
    return _AOCDoesValidBackupMethodExist(cls, selector);
}

AOCMethodInvocationHook AOCGlobalInvocationHook()
{
    return g_globalInvocationHook;
}

void AOCSetGlobalInvocationHook(AOCMethodInvocationHook hook)
{
    g_globalInvocationHook = hook;
}
