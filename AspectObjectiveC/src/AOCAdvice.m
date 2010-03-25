//
//  AOCAdvice.m
//  AspectObjectiveC
//
//  Created by Tom on 14/03/10.
//  Copyright 2010 . All rights reserved.
//

#import "AOCAdvice.h"


#pragma mark -
#pragma mark AOCAdvice(Private)

@interface AOCAdvice(Private)
-(SEL) _makeAdviceSelWithPrefix:(NSString*)prefix fromSel:(SEL)selBeingInvoked;
-(BOOL) _runAdviceWithPrefix:(NSString*)prefix invocation:(NSInvocation*)inv;
@end

@implementation AOCAdvice(Private)

-(SEL) _makeAdviceSelWithPrefix:(NSString*)prefix fromSel:(SEL)selBeingInvoked;
{
    NSString* selBeingInvokedStr = NSStringFromSelector(selBeingInvoked);
    NSMutableString* adviceSelStr = [NSMutableString string];
    [adviceSelStr appendString:prefix];
    [adviceSelStr appendString:[[selBeingInvokedStr substringToIndex:1] uppercaseString]];
    if([selBeingInvokedStr length] > 1)
        [adviceSelStr appendString:[selBeingInvokedStr substringFromIndex:1]];
    return NSSelectorFromString(adviceSelStr);
}

-(BOOL) _runAdviceWithPrefix:(NSString*)prefix invocation:(NSInvocation*)inv;
{
    SEL adviceSel = [self _makeAdviceSelWithPrefix:prefix fromSel:[inv selector]];
    if(![self respondsToSelector:adviceSel])
        return NO;
    
    _invocation = inv;
    _target = [inv target];
    _selector = [inv selector];
    [inv setSelector:adviceSel];
    [inv invokeWithTarget:self];
    [inv setTarget:_target];
    [inv setSelector:_selector];
    _selector = NULL;
    _target = nil;
    _invocation = nil;
    
    return YES;
}

@end



#pragma mark -
#pragma mark AOCAdvice

@implementation AOCAdvice

-(NSInvocation*) invocation;
{
    return _invocation;
}

-(id) target;
{
    return _target;
}

-(SEL) selector;
{
    return _selector;
}

#pragma mark <AOCAdvice>

-(void) adviceBefore:(NSInvocation*)inv;
{
    [self _runAdviceWithPrefix:@"adviceBefore" invocation:inv];
}

-(BOOL) adviceInsteadOf:(NSInvocation*)inv;
{
    return [self _runAdviceWithPrefix:@"adviceInsteadOf" invocation:inv];
}

-(void) adviceAfter:(NSInvocation*)inv;
{
    [self _runAdviceWithPrefix:@"adviceAfter" invocation:inv];
}

@end

