
#import <Foundation/Foundation.h>

/*!
    Class similar to NSInvocation.
 
    Classes conforming to AOCInvocationProtocol work
    almost exactly like NSInvocation objects.

    The main difference between NSInvocation and
    AOCInvocationProtocol objects is that 
    AOCInvocationProtocol objects can take a specific
    IMP to execute. This is useful when you want to
    run a specific method regardless of whether it is
    attached to a selector or not. This is important in
    AspectObjectiveC because methods are swizzled, and the
    correct IMP may not be the one attached to the selector.

    AOCInvocationProtocol implement NSCopying.
    NSInvocation also implements NSCopying, but it
    doesn't copy the arguments. AOCInvocationProtocol
    copies everything properly.
*/
@protocol AOCInvocationProtocol <NSObject, NSCopying>


/*!
    Sets the selector of the invocation (_cmd variable).
 
    Unlike NSInvocation, this may not change the method that
    is invoked. If <tt>[self imp] == nil</tt>, then <tt>[self invoke]</tt> will
    work exactly the same as NSInvocation. If <tt>[self imp]</tt> is not
    nil, then <tt>[self imp]</tt> will be invoked regardless of what
    [self selector] is.
    @see    setImp:
    @param  selector    The selector to invoke
*/
- (void) setSelector:(SEL)selector;

/*!
    The selector to invoke.
    @see setSelector:
*/
- (SEL) selector;

/*!
    Sets the object of the invocation (self variable).
    @param  target  The target to invoke with
*/
- (void) setTarget:(id)target;

/*!
    The target to invoke with.
*/
- (id) target;

/*!
    Sets the IMP to invoke.
 
    When <tt>[self imp]</tt> is set to NULL, the <tt>[self invoke]</tt> will
    behave like NSInvocation and invoke the IMP returned from:
 
    @code
    [[self target] methodForSelector:[self selector]]
    @endcode

    However, <tt>[self invoke]</tt> will execute <tt>[self imp]</tt> if it is not NULL.
    The IMP will be passed <tt>[self target]</tt> and <tt>[self selector]</tt> as
    <tt>self</tt> and <tt>_cmd</tt> respectively.
 
    @param  imp The IMP to invoke, or NULL if the IMP should be looked up
                with the target and selector like NSInvocation does
*/
- (void) setImp:(IMP)imp;

/*!
    The IMP to invoke (can be NULL).
    @see setImp:
*/
- (IMP) imp;

/*!
    Works exactly like <tt>-[NSInvocation setArgument:atIndex:]</tt>.
*/
- (void) setArgument:(void*)argPtr atIndex:(NSUInteger)idx;

/*!
    Works exactly like <tt>-[NSInvocation getArgument:atIndex:]</tt>.
 */
- (void) getArgument:(void*)argPtr atIndex:(NSUInteger)idx;

/*!
    Works exactly like <tt>-[NSInvocation setReturnValue:]</tt>.
 */
- (void) setReturnValue:(void*)returnValPtr;

/*!
    Works exactly like <tt>-[NSInvocation getReturnValue:]</tt>.
 */
- (void) getReturnValue:(void*)returnValPtr;

/*!
    The number of bytes required to hold the return value.
 */
- (size_t) returnValueSize;

/*!
    Works (almost) like <tt>-[NSInvocation invoke]</tt>.
 
    If <tt>[self imp]</tt> is NULL, then this method works exactly like 
    NSInvocation. Otherwise, <tt>[self imp]</tt> is invoked instead of
    the actual IMP attached to the selector of the target.
 */
- (void) invoke;

@end
