
#import "AOCMethodHooking.h"
#import "AOCError.h"
#include <objc/runtime.h>

static AOCMethodInvocationHook g_globalInvocationHook = NULL;

static NSString* const _AOC_BACKUP_SEL_PREFIX = @"__AOC_actual_imp_of_";

#pragma mark -
#pragma mark Private functions declaration

SEL _AOCBackupSelForSel(SEL selector);
BOOL _AOCCanInstallHookForMethodSig(NSMethodSignature* methodSig, NSError** outError);
IMP _AOCHookImpForMethodSig(NSMethodSignature* methodSig);
void _AOCHookImpGuts(id self, SEL _cmd, NSInvocation* inv);
NSInvocation* _AOCInvocationFromVargs(id self, SEL _cmd, va_list vl);
void _AOCSetInvocationArgFromVargs(NSInvocation* inv, NSMethodSignature* ms, va_list vl, int argIndex);

#pragma mark -
#pragma mark Hook IMPs for supported return types

#define _AOC_HOOK_IMP_GUTS\
	va_list vl; \
	va_start(vl,_cmd);\
	NSInvocation* inv = _AOCInvocationFromVargs(self, _cmd, vl); \
	va_end(vl); \
	\
	_AOCHookImpGuts(self, _cmd, inv);

#define _AOC_MAKE_HOOK_IMP(TYPE, SUFFIX) \
	TYPE _AOCHookImp_ ## SUFFIX(id self, SEL _cmd, ...) \
	{ \
		_AOC_HOOK_IMP_GUTS \
		\
		TYPE returnVal; \
		[inv getReturnValue:&returnVal]; \
		return returnVal; \
	} \

_AOC_MAKE_HOOK_IMP(char,char);
_AOC_MAKE_HOOK_IMP(int,int);
_AOC_MAKE_HOOK_IMP(short,short);
_AOC_MAKE_HOOK_IMP(long,long);
_AOC_MAKE_HOOK_IMP(long long,longLong);
_AOC_MAKE_HOOK_IMP(unsigned char,uchar);
_AOC_MAKE_HOOK_IMP(unsigned int,uint);
_AOC_MAKE_HOOK_IMP(unsigned short,ushort);
_AOC_MAKE_HOOK_IMP(unsigned long,ulong);
_AOC_MAKE_HOOK_IMP(unsigned long long,ulongLong);
_AOC_MAKE_HOOK_IMP(float,float);
_AOC_MAKE_HOOK_IMP(double,double);
_AOC_MAKE_HOOK_IMP(_Bool,bool);
_AOC_MAKE_HOOK_IMP(char*,charptr);
_AOC_MAKE_HOOK_IMP(id,id);
_AOC_MAKE_HOOK_IMP(Class,class);
_AOC_MAKE_HOOK_IMP(SEL,sel);
_AOC_MAKE_HOOK_IMP(void*,ptr);
//special case because it doesn't return anything
void _AOCHookImp_void(id self, SEL _cmd, ...) { _AOC_HOOK_IMP_GUTS }

#pragma mark -
#pragma mark Private functions definition

SEL _AOCBackupSelForSel(SEL selector)
{
	NSCParameterAssert(selector != NULL);
	return NSSelectorFromString([_AOC_BACKUP_SEL_PREFIX stringByAppendingString:NSStringFromSelector(selector)]);
}

BOOL _AOCCanInstallHookForMethodSig(NSMethodSignature* methodSig, NSError** outError)
{
	IMP hookImp = _AOCHookImpForMethodSig(methodSig);
	if(hookImp == NULL){
		AOCSetError(outError, NSLocalizedString(@"Can't install hook",@""), NSLocalizedString(@"The return type of the method is unsupported.",@""));
		return NO;
	}
	
	//TODO: check argument types
	
	return YES;
}

IMP _AOCHookImpForMethodSig(NSMethodSignature* methodSig)
{
	NSCAssert(methodSig != nil, @"");
	const char* returnTypeEncoding = [methodSig methodReturnType];
	NSCAssert(returnTypeEncoding != NULL, @"");
	NSCAssert(returnTypeEncoding[0] != 0, @"");
	
	switch(returnTypeEncoding[0]){
		case _C_CHR: return (IMP)_AOCHookImp_char;
		case _C_INT: return (IMP)_AOCHookImp_int;
		case _C_SHT: return (IMP)_AOCHookImp_short;
		case _C_LNG: return (IMP)_AOCHookImp_long;
		case _C_LNG_LNG: return (IMP)_AOCHookImp_longLong;
		case _C_UCHR: return (IMP)_AOCHookImp_uchar;
		case _C_UINT: return (IMP)_AOCHookImp_uint;
		case _C_USHT: return (IMP)_AOCHookImp_ushort;
		case _C_ULNG: return (IMP)_AOCHookImp_ulong;
		case _C_ULNG_LNG: return (IMP)_AOCHookImp_ulongLong;
		case _C_FLT: return (IMP)_AOCHookImp_float;
		case _C_DBL: return (IMP)_AOCHookImp_double;
		case _C_BOOL: return (IMP)_AOCHookImp_bool;
		case _C_VOID: return (IMP)_AOCHookImp_void;
		case _C_CHARPTR: return (IMP)_AOCHookImp_charptr;
		case _C_ID: return (IMP)_AOCHookImp_id;
		case _C_CLASS: return (IMP)_AOCHookImp_class;
		case _C_SEL: return (IMP)_AOCHookImp_sel;
		case _C_PTR: return (IMP)_AOCHookImp_ptr;
		default: return NULL;
	}
}

void _AOCHookImpGuts(id self, SEL _cmd, NSInvocation* inv)
{
	SEL backupSel = _AOCBackupSelForSel(_cmd);
	Method mthd = class_getInstanceMethod([self class], _cmd);
	Method backupMthd = class_getInstanceMethod([self class], backupSel);
	NSCAssert(mthd && backupMthd, @"");
	IMP realImp = method_getImplementation(backupMthd);
	IMP hookImp = method_getImplementation(mthd);
	
	//TODO: handle hook uninstall during invocation
	method_setImplementation(mthd, realImp);
	if(g_globalInvocationHook == NULL){
		[inv invoke];
	} else {
		g_globalInvocationHook(inv);
	}
	method_setImplementation(mthd, hookImp);
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
#		define ARGT(TYPECHAR, TYPE) \
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


#pragma mark -
#pragma mark Public functions

BOOL AOCInstallHook(Class cls, SEL selector, NSError** outError)
{
	NSCParameterAssert(cls != NULL);
	NSCParameterAssert(selector != NULL);
	
	if(AOCIsHookInstalled(cls, selector)){
		AOCSetError(outError, NSLocalizedString(@"Can't install hook", @""), NSLocalizedString(@"A hook is already installed.", @""));
		return NO;
	}
	
	Method mthd = class_getInstanceMethod(cls, selector);
	if(mthd == NULL){
		AOCSetError(outError, NSLocalizedString(@"Can't install hook", @""), NSLocalizedString(@"No instance method exists for the specified selector and class.", @""));
		return NO;
	}
	
	NSMethodSignature* methodSig = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(mthd)];
	NSCAssert(methodSig != nil, @"Couldn't create NSMethodSignature from method_getTypeEncoding");
	if(!_AOCCanInstallHookForMethodSig(methodSig, outError))
		return NO;
	
	SEL backupSel = _AOCBackupSelForSel(selector);
	BOOL didBackup = class_addMethod(cls, backupSel, method_getImplementation(mthd), method_getTypeEncoding(mthd));
	if(!didBackup){
		AOCSetError(outError, NSLocalizedString(@"Can't install hook", @""), NSLocalizedString(@"Failed to create backup method.", @""));
		return NO;
	}
	
	IMP hookImp = _AOCHookImpForMethodSig(methodSig);
	NSCAssert(hookImp != NULL, @"_AOCCanInstallHookForMethodSig passed, but _AOCHookImpForMethodSig returned NULL");
	method_setImplementation(mthd, hookImp);
	
	return YES;
}

void AOCUninstallHook(Class cls, SEL selector)
{
	NSCParameterAssert(cls != NULL);
	NSCParameterAssert(selector != NULL);
	
	if(!AOCIsHookInstalled(cls, selector))
		return;
	
	SEL backupSel = _AOCBackupSelForSel(selector);
	Method mthd = class_getInstanceMethod(cls, selector);
	Method backupMthd = class_getInstanceMethod(cls, backupSel);
	
	method_exchangeImplementations(mthd, backupMthd);
	//TODO: find a way to remove backupMthd or mark it as deleted
}

BOOL AOCIsHookInstalled(Class cls, SEL selector)
{
	if(cls == NULL || selector == NULL)
		return NO;
	
	SEL backupSel = _AOCBackupSelForSel(selector);
	return (class_getInstanceMethod(cls, backupSel) != NULL);
}

AOCMethodInvocationHook AOCGlobalInvocationHook()
{
	return g_globalInvocationHook;
}

void AOCSetGlobalInvocationHook(AOCMethodInvocationHook hook)
{
	g_globalInvocationHook = hook;
}
