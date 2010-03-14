//
//  AOCDemoAppDelegate.h
//  AspectObjectiveC
//
//  Created by Tom on 14/03/10.
//  Copyright 2010 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AOCAutoAdvice.h"


@interface AOCDemoAppDelegate : NSWindowController {
    NSNumber* _celcius;
    AOCAutoAdvice* _hijackAdvice;
    BOOL _isHijacked;
}
@property(copy) NSNumber* celcius;
@property(copy, readonly) NSNumber* fahrenheit;
@property(assign, readonly) BOOL isHijacked;
-(IBAction) toggleHijacked:(id)sender;
@end
