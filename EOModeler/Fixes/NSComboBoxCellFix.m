//
//  NSComboBoxCellFix.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/28/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSComboBoxCellFix.h"

#import <AJRFoundation/AJRFoundation.h>

// Some private Apple API
@interface NSComboBoxCell (ApplePrivate)

- (void)initPopUpWindow;

@end


@implementation NSComboBoxCellFix

+ (void)load
{
	[self poseAsClass:[NSComboBoxCell class]];
}

- (void)setStringValue:(NSString *)aString
{
	if (aString == nil) aString = @"";
	[super setStringValue:aString];
}

- (float)minWidth
{
	NSDictionary	*attribs = [NSDictionary dictionaryWithObject:[self font] forKey:NSFontAttributeName];
	int				x;
	float				min = 0.0;
	
	for (x = 0; x < (const int)[_popUpList count]; x++) {
		NSSize		size = [[_popUpList objectAtIndex:x] sizeWithAttributes:attribs];
		if (min < size.width) min = size.width;
	}
	
	return min + 30.0;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ([controlView isKindOfClass:[NSTableView class]]) {
		cellFrame.size.width -= 10.0;
		cellFrame.origin.x += 2.0;
		[[self attributedStringValue] drawInRect:cellFrame];
		cellFrame.origin.x -= 2.0;
		cellFrame.size.width += 10.0;
		_controlView = controlView;
		if (_cellFrame) {
			float		min = [self minWidth];
			*_cellFrame = cellFrame;
			if (_cellFrame->size.width < min) {
				_cellFrame->size.width = min;
			}
		}
		[[NSImage imageNamed:@"smallPopupArrows"] compositeToPoint:(NSPoint){cellFrame.origin.x + cellFrame.size.width - 5.0, cellFrame.origin.y + cellFrame.size.height - 2.0} operation:NSCompositeSourceOver];
	} else {
		[super drawWithFrame:cellFrame inView:controlView];
	}
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if ([controlView isKindOfClass:[NSTableView class]]) {
		cellFrame.size.height += 1.0;
		cellFrame.size.width += 10.0;
		
		[[self attributedStringValue] drawInRect:cellFrame];
	} else {
		[super drawInteriorWithFrame:cellFrame inView:controlView];
	}
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
	if ([controlView isKindOfClass:[NSTableView class]]) {
		aRect.origin.y -= 1.0;
		aRect.size.height += 3.0;
		aRect.size.width += 10.0;
	}
	[super editWithFrame:aRect inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(int)selStart length:(int)selLength
{
	if ([controlView isKindOfClass:[NSTableView class]]) {
		aRect.origin.y -= 1.0;
		aRect.size.height += 3.0;
		aRect.size.width += 10.0;
	}
	[super selectWithFrame:aRect inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (id)initWithCoder:(NSCoder *)coder
{
	[super initWithCoder:coder];
	switch ([self controlSize]) {
		case NSRegularControlSize:
			[self setFont:[[NSFontManager sharedFontManager] convertFont:[self font] toSize:[NSFont systemFontSize]]];
			break;
		case NSSmallControlSize:
			[self setFont:[[NSFontManager sharedFontManager] convertFont:[self font] toSize:[NSFont smallSystemFontSize]]];
			break;
		case NSMiniControlSize:
			[self setFont:[[NSFontManager sharedFontManager] convertFont:[self font] toSize:[NSFont smallSystemFontSize] - 2.0]];
			break;
	}
	
	return self;
}

- (void)initPopUpWindow
{
	[super initPopUpWindow];
	[[[[_tableView tableColumns] objectAtIndex:0] dataCell] setFont:[self font]];
}

@end
