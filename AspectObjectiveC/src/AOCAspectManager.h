
#import <Cocoa/Cocoa.h>
#import "AOCAdvice.h"

/*!
    Manages the installation and uninstallation of advice objects.
 
    AOCAspectManager is not a singleton. #defaultAspectManager will
    return an application-wide default object, but you may create other 
    AOCAspectManager objects if you wish.
 */
@interface AOCAspectManager : NSObject {
    NSMutableDictionary* _adviceListBySelectorByClass;
}

/*!
    @result The default AOCAspectManager
 */
+(AOCAspectManager*) defaultAspectManager;

/*!
    Installs an advice object.
 
    If two separate AOCAspectManager try to install advice for the same
    selector and class, then the second installation will override the first one
 
    @param advice   The advice object to install
    @param selector The selector to install the advice for. Must be an instance method.
    @param cls      The class to install the advice for. The selector must be implemented on
                    this class, not on a superclass.
    @param outError A pointer to an <tt>NSError*</tt>. If this method returns NO, 
                    <tt>*outError</tt> will be set to an <tt>NSError*</tt> that describes
                    the problem. This argument may be NULL if you don't want the error.
    @result YES if the installation succeeded, otherwise NO.
 */
-(BOOL) installAdvice:(id<AOCAdviceProtocol>)advice forSelector:(SEL)selector ofClass:(Class)cls error:(NSError**)outError;

/*!
    Uninstalls an advice object.
    @param advice   The advice object to uninstall
    @param selector The selector the advice was installed for
    @param cls      The class the advice was installed for
 */
-(void) uninstallAdvice:(id<AOCAdviceProtocol>)advice forSelector:(SEL)selector ofClass:(Class)cls;

/*!
    Uninstalls all advice objects.
 */
-(void) uninstallAllAdvice;

/*!
    Calls <tt>[self uninstallAllAdvice]</tt>. 
 */
-(void) dealloc;

@end
