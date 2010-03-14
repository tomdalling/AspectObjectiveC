
#import <Cocoa/Cocoa.h>
#import "AOCAdvice.h"


@interface AOCAspectManager : NSObject {
    NSMutableDictionary* _adviceByClass;
}
+(AOCAspectManager*) sharedAspectManager;
-(BOOL) addAdvice:(NSObject<AOCAdvice>*)advice forSelector:(SEL)selector ofClass:(Class)cls error:(NSError**)outError;
-(void) removeAdvice:(NSObject<AOCAdvice>*)advice forSelector:(SEL)selector ofClass:(Class)cls;
@end
