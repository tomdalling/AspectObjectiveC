
#import <SenTestingKit/SenTestingKit.h>
#import "AOCAspectManager.h"
#import "AOCAdvice.h"

@class HelloAdvice;

@interface TestAOCAdvice : SenTestCase {
    HelloAdvice* _advice;
    AOCAspectManager* _aspectManager;
    int _receivedHelloArg;
}

@end
