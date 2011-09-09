//
//  ModelOutlineCell.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "ModelOutlineCell.h"

@implementation ModelOutlineCell

- (void)dealloc
{
	[imageName release];
	
	[super dealloc];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (imageName) {
		[[self attributedStringValue] drawInRect:[self titleRectForBounds:cellFrame]];
		[[NSImage imageNamed:imageName] compositeToPoint:(NSPoint){cellFrame.origin.x + 2, cellFrame.origin.y + cellFrame.size.height} operation:NSCompositeSourceOver];
	} else {
		[super drawInteriorWithFrame:cellFrame inView:controlView];
	}
}

- (NSRect)titleRectForBounds:(NSRect)theRect
{
	NSRect		rect = [super titleRectForBounds:theRect];
	
	if (imageName) {
		rect.origin.x += 20.0;
		rect.size.width -= 20.0;
	}
	
	return rect;
}

- (void)setImageName:(NSString *)anImageName
{
	if (imageName != anImageName) {
		[imageName release];
		imageName = [anImageName retain];
	}
}

- (NSString *)imageName
{
	return imageName;
}

@end
