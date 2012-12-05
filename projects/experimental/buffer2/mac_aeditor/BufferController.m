#import "BufferController.h"

@implementation BufferController

- (IBAction)openFontRequester:(id)sender {
	NSFontManager *fm = [NSFontManager sharedFontManager];
	[fm orderFrontFontPanel:self];
}

- (IBAction)refreshCanvas:(id)sender {
	[buffer setNeedsDisplay: YES];
}

- (IBAction)chooseAlgorithm:(id)sender {
	int tag = [[sender selectedItem] tag];
	switch(tag) {
	case 0:
		[buffer changeSlowAlgo];
		break;
	case 1:
		[buffer changeFastAlgo];
		break;
	default:
		NSLog(@"chooseAlgorithm: unknown tag %i", tag);
	}
}

- (IBAction)setLineSpacing:(id)sender {
	int position = [sender intValue];
	[buffer setLineSpacing:position];
}

- (IBAction)setLetterSpacing:(id)sender {
	int position = [sender intValue];
	[buffer setLetterSpacing:position];
}

- (IBAction)increaseFontSize:(id)sender {
	[buffer adjustFontSize:+1];
}   

- (IBAction)decreaseFontSize:(id)sender {
	[buffer adjustFontSize:-1];
}   

@end
