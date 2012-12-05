//
//  AE_View.h
//  mac_aeditor
//
//  Created by Simon Strandgaard on 10/4-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AE_Model.h"

@interface View : NSObject {
	Model *_model;
	ModelPosition _position;
}

- (id) init;

- (void) modelNotify;

- (void)loadFile;

- (NSString*)stringFromLine:(unsigned int)line;

- (void)insert:(NSString*)string;
- (void)eraseLeft;

- (void)moveLeft;
- (void)moveRight;
- (void)moveUp;
- (void)moveDown;

- (ModelPosition)position;


@end
