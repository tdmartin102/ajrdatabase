//
//  NSTableView-ColumnVisibility.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSTableView-ColumnVisibility.h"

#import "PBPopUpButton.h"

static void (*_ajrPersistentRead)(id, SEL);
static void (*_ajrPersistentWrite)(id, SEL);

@interface NSTableView (Private)

- (void)_writePersistentTableColumns;

@end

@implementation NSTableView (ColumnVisibility)

+ (void)load
{
	if (!_ajrPersistentRead) {
		Method		method;
		
		method = class_getInstanceMethod([NSTableView class], @selector(_readPersistentTableColumns));
		_ajrPersistentRead = (void (*)(id, SEL))method->method_imp;
		method->method_imp = [NSTableView instanceMethodForSelector:@selector(_ajrReadPersistentTableColumns)];
		
		method = class_getInstanceMethod([NSTableView class], @selector(_writePersistentTableColumns));
		_ajrPersistentWrite = (void (*)(id, SEL))method->method_imp;
		method->method_imp = [NSTableView instanceMethodForSelector:@selector(_ajrWritePersistentTableColumns)];
	}
}

- (NSArray *)hiddenColumns
{
	NSArray		*columns = [self instanceObjectForKey:@"hiddenColumns"];
	
	if (columns == nil) {
		columns = [[NSMutableArray allocWithZone:[self zone]] init];
		[self setInstanceObject:columns forKey:@"hiddenColumns"];
		[columns release];
	}
	
	return columns;
}

- (void)setColumn:(NSTableColumn *)column visible:(BOOL)flag
{
	NSMutableArray	*hiddenColumns = (NSMutableArray *)[self hiddenColumns];
		
	if (flag) {
		if ([hiddenColumns indexOfObjectIdenticalTo:column] != NSNotFound) {
			[column retain];
			[hiddenColumns removeObject:column];
			[self addTableColumn:column];
			[column release];
			[self setNeedsDisplay:YES];
			[self _writePersistentTableColumns];
		}
	} else {
		if ([hiddenColumns indexOfObjectIdenticalTo:column] == NSNotFound) {
			[column retain];
			[self removeTableColumn:column];
			[hiddenColumns addObject:column];
			[column release];
			[self setNeedsDisplay:YES];
			[self _writePersistentTableColumns];
		}
	}
}

- (BOOL)isColumnVisible:(NSTableColumn *)column
{
	return [[self hiddenColumns] indexOfObjectIdenticalTo:column] == NSNotFound;
}

- (BOOL)isColumnWithIdentifierVisible:(id)identifier
{
	NSTableColumn		*column = [self tableColumnWithIdentifier:identifier];
	NSArray				*hidden;
	int					x;
	
	if (column) return [self isColumnVisible:column];
	
	hidden = [self hiddenColumns];
	for (x = 0; x < (const int)[hidden count]; x++) {
		column = [hidden objectAtIndex:x];
		if ([(NSString *)[column identifier] isEqual:identifier]) {
			return [self isColumnVisible:column];
		}
	}
	
	return NO;
}

- (NSTableColumn *)anyTableColumnWithIdentifier:(id)identifier
{
	NSTableColumn		*column = [self tableColumnWithIdentifier:identifier];
	NSArray				*hidden;
	int					x;
	
	if (column) return column;
	
	hidden = [self hiddenColumns];
	for (x = 0; x < (const int)[hidden count]; x++) {
		column = [hidden objectAtIndex:x];
		if ([(NSString *)[column identifier] isEqual:identifier]) {
			return column;
		}
	}
	
	return nil;
}

- (NSString *)_autosaveNameKey
{
	return [NSString stringWithFormat:@"%C Hidden %@", self, [self autosaveName]];
}

- (void)_ajrReadPersistentTableColumns
{
	NSString		*nameKey = [self _autosaveNameKey];
	NSArray		*names;
	int			x;

	_ajrPersistentRead(self, _cmd);
	
	names = [[NSUserDefaults standardUserDefaults] arrayForKey:nameKey];
	for (x = 0; x < (const int)[names count]; x++) {
		NSTableColumn		*column = [self anyTableColumnWithIdentifier:[names objectAtIndex:x]];
		if (column != nil) [self setColumn:column visible:NO];
	}
}

- (void)_ajrWritePersistentTableColumns
{
	NSArray			*hidden = [self hiddenColumns];
	int				x;
	NSString			*nameKey = [self _autosaveNameKey];
	NSMutableArray	*names;
	
	for (x = 0; x < (const int)[hidden count]; x++) {
		[self addTableColumn:[hidden objectAtIndex:x]];
	}
	_ajrPersistentWrite(self, _cmd);
	names = [[NSMutableArray allocWithZone:[self zone]] init];
	for (x = 0; x < (const int)[hidden count]; x++) {
		[self removeTableColumn:[hidden objectAtIndex:x]];
		[names addObject:[[hidden objectAtIndex:x] identifier]];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:names forKey:nameKey];
	
	[names release];
}

- (void)setCanHideColumns:(BOOL)flag
{
	if (flag) {
		PBPopUpButton		*button;
		id <NSMenuItem>	item;
		NSMutableArray		*titles;
		NSArray				*columns;
		int					x;
	
		button = [[PBPopUpButton allocWithZone:[self zone]] initWithFrame:(NSRect){{0.0, 0.0}, {19.0, 18.0}} pullsDown:YES];
		[button addItemWithTitle:@"One"];
		[button setBordered:NO];
		item = [button itemAtIndex:0];
		[item setTitle:@""];

		columns = [self tableColumns];
		titles = [[NSMutableArray allocWithZone:[self zone]] init];
		for (x = 0; x < (const int)[columns count]; x++) {
			[titles addObject:[[[columns objectAtIndex:x] headerCell] stringValue]];
			[[titles lastObject] setInstanceObject:[columns objectAtIndex:x] forKey:@"column"];
		}
		columns = [self hiddenColumns];
		for (x = 0; x < (const int)[columns count]; x++) {
			[titles addObject:[[[columns objectAtIndex:x] headerCell] stringValue]];
			[[titles lastObject] setInstanceObject:[columns objectAtIndex:x] forKey:@"column"];
		}
		[titles sortUsingSelector:@selector(caseInsensitiveCompare:)];
		
		for (x = 0; x < (const int)[titles count]; x++) {
			[button addItemWithTitle:[titles objectAtIndex:x]];
		}
		
		[self setCornerView:button];
		
		[button setTarget:self];
		[button setAction:@selector(_toggleColumnVisibility:)];
	} else {
		if ([[self cornerView] isKindOfClass:[PBPopUpButton class]]) {
			[self setCornerView:nil];
		}
	}
}

- (void)_toggleColumnVisibility:(id)sender
{
	NSTableColumn	*column = [[[sender selectedItem] title] instanceObjectForKey:@"column"];
	
	[self setColumn:column visible:![self isColumnVisible:column]];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)item
{
	NSTableColumn	*column = [[item title] instanceObjectForKey:@"column"];
	
	[item setState:[self isColumnVisible:column] ? NSOnState : NSOffState];
	
	return YES;
}

@end
