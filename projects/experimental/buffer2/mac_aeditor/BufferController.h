/* BufferController */

#import <Cocoa/Cocoa.h>
#import "canvas.h"

@interface BufferController : NSObject
{
    IBOutlet canvas *buffer;
}
- (IBAction)openFontRequester:(id)sender;
- (IBAction)refreshCanvas:(id)sender;
- (IBAction)chooseAlgorithm:(id)sender;
- (IBAction)setLineSpacing:(id)sender;
- (IBAction)setLetterSpacing:(id)sender;
- (IBAction)increaseFontSize:(id)sender;
- (IBAction)decreaseFontSize:(id)sender;
@end
