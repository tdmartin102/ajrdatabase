//
//  IconHeaderCell.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <EOInterface/EOInterface.h>

@interface IconHeaderCell : NSTableHeaderCell
{
	NSImage		*image;
}

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;

@end
