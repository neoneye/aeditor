//
//  AE_Model.h
//  mac_aeditor
//
//  Created by Simon Strandgaard on 10/4-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct {
	unsigned int x;
	unsigned int y;
} ModelPosition;

@interface Model : NSObject {
	NSMutableString* _text;
	NSMutableArray*  _observers;
}

- (id)init;

- (void)addObserver:(id)observer;

- (void)replaceCharactersInRange:(NSRange)aRange
                      withString:(NSString*)aString;

- (unsigned int)length;

- (unsigned int)lines;

- (NSString*)stringFromLine:(unsigned int)line;

- (unsigned int)convertPositionToIndex:(ModelPosition)position;
- (ModelPosition)convertIndexToPosition:(unsigned int)index;

@end
