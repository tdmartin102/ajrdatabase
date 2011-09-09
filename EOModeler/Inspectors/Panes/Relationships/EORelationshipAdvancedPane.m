//
//  EORelationshipAdvancedPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EORelationshipAdvancedPane.h"

#import <EOAccess/EOAccess.h>

@implementation EORelationshipAdvancedPane

- (NSString *)name
{
	return @"Advanced";
}

- (EORelationship *)selectedRelationship
{
	id		selectedObject = [self selectedObject];
	
	if ([selectedObject isKindOfClass:[EORelationship class]]) return selectedObject;
	
	return nil;
}

- (void)update
{
	EORelationship		*relationship = [self selectedRelationship];
	
	[batchSizeField setIntValue:[relationship numberOfToManyFaultsToBatchFetch]];
	[optionalityMatrix selectCellWithTag:[relationship isMandatory] ? 1 : 0];
	[deleteRuleMatrix selectCellWithTag:[relationship deleteRule]];
	[ownsDestinationCheck setState:[relationship ownsDestination]];
	[propagatesPKCheck setState:[relationship propagatesPrimaryKey]];
}

- (void)setBatchSize:(id)sender
{
	[[self selectedRelationship] setNumberOfToManyFaultsToBatchFetch:[sender intValue]];
}

- (void)selectOptionality:(id)sender
{
	[[self selectedRelationship] setIsMandatory:[[sender selectedCell] tag]];
}

- (void)selectDeleteRule:(id)sender
{
	[[self selectedRelationship] setDeleteRule:[[sender selectedCell] tag]];
}

- (void)toggleOwnsDestination:(id)sender
{
	[[self selectedRelationship] setOwnsDestination:[[sender selectedCell] state]];
}

- (void)togglePropagatesPK:(id)sender
{
	[[self selectedRelationship] setPropagatesPrimaryKey:[[sender selectedCell] state]];
}

@end
