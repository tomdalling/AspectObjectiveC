//
//  AOCDemoAppDelegate.m
//  AspectObjectiveC
//
//  Created by Tom on 14/03/10.
//  Copyright 2010 . All rights reserved.
//

#import "AOCDemoAppDelegate.h"
#import "AOCAspectManager.h"

#define SEL_TO_HIJACK @selector(fahrenheit)

#pragma mark -
#pragma mark HijackAdvice

@interface HijackAdvice : AOCAutoAdvice
-(NSNumber*) adviceBeforeFahrenheit;
-(NSNumber*) adviceInsteadOfFahrenheit;
@end

@implementation HijackAdvice

-(NSNumber*) adviceBeforeFahrenheit;
{
    NSLog(@"I'm about to hijack -(NSNumber*)fahrenheit;");
    return nil; //return value is ignored here
}

-(NSNumber*) adviceInsteadOfFahrenheit;
{
    //return value here will be used instead of actual return value
    return [NSNumber numberWithInt:123456];
}

@end


#pragma mark -
#pragma mark AOCDemoAppDelegate

@implementation AOCDemoAppDelegate

@synthesize celcius = _celcius;
@synthesize isHijacked = _isHijacked;

-(NSNumber*) fahrenheit;
{
    double c = [_celcius doubleValue];
    double f = c * (9.0/5.0) + 32.0;
    NSLog(@"%f degrees celcius is %f degrees farenheit", c, f);
    return [NSNumber numberWithDouble:f];
}

-(IBAction) toggleHijacked:(id)sender;
{
    [self willChangeValueForKey:@"isHijacked"];
    
    _isHijacked = !_isHijacked;
    
    NSLog(@"before = %p", [self methodForSelector:SEL_TO_HIJACK]);
    if(_isHijacked){
        NSLog(@"Installing advice");
        [[AOCAspectManager sharedAspectManager] addAdvice:_hijackAdvice
                                              forSelector:SEL_TO_HIJACK
                                                  ofClass:[self class]
                                                    error:nil];
        [self valueForKey:@"fahrenheit"];
    } else {
        NSLog(@"Uninstalling advice");
        [[AOCAspectManager sharedAspectManager] removeAdvice:_hijackAdvice
                                                 forSelector:SEL_TO_HIJACK
                                                     ofClass:[self class]];
    }
    NSLog(@"after = %p", [self methodForSelector:SEL_TO_HIJACK]);
    
    [self didChangeValueForKey:@"isHijacked"];
}

#pragma mark NSWindowController

- (void)windowWillClose:(NSNotification *)notification;
{
    [[AOCAspectManager sharedAspectManager] removeAdvice:_hijackAdvice
                                             forSelector:SEL_TO_HIJACK
                                                 ofClass:[self class]];
    [NSApp terminate:self];
}

#pragma mark NSObject

-(id) init;
{
    self = [super init];
    if(self == nil)
        return nil;
    
    _celcius = [[NSNumber alloc] initWithInt:100.0];
    _isHijacked = YES;
    _hijackAdvice = [HijackAdvice new];
    
    return self;
}

-(void) dealloc;
{
    [_celcius release]; _celcius = nil;
    [_hijackAdvice release]; _hijackAdvice = nil;
    [super dealloc];
}

#pragma mark <NSKeyValueCoding>

-(id) valueForKey:(NSString*)key;
{
    SEL s = NSSelectorFromString(key);
    if([self respondsToSelector:s])
        return [self performSelector:s];
    else
        return [self valueForUndefinedKey:key];
}

#pragma mark <NSKeyValueObserving>

+(NSSet*) keyPathsForValuesAffectingFahrenheit;
{
    return [NSSet setWithObjects:@"celcius", @"isHijacked", nil];
}

@end
