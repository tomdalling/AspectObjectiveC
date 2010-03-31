
#import <Cocoa/Cocoa.h>
#import "ffi.h"
#import "AOCInvocationProtocol.h"

@interface AOCFFIInvocation : NSObject<AOCInvocationProtocol> {
    ffi_cif* _cif;
    void* _returnValue;
    void** _args;
    IMP _imp;
}
-(id) initWithCif:(ffi_cif*)cif arguments:(void**)argPtrs imp:(IMP)imp;
@end
