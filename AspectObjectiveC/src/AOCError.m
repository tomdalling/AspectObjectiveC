
#import "AOCError.h"


NSString* const AOCErrorDomain = @"AOCErrorDomain";

void AOCSetError(NSError** outError, NSString* localizedDescription, NSString* localizedFailureReason)
{
    if(outError == NULL)
        return;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    if(localizedDescription != nil)
        [userInfo setObject:localizedDescription forKey:NSLocalizedDescriptionKey];
    if(localizedFailureReason != nil)
        [userInfo setObject:localizedFailureReason forKey:NSLocalizedFailureReasonErrorKey];
    
    
    *outError = [[[NSError alloc] initWithDomain:AOCErrorDomain
                                            code:-1
                                        userInfo:userInfo] autorelease];
}
