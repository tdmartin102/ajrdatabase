//
//  EOStringPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOStringPane.h"

#import <EOAccess/EOAccess.h>

@implementation EOStringPane

+ (void)load { }

+ (NSString *)name
{
	return @"String";
}

+ (Class)inspectedClass
{
	return [NSString class];
}

- (void)update
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[externalWidthField setIntValue:[attribute width]];
}

- (void)updateAttribute
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[attribute setValueClassName:@"NSString"];
}

- (void)setExternalWidth:(id)sender
{
	[[self selectedAttribute] setWidth:[sender intValue]];
}

@end
