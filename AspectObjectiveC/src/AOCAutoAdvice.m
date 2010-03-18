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
    SEL adviceSel = [self _makeAdviceSelWithPrefix:prefix fromSel:[inv selector]];
    if(![self respondsToSelector:adviceSel])
        return NO;
    
    _invocation = inv;
    NSInvocation* adviceInvocation = [[inv copy] autorelease];
    [adviceInvocation setSelector:adviceSel];
    [adviceInvocation invokeWithTarget:self];
    _invocation = nil;
    
    return YES;
}

@end



#pragma mark -
#pragma mark AOCAutoAdvice

@implementation AOCAutoAdvice

-(NSInvocation*) invocation;
{
    return _invocation;
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

