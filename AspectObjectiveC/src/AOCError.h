
#import <Foundation/Foundation.h>


extern NSString* const AOCErrorDomain;

void AOCSetError(NSError** outError, NSString* localizedDescription, NSString* localizedFailureReason);
