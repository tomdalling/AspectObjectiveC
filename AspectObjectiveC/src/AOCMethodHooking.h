
#import <Cocoa/Cocoa.h>

typedef void(*AOCMethodInvocationHook)(NSInvocation*);

BOOL AOCInstallHook(Class cls, SEL selector, NSError** outError);
void AOCUninstallHook(Class cls, SEL selector);
BOOL AOCIsHookInstalled(Class cls, SEL selector);
//TODO: BOOL AOCInstallValueForKeyOverride(Class cls);
//TODO: BOOL AOCUninstallValueForKeyOverride(Class cls);
AOCMethodInvocationHook AOCGlobalInvocationHook();
void AOCSetGlobalInvocationHook(AOCMethodInvocationHook hook);