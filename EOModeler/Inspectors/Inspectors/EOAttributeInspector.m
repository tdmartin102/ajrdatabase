//
//  EOAttributeInspector.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOAttributeInspector.h"

#import "EOAttributePane.h"
#import "EOUserInfoPane.h"

@implementation EOAttributeInspector

- (NSString *)name
{
	return @"Attribute";
}

- (NSArray *)inspectorPanes
{
	if (inspectorPanes == nil) {
		inspectorPanes = [[NSArray allocWithZone:[self zone]] initWithObjects:
			[EOAttributePane paneWithInspector:self],
			[EOUserInfoPane paneWithInspector:self],
			nil];
	}
	
	return inspectorPanes;
}

@end


@implementation EOAttribute (EOInspector)

static EOAttributeInspector		*inspector = nil;

- (EOInspector *)inspector
{
	if (inspector == nil) {
		inspector = [[EOAttributeInspector alloc] init];
	}
	
	return inspector;
}

@end
