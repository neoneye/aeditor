//
//  AE_View.m
//  mac_aeditor
//
//  Created by Simon Strandgaard on 10/4-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AE_View.h"


@implementation View

- (id) init {
	self = [super init];
	if (self) {
		
		_position.x = 0;
		_position.y = 0;
		
	    _model = [
			[Model alloc]
			init
		];
		[_model retain];
		
		[_model addObserver:self];
		NSLog(@"added");


		// testing
		NSRange range;
		range.location=4;
		range.length=3;
		
		NSString *str = @"hello";
		
		[_model replaceCharactersInRange:range withString:str];

		unsigned int i;		
		for(i=0;i<4;i++) {
			NSString *line = [_model stringFromLine:i];
			NSLog(@"line%i=\"%@\"", i, line);
		}
		
		NSLog(@"lines=%i length=%i", [_model lines], [_model length]);
		
	}	
	return self;
}

- (void) modelNotify {
	NSLog(@"modelNotify");
}

- (void)loadFile {
	// TODO: prevent this absolute path
	NSString *path = @"/Users/simonstrandgaard/code/aeditor/projects/experimental/buffer2/mac_aeditor/testdata.txt";
	NSString *data = [NSString stringWithContentsOfFile:path];
//	NSLog(@"loading: %@\n%@", data, path);

	NSRange range;
	range.location=0;
	range.length=[_model length];
	[_model replaceCharactersInRange:range withString:data];
}

- (NSString*)stringFromLine:(unsigned int)line {
	return [_model stringFromLine:line];
}

- (void)insert:(NSString*)string {
	unsigned int i=[_model convertPositionToIndex:_position];
	NSRange range;
	range.location=i;
	range.length=0;
	[_model replaceCharactersInRange:range withString:string];
	_position = [_model convertIndexToPosition:i+1];
}

- (void)eraseLeft {
	unsigned int i=[_model convertPositionToIndex:_position];
	if(i == 0)
		return;
	i-=1;
	if(i+1 >= [_model length])
		return;
	NSRange range;
	range.location=i;
	range.length=1;
	[_model replaceCharactersInRange:range withString:@""];
	_position = [_model convertIndexToPosition:i];
}


- (void)moveLeft {
	if(_position.x == 0)
		return;
	_position.x -= 1;
}

- (void)moveRight {
	_position.x += 1;
}

- (void)moveUp {
	if(_position.y == 0)
		return;
	_position.y -= 1;
}

- (void)moveDown {
	_position.y += 1;
}

- (ModelPosition)position {
	return _position;
}

@end
