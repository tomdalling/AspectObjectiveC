
#import <Cocoa/Cocoa.h>

typedef void(*AOCMethodInvocationHook)(NSInvocation*);

BOOL AOCInstallHook(Class cls, SEL selector, NSError** outError);
void AOCUninstallHook(Class cls, SEL selector);
BOOL AOCIsHookInstalled(Class cls, SEL selector);
AOCMethodInvocationHook AOCGlobalInvocationHook();
void AOCSetGlobalInvocationHook(AOCMethodInvocationHook hook);