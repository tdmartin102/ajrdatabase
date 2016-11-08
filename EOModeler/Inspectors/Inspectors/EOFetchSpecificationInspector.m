//
//  EOFetchSpecificationInspector.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOFetchSpecificationInspector.h"

#import "EOUserInfoPane.h"

@implementation EOFetchSpecificationInspector

- (NSString *)name
{
	return @"Fetch Specification";
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


@implementation EOFetchSpecification (EOInspector)

static EOFetchSpecificationInspector		*inspector = nil;

- (EOInspector *)inspector
{
	if (inspector == nil) {
		inspector = [[EOFetchSpecificationInspector alloc] init];
	}
	
	return inspector;
}

@end
