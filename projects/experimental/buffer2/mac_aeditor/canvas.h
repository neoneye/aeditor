//
//  canvas.h
//  mac_aeditor
//
//  Created by Simon Strandgaard on 12/3-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AEditorLine.h"
#import "AE_View.h"

@interface canvas : NSView {
	NSFont *font;
	NSDictionary *attrs;

	int lineheight;
	int topskip;
	int cellwidth;
	long line_render_count;
	BOOL use_optimized_rendering;
	int line_spacing;
	int letter_spacing;
	
	NSMutableArray *display_list;
	NSString* texts[2];
	
	View *_view;
}

- (void)setFont:(NSFont*)newFont;
- (void)draw:(AEditorLine*)line;
- (void)refreshDisplayLists;

- (void)changeSlowAlgo;
- (void)changeFastAlgo;
- (void)setLineSpacing:(int)pixels;
- (void)setLetterSpacing:(int)pixels;

- (void)adjustFontSize:(int)delta;

@end
