//
//  EOEntityPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOEntityPane.h"

#import "Additions.h"
#import "IconHeaderCell.h"
#import "NSTableView-ColumnVisibility.h"

#import <EOAccess/EOAccess.h>

@implementation EOEntityPane

- (void)awakeFromNib
{
	[[[propertiesTable anyTableColumnWithIdentifier:@"primaryKey"] morphHeaderCellToClass:[IconHeaderCell class]] setImage:[NSImage imageNamed:@"keyTitle"]];
	[[[propertiesTable anyTableColumnWithIdentifier:@"classProperty"] morphHeaderCellToClass:[IconHeaderCell class]] setImage:[NSImage imageNamed:@"classTitle"]];
	[[[propertiesTable anyTableColumnWithIdentifier:@"locking"] morphHeaderCellToClass:[IconHeaderCell class]] setImage:[NSImage imageNamed:@"lockTitle"]];
}

- (NSString *)name
{
	return @"General";
}

- (void)update
{
	EOEntity		*entity = [self selectedEntity];
	
	[nameField setStringValue:[entity name]];
	[tableNameField setStringValue:[entity externalName]];
	[classNameField setStringValue:[entity className]];
	[propertiesTable reloadData];
}

- (void)setEntityName:(id)sender
{
	[[self selectedEntity] setName:[sender stringValue]];
}

- (void)setTableName:(id)sender
{
}

- (void)setClassName:(id)sender
{
	// william @ swats.org 2005-07-23
	// Added implementation
	[[self selectedEntity] setClassName:[sender stringValue]];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	EOEntity		*entity = [self selectedEntity];
	
	return [[entity attributes] count] + [[entity relationships] count];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	EOEntity		*entity = [self selectedEntity];
	NSArray		*attributes = [entity attributes];
	NSArray		*relationships = [entity relationships];
	NSString		*ident = [aTableColumn identifier];
	
	if (rowIndex < [attributes count]) {
		if ([ident isEqualToString:@"primaryKey"]) {
			[aCell setImage:nil];
			[aCell setState:[[entity primaryKeyAttributes] containsObject:[attributes objectAtIndex:rowIndex]]];
			[aCell setEnabled:YES];
		} else if ([ident isEqualToString:@"locking"]) {
			[aCell setImage:nil];
			[aCell setState:[[entity attributesUsedForLocking] containsObject:[attributes objectAtIndex:rowIndex]]];
			[aCell setEnabled:YES];
		} else if ([ident isEqualToString:@"classProperty"]) {
			[aCell setState:[[entity classProperties] containsObject:[attributes objectAtIndex:rowIndex]]];
		}
	} else {
		if ([ident isEqualToString:@"primaryKey"]) {
			[aCell setImage:[NSImage imageNamed:@"naTitle"]];
			[aCell setState:NSOffState];
			[aCell setEnabled:NO];
		} else if ([ident isEqualToString:@"locking"]) {
			[aCell setImage:[NSImage imageNamed:@"naTitle"]];
			[aCell setState:NSOffState];
			[aCell setEnabled:NO];
		} else if ([ident isEqualToString:@"classProperty"]) {
			if (rowIndex - [attributes count] < [relationships count]) {
				[aCell setState:[[entity classProperties] containsObject:[relationships objectAtIndex:rowIndex - [attributes count]]]];
			}
		}
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	EOEntity		*entity = [self selectedEntity];
	NSArray		*attributes = [entity attributes];
	NSArray		*relationships = [entity relationships];
	NSString		*ident = [aTableColumn identifier];
	
	if ([ident isEqualToString:@"name"]) {
		if (rowIndex < [attributes count]) {
			return [[attributes objectAtIndex:rowIndex] name];
		}
		if (rowIndex - [attributes count] < [relationships count]) {
			return [[relationships objectAtIndex:rowIndex - [attributes count]] name];
		}
	}
	
	return @"?";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	EOEntity		*entity = [self selectedEntity];
	NSArray		*attributes = [entity attributes];
	NSArray		*relationships = [entity relationships];
	NSString		*ident = [aTableColumn identifier];
	id				property;
	
	if (rowIndex < [attributes count]) {
		property = [attributes objectAtIndex:rowIndex];
	} else {
		property = [relationships objectAtIndex:rowIndex - [attributes count]];
	}
	
	if ([ident isEqualToString:@"primaryKey"]) {
		NSMutableArray		*array = [[entity primaryKeyAttributes] mutableCopyWithZone:[self zone]];
		if ([anObject intValue]) {
			[array addObject:property];
			if ([property allowsNull]) {
				[property setAllowsNull:NO];
			}
		} else {
			[array removeObject:property];
		}
		[entity setPrimaryKeyAttributes:array];
		[array release];
	} else if ([ident isEqualToString:@"classProperty"]) {
		NSMutableArray		*array = [[entity classProperties] mutableCopyWithZone:[self zone]];
		if ([anObject intValue]) {
			[array addObject:property];
		} else {
			[array removeObject:property];
		}
		[entity setClassProperties:array];
		[array release];
	} else if ([ident isEqualToString:@"locking"]) {
		NSMutableArray		*array = [[entity attributesUsedForLocking] mutableCopyWithZone:[self zone]];
		if ([anObject intValue]) {
			[array addObject:property];
		} else {
			[array removeObject:property];
		}
		[entity setAttributesUsedForLocking:array];
		[array release];
	} else if ([ident isEqualToString:@"nullable"]) {
		[property setAllowsNull:[anObject intValue] == 0 ? NO : YES];
	}
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	if (control == nameField) {
		return [[self selectedEntity] validateName:[fieldEditor string]] == nil;
	}
	
	return YES;
}

@end
