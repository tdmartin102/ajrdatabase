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
	NSString		*title = [self title];
	NSSize          size;
    NSRect          imageRect;

	[self setTitle:@""];
	[super drawInteriorWithFrame:cellFrame inView:controlView];
	[self setTitle:title];
	
	if ([self image]) {
		size = [[self image] size];
        imageRect.origin.x = cellFrame.origin.x + (cellFrame.size.width - size.width) / 2.0;
        imageRect.origin.y = cellFrame.origin.y + ((cellFrame.size.height - size.height) / 2.0);
        imageRect.size = size;
        
        [[self image] drawInRect:imageRect fromRect:NSZeroRect
                       operation:NSCompositeSourceOver fraction:1.0];
	}
}

- (void)setImage:(NSImage *)anImage
{
	if (image != anImage) {
		image = anImage;
	}
}

- (NSImage *)image
{
	return image;
}

@end
