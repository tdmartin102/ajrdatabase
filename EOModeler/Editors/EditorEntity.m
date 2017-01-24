//
//  EditorEntity.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EditorEntity.h"

#import "Additions.h"
#import "Document.h"
#import "IconHeaderCell.h"
#import "NSTableView-ColumnVisibility.h"

#import "Additions.h"

#import <EOAccess/EOAccess.h>
//#import <EOControl/NSArray+CocoaDevUsersAdditions.h>

// Need to access some private relationship API
@interface EORelationship (Private)

- (void)_setDestinationEntity:(EOEntity *)anEntity;

@end

@interface EOJoin (Private)

- (void)_setSourceAttribute:(EOAttribute *)attribute;
- (void)_setDestinationAttribute:(EOAttribute *)attribute;

@end


@implementation EditorEntity

+ (void)load { } 

+ (NSString *)name
{
	return @"Entity";
}

- (void)awakeFromNib
{
	[entityAttributesText setStringValue:@""];
	[entityAttributesTable setCanHideColumns:YES];
	[entityRelationshipsText setStringValue:@""];
	[entityRelationshipsTable setCanHideColumns:YES];
	[[[entityAttributesTable anyTableColumnWithIdentifier:@"primaryKey"] morphHeaderCellToClass:[IconHeaderCell class]] setImage:[NSImage imageNamed:@"keyTitle"]];
	[[[entityAttributesTable anyTableColumnWithIdentifier:@"classProperty"] morphHeaderCellToClass:[IconHeaderCell class]] setImage:[NSImage imageNamed:@"classTitle"]];
	[[[entityAttributesTable anyTableColumnWithIdentifier:@"lock"] morphHeaderCellToClass:[IconHeaderCell class]] setImage:[NSImage imageNamed:@"lockTitle"]];
	[[[entityAttributesTable anyTableColumnWithIdentifier:@"nullable"] morphHeaderCellToClass:[IconHeaderCell class]] setImage:[NSImage imageNamed:@"nullTitle"]];
    
	[[[entityRelationshipsTable anyTableColumnWithIdentifier:@"type"] morphHeaderCellToClass:[IconHeaderCell class]] setImage:[NSImage imageNamed:@"relationshipTitle"]];
    [[[entityRelationshipsTable anyTableColumnWithIdentifier:@"classProperty"] morphHeaderCellToClass:[IconHeaderCell class]] setImage:[NSImage imageNamed:@"classTitle"]];
	needsToSetExternalTypes = YES;
	needsToSetValueClasses = YES;
}

- (EOJoin *)firstJoinInRelationship:(EORelationship *)relationship create:(BOOL)flag
{
	NSArray		*joins = [relationship joins];
	EOJoin		*join;
	
	if ([joins count]) {
		return [joins objectAtIndex:0];
	}
	
	join = [[EOJoin alloc] initWithSourceAttribute:nil destinationAttribute:nil];
	[relationship addJoin:join];

	if ([[relationship joins] count] == 1 && [[relationship name] hasPrefix:@"relationship"]) {
		if ([relationship isToMany]) {
			[relationship setName:[[[relationship destinationEntity] externalName] stringByAppendingString:@"s"]];
		} else {
			[relationship setName:[[relationship destinationEntity] externalName]];
		}
		[relationship beautifyName];
	}
	
	return join;
}

- (void)setSourceAttribute:(EOAttribute *)attribute forJoin:(EOJoin *)join
{
	[[[[self model] undoManager] prepareWithInvocationTarget:self] setSourceAttribute:[join sourceAttribute] forJoin:join];
	[join _setSourceAttribute:attribute];
}

- (void)setDestinationAttribute:(EOAttribute *)attribute forJoin:(EOJoin *)join
{
	[[[[self model] undoManager] prepareWithInvocationTarget:self] setDestinationAttribute:[join destinationAttribute] forJoin:join];
	[join _setDestinationAttribute:attribute];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == entityAttributesTable) {
		return [[[self selectedEntity] attributes] count];
	} else if (aTableView == entityRelationshipsTable) {
		return [[[self selectedEntity] relationships] count];
	}
	
	return 0;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
	if (aTableView == entityAttributesTable) {
		NSString		*ident = [aTableColumn identifier];
		EOAttribute	*attribute = [[[self selectedEntity] attributes] objectAtIndex:rowIndex];
		
		if ([ident isEqualToString:@"primaryKey"]) {
			[aCell setState:[[[self selectedEntity] primaryKeyAttributes] containsObject:attribute]];
		} else if ([ident isEqualToString:@"classProperty"]) {
			[aCell setState:[[[self selectedEntity] classProperties] containsObject:attribute]];
		} else if ([ident isEqualToString:@"lock"]) {
			[aCell setState:[[[self selectedEntity] attributesUsedForLocking] containsObject:attribute]];
		} else if ([ident isEqualToString:@"nullable"]) {
			[aCell setState:[attribute allowsNull]];
			[aCell setEnabled:![[[self selectedEntity] primaryKeyAttributes] containsObject:attribute]];
		} else if ([ident isEqualToString:@"externalType"]) {
			if (needsToSetExternalTypes) {
				NSArray		*types;
				
				[aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
				[aCell removeAllItems];
				types = [[[document adaptorClass] externalTypesWithModel:[document model]] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
				[aCell addItemsWithObjectValues:types];
				
				needsToSetExternalTypes = NO;
			}
		} else if ([ident isEqualToString:@"valueClass"]) {
			if (needsToSetValueClasses) {
				NSArray		*types = [NSArray arrayWithObjects:@"NSString", @"NSDate", @"NSData", @"NSNumber", @"NSDecimalNumber", nil];
				
				types = [types sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
				[aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
				[aCell removeAllItems];
				[aCell addItemsWithObjectValues:types];
				
				needsToSetValueClasses = NO;
			}
		}
	} else if (aTableView == entityRelationshipsTable) {
		NSString			*ident = [aTableColumn identifier];
		EORelationship	*relationship = [[[self selectedEntity] relationships] objectAtIndex:rowIndex];

		if ([ident isEqualToString:@"type"]) {
			[aCell setState:[relationship isToMany] ? NSOnState : NSOffState];
		}

		else if ([ident isEqualToString:@"classProperty"]) {
			[aCell setState:[[[self selectedEntity] classProperties] containsObject:relationship]];
		}
    
        // Im not doing combo boxes for now
        /*
        else if ([ident isEqualToString:@"destinationEntity"]) {
			[aCell removeAllItems];
			[aCell addItemWithObjectValue:@""];
			[aCell addItemsWithObjectValues:[[self model] entityNames]];
			[aCell setStringValue:[[relationship destinationEntity] name]];
		}
         */
        /*
        else if ([ident isEqualToString:@"sourceAttribute"]) {
			NSArray		*joins = [relationship joins];
			[aCell removeAllItems];
			[aCell addItemWithObjectValue:@""];
			[aCell addItemsWithObjectValues:[[[self selectedEntity] attributes] valueForKey:@"name"]];
			if ([joins count]) {
				[aCell setStringValue:[[[joins objectAtIndex:0] sourceAttribute] name]];
			} else {
				[aCell setStringValue:@""];
			}
		}
         */
        /*
        else if ([ident isEqualToString:@"destinationAttribute"]) {
			EOEntity		*destinationEntity = [relationship destinationEntity];
			NSArray		*joins = [relationship joins];
			
			[aCell removeAllItems];
			[aCell addItemWithObjectValue:@""];
			[aCell addItemsWithObjectValues:[[destinationEntity attributes] valueForKey:@"name"]];
			if ([joins count]) {
				[aCell setStringValue:[[[joins objectAtIndex:0] destinationAttribute] name]];
			} else {
				[aCell setStringValue:@""];
			}
		}
         */
		if ([relationship definition]) {
			[aCell setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
		} else {
			[aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
		}
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == entityAttributesTable) {
		NSString		*ident = [aTableColumn identifier];
		EOAttribute	*attribute = [[[self selectedEntity] attributes] objectAtIndex:rowIndex];
		
		if ([ident isEqualToString:@"name"]) {
			return [attribute name];
		} else if ([ident isEqualToString:@"columnName"]) {
			return [attribute columnName];
		} else if ([ident isEqualToString:@"valueClass"]) {
			return [attribute valueClassName];
		} else if ([ident isEqualToString:@"externalType"]) {
			return [attribute externalType];
		} else if ([ident isEqualToString:@"width"]) {
			return [NSNumber numberWithInt:[attribute width]];
		} else if ([ident isEqualToString:@"scale"]) {
			return [NSNumber numberWithInt:[attribute scale]];
		} else if ([ident isEqualToString:@"precision"]) {
			return [NSNumber numberWithInt:[attribute precision]];
		} else if ([ident isEqualToString:@"valueType"]) {
			return [attribute valueType];
		} else if ([ident isEqualToString:@"definition"]) {
			return [attribute definition];
		} else if ([ident isEqualToString:@"prototype"]) {
			return @"Not Supported";
		} else if ([ident isEqualToString:@"readFormat"]) {
			return [attribute readFormat];
		} else if ([ident isEqualToString:@"writeFormat"]) {
			return [attribute writeFormat];
		}
	} else if (aTableView == entityRelationshipsTable) {
		NSString			*ident = [aTableColumn identifier];
		EORelationship	*relationship = [[[self selectedEntity] relationships] objectAtIndex:rowIndex];
		
		if ([ident isEqualToString:@"name"]) {
			return [relationship name];
		} else if ([ident isEqualToString:@"definition"]) {
			return [relationship definition];
		} else if ([ident isEqualToString:@"destinationEntity"]) {
            return [[relationship destinationEntity] name];
        } else if ([ident isEqualToString:@"sourceAttribute"]) {
             NSArray		*joins = [relationship joins];
             if ([joins count]) {
                 return [[[joins objectAtIndex:0] sourceAttribute] name];
             }
         } else if ([ident isEqualToString:@"destinationAttribute"]) {
             NSArray		*joins = [relationship joins];
             if ([joins count]) {
                 return [[[joins objectAtIndex:0] destinationAttribute] name];
             }
         }
	}
	
	return @"";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == entityAttributesTable) {
		NSString		*ident = [aTableColumn identifier];
		EOAttribute	*attribute = [[[self selectedEntity] attributes] objectAtIndex:rowIndex];
		
		if ([ident isEqualToString:@"name"]) {
			[attribute setName:anObject];
		} else if ([ident isEqualToString:@"columnName"]) {
			[attribute setColumnName:anObject];
		} else if ([ident isEqualToString:@"valueClass"]) {
			[attribute setValueClassName:anObject];
		} else if ([ident isEqualToString:@"externalType"]) {
			[attribute setExternalType:anObject];
		} else if ([ident isEqualToString:@"width"]) {
			[attribute setWidth:[anObject unsignedIntValue]];
		} else if ([ident isEqualToString:@"scale"]) {
			[attribute setScale:[anObject unsignedIntValue]];
		} else if ([ident isEqualToString:@"precision"]) {
			[attribute setPrecision:[anObject unsignedIntValue]];
		} else if ([ident isEqualToString:@"valueType"]) {
			[attribute setValueType:anObject];
		} else if ([ident isEqualToString:@"definition"]) {
			[attribute setDefinition:anObject];
		} else if ([ident isEqualToString:@"prototype"]) {
		} else if ([ident isEqualToString:@"readFormat"]) {
			[attribute setReadFormat:anObject];
		} else if ([ident isEqualToString:@"writeFormat"]) {
			[attribute setWriteFormat:anObject];
		} else if ([ident isEqualToString:@"primaryKey"]) {
			NSMutableArray		*array = [[[self selectedEntity] primaryKeyAttributes] mutableCopy];
			if ([anObject intValue]) {
				[array addObject:attribute];
				if ([attribute allowsNull]) {
					[attribute setAllowsNull:NO];
				}
			} else {
				[array removeObject:attribute];
			}
			[[self selectedEntity] setPrimaryKeyAttributes:array];
		} else if ([ident isEqualToString:@"classProperty"]) {
			NSMutableArray		*array = [[[self selectedEntity] classProperties] mutableCopy];
			if ([anObject intValue]) {
				[array addObject:attribute];
			} else {
				[array removeObject:attribute];
			}
			[[self selectedEntity] setClassProperties:array];
		} else if ([ident isEqualToString:@"lock"]) {
			NSMutableArray		*array = [[[self selectedEntity] attributesUsedForLocking] mutableCopy];
			if ([anObject intValue]) {
				[array addObject:attribute];
			} else {
				[array removeObject:attribute];
			}
			[[self selectedEntity] setAttributesUsedForLocking:array];
		} else if ([ident isEqualToString:@"nullable"]) {
			[attribute setAllowsNull:[anObject intValue] == 0 ? NO : YES];
		}
	} else if (aTableView == entityRelationshipsTable) {
		NSString			*ident = [aTableColumn identifier];
		EORelationship	*relationship = [[[self selectedEntity] relationships] objectAtIndex:rowIndex];
		
		if ([ident isEqualToString:@"name"]) {
			[relationship setName:anObject];
		} else if ([ident isEqualToString:@"type"]) {
			[relationship setToMany:[anObject boolValue]];;
		} else if ([ident isEqualToString:@"classProperty"]) {
			NSMutableArray		*array = [[[self selectedEntity] classProperties] mutableCopy];
			if ([anObject intValue]) {
				[array addObject:relationship];
			} else {
				[array removeObject:relationship];
			}
			[[self selectedEntity] setClassProperties:array];
		} else if ([ident isEqualToString:@"destinationEntity"]) {
			EOEntity		*destinationEntity = [[EOModelGroup defaultModelGroup] entityNamed:anObject];
			
			if (destinationEntity) {
				[relationship _setDestinationEntity:destinationEntity];
			} else {
				NSBeep();
				[relationship _setDestinationEntity:nil];
			}
		} else if ([ident isEqualToString:@"sourceAttribute"]) {
			EOJoin		*join = [self firstJoinInRelationship:relationship create:YES];
			EOEntity		*entity = [self selectedEntity];
			EOAttribute	*attribute = [entity attributeNamed:anObject];
			
			[[[[self model] undoManager] prepareWithInvocationTarget:self] setSourceAttribute:[join sourceAttribute] forJoin:join];
			if (attribute) {
				[join _setSourceAttribute:attribute];
			} else {
				NSBeep();
				[join _setSourceAttribute:nil];
			}
		} else if ([ident isEqualToString:@"destinationAttribute"]) {
			EOJoin		*join = [self firstJoinInRelationship:relationship create:YES];
			EOEntity		*entity = [relationship destinationEntity];
			EOAttribute	*attribute = [entity attributeNamed:anObject];
			
			[[[[self model] undoManager] prepareWithInvocationTarget:self] setDestinationAttribute:[join destinationAttribute] forJoin:join];
			if (attribute) {
				[join _setDestinationAttribute:attribute];
			} else {
				NSBeep();
				[join _setDestinationAttribute:nil];
			}
		} else if ([ident isEqualToString:@"definition"]) {
			[relationship setDefinition:anObject];
		}
	}
}

- (EORelationship *)relationshipForJoin:(EOJoin *)join
{
	NSArray		*relationships = [[self selectedEntity] relationships];
	int			x;
	
	for (x = 0; x < (const int)[relationships count]; x++) {
		if ([[[relationships objectAtIndex:x] joins] containsObject:join]) {
			return [relationships objectAtIndex:x];
		}
	}
	
	return nil;
}

- (void)updateAttributeSelection
{
	if ([[document selectedObject] isKindOfClass:[EOAttribute class]] && [document selectedEntity]) {
		NSUInteger		count = [[entityAttributesTable selectedRowIndexes] count];
		if (count == 0) {
			// Let's see if we can defer to an attribute selection
			count = [[entityRelationshipsTable selectedRowIndexes] count];
			if (count == 0) {
				// No selection there, so select my entity
				[document setSelectedObject:[document selectedEntity]];
			} else {
				// Yep, there's a attribute selection, so forward it along
				[self selectRelationship:entityRelationshipsTable];
				// If we were the focused table, then go a head and focus the attribute table
				if ([[entityAttributesTable window] firstResponder] == entityAttributesTable) {
					[[entityAttributesTable window] makeFirstResponder:entityRelationshipsTable];
				}
			}
		} else if (count == 1) {
			EOAttribute		*selectedAttribute;
			
			selectedAttribute = [[[document selectedEntity] attributes] objectAtIndex:[entityAttributesTable selectedRow]];
			if (selectedAttribute != [document selectedObject] && 
				 [[entityAttributesTable window] firstResponder] == entityAttributesTable) {
				[document setSelectedObject:selectedAttribute];
			}
		}
	}
}

- (void)updateRelationshipSelection
{
	if ([[document selectedObject] isKindOfClass:[EORelationship class]]) {
		NSInteger		count = [[entityRelationshipsTable selectedRowIndexes] count];
		if (count == 0) {
			// Let's see if we can defer to an attribute selection
			count = [[entityAttributesTable selectedRowIndexes] count];
			if (count == 0) {
				// No selection there, so select my entity
				[document setSelectedObject:[document selectedEntity]];
			} else {
				// Yep, there's a attribute selection, so forward it along
				[self selectAttribute:entityAttributesTable];
				// If we were the focused table, then go a head and focus the attribute table
				if ([[entityRelationshipsTable window] firstResponder] == entityRelationshipsTable) {
					[[entityRelationshipsTable window] makeFirstResponder:entityAttributesTable];
				}
			}
		} else if (count == 1) {
			EORelationship		*selectedRelationship;
			
			selectedRelationship = [[[document selectedEntity] relationships] objectAtIndex:[entityRelationshipsTable selectedRow]];
			if (selectedRelationship != [document selectedObject] && 
				 [[entityRelationshipsTable window] firstResponder] == entityRelationshipsTable) {
				[document setSelectedObject:selectedRelationship];
			}
		}
	}
}

- (void)updateAttribute:(EOAttribute *)attribute
{
	EOEntity		*entity = [attribute entity];
	NSUInteger      index = [[entity attributes] indexOfObjectIdenticalTo:attribute];
		
	if (index != NSNotFound) {
		if (attribute == editingObject) {
			NSInteger		editedColumn;
			
			// We had a name change, or at least a sorting change, so we need to re-display the whole table.
			[entityAttributesTable setNeedsDisplay:YES];
			editedColumn = [entityAttributesTable editedColumn];
			[entityAttributesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                    byExtendingSelection:NO];
			if (editedColumn >= 0) {
				[entityAttributesTable editColumn:editedColumn row:index withEvent:nil select:YES];
			}
		} else {
			[entityAttributesTable setNeedsDisplayInRect:[entityAttributesTable rectOfRow:index]];
		}
	}
	
	[self updateAttributeSelection];
}

- (void)updateRelationship:(EORelationship *)relationship
{
	EOEntity			*entity = [relationship entity];
	NSUInteger	index = [[entity relationships] indexOfObjectIdenticalTo:relationship];
	
	if (index != NSNotFound) {
		if (relationship == editingObject) {
			NSInteger		editedColumn;
			
			// We had a name change, or at least a sorting change, so we need to re-display the whole table.
			[entityRelationshipsTable setNeedsDisplay:YES];
			editedColumn = [entityRelationshipsTable editedColumn];
			[entityRelationshipsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                                  byExtendingSelection:NO];
			if (editedColumn >= 0) {
				[entityRelationshipsTable editColumn:editedColumn row:index withEvent:nil select:YES];
			}
		} else {
			[entityRelationshipsTable setNeedsDisplayInRect:[entityRelationshipsTable rectOfRow:index]];
		}
	}
	
	[self updateAttributeSelection];
}

- (void)updateDisplayForEntity:(EOEntity *)entity
{
	[entityAttributesTable reloadData];
	[entityRelationshipsTable reloadData];

	// Make sure the selection in the inspector is kosher
	[self updateAttributeSelection];
	[self updateRelationshipSelection];
}

- (void)objectWillChange:(id)object
{
	if ([object isKindOfClass:[EOAttribute class]]) {
		NSInteger		index = [[(EOEntity *)[object entity] attributes] indexOfObjectIdenticalTo:object];
		
		if (index != NSNotFound) {
			if (index == [entityAttributesTable editedRow]) {
				editingObject = object;
			}
			[entityAttributesTable setNeedsDisplayInRect:[entityAttributesTable rectOfRow:index]];
		}
	} else if ([object isKindOfClass:[EORelationship class]]) {
		NSInteger		index = [[(EOEntity *)[object entity] relationships] indexOfObjectIdenticalTo:object];
		
		if (index != NSNotFound) {
			if (index == [entityRelationshipsTable editedRow]) {
				editingObject = object;
			}
			[entityRelationshipsTable setNeedsDisplayInRect:[entityRelationshipsTable rectOfRow:index]];
		}
	}
}

- (void)objectDidChange:(id)object
{
	if ([object isKindOfClass:[EOAttribute class]]) {
		[self updateAttribute:object];
	} else if ([object isKindOfClass:[EORelationship class]]) {
		[self updateRelationship:object];
	} else if ([object isKindOfClass:[EOJoin class]]) {
		EORelationship	*relationship = [self relationshipForJoin:object];
		if (relationship) {
			[object updateRelationship:object];
		}
	} else if ([object isKindOfClass:[EOEntity class]]) {
		[self updateDisplayForEntity:object];
	}
}

- (void)update
{
	//AJRPrintf(@"Selected: %@\n", [self selectedEntity]);
	[entityAttributesText setStringValue:[NSString stringWithFormat:@"%@ Attributes", [[self selectedEntity] name]]];
	[entityRelationshipsText setStringValue:[NSString stringWithFormat:@"%@ Relationships", [[self selectedEntity] name]]];
	
	[entityAttributesTable reloadData];
	[entityRelationshipsTable reloadData];
}

- (void)editAttribute:(EOAttribute *)attribute
{
	NSInteger		index = [[[self selectedEntity] attributes] indexOfObjectIdenticalTo:attribute];
	NSTableColumn	*column;
	NSInteger		columnIndex;
	
	// mont_rothstein @ yahoo.com 2005-04-17
	// This was checking for index >= 0 it needs to be NSNotFound.
	if (index >= NSNotFound) {
		[entityAttributesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                byExtendingSelection:NO];
		[[entityAttributesTable window] makeFirstResponder:entityAttributesTable];
		column = [entityAttributesTable tableColumnWithIdentifier:@"name"];
		if (column) {
			columnIndex = [[entityAttributesTable tableColumns] indexOfObjectIdenticalTo:column];
			if (columnIndex != NSNotFound) {
				[entityAttributesTable editColumn:columnIndex row:index withEvent:nil select:YES];
			}
		}
		[document setSelectedObject:attribute];
	}
}

- (void)editRelationship:(EORelationship *)relationship
{
	NSInteger		index = [[[self selectedEntity] relationships] indexOfObjectIdenticalTo:relationship];
	//NSTableColumn	*column;
	//int				columnIndex;
	
	// mont_rothstein @ yahoo.com 2005-04-17
	// This was checking for index >= 0 it needs to be NSNotFound.
	if (index >= NSNotFound) {
		[entityRelationshipsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                byExtendingSelection:NO];
		[[entityRelationshipsTable window] makeFirstResponder:entityRelationshipsTable];
		[entityRelationshipsTable scrollRowToVisible:index];
#if 0
		column = [entityRelationshipsTable tableColumnWithIdentifier:@"destinationEntity"];
		if (column) {
			columnIndex = [[entityRelationshipsTable tableColumns] indexOfObjectIdenticalTo:column];
			if (columnIndex != NSNotFound) {
				[entityRelationshipsTable editColumn:columnIndex row:index withEvent:nil select:YES];
			}
		}
#endif
		[document setSelectedObject:relationship];
	}
}

- (void)selectAttribute:(id)sender
{
	NSInteger		row = [sender selectedRow];
	
	editingObject = nil;
	
	if ([[sender selectedRowIndexes] count] <= 1) {
		if (row == -1) {
			row = [entityRelationshipsTable selectedRow];
			if (row == -1) {
				[document setSelectedObject:[self selectedEntity]];
			} else {
				[document setSelectedObject:[[[self selectedEntity] relationships] objectAtIndex:row]];
			}
		} else {
			[document setSelectedObject:[[[self selectedEntity] attributes] objectAtIndex:row]];
		}
	} else {
		NSMutableArray		*selectedAttributes = [[NSMutableArray alloc] init];
		NSIndexSet          *indexSet = [entityAttributesTable selectedRowIndexes];
		NSArray				*attributes = [[self selectedEntity] attributes];
		
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
            [selectedAttributes addObject:[attributes objectAtIndex:idx]];}];
		
		[document setSelectedObject:selectedAttributes];
	}
}

- (void)selectRelationship:(id)sender
{
	NSInteger		row = [sender selectedRow];
	
	editingObject = nil;
	
	if (row == -1) {
		row = [entityAttributesTable selectedRow];
		if (row == -1) {
			[document setSelectedObject:[self selectedEntity]];
		} else {
			[document setSelectedObject:[[[self selectedEntity] attributes] objectAtIndex:row]];
		}
	} else {
		[document setSelectedObject:[[[self selectedEntity] relationships] objectAtIndex:row]];
	}
}

- (void)deleteAttribute:(EOAttribute *)attribute
{
	EOEntity		*entity = [document selectedEntity];
	
	if (entity) {
		[entity removeAttribute:attribute];
	}
}

- (void)deleteRelationship:(EORelationship *)relationship
{
	EOEntity		*entity = [document selectedEntity];
	
	if (entity) {
		[entity removeRelationship:relationship];
	}
}

- (void)deleteEntity:(EOEntity *)entity
{
	EOModel *model = [entity model];
	
	// 2005-05-11 AJR Only remove the entity if it's contained in the model.
	if ([model entityNamed:[entity name]]) {
		[[entity model] removeEntity:entity];
	}
}

- (void)deleteSelection:(id)sender
{
	NSArray	*selection = [document selectedObject];
	int		x;
	
	if (![selection isKindOfClass:[NSArray class]]) {
		selection = [NSArray arrayWithObject:selection];
	}
	
	for (x = 0; x < (const int)[selection count]; x++) {
		id		selected = [selection objectAtIndex:x];

		if ([selected isKindOfClass:[EOAttribute class]]) {
			[self deleteAttribute:selected];
		} else if ([selected isKindOfClass:[EORelationship class]]) {
			[self deleteRelationship:selected];
		} else if ([selected isKindOfClass:[EOEntity class]]) {
			[self deleteEntity:selected];
		}
	}
}

@end
