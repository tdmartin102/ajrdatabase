/*%*%*%*%*
Copyright (C) 1995-2004 Alex J. Raftis

This library is free software; you can redistribute it and/or modify it 
under the terms of the GNU General Public License as published by the Free 
Software Foundation; either version 2.1 of the License, or (at your option) 
any later version.

This library is distributed in the hope that it will be useful, but WITHOUT 
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with 
this library; if not, write to the Free Software Foundation, Inc., 59 Temple 
Place, Suite 330, Boston, MA  02111-1307  USA

Or, contact the author,

Alex J. Raftis
709 Bay Area Blvd.
League City, TX 77573
mailto:alex@raftis.net
http://www.raftis.net/~alex/
 *%*%*%*%*/
//
//  PBPopUpButtonCell.m
//  Paper Boy
//
//  Created by Alex Raftis on Tue Jan 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "PBPopUpButtonCell.h"

#import <AJRFoundation/AJRFoundation.h>

@implementation PBPopUpButtonCell

- (void)dealloc
{
	[image release];
	
	[super dealloc];
}

- (void)setImage:(NSImage *)anImage
{
	if (image != anImage) {
		[image release];
		image =[anImage retain];
	}
}

- (NSImage *)image
{
	if (image == nil) return [NSImage imageNamed:@"pullDown"];
	return image;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSSize		size = [[self image] size];
	
	[[NSImage imageNamed:@"PBPopUpButtonCellBackground"] compositeToPoint:(NSPoint){cellFrame.origin.x, cellFrame.origin.y + cellFrame.size.height} operation:NSCompositeCopy];
	
	[[self image] compositeToPoint:(NSPoint){cellFrame.origin.x + ceil((cellFrame.size.width - size.width) / 2.0), cellFrame.origin.y + rint((cellFrame.size.height + size.height) / 2.0)} operation:NSCompositeSourceOver];
}

@end
