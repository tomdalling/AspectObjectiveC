
#import <Cocoa/Cocoa.h>
#import "AOCInvocationProtocol.h"

typedef void(*AOCMethodInvocationHook)(id<AOCInvocationProtocol>,void*);

BOOL AOCInstallHook(AOCMethodInvocationHook hook, void* context, Class cls, SEL selector, NSError** outError);
AOCMethodInvocationHook AOCGetInstalledHook(Class cls, SEL selector, void** outContext);
void AOCUninstallHook(Class cls, SEL selector);
BOOL AOCIsHookInstalled(Class cls, SEL selector);