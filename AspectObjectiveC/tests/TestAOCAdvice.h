
#import <SenTestingKit/SenTestingKit.h>
#import <AspectObjectiveC/AOC.h>

@class HelloAdvice;

@interface TestAOCAdvice : SenTestCase {
    HelloAdvice* _advice;
    AOCAspectManager* _aspectManager;
    int _receivedHelloArg;
}

@end
