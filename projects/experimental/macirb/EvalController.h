/* EvalController */

#import <Cocoa/Cocoa.h>

@interface EvalController : NSObject
{
    IBOutlet NSTextField *evalField;
    IBOutlet NSTextView *output;
}
- (IBAction)eval:(id)sender;
@end
