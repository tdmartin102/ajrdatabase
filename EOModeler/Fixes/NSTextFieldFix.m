//
//  NSTextFieldFix.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSTextFieldFix.h"

#import <objc/objc-class.h>

@implementation NSTextField (EOModler)

+ (void)load
{
	Method		originalMethod;
	Method		ourMethod;

	//[self poseAsClass:[NSComboBoxCell class]];
    // we will instead swizzel the one method we need.

	originalMethod = class_getInstanceMethod([NSTextField class], @selector(setStringValue:));
	ourMethod = class_getInstanceMethod([NSTextField class], @selector(_ajrSetStringValue:));
	method_exchangeImplementations(originalMethod, ourMethod);
}

- (void)_ajrSetStringValue:(NSString *)aValue
{
	if (aValue == nil) [self _ajrSetStringValue:@""];
	else [self _ajrSetStringValue:aValue];
}

@end
