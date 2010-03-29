
#import <Cocoa/Cocoa.h>

/*!
    @abstract    The protocol implemented by all advice objects.
    @discussion  All methods are optional.
*/
@protocol AOCAdviceProtocol
@optional

/*!
    @abstract   Where "before" advice is executed
    @discussion The NSInvocation argument will be invoked after this method is called,
                with any modification made to it.
    @param      inv The invocation before which this method is executing
*/
- (void) adviceBefore:(NSInvocation*)inv;
/*!
    @abstract   Where the "instead of" advice is executed
    @discussion The NSInvocation argument is only invoked if this method returns YES.
                Otherwise, the return value of the invocation should be set manually
                by calling either -invoke or -setReturnValue:
    @param      inv The invocation instead of which this method is executing
    @result     YES if the NSInvocation argument should still be invoked after this method returns, otherwise NO
*/
- (BOOL) adviceInsteadOf:(NSInvocation*)inv;

/*!
    @abstract   Where "after" advice is executed
    @discussion The NSInvocation argument will be invoked after this method is called,
                with any modification made to it.
    @param      inv The invocation after which this method is executing
*/
- (void) adviceAfter:(NSInvocation*)inv;
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
 
                 The NSInvocation returned by [self invocation] will have an incorrect
                 target and selector. The target will be self, and the selector will be _cmd,
                 as the invocation object is being used to run the advice methods. To access
                 the actual target and actual selector, use [self target] and [self selector].
*/
@interface AOCAdvice : NSObject<AOCAdviceProtocol> {
    NSInvocation* _invocation;
    id _target;
    SEL _selector;
}

/*!
    @discussion The NSInvocation returned by [self invocation] will have an incorrect
                target and selector. The target will be self, and the selector will be _cmd,
                as the invocation object is being used to run the advice methods. To access
                the actual target and actual selector, use [self target] and [self selector].
                The NSInvocation returned by [self invocation] can, however, be used to modify
                the arguments and return value.
 
    @result     The NSInvocation representing the actual method that the advice is running for, 
                or nil if not called from within an advice method
*/
- (NSInvocation*) invocation;


/*!
    @discussion This differs from [[self invocation] target]. This method returns nil
                if it's not called during the execution of -adviceBefore<sel>, -adviceAfter<sel>
                or -adviceInsteadOf<sel>
 
    @result     The actual target of [self invocation], or nil if not called from within an
                advice method
 
    @see        - (NSInvocation*) invocation;
*/
- (id) target;

/*!
    @discussion This differs from [[self invocation] selector]. This method returns NULL
                if it's not called during the execution of -adviceBefore<sel>, -adviceAfter<sel>
                or -adviceInsteadOf<sel>
 
    @result     The actual selector of [self invocation], or NULL if not called from within an 
                advice method
 
    @see        - (NSInvocation*) invocation;
*/
- (SEL) selector;

@end

