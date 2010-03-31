
#import <Cocoa/Cocoa.h>
#import "AOCInvocationProtocol.h"

/*!
    @abstract    The protocol implemented by all advice objects.
    @discussion  All methods are optional.
*/
@protocol AOCAdviceProtocol <NSObject>
@optional

/*!
    @abstract   Where "before" advice is executed
    @discussion The invocation argument will be invoked after this method is called,
                with any modification made to it.
    @param      inv The invocation before which this method is executing
*/
- (void) adviceBefore:(id<AOCInvocationProtocol>)inv;
/*!
    @abstract   Where the "instead of" advice is executed
    @discussion The invocation argument is only invoked if this method returns YES.
                Otherwise, the return value of the invocation should be set manually
                by calling either -invoke or -setReturnValue:
    @param      inv The invocation instead of which this method is executing
    @result     YES if the invocation argument should still be invoked after this method returns, otherwise NO
*/
- (BOOL) adviceInsteadOf:(id<AOCInvocationProtocol>)inv;

/*!
    @abstract   Where "after" advice is executed
    @discussion The invocation argument will be invoked after this method is called,
                with any modification made to it.
    @param      inv The invocation after which this method is executing
*/
- (void) adviceAfter:(id<AOCInvocationProtocol>)inv;
@end


/*!
    @abstract    An implementation of the AOCAdviceProtocol for convenience
    @discussion  The AOCAdvice class invokes "before", "instead of", and "after"
                 methods with the same arguments as the actual method that the
                 advice is running for. For example, if the advice is installed
                 for the selector:
 
                 -(double)divide:(double)numerator by:(double)denominator;
 
                 AOCAdvice will run these methods on itself if they exist:
 
                 -(double)adviceBeforeDivide:(double)numerator by:(double)denominator;
                 -(double)adviceInsteadOfDivide:(double)numerator by:(double)denominator;
                 -(double)adviceAfterDivide:(double)numerator by:(double)denominator;
 
                 The return values of -adviceBefore<sel> and -adviceAfter<sel> are ignored.
 
                 In -adviceBefore<sel>, the arguments may be modified via 
                 [[self invocation] setArgument:... atIndex:...] before the actual method is
                 called. Be aware that the first argument is at index 2.
 
                 If -adviceInsteadOf<sel> is implemented, then the advice will replace
                 the actual method. The actual method will not be called, and the
                 return value from -adviceInsteadOf<sel> is treated as the actual return value.
 
                 In -adviceAfter<sel>, the return value may be modified via
                 [[self invocation] setReturnValue:...] after the actual method has been
                 called. You can also retreive the return value of the actual method via
                 [[self invocation] getReturnValue:...]
*/
@interface AOCAdvice : NSObject<AOCAdviceProtocol> {
    id<AOCInvocationProtocol> _inv;
}

/*!
    @result     The invocation representing the actual method that the advice is running for, 
                or nil if not called from within an advice method.
*/
- (id<AOCInvocationProtocol>) invocation;

@end

