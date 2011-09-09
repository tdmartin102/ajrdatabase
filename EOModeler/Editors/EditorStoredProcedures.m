//
//  EditorStoredProcedures.m
//  AJRDatabase
//
//  Created by Alex Raftis on Sat Sep 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "EditorStoredProcedures.h"

#import "Document.h"
#import "IconHeaderCell.h"
#import "NSTableView-ColumnVisibility.h"

#import <EOAccess/EOAccess.h>
#import <AJRInterface/AJRInterface.h>

@implementation EditorStoredProcedures

+ (void)load { } 

+ (NSString *)name
{
	return @"Stored Procedures";
}

- (void)dealloc
{
	[editingObject release];
	
	[super dealloc];
}

- (void)awakeFromNib
{
	[proceduresTable setCanHideColumns:YES];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[[self model] storedProcedures] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	EOStoredProcedure	*procedure = [[[self model] storedProcedures] objectAtIndex:rowIndex];
	NSString				*ident = [aTableColumn identifier];
	
	if ([ident isEqualToString:@"name"]) {
		return [procedure name];
	} else if ([ident isEqualToString:@"externalName"]) {
		return [procedure externalName];
	}
	
	return @"?";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	EOStoredProcedure	*procedure = [[[self model] storedProcedures] objectAtIndex:rowIndex];
	NSString				*ident = [aTableColumn identifier];
	
	if ([ident isEqualToString:@"name"]) {
		[procedure setName:anObject];
	} else if ([ident isEqualToString:@"externalName"]) {
		[procedure setExternalName:anObject];
	} else {
		AJRPrintf(@"Unhandled edit from %@:%@\n", ident, anObject);
	}
}

- (void)updateProcedureDisplay:(EOStoredProcedure *)procedure
{
	unsigned int index = [[[self model] storedProcedures] indexOfObjectIdenticalTo:procedure];
	
	if (index != NSNotFound) {
		if (procedure == editingObject) {
			int		editedColumn;
			
			// We had a name change, or at least a sorting change, so we need to re-display the whole table.
			[proceduresTable setNeedsDisplay:YES];
			editedColumn = [proceduresTable editedColumn];
			[proceduresTable selectRow:index byExtendingSelection:NO];
			if (editedColumn >= 0) {
				[proceduresTable editColumn:editedColumn row:index withEvent:nil select:YES];
			}
		} else {
			[proceduresTable setNeedsDisplayInRect:[proceduresTable rectOfRow:index]];
		}
	}
}

- (void)objectWillChange:(id)object
{
	if ([object isKindOfClass:[EOStoredProcedure class]]) {
		int		index = [[[self model] storedProcedures] indexOfObjectIdenticalTo:object];
		
		if (index != NSNotFound) {
			if (index == [proceduresTable editedRow]) {
				[editingObject release];
				editingObject = [object retain];
			}
			[proceduresTable setNeedsDisplayInRect:[proceduresTable rectOfRow:index]];
		}
	}
}

- (void)objectDidChange:(id)object
{
	if ([object isKindOfClass:[EOStoredProcedure class]]) {
		[self updateProcedureDisplay:object];
	}
}

- (void)selectStoredProcedure:(id)sender
{
	int		row = [proceduresTable selectedRow];
	
	if (row >= 0) {
		[document setSelectedObject:[[[self model] storedProcedures] objectAtIndex:row]];
	} else {
		[document setSelectedObject:nil];
	}
	
	if (editingObject) {
		[editingObject release]; editingObject = nil;
	}
}

- (void)editStoredProcedure:(EOStoredProcedure *)storedProcedure
{
	int				index = [[[self model] storedProcedures] indexOfObjectIdenticalTo:storedProcedure];
	NSTableColumn	*column;
	int				columnIndex;
	
	// mont_rothstein @ yahoo.com 2005-04-17
	// This was checking for index >= 0 it needs to be NSNotFound.
	if (index >= NSNotFound) {
		[proceduresTable selectRow:index byExtendingSelection:NO];
		[[proceduresTable window] makeFirstResponder:proceduresTable];
		column = [proceduresTable tableColumnWithIdentifier:@"name"];
		if (column) {
			columnIndex = [[proceduresTable tableColumns] indexOfObjectIdenticalTo:column];
			if (columnIndex != NSNotFound) {
				[proceduresTable editColumn:columnIndex row:index withEvent:nil select:YES];
			}
		}
		[document setSelectedObject:storedProcedure];
	}
}

@end
