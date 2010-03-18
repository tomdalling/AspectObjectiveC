
#import "HijackAdvice.h"
#import "DemoAppDelegate.h"


@implementation HijackAdvice

-(IBAction) adviceBeforeConvertCelciusToFahrenheit:(id)sender;
{
    // Advice before can be used to alter method arguments before they
    // reach the method. The following two lines set the sender arg to nil:
    
    // id newSender = nil;
    // [[self invocation] setArgument:&newSender atIndex:2];
    
    // In this case, we're just going to NSLog a message
    NSLog(@"Before advice. sender = %@ ", sender); 
}

-(IBAction) adviceInsteadOfConvertCelciusToFahrenheit:(id)sender;
{
    // "Instead of" advice completely replaces a method.
    // In this case, we're going to hijack the fahrenheit calculation
    // and make the fahrenheit text field say "dunno"
    DemoAppDelegate* target = [self target];
    [target.fahrenheitTextField setStringValue:NSLocalizedString(@"dunno", nil)];
}

-(IBAction) adviceAfterConvertCelciusToFahrenheit:(id)sender;
{
    // Advice after can be used to change the return value of a method.
    // The return value of this method is void, but if it was an int
    // you could add 2 to the return value like so:
    
    // int returnValue;
    // [[self invocation] getReturnValue:&returnValue];
    // returnValue += 2;
    // [[self invocation] setReturnValue:&newReturnValue];
    
    //In this case, we're just going to NSLog a message
    NSLog(@"After advice. sender = %@", sender);
}

@end
