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
//  PBPopUpButton.m
//  Paper Boy
//
//  Created by Alex Raftis on Tue Jan 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "PBPopUpButton.h"

#import "PBPopUpButtonCell.h"

static Class		cellClass = Nil;

@implementation PBPopUpButton

+ (void)setCellClass:(Class)aClass
{
	cellClass = aClass;
}

+ (Class)cellClass
{
	if (cellClass == Nil) return [PBPopUpButtonCell class];
	return cellClass;
}

- (id)initWithCoder:(NSCoder *)coder
{
	NSPopUpButtonCell		*oldCell;
	PBPopUpButtonCell		*newCell;
	
	self = [super initWithCoder:coder];
	
	oldCell = [self cell];
	newCell = [[[[self class] cellClass] alloc] initImageCell:[oldCell image]];
	[newCell setMenu:[oldCell menu]];
	[newCell setPullsDown:[oldCell pullsDown]];
	[newCell setAutoenablesItems:[oldCell autoenablesItems]];
	[newCell setPreferredEdge:[oldCell preferredEdge]];
	[newCell setUsesItemFromMenu:[oldCell usesItemFromMenu]];
	[newCell setAltersStateOfSelectedItem:[oldCell altersStateOfSelectedItem]];
	[newCell setArrowPosition:NSPopUpNoArrow];
	[newCell setImage:[[[newCell menu] itemAtIndex:0] image]];
	[[newCell menu] removeItemAtIndex:0];
	[self setCell:newCell];
	
	return self;
}

@end
