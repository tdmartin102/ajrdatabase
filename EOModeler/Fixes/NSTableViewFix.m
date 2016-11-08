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
	// #warning We need to swizzel this class or better yet set NSTableViews in IB to be this class.  

    Method		originalMethod;
    Method		ourMethod;
    
    // [self poseAsClass:[NSWindow class]];
    // We need to swizzel this class or better yet set up windows in IB to BE this class.
    
    originalMethod = class_getInstanceMethod([NSTableView class], @selector(selectAll:));
    ourMethod = class_getInstanceMethod([NSTableView class], @selector(_ajrSelectAll:));
    method_exchangeImplementations(originalMethod, ourMethod);

    originalMethod = class_getInstanceMethod([NSTableView class], @selector(keyDown:));
    ourMethod = class_getInstanceMethod([NSTableView class], @selector(_ajrKeyDown:));
    method_exchangeImplementations(originalMethod, ourMethod);
}

- (void)_ajrSelectAll:(id)sender
{
	[self _ajrSelectAll:sender];
	
	if ([self action]) {
		[NSApp sendAction:[self action] to:[self target] from:self];
	}
}

- (void)_ajrKeyDown:(NSEvent *)event
{
	NSInteger	row = [self selectedRow];
	
	[self _ajrKeyDown:event];
	
	if (row != [self selectedRow] && [self action]) {
		[NSApp sendAction:[self action] to:[self target] from:self];
	}
}

@end
