//
//  EOStoredProcedureInspector.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOStoredProcedureInspector.h"

#import "EOUserInfoPane.h"

@implementation EOStoredProcedureInspector

- (NSString *)name
{
	return @"Stored Procedure";
}

- (NSArray *)inspectorPanes
{
	if (inspectorPanes == nil) {
		inspectorPanes = [[NSArray alloc] initWithObjects:
			[EOUserInfoPane paneWithInspector:self],
			nil];
	}
	
	return inspectorPanes;
}

@end

@implementation EOStoredProcedure (EOInspector)

static EOStoredProcedureInspector		*inspector = nil;

- (EOInspector *)inspector
{
	if (inspector == nil) {
		inspector = [[EOStoredProcedureInspector alloc] init];
	}
	
	return inspector;
}

@end
