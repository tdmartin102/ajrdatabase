//
//  EORelationshipPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EORelationshipPane.h"
#import "Additions.h"

#import <EOAccess/EOAccess.h>

// Need to access some private relationship API
@interface EORelationship (Private)

- (void)_setDestinationEntity:(EOEntity *)anEntity;

@end

@interface EOJoin (Private)

- (void)_setSourceAttribute:(EOAttribute *)attribute;
- (void)_setDestinationAttribute:(EOAttribute *)attribute;

@end


@implementation EORelationshipPane
{
    NSArray *entities;
}

- (NSString *)name
{
	return @"General";
}

- (EORelationship *)selectedRelationship
{
	id		selectedObject = [self selectedObject];
	
	if ([selectedObject isKindOfClass:[EORelationship class]]) return selectedObject;
	
	return nil;
}

- (EOEntity *)sourceEntity
{
	return [[self selectedRelationship] entity];
}

- (EOEntity *)destinationEntity
{
	return [[self selectedRelationship] destinationEntity];
}

- (EOEntity *)selectedDestinationEntity
{
	NSInteger				row = [entitiesTable selectedRow];
	
	if (row < 0) return nil;
    
    return (EOEntity *)[entities objectAtIndex:row];
}

- (NSUInteger)indexOfJoinForSourceAttribute:(EOAttribute *)attribute
{
	EORelationship		*relationship = [self selectedRelationship];
	NSArray				*joins;
	int					x;
	
	joins = [relationship joins];
	for (x = 0; x < (const int)[joins count]; x++) {
		EOJoin	*join = [joins objectAtIndex:x];
		if ([join sourceAttribute] == attribute) return x;
	}
	
	return NSNotFound;
}

- (NSUInteger)indexOfJoinForDestinationAttribute:(EOAttribute *)attribute
{
	EORelationship		*relationship = [self selectedRelationship];
	NSArray				*joins;
	int					x;
	
	joins = [relationship joins];
	for (x = 0; x < (const int)[joins count]; x++) {
		EOJoin	*join = [joins objectAtIndex:x];
		if ([join destinationAttribute] == attribute) return x;
	}
	
	return NSNotFound;
}

- (void)updateConnectButton
{
	NSInteger	sIndex = [sourceTable selectedRow];
	NSInteger	dIndex = [destinationTable selectedRow];
	NSInteger	jIndex;
	EOJoin		*join;
	EOAttribute	*sourceAttribute = nil;
	EOAttribute	*destinationAttribute = nil;
	
	// The easiest case is we have non-existent selection in either the source or destination column
	if (sIndex < 0 || dIndex < 0) {
		[connectButton setTitle:@"Connect"];
		[connectButton setEnabled:NO];
		return;
	}
	
	if (sIndex >= 0) {
		sourceAttribute = [[[self sourceEntity] attributes] objectAtIndex:sIndex];
	}
	if (dIndex >= 0) {
		destinationAttribute = [[[self destinationEntity] attributes] objectAtIndex:dIndex];
	}
	
	// Let's see if our source represents the selection of a join.
	jIndex = [self indexOfJoinForSourceAttribute:sourceAttribute];
	if (jIndex != NSNotFound) {
		// Get the appropriate join
		join = [[[self selectedRelationship] joins] objectAtIndex:jIndex];
		// If we have the join's destination select, advertise disconnect.
		if ([join destinationAttribute] == destinationAttribute) {
			[connectButton setTitle:@"Disconnect"];
		} else {
			[connectButton setTitle:@"Connect"];
		}
		[connectButton setEnabled:YES];
	} else {
		// We don't have a current join selected, so let the user know we can make a new connection.
		[connectButton setTitle:@"Connect"];
		[connectButton setEnabled:YES];
	}
}

- (void)updateWithSelectedObject:(id)value
{
	EORelationship		*relationship = nil;
	int					x, selectedIndex = 0;
	NSArray				*models;
	NSArray				*joins;
	EOJoin				*firstJoin = nil;
    NSIndexSet          *indexSet;
    NSArray             *anArray;
    EOModel             *model;
    
    if (value ) {
        if ([value isKindOfClass:[EORelationship class]])
            relationship = value;
    }
    if (! relationship)
        relationship = [self selectedRelationship];
	
    currentObject = relationship;
	[nameField setStringValue:[relationship name]];

	if ([relationship definition]) {
		[tabView selectTabViewItemWithIdentifier:@"flattenedRelationship"];
		[entityField setStringValue:[[relationship destinationEntity] name]];
		[definitionField setStringValue:[relationship definition]];
        entities = [NSArray array];
	} else {
		[tabView selectTabViewItemWithIdentifier:@"relationship"];
		[modelsPopUp removeAllItems];
		models = [[EOModelGroup defaultModelGroup] models];
		for (x = 0; x < (const int)[models count]; x++) {
			model = [models objectAtIndex:x];
			
			[modelsPopUp addItemWithTitle:[model name]];
			[[[modelsPopUp itemArray] lastObject] setRepresentedObject:model];
			if (model == [[relationship destinationEntity] model]) {
				selectedIndex = x;
			}
		}
		[modelsPopUp setEnabled:[[modelsPopUp itemArray] count] != 1];
		[modelsPopUp selectItemAtIndex:selectedIndex];
		
		[toOneMatrix selectCellWithTag:[relationship isToMany] ? 1 : 0];
		[joinTypePopUp selectItemAtIndex:[relationship joinSemantic]];
        
        model = (EOModel *)[[modelsPopUp selectedItem] representedObject];
		entities = [[model entities] sortedArrayUsingComparator:^NSComparisonResult(EOEntity *obj1, EOEntity *obj2) {
            return [[obj1 name] compare:[obj2 name]];
        }];
		[entitiesTable reloadData];
		if ([self destinationEntity] == nil) {
			[entitiesTable deselectAll:self];
		} else {
            indexSet = [NSIndexSet indexSetWithIndex:[entities indexOfObjectIdenticalTo:[self destinationEntity]]];
			[entitiesTable selectRowIndexes:indexSet byExtendingSelection:NO];
		}
		[entitiesTable scrollRowToVisible:[entitiesTable selectedRow]];
		
		joins = [relationship joins];
		if ([joins count]) firstJoin = [joins objectAtIndex:0];
		
		[sourceTable reloadData];
		if (firstJoin) {
            anArray = [[self sourceEntity] attributes];
            indexSet = [NSIndexSet indexSetWithIndex:
                        [anArray indexOfObjectIdenticalTo:[firstJoin sourceAttribute]]];
			[sourceTable selectRowIndexes:indexSet byExtendingSelection:NO];
			[sourceTable scrollRowToVisible:[sourceTable selectedRow]];
		} else {
			[sourceTable deselectAll:self];
		}
		
		[destinationTable reloadData];
		if (firstJoin) {
            anArray = [[self destinationEntity] attributes];
            indexSet = [NSIndexSet indexSetWithIndex:
                        [anArray indexOfObjectIdenticalTo:[firstJoin destinationAttribute]]];
			[destinationTable selectRowIndexes:indexSet byExtendingSelection:NO];
			[destinationTable scrollRowToVisible:[destinationTable selectedRow]];
		} else {
			[destinationTable deselectAll:self];
		}
		
		[self updateConnectButton];
	}
}

- (void)setName:(id)sender
{
	[[self selectedRelationship] setName:[sender stringValue]];
}

- (void)selectModel:(id)sender
{
    EOModel *model = (EOModel *)[[modelsPopUp selectedItem] representedObject];
    entities = [[model entities] sortedArrayUsingComparator:^NSComparisonResult(EOEntity *obj1, EOEntity *obj2) {
        return [[obj1 name] compare:[obj2 name]];
    }];

	[entitiesTable reloadData];
}

- (void)selectToOne:(id)sender
{
	[[self selectedRelationship] setToMany:[[sender selectedCell] tag]];
}

- (void)selectJoinType:(id)sender
{
	[[self selectedRelationship] setJoinSemantic:(EOJoinSemantic)[[sender selectedItem] tag]];
}

- (void)selectDestinationEntity:(id)sender
{
	EORelationship	*relationship = [self selectedRelationship];
	EOEntity			*destinationEntity = [self selectedDestinationEntity];
	
	if ([relationship destinationEntity] == destinationEntity) {
		// Don't have to do anything.
		return;
	}
	
	// Otherwise, set the new destination
	[relationship _setDestinationEntity:destinationEntity];
}

- (void)selectSourceAttribute:(id)sender
{
	[self updateConnectButton];
}

- (void)selectDestinationAttribute:(id)sender
{
	[self updateConnectButton];
}

- (void)setSourceAttribute:(EOAttribute *)attribute forJoin:(EOJoin *)join
{
	[[[[[[self selectedRelationship] entity] model] undoManager] prepareWithInvocationTarget:self] setSourceAttribute:[join sourceAttribute] forJoin:join];
	[join _setSourceAttribute:attribute];
}

- (void)setDestinationAttribute:(EOAttribute *)attribute forJoin:(EOJoin *)join
{
	[[[[[[self selectedRelationship] entity] model] undoManager] prepareWithInvocationTarget:self] setDestinationAttribute:[join destinationAttribute] forJoin:join];
	[join _setDestinationAttribute:attribute];
}

- (void)toggleJoin:(id)sender
{
	EORelationship	*relationship = [self selectedRelationship];
	NSInteger		sIndex = [sourceTable selectedRow];
	NSInteger		dIndex = [destinationTable selectedRow];
	NSArray			*joins = [relationship joins];
	EOJoin			*sJoin = nil;
	EOJoin			*dJoin = nil;
	EOAttribute		*sourceAttribute = nil;
	EOAttribute		*destinationAttribute = nil;
	
	sourceAttribute = [[[self sourceEntity] attributes] objectAtIndex:sIndex];
	destinationAttribute = [[[self destinationEntity] attributes] objectAtIndex:dIndex];
	
	// Let's see if our source represents the selection of a join.
	sIndex = [self indexOfJoinForSourceAttribute:sourceAttribute];
	dIndex = [self indexOfJoinForDestinationAttribute:destinationAttribute];
	if (sIndex != NSNotFound) sJoin = [joins objectAtIndex:sIndex];
	if (dIndex != NSNotFound) dJoin = [joins objectAtIndex:dIndex];
	
	AJRPrintf(@"sourceAttribute: %@, destinationAttribute: %@, sIndex: %d, dIndex: %d, sJoin: %@, dJoin: %@\n", sourceAttribute, destinationAttribute, sIndex, dIndex, sJoin, dJoin);
	
	// No join for either source or destination attributes, so create a new one.
	if (!sJoin && !dJoin) {
		sJoin = [[EOJoin alloc] initWithSourceAttribute:sourceAttribute destinationAttribute:destinationAttribute];
		AJRPrintf(@"adding: %@\n", sJoin);
		[relationship addJoin:sJoin];
		AJRPrintf(@"joins: %@\n", [relationship joins]);
		// Check and see if we should change the name...
		if ([[relationship joins] count] == 1 && [[relationship name] hasPrefix:@"relationship"]) {
			if ([relationship isToMany]) {
				[relationship setName:[[[relationship destinationEntity] externalName] stringByAppendingString:@"s"]];
			} else {
				[relationship setName:[[relationship destinationEntity] externalName]];
			}
			[relationship beautifyName];
		}
		return;
	}

	// The sJoin and dJoin are equal, then we're doing a disconnect
	if (sJoin == dJoin) {
		[relationship removeJoin:sJoin];
		return;
	}
	
	// See if we're updating the source join.
	if (sJoin && !dJoin) {
		[self setDestinationAttribute:destinationAttribute forJoin:sJoin];
		return;
	}
	
	// Or perhaps the destination attribute
	if (!sJoin && dJoin) {
		[self setSourceAttribute:sourceAttribute forJoin:dJoin];
		return;
	}
	
	// Or, both are set, so remove the destination join and update the source join.
	if (sJoin && dJoin) {
		[relationship removeJoin:dJoin];
		[self setDestinationAttribute:destinationAttribute forJoin:sJoin];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == entitiesTable) {
		return [entities count];
	} else if (aTableView == sourceTable) {
		return [[[self sourceEntity] attributes] count];
	} else if (aTableView == destinationTable) {
		return [[[self destinationEntity] attributes] count];
	}
	
	return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString		*ident = [aTableColumn identifier];
	
	if (aTableView == entitiesTable) {
		return [[entities objectAtIndex:rowIndex] name];
	} else if (aTableView == sourceTable) {
		EOAttribute		*attribute = [[[self sourceEntity] attributes] objectAtIndex:rowIndex];
		
		if ([ident isEqualToString:@"source"]) {
			return [attribute name];
		} else if ([ident isEqualToString:@"index"]) {
			NSInteger		index = [self indexOfJoinForSourceAttribute:attribute];
			if (index != NSNotFound) return [NSString stringWithFormat:@"%ld", index + 1];
			return @"";
		}
	} else if (aTableView == destinationTable) {
		EOAttribute		*attribute = [[[self destinationEntity] attributes] objectAtIndex:rowIndex];
		
		if ([ident isEqualToString:@"destination"]) {
			return [attribute name];
		} else if ([ident isEqualToString:@"index"]) {
			NSInteger		index = [self indexOfJoinForDestinationAttribute:attribute];
			if (index != NSNotFound) return [NSString stringWithFormat:@"%ld", index + 1];
			return @"";
		}
	}
	
	return @"?";
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	if (control == nameField) {
		return [[self selectedRelationship] validateName:[fieldEditor string]] == nil;
	}
	
	return YES;
}

@end
