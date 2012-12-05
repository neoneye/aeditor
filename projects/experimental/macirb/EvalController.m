#import "EvalController.h"

@implementation EvalController

- (IBAction)eval:(id)sender
{
	NSString *str = [evalField stringValue];
	printf("eval \"%s\"\n", [str cString]);
	NSString *str2 = [str stringByAppendingString:@"\n"];
	
	NSRange range;
    range = NSMakeRange([[output string] length], 0);
    [output replaceCharactersInRange: range withString: str2];
	
	// TODO: how to delete str2
	
	NSRange range2;
    range2 = NSMakeRange([[output string] length], 0);
	[output scrollRangeToVisible: range2];
}

@end
