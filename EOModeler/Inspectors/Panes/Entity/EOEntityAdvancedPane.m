//
//  EOEntityAdvancedPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOEntityAdvancedPane.h"

#import <EOAccess/EOAccess.h>

@implementation EOEntityAdvancedPane

- (NSString *)name
{
	return @"Advanced";
}

- (NSArray *)entities
{
	if (entities == nil) {
		int				x;
		NSArray			*models = [[EOModelGroup defaultModelGroup] models];
		
		entities = [[NSMutableArray allocWithZone:[self zone]] init];
		
		for (x = 0; x < (const int)[models count]; x++) {
			[entities addObjectsFromArray:[[models objectAtIndex:x] entities]];
		}
		
		[entities sortUsingSelector:@selector(compare:)];
		
		// And make sure we're aware of changes to our master entity list...
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(modelDidAddEntity:) name:EOModelDidAddEntityNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(modelDidRemoveEntity:) name:EOModelDidRemoveEntityNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(entityDidChangeName:) name:EOEntityDidChangeNameNotification object:nil];
	}
	
	return entities;
}

- (void)modelDidAddEntity:(NSNotification *)notification
{
	[entities addObject:[[notification userInfo] objectForKey:@"entity"]];
	[entities sortUsingSelector:@selector(compare:)];
}

- (void)modelDidRemoveEntity:(NSNotification *)notification
{
	[entities removeObjectIdenticalTo:[[notification userInfo] objectForKey:@"entity"]];
	[entities sortUsingSelector:@selector(compare:)];
}

- (void)entityDidChangeName:(NSNotification *)notification
{
	[entities sortUsingSelector:@selector(compare:)];
}

- (void)updateParentButton
{
	int		row = [parentTable selectedRow];
	
	if (row < 0) {
		[parentButton setEnabled:NO];
		[parentButton setTitle:@"Set Parent"];
	} else {
		EOEntity		*selected = [[self entities] objectAtIndex:row];
		EOEntity		*entity = [self selectedEntity];
		
		if (entity == selected) {
			[parentButton setEnabled:NO];
			[parentButton setTitle:@"N/A"];
		} else if ([entity parentEntity] == selected) {
			[parentButton setEnabled:YES];
			[parentButton setTitle:@"Clear Parent"];
		} else {
			[parentButton setEnabled:YES];
			[parentButton setTitle:@"Set Parent"];
		}
	}
}

- (void)update
{
	EOEntity		*entity = [self selectedEntity];
	
	[batchSizeField setIntValue:[entity maxNumberOfInstancesToBatchFetch]];
	[externalQueryField setStringValue:[entity externalQuery] ? [entity externalQuery] : @""];
	[qualifierField setStringValue:[entity restrictingQualifier] ? [[entity restrictingQualifier] description] : @""];
	[readOnlyCheck setState:[entity isReadOnly]];
	[cacheInMemoryCheck setState:[entity cachesObjects]];
	[abstractCheck setState:[entity isAbstractEntity]];
	
	if ([parentTable selectedRow] < 0) {
		[parentButton setEnabled:NO];
		[parentButton setTitle:@"Set Parent"];
	}
	
	[parentTable reloadData];
	[self updateParentButton];
}

- (void)setBatchSize:(id)sender
{
	[[self selectedEntity] setMaxNumberOfInstancesToBatchFetch:[sender intValue]];
}

- (void)setExternalQuery:(id)sender
{
	NSString		*value = [sender stringValue];
	[[self selectedEntity] setExternalQuery:[value length] ? value : nil];
}

- (void)setQualifier:(id)sender
{
	NSString		*value = [sender stringValue];
	[[self selectedEntity] setRestrictingQualifier:[value length] ? [EOQualifier qualifierWithQualifierFormat:value] : nil];
}

- (void)selectParent:(id)sender
{
	[self updateParentButton];
}

- (void)toggleParent:(id)sender
{
	int		row = [parentTable selectedRow];
	
	if (row < 0) {
		NSBeep();
	} else {
		EOEntity		*selected = [[self entities] objectAtIndex:row];
		EOEntity		*entity = [self selectedEntity];
		
		if ([entity parentEntity] == selected) {
			[selected removeSubEntity:entity];
			[parentButton setEnabled:YES];
			[parentButton setTitle:@"Set Parent"];
		} else {
			[selected addSubEntity:entity];
			[parentButton setEnabled:YES];
			[parentButton setTitle:@"Clear Parent"];
		}
		
		[parentTable setNeedsDisplayInRect:[parentTable rectOfRow:row]];
	}
}

- (void)toggleReadOnly:(id)sender
{
	[[self selectedEntity] setReadOnly:[sender state]];
}

- (void)toggleCacheInMemory:(id)sender
{
	[[self selectedEntity] setCachesObjects:[sender state]];
}

- (void)toggleAbstract:(id)sender
{
	[[self selectedEntity] setIsAbstractEntity:[sender state]];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self entities] count];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	EOEntity		*entity = [[self entities] objectAtIndex:rowIndex];
	NSString		*ident = [aTableColumn identifier];
	EOEntity		*inspected = [self selectedEntity];
	
	if (entity == inspected) {
		[aCell setEnabled:NO];
		if ([aCell isKindOfClass:[NSTextFieldCell class]]) {
			[(NSTextFieldCell *)aCell setTextColor:[NSColor gridColor]];
		}
	} else {
		[aCell setEnabled:YES];
		if ([aCell isKindOfClass:[NSTextFieldCell class]]) {
			[(NSTextFieldCell *)aCell setTextColor:[NSColor controlTextColor]];
		}
	}

	if ([ident isEqualToString:@"selected"] && entity != inspected) {
		[aCell setEnabled:YES];
		[aCell setState:entity == [inspected parentEntity]];
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	EOEntity		*entity = [[self entities] objectAtIndex:rowIndex];
	NSString		*ident = [aTableColumn identifier];
	
	if ([ident isEqualToString:@"entityName"]) {
		return [entity name];
	} else if ([ident isEqualToString:@"className"]) {
		return [entity className];
	}
	
	return @"?";
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)row
{
	EOEntity		*selected = [[self entities] objectAtIndex:row];
	EOEntity		*entity = [self selectedEntity];
	
	if ([entity parentEntity] == selected) {
		[selected removeSubEntity:entity];
		[parentButton setEnabled:YES];
		[parentButton setTitle:@"Set Parent"];
	} else {
		[selected addSubEntity:entity];
		[parentButton setEnabled:YES];
		[parentButton setTitle:@"Clear Parent"];
	}
	
	[parentTable setNeedsDisplay:YES];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex
{
	EOEntity		*selected = [[self entities] objectAtIndex:rowIndex];
	EOEntity		*entity = [self selectedEntity];
	
	return selected != entity;
}

@end
