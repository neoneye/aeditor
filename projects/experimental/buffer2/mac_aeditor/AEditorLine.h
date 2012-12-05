//
//  AEditorLine.h
//  mac_aeditor
//
//  Created by Simon Strandgaard on 20/3-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AEditorLine : NSObject {   
	int _lineNumber;
	int _y;
	NSRect _bounds;
}

- (id) initWithLine: (int) lineNumber
             bounds: (NSRect) bounds
		      withY: (int) y;

- (NSRect) bounds;

- (int) lineNumber;

- (int) y;

@end
