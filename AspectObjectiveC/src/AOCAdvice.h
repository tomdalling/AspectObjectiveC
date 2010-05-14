
#import <Foundation/Foundation.h>
#import "AOCInvocationProtocol.h"

/*!
    The protocol implemented by all advice objects.

    In all of the methods, <tt>[inv imp]</tt> is the actual IMP that the advice is running for.
    This will be different from <tt>[[inv target] methodForSelector:[inv selector]]</tt>
    because the method has been swizzled.
 
    The following code will crash because of infinite recursion:
 
    @code
    [[inv target] performSelector:[inv selector]]
    @endcode
 
    You can't call the selector that advice is running for without causing infinite recursion.
    If you want to call actual method the advice is running for, use <tt>[inv invoke]</tt>
    without modifying the target, selector or IMP.
*/
@protocol AOCAdviceProtocol <NSObject>
@optional

/*!
    Where "before" advice is executed.
 
    The invocation argument will be invoked after this method is called,
    with any modification made to it. This means that the arguments may
    be modified here before the actual method is invoked.
 
    @param  inv The invocation before which this method is executing.
*/
- (void) adviceBefore:(id<AOCInvocationProtocol>)inv;

/*!
    Where the "instead of" advice is executed.
 
    The invocation argument is only invoked if this method returns YES.
    Otherwise, the return value of the invocation should be set manually
    by calling either AOCInvocationProtocol#invoke or AOCInvocationProtocol#setReturnValue:
 
    @param  inv The invocation instead of which this method is executing
    @result YES if the invocation argument should still be invoked after
            this method returns, otherwise NO
*/
- (BOOL) adviceInsteadOf:(id<AOCInvocationProtocol>)inv;

/*!
    Where "after" advice is executed.
 
    The invocation argument should have already been invoked by the time
    this method is called. The return value of the invocation argument
    may be modified here.
 
    @param  inv The invocation after which this method is executing
*/
- (void) adviceAfter:(id<AOCInvocationProtocol>)inv;
@end


/*! 
    A convenient base class for advice objects.
 
    Advice objects needn't be a subclass of AOCAdvice, they must simply
    implement AOCAdviceProtocol. AOCAdvice is only provided for convenience.
 
    The AOCAdvice class invokes "before", "instead of", and "after"
    methods with the same arguments as the actual method that the
    advice is running for. For example, if the advice is installed
    for the selector:

    @code
    -(double)divide:(double)numerator by:(double)denominator;
    @endcode

    AOCAdvice will run these methods on itself if they exist:

    @code
    -(double)adviceBeforeDivide:(double)numerator by:(double)denominator;
    -(double)adviceInsteadOfDivide:(double)numerator by:(double)denominator;
    -(double)adviceAfterDivide:(double)numerator by:(double)denominator;
    @endcode

    The return values of <tt>-adviceBefore[sel]</tt> and <tt>-adviceAfter[sel]</tt> are ignored.

    In <tt>-adviceBefore[sel]</tt>, the arguments may be modified via 
    <tt>[[self invocation] setArgument:... atIndex:...]</tt> before the actual method is
    called. Be aware that the first argument is at index 2.

    If <tt>-adviceInsteadOf[sel]</tt> is implemented, then the advice will replace
    the actual method. The actual method will not be called, and the
    return value from -adviceInsteadOf[sel] is treated as the actual return value.

    In <tt>-adviceAfter[sel]</tt>, the return value may be modified via
    <tt>[[self invocation] setReturnValue:...]</tt> after the actual method has been
    called. You can also retreive the return value of the actual method via
    <tt>[[self invocation] getReturnValue:...]</tt>.
*/
@interface AOCAdvice : NSObject<AOCAdviceProtocol> {
    id<AOCInvocationProtocol> _inv;
}

/*!
    @result The invocation representing the actual method that the advice is running for, 
            or nil if not called from within an advice method. The object returned should
            not be retained for later use, because it will be invalid after the advice
            method has returned.
    @see AOCInvocationProtocol
*/
- (id<AOCInvocationProtocol>) invocation;

@end

