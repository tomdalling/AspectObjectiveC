
#import <Cocoa/Cocoa.h>
#import "AOCAdvice.h"


@interface AOCAutoAdvice : NSObject<AOCAdvice> {
    NSInvocation* _invocation;
}
-(NSInvocation*) invocation;
@end
