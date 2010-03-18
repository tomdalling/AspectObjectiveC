
#import <Cocoa/Cocoa.h>
#import "AOCAutoAdvice.h"

@interface HijackAdvice : AOCAutoAdvice
-(IBAction) adviceBeforeConvertCelciusToFahrenheit:(id)sender;
-(IBAction) adviceInsteadOfConvertCelciusToFahrenheit:(id)sender;
-(IBAction) adviceAfterConvertCelciusToFahrenheit:(id)sender;
@end
