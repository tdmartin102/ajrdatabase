//
//  EditorEntities.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EditorEntities.h"

#import "Document.h"
#import "NSTableView-ColumnVisibility.h"

#import "Additions.h"

#import <EOAccess/EOAccess.h>

@implementation EditorEntities
{
    EOEntity					*editingEntity;
    NSMutableArray              *entities;
}

+ (void)load { } 

+ (NSString *)name
{
	return @"Entities";
}

- (instancetype)initWithDocument:(Document *)aDocument
{
	self = [super initWithDocument:aDocument];
	
	return self;
}


- (void)awakeFromNib
{
	[entityTable setCanHideColumns:YES];
}

- (void)loadEntities
{
    entities = [[[self model] entities] mutableCopy];
    [entities sortUsingComparator:^NSComparisonResult(EOEntity *obj1, EOEntity *obj2) {
        return [[obj1 name] compare:[obj2 name]];
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (! entities && [self model])
        [self loadEntities];
    
	return [entities count];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
	EOEntity		*entity = [entities objectAtIndex:rowIndex];
	NSString		*ident = [aTableColumn identifier];
	
	if ([ident isEqualToString:@"isReadOnly"]) {
		[aCell setState:[entity isReadOnly]];
	} else if ([ident isEqualToString:@"isAbstractEntity"]) {
		[aCell setState:[entity isAbstractEntity]];
	} else if ([ident isEqualToString:@"cachesObjects"]) {
		[aCell setState:[entity cachesObjects]];
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex
{
	EOEntity		*entity = [entities objectAtIndex:rowIndex];
	NSString		*ident = [aTableColumn identifier];
	
	if ([ident isEqualToString:@"name"]) {
		return [entity name];
	} else if ([ident isEqualToString:@"externalName"]) {
		return [entity externalName];
	} else if ([ident isEqualToString:@"className"]) {
		return [entity className];
	} else if ([ident isEqualToString:@"parent"]) {
		return [[entity parentEntity] name];
	} else if ([ident isEqualToString:@"externalQuery"]) {
		return [entity externalQuery];
	}
	
	return @"?";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
	EOEntity		*entity = [entities objectAtIndex:rowIndex];
	NSString		*ident = [aTableColumn identifier];
	
	if ([ident isEqualToString:@"name"]) {
		[entity setName:anObject];
	} else if ([ident isEqualToString:@"externalName"]) {
		[entity setExternalName:anObject];
	} else if ([ident isEqualToString:@"className"]) {
		[entity setClassName:anObject];
	} else if ([ident isEqualToString:@"parent"]) {
		[[[[self model] modelGroup] entityNamed:anObject] addSubEntity:entity];
	} else if ([ident isEqualToString:@"externalQuery"]) {
		[entity setExternalQuery:anObject];
	} else if ([ident isEqualToString:@"cachesObjects"]) {
		[entity setCachesObjects:[anObject boolValue]];
	} else if ([ident isEqualToString:@"isReadOnly"]) {
		[entity setReadOnly:[anObject boolValue]];
	} else if ([ident isEqualToString:@"isAbstractEntity"]) {
		[entity setIsAbstractEntity:[anObject boolValue]];
	} else {
		AJRPrintf(@"Unhandled edit from %@:%@\n", ident, anObject);
	}
}

- (void)updateEntityDisplay:(EOEntity *)entity
{
	NSUInteger index = [entities indexOfObjectIdenticalTo:entity];
	
	if (index != NSNotFound) {
		if (entity == editingEntity) {
			NSInteger		editedColumn;
			
			// We had a name change, or at least a sorting change, so we need to re-display the whole table.
			[entityTable setNeedsDisplay:YES];
			editedColumn = [entityTable editedColumn];
			[entityTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                     byExtendingSelection:NO];
			if (editedColumn >= 0) {
				[entityTable editColumn:editedColumn row:index withEvent:nil select:YES];
			}
		} else {
			[entityTable setNeedsDisplayInRect:[entityTable rectOfRow:index]];
		}
	}
}

- (void)updateModelDisplay:(EOModel *)model
{
    [self loadEntities];
	[entityTable reloadData];
}

- (void)objectWillChange:(id)object
{
	if ([object isKindOfClass:[EOEntity class]]) {
		NSUInteger	index = [entities indexOfObjectIdenticalTo:object];
		
		if (index != NSNotFound && index == [entityTable editedRow]) {
			editingEntity = object;
		}
		[entityTable setNeedsDisplayInRect:[entityTable rectOfRow:index]];
	}
}

- (void)objectDidChange:(id)object
{
	if ([object isKindOfClass:[EOEntity class]]) {
		[self updateEntityDisplay:object];
	} else if ([object isKindOfClass:[EOModel class]]) {
		[self updateModelDisplay:object];
	}
}

- (void)selectEntity:(id)sender
{
	EOEntity		*entity;
	NSInteger		row = [entityTable selectedRow];
	
	if ([[entityTable selectedRowIndexes] count] > 1) {
		NSMutableArray		*selectedEntities = [[NSMutableArray alloc] init];
		NSIndexSet          *indexSet = [entityTable selectedRowIndexes];
		
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop){
            [selectedEntities addObject:[entities objectAtIndex:idx]];}];
        
		[document setSelectedEntity:nil];
		[document setSelectedObject:selectedEntities];
	} else {
		if (row < 0) {
			[document setSelectedEntity:nil];
			[document setSelectedObject:[self model]];
		} else {
			entity = [entities objectAtIndex:row];
			[document setSelectedEntity:entity];
			[document setSelectedObject:entity];
		}
	}
	
	editingEntity = nil;
}

- (void)editEntity:(EOEntity *)entity
{
	NSInteger		index = [entities indexOfObjectIdenticalTo:entity];
	NSTableColumn	*column;
	NSInteger		columnIndex;
	
	// mont_rothstein @ yahoo.com 2005-04-17
	// This was checking for index >= 0 which causes all new (not added to model) entities to be included.
	if (index != NSNotFound) {
		[entityTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
            byExtendingSelection:NO];
		[[entityTable window] makeFirstResponder:entityTable];
		column = [entityTable tableColumnWithIdentifier:@"name"];
		if (column) {
			columnIndex = [[entityTable tableColumns] indexOfObjectIdenticalTo:column];
			if (columnIndex != NSNotFound) {
				[entityTable editColumn:columnIndex row:index withEvent:nil select:YES];
			}
		}
		[document setSelectedObject:entity];
	}
}

// william @ swats.org 2005-07-23
// Modified/re-wrote method to allow the class name to be the same as the entity name.
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	EOEntity		*entity				= nil;
	NSString		*ident				= nil;
	NSArray			*theTableColumns	= nil;
	NSTableColumn	*aTableColumn		= nil;
	NSInteger		row                 = -1;
	NSInteger		col                 = -1;
	
	col = [(NSTableView *)control editedColumn];
	if ( col != -1 ) {
		theTableColumns = [(NSTableView *)control tableColumns];
		if ( (theTableColumns != nil) && 
			 ([theTableColumns count] > col) ) {
			aTableColumn = [theTableColumns objectAtIndex:col];
			ident = [aTableColumn identifier];
			if ([ident isEqualToString:@"className"]) {
				// The ClassName can be the same as entity name.
				return YES;
			}
		}
	}
	row = [(NSTableView *)control selectedRow];
	entity = [entities objectAtIndex:row];
	if (row >= 0) {
		return ([entity validateName:[fieldEditor string]] == nil);
	}

	return YES;
}

@end
