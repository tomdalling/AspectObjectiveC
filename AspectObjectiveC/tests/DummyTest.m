//
//  DummyTest.m
//  AspectObjectiveC
//
//  Created by Tom on 10/03/10.
//  Copyright 2010 . All rights reserved.
//

#import "DummyTest.h"


@implementation DummyTest

-(void) testThatTestsRun;
{
	NSLog(@"Hello!");
	STAssertTrue(YES, @"Something is horribly wrong if this fails");
}

@end
