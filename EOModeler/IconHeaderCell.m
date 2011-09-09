//
//  IconHeaderCell.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "IconHeaderCell.h"

@implementation IconHeaderCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSString		*title = [[self title] retain];
	NSSize		size;

	[self setTitle:@""];
	[super drawInteriorWithFrame:cellFrame inView:controlView];
	[self setTitle:title];
	[title release];
	
	if ([self image]) {
		size = [[self image] size];
		[[self image] compositeToPoint:(NSPoint){cellFrame.origin.x + (cellFrame.size.width - size.width) / 2.0, cellFrame.origin.y + cellFrame.size.height - (cellFrame.size.height - size.height) / 2.0} operation:NSCompositeSourceOver];
	}
}

- (void)setImage:(NSImage *)anImage
{
	if (image != anImage) {
		[image release];
		image = [anImage retain];
	}
}

- (NSImage *)image
{
	return image;
}

@end
