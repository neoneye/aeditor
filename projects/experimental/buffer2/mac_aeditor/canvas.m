//
//  canvas.m
//  mac_aeditor
//
//  Created by Simon Strandgaard on 12/3-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "canvas.h"
#include <sys/time.h>

#define FONTSIZE 28

static unichar UC_BOX_DRAWINGS_LIGHT_ARC_DOWN_AND_RIGHT = 0x256D;
static unichar UC_BOX_DRAWINGS_LIGHT_ARC_DOWN_AND_LEFT = 0x256E;
static unichar UC_BOX_DRAWINGS_LIGHT_ARC_UP_AND_RIGHT = 0x2570;
static unichar UC_BOX_DRAWINGS_LIGHT_ARC_UP_AND_LEFT = 0x256F;
static unichar UC_SQUARE_MM_SQUARED = 0x339F;
static unichar UC_FULLWIDTH_N = 0xFF2E;
static unichar UC_CJK = 0x4E21;


@implementation canvas

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
   		_view = [
			[View alloc]
			init
		];
		[_view retain];
		
		[_view loadFile];

	
		// reset statistics
		line_render_count = 0;
		
		use_optimized_rendering = YES;
		line_spacing = 0;
		letter_spacing = 0;

		// pick a font
		display_list = [[NSMutableArray alloc] init];
		font = nil;
		attrs = nil;
		[self setFont:[NSFont userFixedPitchFontOfSize:FONTSIZE]];
		
		// build some strings to output
		NSString* str0 = [[NSString alloc] initWithFormat:@"%@%@<%@><%@><%@><j_J>",
			[NSString stringWithCharacters: &UC_BOX_DRAWINGS_LIGHT_ARC_DOWN_AND_RIGHT length: 1],
			[NSString stringWithCharacters: &UC_BOX_DRAWINGS_LIGHT_ARC_UP_AND_LEFT length: 1],
			[NSString stringWithCharacters: &UC_SQUARE_MM_SQUARED length: 1],
			[NSString stringWithCharacters: &UC_FULLWIDTH_N length: 1],
			[NSString stringWithCharacters: &UC_CJK length: 1]
		];
		texts[0] = str0; 
		NSString* str1 = [[NSString alloc] initWithFormat:@"%@%@01234567890123456789",
			[NSString stringWithCharacters: &UC_BOX_DRAWINGS_LIGHT_ARC_UP_AND_RIGHT length: 1],
			[NSString stringWithCharacters: &UC_BOX_DRAWINGS_LIGHT_ARC_DOWN_AND_LEFT length: 1]
		];
		texts[1] = str1;
	}
    return self;
}

-(void) awakeFromNib {
	NSRect r;
	r.origin.x=0;
	r.origin.y=0;
	r.size.width=2000;
	r.size.height=500;
	[self setFrame:r];
	[self setBounds:r];
	
	[[self enclosingScrollView] setHasHorizontalScroller:NO]; // disable h-scroller
	[self scrollToCaret];
}

- (void)drawRect:(NSRect)rect { 
	BOOL optimized = use_optimized_rendering;
	
	struct timeval t0, t1;
	gettimeofday(&t0, NULL);
	
	NSRect frame = [self frame];
	NSRect bounds = [self bounds];
	NSRect visible = [self visibleRect];
    NSLog(@"drawRect: algo=%s "
		//"frame(%4.1f,%4.1f,%4.1f,%4.1f)\n"
		//"bounds(%4.1f,%4.1f,%4.1f,%4.1f)\n" 
		"visible(%4.1f,%4.1f,%4.1f,%4.1f)", 
		(optimized?"fast":"slow"),
		/*frame.origin.x, frame.origin.y,
		frame.size.width, frame.size.height,
		bounds.origin.x, bounds.origin.y,
		bounds.size.width, bounds.size.height,*/
		visible.origin.x, visible.origin.y,
		visible.size.width, visible.size.height);
	
	// calculate number of visible lines
	int number_of_lines = (bounds.size.height+lineheight-1.0)/lineheight;

	// only render visible things
	NSEnumerator *en;
	en = [display_list objectEnumerator];
	const NSRect *rects;
	int count, i;
	[self getRectsBeingDrawn:&rects count:&count];
	//NSLog(@"count=%i\n", count);

	// fill background
	[[NSColor blackColor] set];
	for (i = 0; i < count; i++) {
		[NSBezierPath fillRect:rects[i]];
	}                 
	
	// render text
	line_render_count=0;
	if(optimized)
	{
		NSMutableString *affected_lines = [NSMutableString stringWithCapacity:200];
		id thing;
		[self lockFocus];
		while(thing = [en nextObject]) 
		{
			if (NSIntersectsRect([thing bounds], rect)) {
				for (i = 0; i < count; i++) {
					if (NSIntersectsRect([thing bounds], rects[i])) {
						[self draw:thing];
						[affected_lines appendFormat: @"%i, ", [thing lineNumber]];
						break;
					}
				}
			}
		}
		[self unlockFocus];
		NSLog(@"affected lines: [%@]", affected_lines);
	}
	else
	{
		id thing;
		while(thing = [en nextObject]) 
		{
			[self draw:thing];
		}
	}
	gettimeofday(&t1, NULL);
	double ft0, ft1;
	ft0 = (t0.tv_sec * 1000000.0 + t0.tv_usec) / 1000000.0;
	ft1 = (t1.tv_sec * 1000000.0 + t1.tv_usec) / 1000000.0;
	double total = ft1 - ft0;
	double average = total / line_render_count;
	NSLog(@"drawRect took %f seconds, "
		"%i lines affected (average %f seconds per line)", 
		total, line_render_count, average);	
}

/*- (BOOL)wantsDefaultClipping {
    return NO;
}*/

- (void)draw:(AEditorLine*)line
{
	line_render_count += 1;

	int line_number = [line lineNumber];
	//NSLog(@"draw line %i\n", line_number);
	int y = [line y];

	int glyph_width = cellwidth+letter_spacing;
	int glyph_height = lineheight+line_spacing;
	
	// TODO: why doesn't the first letter get rendered?
	NSString *string = [_view stringFromLine:line_number];
	/*	NSString *string = [
			NSString 
			stringWithFormat:@"xx %2i %@", 
			line_number+1, 
	//		line_text
			texts[(line_number+1)%2]
		];*/
	

	ModelPosition cursor = [_view position];	
	if(cursor.y == line_number) {
		
		[[NSColor whiteColor] set];
		NSRect cursor_area = NSMakeRect(
			glyph_width*cursor.x, y, glyph_width, lineheight);
		[NSBezierPath fillRect:cursor_area];
		
		
		NSLog(@"render line \"%@\"", string);
	}
	

	// render red line at baseline
	if((line_number == 49) || (line_number == 50))
	{
		if(line_number == 50)
			[[NSColor redColor] set];
		else
			[[NSColor blueColor] set];
		NSRect baseline = NSMakeRect(0, y, 4000, 4);
   		[NSBezierPath fillRect:baseline];
	}

	unsigned int length = [string length];
	unsigned int cellx=0;
	unsigned int j;
	for(j=0; j<length; j++) {
		// style for this glyph
		NSMutableDictionary *style = [attrs mutableCopy];
		
		NSColor *color = nil;
		if(j%2==0) 
			color = [NSColor greenColor];
		else
			color = [NSColor redColor];
		
		[style
			setObject:color 
			forKey:NSForegroundColorAttributeName
		];

   		// make string per letter
		unichar ch = [string characterAtIndex:j];
		
		NSString *ls = [NSString stringWithCharacters:&ch length:1];
		NSAttributedString *letter = [
			[NSAttributedString alloc]
			initWithString:ls
			attributes:style
		];
		
		// fullwidth=2 cells   or halfwidth=1 cell
		NSSize glyph_size = [letter size];
		int cells = (glyph_size.width > (1.2 * cellwidth)) ? 2 : 1;
		
		/*
		TODO: detect of halfwidth/fullwidth fails.
		*/
/*		if(i == 1) {
			printf("%i: gs.width=%f  cellwidth=%i  => cells=%i\n", 
				j, glyph_size.width, cellwidth, cells);
		}*/
		
		// render glyph
		int extra_x = 5;
		int extra_y = 5;  // cocoa does strange v-center when y is negative
		NSRect r = NSMakeRect(
			((float)(cellx * glyph_width)) - extra_x, 
			((float)y) - extra_y, 
			cells * glyph_width + 2 * extra_x, 
			lineheight + 2 * extra_y
		);
		[letter drawInRect:r];
		
		
/*		NSRect r;
		r.size = [letter size];
		r.origin.x = (cellx * glyph_width) + (cells * glyph_width / 2.0) - (r.size.width / 2.0);
		r.origin.y = ((float)y) + (glyph_height / 2.0) - (r.size.height / 2.0);
		[letter drawInRect:r];*/
		
		

		if(cursor.y == line_number)
			NSLog(@"j=%i x=%f y=%f w=%f h=%f ch=%i", 
				j, r.origin.x, r.origin.y, r.size.width, r.size.height, ch);

		cellx += cells;
	} 
}

- (void)keyDown:(NSEvent *)theEvent {
	
	NSLog(@"%@\n", theEvent);

	unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	NSString *str = [theEvent characters];
	switch(key) {
	case NSLeftArrowFunctionKey:
		[_view moveLeft];
		break;
   	case NSRightArrowFunctionKey:
	   	[_view moveRight];
		break;
	case NSUpArrowFunctionKey:
		[_view moveUp];
		break;
	case NSDownArrowFunctionKey:
	   	[_view moveDown];
		break;
	case 127: // backspace
		[_view eraseLeft];
		break;
/*	case NSDeleteFunctionKey:
		[_view eraseRight];
		break;*/
	case 13: // enter
   		[_view insert:@"\n"];
		break;
	default:
		NSLog(@"unknown key (%i). Inserting", key);
		[_view insert:str];
	}

	[self scrollToCaret];
	[self setNeedsDisplay: YES];
}

- (BOOL)isFlipped {
	return YES;
}

- (void)scrollToCaret {
	int glyph_width = cellwidth+letter_spacing;
	int glyph_height = line_spacing + lineheight;
	
	ModelPosition position = [_view position];
	
	NSRect r;
	r.origin.x = position.x * glyph_width;
	r.origin.y = position.y * glyph_height;
	r.size.width = glyph_width;
	r.size.height = glyph_height;
	[self scrollRectToVisible:r];
}

- (BOOL)acceptsFirstResponder {
	NSLog(@"accept");
    return YES;
}

- (NSFont*)font {
	return font;
}

- (void)changeFont:(id)sender
{
	NSFont *oldFont = [self font];
	NSFont *newFont = [sender convertFont: oldFont];
	NSLog(@"font was changed. sender=%@", sender);
	
	
	[self setFont:newFont];
}

- (void)setFont:(NSFont*)newFont {
	//NSLog(@"setFont: oldfont=%@ newfont=%@", font, newFont);
	[newFont retain];
	[font release];
	font = newFont;

	NSMutableParagraphStyle *centered = [
		[[NSParagraphStyle defaultParagraphStyle] mutableCopy] 
		setAlignment:NSCenterTextAlignment
	];
	
	attrs = [
		[NSDictionary alloc] initWithObjectsAndKeys: 
		font, NSFontAttributeName, 
		centered, NSParagraphStyleAttributeName,
		[NSColor whiteColor], NSForegroundColorAttributeName, 
		nil
	]; 
		
	// extract info about our font
	float ascent = [font ascender];
	float descent = [font descender];
	float default_lineheight = [font defaultLineHeightForFont];
	float capheight = [font capHeight];
	NSSize adv = [font maximumAdvancement];

	/* 
	convert from float to integers
	Cocoa's font renderer cannot render glyphs on subpixel offsets,
	when it gets a subpixel offset it rounds it to the nearest integer
	and it produces 1pixel horizontal ugly lines.
	By using integers we avoid these ugly artifacts.
	*/
	lineheight = capheight + 0.5;
	if(lineheight < 8) {
		//NSLog(@"WARNING: lineheight is very low "
		//	"forcing lineheight=8");
		lineheight = 8;
	}
//	topskip = default_lineheight + descent + 0.5;
	topskip = default_lineheight - ascent + 0.5;
	cellwidth = adv.width;
	if(cellwidth < 8) {
		//NSLog(@"WARNING: cellwidth is very low "
		//	"forcing cellwidth=8");
		cellwidth = 8;
	}

	//NSLog(@"max adv=%i\n", cellwidth);		


	NSLog(
		@"setFont %@\n"
		"fixedpitch=%s "
		"adv.width=%3.1f "
		"cellwidth=%i\n"
		"topskip=%i "
		"def_lineheight=%3.1f "
		"capheight=%3.1f "
		"ascent=%3.1f "
		"descent=%3.1f "
		"lineheight=%i",
		font,
		[font isFixedPitch] ? "YES" : "NO",
		adv.width,
		cellwidth,
		topskip,
		default_lineheight,
		capheight,
		ascent,
		descent,
		lineheight
	);


	[self refreshDisplayLists];

	[self setNeedsDisplay: YES];
//	[self setNeedsDisplayInRect: [self bounds]];
//	[self setNeedsDisplayInRect: [self visibleRect]]; //[self frame]];
}

- (void)adjustFontSize:(int)delta {
	NSLog(@"adjustFontSize: "
		"delta=%i"
		"pointsize=%f", 
		delta,
		[font pointSize]
	);
	float size=[font pointSize] + delta;
	NSString *fontName = [font fontName];
	[self setFont:[NSFont fontWithName:fontName size:size]];
}


- (void)refreshDisplayLists {
	[display_list removeAllObjects];

	NSRect bounds = [self bounds];


	int rowheight = line_spacing + lineheight;
	int number_of_lines = bounds.size.height / rowheight;

	NSLog(@"refreshDisplayLists: "
		"lineheight=%i "
		"linespacing=%i "
		"rowheight=%i "
		"topskip=%i "
		"number_of_lines=%i ",
		lineheight, 
		line_spacing,
		rowheight,
		topskip,
		number_of_lines
	);

	int i;
	for(i=0; i<number_of_lines; i++) {
		int line_number = i;
		
		int extra = 4;
		int y = rowheight * i;
		NSRect area = NSMakeRect(
			0, y - extra,
			4000, rowheight + extra*2
		);
		
		if((line_number<3)||(line_number>number_of_lines-2))
		{
			NSLog(@"linenumber=%i (i=%i) %4.1f,%4.1f,%4.1f,%4.1f", 
				line_number, i,
				area.origin.x, area.origin.y,
				area.size.width, area.size.height);
		}
		AEditorLine* line = [
			[AEditorLine alloc] 
			initWithLine:line_number
			bounds:area 
			withY:y
		]; 
		[display_list addObject:line];
		[line release];
	}               
}

- (void)changeAttributes:(id)sender {
	NSLog(@"change attrs");
}

- (void)changeSlowAlgo {
	use_optimized_rendering = NO;
}

- (void)changeFastAlgo {
	use_optimized_rendering = YES;
}

- (void)setLineSpacing:(int)position {
	NSLog(@"setLineSpacing: %i", position);
	line_spacing = position;
	[self refreshDisplayLists];
	[self setNeedsDisplay: YES];
}

- (void)setLetterSpacing:(int)position {
	NSLog(@"setLetterSpacing: %i", position);
	letter_spacing = position;
	[self setNeedsDisplay: YES];
}


@end


// openvpn --daemon --verb 1 --writepid /var/run/ovpn_client0.pid --dev tap1 --proto tcp-client --lport 5002 --remote 212.97.207.21 5002 --tls-client --ca /var/db/ovpn_ca_cert0.pem --cert /var/db/ovpn_cli_cert0.pem --key /var/db/ovpn_cli_key0.pem --comp-lzo --tun-mtu 1500 --mssfix 1400
// openvpn --daemon --verb 1 --writepid /var/run/ovpn_client0.pid --dev tap1 --proto tcp-client --lport 5002 --remote 212.97.207.21 5002 --tls-client --ca /var/db/ovpn_ca_cert_0.pem --cert /var/db/ovpn_cli_cert_0.pem --key /var/db/ovpn_cli_key_0.pem --comp-lzo --tun-mtu 1500 --mssfix 1400
