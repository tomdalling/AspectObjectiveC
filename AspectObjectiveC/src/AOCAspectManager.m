
#import "AOCAspectManager.h"
#import "AOCMethodHooking.h"
#import "AOCError.h"

static AOCAspectManager* g_defaultAspectManager = nil;


#pragma mark -
#pragma mark AOCAspectManager(Private)

@interface AOCAspectManager(Private)
-(NSMutableDictionary*) _adviceListBySelectorForClass:(Class)cls createIfNotFound:(BOOL)createIfNotFound;
-(NSMutableArray*) _adviceListForSelector:(SEL)selector ofClass:(Class)cls createIfNotFound:(BOOL)createIfNotFound;
-(BOOL) _installHookMethodForSelector:(SEL)selector ofClass:(Class)cls error:(NSError**)outError;
-(BOOL) _isMethodHookedBySelf:(SEL)selector class:(Class)cls error:(NSError**)outError;
-(void) _uninstallHookMethodForSelector:(SEL)selector ofClass:(Class)cls;
-(void) _uninstallAllHooks;

-(void) _runAdvice:(NSArray*)adviceList beforeInvocation:(id<AOCInvocationProtocol>)inv;
-(BOOL) _runAdvice:(NSArray*)adviceList insteadOfInvocation:(id<AOCInvocationProtocol>)inv;
-(void) _runAdvice:(NSArray*)adviceList afterInvocation:(id<AOCInvocationProtocol>)inv;
-(void) _runAdviceForInvocation:(id<AOCInvocationProtocol>)inv;
@end

void AOCAspectManagerHook(id<AOCInvocationProtocol> inv, void* context);

@implementation AOCAspectManager(Private)

-(NSMutableDictionary*) _adviceListBySelectorForClass:(Class)cls createIfNotFound:(BOOL)createIfNotFound;
{
    NSMutableDictionary* adviceBySel = [_adviceListBySelectorByClass objectForKey:NSStringFromClass(cls)];
    if(adviceBySel == nil && createIfNotFound){
        adviceBySel = [NSMutableDictionary dictionary];
        [_adviceListBySelectorByClass setObject:adviceBySel forKey:NSStringFromClass(cls)];
    }
    return adviceBySel;
}

-(NSMutableArray*) _adviceListForSelector:(SEL)selector ofClass:(Class)cls createIfNotFound:(BOOL)createIfNotFound;
{
    NSMutableDictionary* adviceBySel = [self _adviceListBySelectorForClass:cls createIfNotFound:createIfNotFound];
    if(adviceBySel == nil)
        return nil;
    
    NSMutableArray* adviceList = [adviceBySel objectForKey:NSStringFromSelector(selector)];
    if(adviceList == nil && createIfNotFound){
        adviceList = [NSMutableArray array];
        [adviceBySel setObject:adviceList forKey:NSStringFromSelector(selector)];
    }    
    return adviceList;
}

-(BOOL) _installHookMethodForSelector:(SEL)selector ofClass:(Class)cls error:(NSError**)outError;
{
    if(AOCIsHookInstalled(cls, selector)){
        return [self _isMethodHookedBySelf:selector class:cls error:outError];
    } else {
        return AOCInstallHook(AOCAspectManagerHook, self, cls, selector, outError);
    }
}

-(BOOL) _isMethodHookedBySelf:(SEL)selector class:(Class)cls error:(NSError**)outError;
{
    id context = nil;
    AOCMethodInvocationHook hook = AOCGetInstalledHook(cls, selector, (void**)&context);
    
    if(hook != AOCAspectManagerHook){
        AOCSetError(outError, @"Method is already hooked by something other than AOCAspectManager", nil);
        return NO;
    }
    
    if(context == self)
        return YES; //hook already installed by self

    //hooked by another instance of AOCAspectManager
    NSString* errorString = [NSString stringWithFormat:@"Advice was already installed by another aspect manager: <%@ %p>", [context className], context];
    AOCSetError(outError, errorString, nil);
    return NO;
}

-(void) _uninstallHookMethodForSelector:(SEL)selector ofClass:(Class)cls;
{
    if(!AOCIsHookInstalled(cls, selector))
        return;
    
    id context = nil;
    AOCMethodInvocationHook hook = AOCGetInstalledHook(cls, selector, (void**)&context);

    //have to check that this object installed the hook, otherwise it will uninstall
    //a hook that other objects may be using
    if(hook == AOCAspectManagerHook && context == self)
        AOCUninstallHook(cls, selector);
}

-(void) _uninstallAllHooks;
{
    for(NSString* classString in [_adviceListBySelectorByClass allKeys]){
        Class cls = NSClassFromString(classString);
        for(NSString* selString in [[_adviceListBySelectorByClass objectForKey:classString] allKeys]){
            SEL sel = NSSelectorFromString(selString);
            [self _uninstallHookMethodForSelector:sel ofClass:cls];
        }
    }
}

-(void) _runAdvice:(NSArray*)adviceList beforeInvocation:(id<AOCInvocationProtocol>)inv;
{
    for(NSObject<AOCAdviceProtocol>* advice in adviceList){
        if([advice respondsToSelector:@selector(adviceBefore:)]){
            [advice adviceBefore:inv];
        }
    }
}

-(BOOL) _runAdvice:(NSArray*)adviceList insteadOfInvocation:(id<AOCInvocationProtocol>)inv;
{    
    BOOL invocationWasReplaced = NO;
    for(NSObject<AOCAdviceProtocol>* advice in adviceList){
        if([advice respondsToSelector:@selector(adviceInsteadOf:)]){
            if([advice adviceInsteadOf:inv]){
                invocationWasReplaced = YES;
            }
        }
    }
    
    return invocationWasReplaced;
}

-(void) _runAdvice:(NSArray*)adviceList afterInvocation:(id<AOCInvocationProtocol>)inv;
{
    for(NSObject<AOCAdviceProtocol>* advice in adviceList){
        if([advice respondsToSelector:@selector(adviceAfter:)]){
            [advice adviceAfter:inv];
        }
    }
}

-(void) _runAdviceForInvocation:(id<AOCInvocationProtocol>)inv;
{
    NSArray* adviceList = [self _adviceListForSelector:[inv selector]
                                               ofClass:[[inv target] class] 
                                      createIfNotFound:NO];
    
    if(adviceList == nil || [adviceList count] <= 0){
        [inv invoke];
        return;
    }
    
    [self _runAdvice:adviceList beforeInvocation:inv];
    if(![self _runAdvice:adviceList insteadOfInvocation:inv]){
        [inv invoke];
    }
    [self _runAdvice:adviceList afterInvocation:inv];
}

@end

void AOCAspectManagerHook(id<AOCInvocationProtocol> inv, void* context)
{
    AOCAspectManager* aspectManager = (AOCAspectManager*)context;
    [aspectManager _runAdviceForInvocation:inv];
}


#pragma mark -
#pragma mark AOCAspectManager

@implementation AOCAspectManager

+(AOCAspectManager*) defaultAspectManager;
{
    if(g_defaultAspectManager == nil){
        g_defaultAspectManager = [AOCAspectManager new];
    }
    return g_defaultAspectManager;
}

-(BOOL) installAdvice:(id<AOCAdviceProtocol>)advice forSelector:(SEL)selector ofClass:(Class)cls error:(NSError**)outError;
{
    NSParameterAssert(advice != nil);
    NSParameterAssert(selector != NULL);
    NSParameterAssert(cls != NULL);
    
    BOOL didInstall = [self _installHookMethodForSelector:selector ofClass:cls error:outError];
    if(!didInstall)
        return NO;
    
    NSMutableArray* adviceList = [self _adviceListForSelector:selector ofClass:cls createIfNotFound:YES];
    if([adviceList indexOfObjectIdenticalTo:advice] == NSNotFound){
        [adviceList addObject:advice];
        return YES;
    } else {
        AOCSetError(outError, NSLocalizedString(@"Can't add advice", @""), NSLocalizedString(@"The same advice object has already been added.", @""));
        return NO;
    }
}

-(void) uninstallAdvice:(id<AOCAdviceProtocol>)advice forSelector:(SEL)selector ofClass:(Class)cls;
{
    NSParameterAssert(advice != nil);
    NSParameterAssert(selector != NULL);
    NSParameterAssert(cls != NULL);
    
    NSMutableArray* adviceList = [self _adviceListForSelector:selector ofClass:cls createIfNotFound:NO];
    [adviceList removeObjectIdenticalTo:advice];
    
    if([adviceList count] <= 0)
        AOCUninstallHook(cls, selector);
}

-(void) uninstallAllAdvice;
{
    [self _uninstallAllHooks];
    [_adviceListBySelectorByClass release];
    _adviceListBySelectorByClass = [NSMutableDictionary new];
}

#pragma mark NSObject

-(id) init;
{
    self = [super init];
    if(self == nil)
        return nil;
    
    _adviceListBySelectorByClass = [NSMutableDictionary new];
    
    return self;
}

-(void) dealloc;
{
    [self _uninstallAllHooks];
    [_adviceListBySelectorByClass release]; _adviceListBySelectorByClass = nil;
    [super dealloc];
}

@end
