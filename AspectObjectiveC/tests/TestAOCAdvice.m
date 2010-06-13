
#import "TestAOCAdvice.h"


#pragma mark -
#pragma mark HelloAdvice

@interface HelloAdvice : AOCAdvice {
    BOOL beforeAdviceRan;
    BOOL insteadOfAdviceRan;
    BOOL afterAdviceRan;
    int fakeReturnValue;
    int fakeArg;
}
@property(assign) BOOL beforeAdviceRan;
@property(assign) BOOL insteadOfAdviceRan;
@property(assign) BOOL afterAdviceRan;
@property(assign) int fakeReturnValue;
@property(assign) int fakeArg;
@end

@implementation HelloAdvice

@synthesize fakeReturnValue, fakeArg, beforeAdviceRan, insteadOfAdviceRan, afterAdviceRan;

-(int) adviceBeforeHello:(int)arg;
{
    beforeAdviceRan = YES;
    
    if(fakeArg != 0)
        [[self invocation] setArgument:&fakeArg atIndex:2];
    
    return 0;
}

-(int) adviceInsteadOfHello:(int)arg;
{
    insteadOfAdviceRan = YES;
    
    //run -[TestAOCAdvice hello:]
    int returnValue;
    [[self invocation] invoke];
    [[self invocation] getReturnValue:&returnValue];
    return returnValue;
}

-(int) adviceAfterHello:(int)arg;
{
    afterAdviceRan = YES;
    
    if(fakeReturnValue != 0)
        [[self invocation] setReturnValue:&fakeReturnValue];
    
    return 0;
}

-(id) init;
{
    self = [super init];
    if(self == nil)
        return nil;
    
    beforeAdviceRan = NO;
    insteadOfAdviceRan = NO;
    afterAdviceRan = NO;
    fakeArg = 0;
    fakeReturnValue = 0;
    
    return self;
}

@end


#pragma mark -
#pragma mark TestAOCAdvice

@implementation TestAOCAdvice

-(int) hello:(int)arg; 
{ 
    _receivedHelloArg = arg;
    NSLog(@"Hello there!"); 
    return 3110; 
}

-(void) testThatAllAdviceMethodsRun;
{
    STAssertFalse(_advice.beforeAdviceRan, @"'Before' advice should not have run");
    STAssertFalse(_advice.insteadOfAdviceRan, @"'Instead of' advice should not have run");
    STAssertFalse(_advice.afterAdviceRan, @"'After' advice should not have run");
    
    [self hello:10];
    
    STAssertTrue(_advice.beforeAdviceRan, @"'Before' advice did not run");
    STAssertTrue(_advice.insteadOfAdviceRan, @"'Instead of' advice did not run");
    STAssertTrue(_advice.afterAdviceRan, @"'After' advice did not run");
}

-(void) testArgsCanBeModified;
{
    [self hello:11];
    STAssertEquals(_receivedHelloArg, 11, @"Unexpectedly modified arg");
    
    _advice.fakeArg = 33;
    [self hello:11];
    STAssertEquals(_receivedHelloArg, 33, @"Arg was not modified by advice");
}

-(void) testReturnValueCanBeModified;
{
    int returnValue;
    
    returnValue = [self hello:0];
    STAssertEquals(returnValue, 3110, @"Unexpected default return value");
    
    _advice.fakeReturnValue = 55;
    returnValue = [self hello:0];
    STAssertEquals(returnValue, 55, @"Return value was not modified by advice");
}

#pragma mark SenTestCase

-(void) setUp;
{
    _receivedHelloArg = 0;
    
    _advice = [HelloAdvice new];
    _aspectManager = [AOCAspectManager new];
    [_aspectManager installAdvice:_advice
                      forSelector:@selector(hello:)
                          ofClass:[self class]
                            error:nil];
    NSLog(@"Did setup");
}

- (void) tearDown;
{
    [_aspectManager uninstallAllAdvice];
    [_aspectManager release]; _aspectManager = nil;
    [_advice release]; _advice = nil;
    NSLog(@"Did tear down");
}

@end
