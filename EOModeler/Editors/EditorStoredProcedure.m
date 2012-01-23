//
//  EditorStoredProcedure.m
//  AJRDatabase
//
//  Created by Alex Raftis on Sat Sep 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "EditorStoredProcedure.h"

#import "Document.h"
#import "IconHeaderCell.h"
#import "NSTableView-ColumnVisibility.h"

#import <EOAccess/EOAccess.h>

@implementation EditorStoredProcedure

+ (void)load { } 

+ (NSString *)name
{
	return @"Stored Procedure";
}

- (void)dealloc
{
	[editingObject release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[procedureTable setCanHideColumns:YES];

	needsToSetExternalTypes = YES;
	needsToSetValueClasses = YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[[self selectedStoredProcedure] arguments] count];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString		*ident = [aTableColumn identifier];
	EOAttribute	*argument = [[[self selectedStoredProcedure] arguments] objectAtIndex:rowIndex];
	
	if ([ident isEqualToString:@"direction"]) {
		if ([[aCell itemArray] count] != 4) {
			[aCell removeAllItems];
			[aCell addItemWithTitle:@"Void"];
			[aCell addItemWithTitle:@"In"];
			[aCell addItemWithTitle:@"Out"];
			[aCell addItemWithTitle:@"In/Out"];
		}
		[aCell selectItemAtIndex:[argument parameterDirection]];
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
			NSArray		*types = [NSArray arrayWithObjects:@"NSString", @"NSCalendarDate", @"NSData", @"NSNumber", @"NSDecimalNumber", nil];
			
			types = [types sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
			[aCell setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
			[aCell removeAllItems];
			[aCell addItemsWithObjectValues:types];
			
			needsToSetValueClasses = NO;
		}
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString		*ident = [aTableColumn identifier];
	EOAttribute	*argument = [[[self selectedStoredProcedure] arguments] objectAtIndex:rowIndex];
	
	if ([ident isEqualToString:@"name"]) {
		return [argument name];
	} else if ([ident isEqualToString:@"columnName"]) {
		return [argument columnName];
	} else if ([ident isEqualToString:@"valueClass"]) {
		return [argument valueClassName];
	} else if ([ident isEqualToString:@"externalType"]) {
		return [argument externalType];
	} else if ([ident isEqualToString:@"width"]) {
		return [NSNumber numberWithInt:[argument width]];
	} else if ([ident isEqualToString:@"scale"]) {
		return [NSNumber numberWithInt:[argument scale]];
	} else if ([ident isEqualToString:@"precision"]) {
		return [NSNumber numberWithInt:[argument precision]];
	} else if ([ident isEqualToString:@"valueType"]) {
		return [argument valueType];
	}
	
	return @"";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString		*ident = [aTableColumn identifier];
	EOAttribute	*argument = [[[self selectedStoredProcedure] arguments] objectAtIndex:rowIndex];
	
	if ([ident isEqualToString:@"name"]) {
		[argument setName:anObject];
	} else if ([ident isEqualToString:@"columnName"]) {
		[argument setColumnName:anObject];
	} else if ([ident isEqualToString:@"valueClass"]) {
		[argument setValueClassName:anObject];
	} else if ([ident isEqualToString:@"externalType"]) {
		[argument setExternalType:anObject];
	} else if ([ident isEqualToString:@"width"]) {
		[argument setWidth:[anObject unsignedIntValue]];
	} else if ([ident isEqualToString:@"scale"]) {
		[argument setScale:[anObject unsignedIntValue]];
	} else if ([ident isEqualToString:@"precision"]) {
		[argument setPrecision:[anObject unsignedIntValue]];
	} else if ([ident isEqualToString:@"valueType"]) {
		[argument setValueType:anObject];
	} else if ([ident isEqualToString:@"direction"]) {
		[argument setParameterDirection:[anObject intValue]];
	}
}

- (BOOL)tableViewShouldMoveRows:(NSTableView *)tableView
{
	return YES;
}

- (BOOL)tableView:(NSTableView *)tableView moveRowAtIndex:(unsigned)index toIndex:(unsigned)otherIndex;
{
	[[self selectedStoredProcedure] moveArgumentAtIndex:index toIndex:otherIndex];
	return YES;
}

- (void)updateDisplayForAttribute:(EOAttribute *)argument
{
	NSUInteger index = [[[self selectedStoredProcedure] arguments] indexOfObjectIdenticalTo:argument];
	if (index != NSNotFound) {
		[procedureTable setNeedsDisplayInRect:[procedureTable rectOfRow:index]];
	}
}

- (void)update
{
	[procedureTable reloadData];
}

- (void)selectedArgument:(id)sender
{
	int		row = [sender selectedRow];
	
	[editingObject release]; editingObject = nil;
	
	if (row < 0) {
		[document setSelectedObject:nil];
	} else {
		[document setSelectedObject:[[[self selectedStoredProcedure] arguments] objectAtIndex:row]];
	}
}

- (void)editArgument:(EOAttribute *)argument
{
	NSInteger		index = [[[self selectedStoredProcedure] arguments] indexOfObjectIdenticalTo:argument];
	NSTableColumn	*column;
	NSInteger		columnIndex;
	
	// mont_rothstein @ yahoo.com 2005-04-17
	// This was checking for index >= 0 it needs to be NSNotFound.
	if (index >= NSNotFound) {
		[procedureTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                    byExtendingSelection:NO];
		[[procedureTable window] makeFirstResponder:procedureTable];
		column = [procedureTable tableColumnWithIdentifier:@"name"];
		if (column) {
			columnIndex = [[procedureTable tableColumns] indexOfObjectIdenticalTo:column];
			if (columnIndex != NSNotFound) {
				[procedureTable editColumn:columnIndex row:index withEvent:nil select:YES];
			}
		}
		[document setSelectedObject:argument];
	}
}

- (void)updateArgumentSelection
{
	if ([[document selectedObject] isKindOfClass:[EOAttribute class]]) {
		int		count = [[procedureTable selectedRowIndexes] count];
		if (count == 0) {
			[document setSelectedObject:[document selectedStoredProcedure]];
		} else if (count == 1) {
			EOAttribute		*selectedArgument;
			
			selectedArgument = [[[document selectedStoredProcedure] arguments] objectAtIndex:[procedureTable selectedRow]];
			if (selectedArgument != [document selectedObject] && 
				 [[procedureTable window] firstResponder] == procedureTable) {
				[document setSelectedObject:selectedArgument];
			}
		}
	}
}

- (void)updateArgument:(EOAttribute *)argument
{
	EOStoredProcedure	*procedure = [self selectedStoredProcedure];
	
	if (procedure) {
		NSUInteger index = [[procedure arguments] indexOfObjectIdenticalTo:procedure];
		
		if (index != NSNotFound) {
			if (argument == editingObject) {
				NSInteger	editedColumn;
				
				// We had a name change, or at least a sorting change, so we need to re-display the whole table.
				[procedureTable setNeedsDisplay:YES];
				editedColumn = [procedureTable editedColumn];
				[procedureTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
				if (editedColumn >= 0) {
					[procedureTable editColumn:editedColumn row:index withEvent:nil select:YES];
				}
			} else {
				[procedureTable setNeedsDisplayInRect:[procedureTable rectOfRow:index]];
			}
		}
		
		[self updateArgumentSelection];
	}
}

- (void)updateDisplayForStoredProcedure:(EOEntity *)entity
{
	[procedureTable reloadData];
	
	// Make sure the selection in the inspector is kosher
	[self updateArgumentSelection];
}

- (void)objectWillChange:(id)object
{
	if ([object isKindOfClass:[EOAttribute class]]) {
		EOStoredProcedure	*procedure = [self selectedStoredProcedure];
		
		if (procedure) {
			NSInteger					index = [[procedure arguments] indexOfObjectIdenticalTo:object];
			
			if (index != NSNotFound) {
				if (index == [procedureTable editedRow]) {
					[editingObject release];
					editingObject = [object retain];
				}
				[procedureTable setNeedsDisplayInRect:[procedureTable rectOfRow:index]];
			}
		}
	}
}

- (void)objectDidChange:(id)object
{
	if ([object isKindOfClass:[EOAttribute class]]) {
		[self updateArgument:object];
	} else if ([object isKindOfClass:[EOStoredProcedure class]]) {
		[self updateDisplayForStoredProcedure:object];
	}
}

@end
