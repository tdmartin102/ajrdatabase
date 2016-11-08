//
//  EOEntityInspector.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOEntityInspector.h"

#import "EOEntityPane.h"
#import "EOEntityAdvancedPane.h"
#import "EOEntitySharedObjectsPane.h"
#import "EOEntityStoredProceduresPane.h"
#import "EOUserInfoPane.h"

@implementation EOEntityInspector

- (NSString *)name
{
	return @"Entity";
}

- (NSArray *)inspectorPanes
{
	if (inspectorPanes == nil) {
		inspectorPanes = [[NSArray alloc] initWithObjects:
			[EOEntityPane paneWithInspector:self],
			[EOEntityAdvancedPane paneWithInspector:self],
			[EOEntitySharedObjectsPane paneWithInspector:self],
			[EOEntityStoredProceduresPane paneWithInspector:self],
			[EOUserInfoPane paneWithInspector:self],
			nil];
	}
	
	return inspectorPanes;
}

@end


@implementation EOEntity (EOInspector)

static EOEntityInspector		*inspector = nil;

- (EOInspector *)inspector
{
	if (inspector == nil) {
		inspector = [[EOEntityInspector alloc] init];
	}
	
	return inspector;
}

@end
