//
//  NSOutlineView-Extensions.m
//  AJRDatabase
//
//  Created by Alex Raftis on 10/15/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSOutlineView-Extensions.h"

@implementation NSOutlineView (Extensions)

- (id)parentForItem:(id)item
{
	int		row = [self rowForItem:item];
	int		level;
	
	if (row > 0) {
		level = [self levelForRow:row];
		
		do {
			int		newLevel = [self levelForRow:row];
			if (newLevel < level) {
				return [self itemAtRow:row];
			}
			row--;
		} while (row >= 0);
	}
	
	return nil;
}

@end
