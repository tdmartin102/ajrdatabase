//
//  NSTableViewFix.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/30/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSTableViewFix.h"

#import <objc/objc-class.h>

@implementation NSTableViewFix

+ (void)load
{
	//[[AJRTableView class] poseAsClass:[NSTableView class]];
	//[self poseAsClass:[NSTableView class]];
	#warning We need to swizzel this class

}

- (void)selectAll:(id)sender
{
	[super selectAll:sender];
	
	if ([self action]) {
		[NSApp sendAction:[self action] to:[self target] from:self];
	}
}

- (void)keyDown:(NSEvent *)event
{
	int		row = [self selectedRow];
	
	[super keyDown:event];
	
	if (row != [self selectedRow] && [self action]) {
		[NSApp sendAction:[self action] to:[self target] from:self];
	}
}

@end
