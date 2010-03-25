
#import <Cocoa/Cocoa.h>
#import "AOCAdvice.h"


@interface AOCAspectManager : NSObject {
    NSMutableDictionary* _adviceByClass;
}
+(AOCAspectManager*) sharedAspectManager;
-(BOOL) addAdvice:(NSObject<AOCAdviceProtocol>*)advice forSelector:(SEL)selector ofClass:(Class)cls error:(NSError**)outError;
-(void) removeAdvice:(NSObject<AOCAdviceProtocol>*)advice forSelector:(SEL)selector ofClass:(Class)cls;
@end
