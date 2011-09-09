//
//  EODataPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EODataPane.h"

#import <EOAccess/EOAccess.h>

@implementation EODataPane

+ (void)load { }

+ (NSString *)name
{
	return @"Data";
}

+ (Class)inspectedClass
{
	return [NSData class];
}

- (void)update
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[externalWidthField setIntValue:[attribute width]];
}

- (void)updateAttribute
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[attribute setValueClassName:@"NSData"];
}

- (void)setExternalWidth:(id)sender
{
	[[self selectedAttribute] setWidth:[sender intValue]];
}

@end
