//
//  ModelOutlineCell.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "ModelOutlineCell.h"

@implementation ModelOutlineCell

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (imageName) {
        NSSize size;
        NSRect imageRect;
        NSImage *aImage = [NSImage imageNamed:imageName];
        if (aImage) {
            [[self attributedStringValue] drawInRect:[self titleRectForBounds:cellFrame]];
        
            size = [aImage size];
            imageRect.origin.x = cellFrame.origin.x + 2;
            imageRect.origin.y = cellFrame.origin.y + cellFrame.size.height;
            imageRect.size = size;
        
            [[self image] drawInRect:imageRect fromRect:NSZeroRect
                       operation:NSCompositeSourceOver fraction:1.0];
         }
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
		imageName = anImageName;
	}
}

- (NSString *)imageName
{
	return imageName;
}

@end
