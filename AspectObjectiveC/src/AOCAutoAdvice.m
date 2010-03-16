//
//  AOCAutoAdvice.m
//  AspectObjectiveC
//
//  Created by Tom on 14/03/10.
//  Copyright 2010 . All rights reserved.
//

#import "AOCAutoAdvice.h"


#pragma mark -
#pragma mark AOCAutoAdvice(Private)

@interface AOCAutoAdvice(Private)
-(SEL) _makeAdviceSelWithPrefix:(NSString*)prefix fromSel:(SEL)selBeingInvoked;
-(BOOL) _runAdviceWithPrefix:(NSString*)prefix invocation:(NSInvocation*)inv;
@end

@implementation AOCAutoAdvice(Private)

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
    SEL originalSel = [inv selector];
    id originalTarget = [inv target];
    
    SEL adviceSel = [self _makeAdviceSelWithPrefix:prefix fromSel:originalSel];
    if(![self respondsToSelector:adviceSel]){
        NSLog(@"can't invoke %@", NSStringFromSelector(adviceSel));
        return NO;
    }
    
    NSLog(@"will invoke %@", NSStringFromSelector(adviceSel));
    
    [inv setSelector:adviceSel];
    [inv invokeWithTarget:self];
    [inv setSelector:originalSel];
    [inv setTarget:originalTarget];
    return YES;
}

@end



#pragma mark -
#pragma mark AOCAutoAdvice

@implementation AOCAutoAdvice

#pragma mark <AOCAdvice>

-(void) adviceBefore:(NSInvocation*)inv;
{
    NSLog(@"boo");
    [self _runAdviceWithPrefix:@"adviceBefore" invocation:inv];
}

-(BOOL) adviceInsteadOf:(NSInvocation*)inv;
{
    NSLog(@"boo2");
    return [self _runAdviceWithPrefix:@"adviceInsteadOf" invocation:inv];
}

-(void) adviceAfter:(NSInvocation*)inv;
{
    NSLog(@"boo3");
    [self _runAdviceWithPrefix:@"adviceAfter" invocation:inv];
}

@end

