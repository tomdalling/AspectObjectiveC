
#import <Cocoa/Cocoa.h>


extern NSString* const AOCErrorDomain;

void AOCSetError(NSError** outError, NSString* localizedDescription, NSString* localizedFailureReason);
