
#import <Cocoa/Cocoa.h>


@protocol AOCAdvice
@optional
-(void) adviceBefore:(NSInvocation*)inv;
-(void) adviceInsteadOf:(NSInvocation*)inv;
-(void) adviceAfter:(NSInvocation*)inv;
@end
