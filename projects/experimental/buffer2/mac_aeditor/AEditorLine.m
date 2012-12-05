//
//  AEditorLine.m
//  mac_aeditor
//
//  Created by Simon Strandgaard on 20/3-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AEditorLine.h"


@implementation AEditorLine

- (id) initWithLine: (int) lineNumber
             bounds: (NSRect) bounds
           	  withY: (int) y {
	self = [super init];

    if (self) {
		_lineNumber = lineNumber;
		_bounds = bounds;
		_y = y;
    }
    return self;
}	

- (NSRect) bounds {
	return _bounds;
}                  

- (int) lineNumber {
	return _lineNumber;
}

- (int) y {
	return _y;
}
	
@end
