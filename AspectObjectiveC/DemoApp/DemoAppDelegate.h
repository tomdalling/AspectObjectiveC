
#import <Cocoa/Cocoa.h>
#import "HijackAdvice.h"


@interface DemoAppDelegate : NSWindowController {
    NSTextField* _celciusTextField;
    NSTextField* _fahrenheitTextField;
    NSButton* _hijackButton;
    BOOL _isHijacked;
    HijackAdvice* _hijackAdvice;
}
@property(retain) IBOutlet NSTextField* celciusTextField;
@property(retain) IBOutlet NSTextField* fahrenheitTextField;
@property(retain) IBOutlet NSButton* hijackButton;
-(IBAction) convertCelciusToFahrenheit:(id)sender;
-(IBAction) hijack:(id)sender;
-(IBAction) unhijack:(id)sender;
-(IBAction) toggleHijacked:(id)sender;
@end
