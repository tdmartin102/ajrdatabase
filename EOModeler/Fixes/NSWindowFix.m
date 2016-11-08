//
//  NSWindowFix.m
//  AJRDatabase
//
//  Created by Alex Raftis on 10/1/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSWindowFix.h"

#import <objc/objc-class.h>

@implementation NSObject (NSWindowFix)

- (BOOL)processKeyDown:(NSEvent *)event
{
	return NO;
}

@end

@implementation NSWindowFix

+ (void)load
{
    Method		originalMethod;
    Method		ourMethod;

	// [self poseAsClass:[NSWindow class]];
	// We need to swizzel this class or better yet set up windows in IB to BE this class.
    
    originalMethod = class_getInstanceMethod([NSWindow class], @selector(sendEvent:));
    ourMethod = class_getInstanceMethod([NSWindow class], @selector(_ajrSendEvent:));
    method_exchangeImplementations(originalMethod, ourMethod);

}

- (void)_ajrSendEvent:(NSEvent *)event
{
	if ([event type] == NSKeyDown) {
		if ([[self firstResponder] isKindOfClass:[NSTextView class]]) {
			[self _ajrSendEvent:event];
			return;
		} else {
			if ([[self firstResponder] processKeyDown:event]) return;
			if ([(NSObject *)[self delegate] processKeyDown:event]) return;
			if ([(NSObject *)[NSApp delegate] processKeyDown:event]) return;
		}
	}
		
	[self _ajrSendEvent:event];
}

@end


