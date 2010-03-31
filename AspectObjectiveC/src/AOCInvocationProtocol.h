
#import <Cocoa/Cocoa.h>


@protocol AOCInvocationProtocol <NSObject, NSCopying>
-(void) setSelector:(SEL)selector;
-(SEL) selector;
-(void) setTarget:(id)target;
-(id) target;
-(IMP) imp;
-(void) setImp:(IMP)imp;
-(void) setArgument:(void*)argPtr atIndex:(NSUInteger)idx;
-(void) getArgument:(void*)argPtr atIndex:(NSUInteger)idx;
-(void) setReturnValue:(void*)returnValPtr;
-(void) getReturnValue:(void*)returnValPtr;
-(size_t) returnValueSize;
-(void) invoke;
@end
