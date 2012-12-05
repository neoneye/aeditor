//
//  AE_Model.m
//  mac_aeditor
//
//  Created by Simon Strandgaard on 10/4-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AE_Model.h"


@implementation Model

- (id) init {
	self = [super init];
	if (self) {
		_text = [
			[NSMutableString alloc]
			initWithString: @"empty buffer\nabcxyz"
		];
		[_text retain];
		
		
		/*ModelPosition p = [self convertIndexToPosition:22];
		p.x = 50;
		p.y = 0;
		unsigned int i = [self convertPositionToIndex:p];
		NSLog(@"position: x=%i y=%i   index=%i", p.x, p.y, i);*/

		
		_observers = [
			[NSMutableArray alloc]
			initWithCapacity:0
		];
		[_observers retain];
	}
	return self;
}

const unichar NEWLINE = 10;

- (unsigned int)convertPositionToIndex:(ModelPosition)position {
	unsigned int index = [_text length];
	unsigned int i;
	for(i=0;i<index;i++) {
		if(position.y == 0)
			break;
   		if([_text characterAtIndex: i] == NEWLINE)
			position.y -= 1;
   	}
   	for(;i<index;i++) {
		if(position.x == 0)
			break;
   		if([_text characterAtIndex: i] == NEWLINE)
			break;
		position.x -= 1;
	}
	return i; // always return a valid index
}   

- (ModelPosition)convertIndexToPosition:(unsigned int)index {
	if(index > [_text length])
		index = [_text length];
	
	ModelPosition position;
	position.x = 0;
	position.y = 0;
	
	unsigned int i;
	for(i=0;i<index;i++) {
		position.x += 1;
		if([_text characterAtIndex: i] == NEWLINE) {
			position.y += 1;
			position.x = 0;
		}
	}
	return position; // always return a valid position
}


- (void)replaceCharactersInRange:(NSRange)aRange
                      withString:(NSString*)aString {
	NSLog(@"replace location=%i length=%i", aRange.location, aRange.length);

	[_text replaceCharactersInRange:aRange withString:aString];

	// notify our observers
	NSEnumerator *en = [_observers objectEnumerator];
	id thing;
	while(thing = [en nextObject])
		[thing modelNotify];
	
}

/*
def replace(x1, y1, x2, y2, utf8_str)
	$logger.debug "model replace xy1=#{x1.inspect},#{y1.inspect} " +
		"xy2=#{x2.inspect},#{y2.inspect} text.size=#{utf8_str.size}"
	check_integer(x1)
	check_integer(y1)
	check_integer(x2)
	check_integer(y2)
	raise ArgumentError, "negative range" if y1 > y2
	raise ArgumentError, "negative range" if y1 == y2 and x1 > x2
	check_valid_utf8(utf8_str)

	begin		
		text_begin_line = p2b(0, y1)
		text_begin_insert = p2b(x1, y1)
	rescue ArgumentError => e
		raise ArgumentError, 
			"first position (#{x1},#{y1}) is invalid, " +
			"reason=#{e.message}"
	end
	begin
		text_end_line = p2b(0, y2) + @bytes[y2]
		text_end_insert = p2b(x2, y2)
	rescue ArgumentError => e
		raise ArgumentError, 
			"second position (#{x1},#{y1}) is invalid, " +
			"reason=#{e.message}"
	end

	b1 = text_begin_line
	w1 = text_begin_insert - text_begin_line
	b2 = text_end_insert
	w2 = text_end_line - text_end_insert
	text = @text[b1, w1] + utf8_str + @text[b2, w2]

	b3 = text_begin_insert
	w3 = text_end_insert - text_begin_insert

	bytes = text.map{|str| str.size}
	if text.empty? or 
		(y2 == @bytes.size-1 and w2 == 0 and utf8_str =~ /\n\z/)
		bytes << 0
	end
	bytes_w = 1+y2-y1
	
	notify(:before, x1, y1, x2, y2, nil, nil)
	@text[b3, w3] = utf8_str
	@bytes[y1, bytes_w] = bytes
	newx2, newy2 = b2p(b3+utf8_str.size)
	notify(:after, x1, y1, x2, y2, newx2, newy2)
end
*/

- (void)addObserver:(id)observer {
	[_observers addObject:observer];
}

- (unsigned int)length {
	return [_text length];
}

- (unsigned int)lines {
	ModelPosition p = [self convertIndexToPosition:[self length]];
	return p.y + 1;
}

- (NSString*)stringFromLine:(unsigned int)line {
	ModelPosition p1;
	p1.x = 0;
	p1.y = line;
	ModelPosition p2;
	p2.x = 0xffffffff;
	p2.y = line;
	NSRange range;
	range.location = [self convertPositionToIndex:p1];
	range.length   = [self convertPositionToIndex:p2] - range.location;
	return [_text substringWithRange:range];
}



@end
