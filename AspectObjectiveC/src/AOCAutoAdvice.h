
#import <Cocoa/Cocoa.h>
#import "AOCAdvice.h"


@interface AOCAutoAdvice : NSObject<AOCAdvice> {
    NSInvocation* _invocation;
    id _target;
    SEL _selector;
}
-(NSInvocation*) invocation;
-(id) target;
-(SEL) selector;
@end
