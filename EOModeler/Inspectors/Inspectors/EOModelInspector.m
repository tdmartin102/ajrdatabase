//
//  EOModelInspector.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOModelInspector.h"

#import "EOModelAdaptorPane.h"
#import "EOModelConnectionPane.h"
#import "EOUserInfoPane.h"

@implementation EOModelInspector

- (NSString *)name
{
	return @"Model";
}

- (NSArray *)inspectorPanes
{
	if (inspectorPanes == nil) {
		inspectorPanes = [[NSArray allocWithZone:[self zone]] initWithObjects:
			[EOModelAdaptorPane paneWithInspector:self],
			[EOModelConnectionPane paneWithInspector:self],
			[EOUserInfoPane paneWithInspector:self],
			nil];
	}
	
	return inspectorPanes;
}
	
@end

@implementation EOModel (EOInspector)

static EOModelInspector		*inspector = nil;

- (EOInspector *)inspector
{
	if (inspector == nil) {
		inspector = [[EOModelInspector alloc] init];
	}
	
	return inspector;
}

@end
