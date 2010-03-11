
#import "AOCAspectManager.h"

static AOCAspectManager* g_sharedAspectManager = nil;


#pragma mark -
#pragma mark AOCAspectManager(Private)

@interface AOCAspectManager(Private)
-(NSMutableDictionary*) _adviceBySelectorForClass:(Class)cls createIfNotFound:(BOOL)createIfNotFound;
-(NSMutableArray*) _adviceListForSelector:(SEL)selector ofClass:(Class)cls createIfNotFound:(BOOL)createIfNotFound;
-(BOOL) _installHookMethodForSelector:(SEL)selector ofClass:(Class)cls error:(NSError**)outError;

-(void) _runAdvice:(NSArray*)adviceList beforeInvocation:(NSInvocation*)inv;
-(BOOL) _runAdvice:(NSArray*)adviceList insteadOfInvocation:(NSInvocation*)inv;
-(void) _runAdvice:(NSArray*)adviceList afterInvocation:(NSInvocation*)inv;
-(void) _runAdviceForInvocation:(NSInvocation*)inv;
@end

@implementation AOCAspectManager(Private)

-(NSMutableDictionary*) _adviceBySelectorForClass:(Class)cls createIfNotFound:(BOOL)createIfNotFound;
{
    NSMutableDictionary* adviceBySel = [m_adviceByClass objectForKey:NSStringFromClass(cls)];
    if(adviceBySel == nil && createIfNotFound){
        adviceBySel = [NSMutableDictionary dictionary];
        [m_adviceByClass setObject:adviceBySel forKey:NSStringFromClass(cls)];
    }
    return adviceBySel;
}

-(NSMutableArray*) _adviceListForSelector:(SEL)selector ofClass:(Class)cls createIfNotFound:(BOOL)createIfNotFound;
{
    NSMutableDictionary* adviceBySel = [self _adviceBySelectorForClass:cls createIfNotFound:createIfNotFound];
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
    if(AOCIsHookInstalled(cls, selector))
        return YES;
    return AOCInstallHook(cls, selector, outError);
}

-(void) _runAdvice:(NSArray*)adviceList beforeInvocation:(NSInvocation*)inv;
{
    for(NSObject<AOCAdvice>* advice in adviceList){
        if([advice respondsToSelector:@selector(adviceBefore:)]){
            [advice adviceBefore:inv];
        }
    }
}

-(BOOL) _runAdvice:(NSArray*)adviceList insteadOfInvocation:(NSInvocation*)inv;
{    
    BOOL didRunAdviceInstead = NO;
    for(NSObject<AOCAdvice>* advice in adviceList){
        if([advice respondsToSelector:@selector(adviceInsteadOf:)]){
            [advice adviceInsteadOf:inv];
            didRunAdviceInstead = YES;
        }
    }
    
    return didRunAdviceInstead;
}

-(void) _runAdvice:(NSArray*)adviceList afterInvocation:(NSInvocation*)inv;
{
    for(NSObject<AOCAdvice>* advice in adviceList){
        if([advice respondsToSelector:@selector(adviceAfter:)]){
            [advice adviceAfter:inv];
        }
    }
}

-(void) _runAdviceForInvocation:(NSInvocation*)inv;
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

void AOCSharedAspectManagerHook(NSInvocation* inv)
{
    [g_sharedAspectManager _runAdviceForInvocation:inv];
}


#pragma mark -
#pragma mark AOCAspectManager

@implementation AOCAspectManager

+(AOCAspectManager*) sharedAspectManager;
{
    if(g_sharedAspectManager == nil){
        g_sharedAspectManager = [AOCAspectManager new];
        AOCSetGlobalInvocationHook(AOCSharedAspectManagerHook);
    }
    return g_sharedAspectManager;
}

-(BOOL) addAdvice:(NSObject<AOCAdvice>*)advice forSelector:(SEL)selector ofClass:(Class)cls error:(NSError**)outError;
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

-(void) removeAdvice:(NSObject<AOCAdvice>*)advice forSelector:(SEL)selector ofClass:(Class)cls;
{
    NSParameterAssert(advice != nil);
    NSParameterAssert(selector != NULL);
    NSParameterAssert(cls != NULL);
    
    NSMutableArray* adviceList = [self _adviceListForSelector:selector ofClass:cls createIfNotFound:NO];
    [adviceList removeObjectIdenticalTo:advice];
    
    if([adviceList count] <= 0)
        AOCUninstallHook(cls, selector);
}

#pragma mark NSObject

-(id) init;
{
    self = [super init];
    if(self == nil)
        return nil;
    
    m_adviceByClass = [NSMutableDictionary new];
    
    return self;
}

-(void) dealloc;
{
    [m_adviceByClass release]; m_adviceByClass = nil;
    [super dealloc];
}

@end
