//
//  NSTextFieldFix.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSTextFieldFix.h"

@implementation NSTextFieldFix

+ (void)load
{
	[self poseAsClass:[NSTextField class]];
}

- (void)setStringValue:(NSString *)aValue
{
	if (aValue == nil) [super setStringValue:@""];
	else [super setStringValue:aValue];
}

@end
