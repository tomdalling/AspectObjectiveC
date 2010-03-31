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
-(BOOL) _runAdviceWithPrefix:(NSString*)prefix invocation:(id<AOCInvocationProtocol>)inv useReturnValue:(BOOL)useReturnValue;
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

-(BOOL) _runAdviceWithPrefix:(NSString*)prefix invocation:(id<AOCInvocationProtocol>)inv useReturnValue:(BOOL)useReturnValue;
{
    SEL adviceSel = [self _makeAdviceSelWithPrefix:prefix fromSel:[inv selector]];
    if(![self respondsToSelector:adviceSel])
        return NO;
    
    _inv = inv;
    
    id<AOCInvocationProtocol> adviceInv = [inv copyWithZone:NULL];
    [adviceInv setSelector:adviceSel];
    [adviceInv setTarget:self];
    [adviceInv setImp:NULL];
    [adviceInv invoke];
    [adviceInv release]; inv = nil;
    
    _inv = nil;
    
    if(useReturnValue){
        void* returnBuffer = malloc([adviceInv returnValueSize]);
        [adviceInv getReturnValue:returnBuffer];
        [inv setReturnValue:returnBuffer];
        free(returnBuffer);
    }
    
    return YES;
}

@end



#pragma mark -
#pragma mark AOCAdvice

@implementation AOCAdvice

-(id<AOCInvocationProtocol>) invocation;
{
    return _inv;
}

#pragma mark <AOCAdvice>

-(void) adviceBefore:(id<AOCInvocationProtocol>)inv;
{
    [self _runAdviceWithPrefix:@"adviceBefore" invocation:inv useReturnValue:NO];
}

-(BOOL) adviceInsteadOf:(id<AOCInvocationProtocol>)inv;
{
    return [self _runAdviceWithPrefix:@"adviceInsteadOf" invocation:inv useReturnValue:YES];
}

-(void) adviceAfter:(id<AOCInvocationProtocol>)inv;
{
    [self _runAdviceWithPrefix:@"adviceAfter" invocation:inv useReturnValue:NO];
}

@end

