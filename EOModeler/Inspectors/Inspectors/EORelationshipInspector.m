//
//  EORelationshipInspector.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EORelationshipInspector.h"

#import "EORelationshipPane.h"
#import "EORelationshipAdvancedPane.h"
#import "EOUserInfoPane.h"

@implementation EORelationshipInspector

- (NSString *)name
{
	return @"Relationship";
}

- (NSArray *)inspectorPanes
{
	if (inspectorPanes == nil) {
		inspectorPanes = [[NSArray alloc] initWithObjects:
			[EORelationshipPane paneWithInspector:self],
			[EORelationshipAdvancedPane paneWithInspector:self],
			[EOUserInfoPane paneWithInspector:self],
			nil];
	}
	
	return inspectorPanes;
}

@end

@implementation EORelationship (EOInspector)

static EORelationshipInspector		*inspector = nil;

- (EOInspector *)inspector
{
	if (inspector == nil) {
		inspector = [[EORelationshipInspector alloc] init];
	}
	
	return inspector;
}

@end
