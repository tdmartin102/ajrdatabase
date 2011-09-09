
#import "Document.h"

#import <EOAccess/EOAccess.h>

@implementation Document (Toolbar)

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
   NSArray *items = [NSArray arrayWithObjects:
      @"Inspector", @"Browse Data",
      NSToolbarSeparatorItemIdentifier, @"Obj-C", @"SQL",
      NSToolbarSeparatorItemIdentifier, @"Entity", @"Attribute", @"Relationship", @"Fetch", @"Flatten", @"Procedure",
      NSToolbarSeparatorItemIdentifier, NSToolbarPrintItemIdentifier,
      nil];
   return items;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
   NSArray *items = [NSArray arrayWithObjects:@"Inspector", @"Browse Data", NSToolbarCustomizeToolbarItemIdentifier, @"Obj-C", @"SQL", @"Entity", @"Attribute", @"Relationship", @"Fetch", @"Flatten", @"Procedure", NSToolbarFlexibleSpaceItemIdentifier, NSToolbarPrintItemIdentifier, NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier,  nil];
   return items;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
   NSToolbarItem        *item;
	
   item = [[NSToolbarItem allocWithZone:[self zone]] initWithItemIdentifier:itemIdentifier];
   [item setLabel:itemIdentifier];
   [item setPaletteLabel:itemIdentifier];
   [item setTarget:nil];
	
   if ([itemIdentifier isEqualToString:@"Inspector"]) {
      [item setToolTip:@"Inspect the selected item"];
      [item setTarget:nil];
      [item setAction:@selector(showInspector:)];
      [item setImage:[NSImage imageNamed:@"toolbarInspector"]];
   } else if ([itemIdentifier isEqualToString:@"Browse Data"]) {
      [item setToolTip:@"Browse the model's database"];
      [item setTarget:self];
      [item setAction:@selector(showDatabaseBrowser:)];
      [item setImage:[NSImage imageNamed:@"toolbarBrowseDB"]];
   } else if ([itemIdentifier isEqualToString:@"Obj-C"]) {
      [item setToolTip:@"Generate Obj-C files template for selected entities"];
      [item setTarget:self];
      [item setAction:@selector(generateObjCFiles:)];
      [item setImage:[NSImage imageNamed:@"toolbarGenerateObjC"]];
   } else if ([itemIdentifier isEqualToString:@"SQL"]) {
      [item setToolTip:@"Generate SQL for selected entities or model"];
      [item setTarget:self];
      [item setAction:@selector(generateSQL:)];
      [item setImage:[NSImage imageNamed:@"toolbarGenerateSQL"]];
   } else if ([itemIdentifier isEqualToString:@"Entity"]) {
      [item setToolTip:@"Add an entity to the model"];
      [item setTarget:self];
      [item setAction:@selector(newEntity:)];
      [item setImage:[NSImage imageNamed:@"toolbarNewEntity"]];
   } else if ([itemIdentifier isEqualToString:@"Attribute"]) {
      [item setToolTip:@"Add an attribute to the selected entity"];
      [item setTarget:self];
      [item setAction:@selector(newAttribute:)];
      [item setImage:[NSImage imageNamed:@"toolbarNewAttribute"]];
   } else if ([itemIdentifier isEqualToString:@"Relationship"]) {
      [item setToolTip:@"Add a relationship to the current entity"];
      [item setTarget:self];
      [item setAction:@selector(newRelationship:)];
      [item setImage:[NSImage imageNamed:@"toolbarNewRelationship"]];
   } else if ([itemIdentifier isEqualToString:@"Fetch"]) {
      [item setToolTip:@"Add a new fetch specification to the current entity"];
      [item setTarget:self];
      [item setAction:@selector(newFetchSpecification:)];
      [item setImage:[NSImage imageNamed:@"toolbarNewFetchSpecification"]];
   } else if ([itemIdentifier isEqualToString:@"Flatten"]) {
      [item setToolTip:@"Flatten the selected relationship path"];
      [item setTarget:self];
      [item setAction:@selector(flattenRelationship:)];
      [item setImage:[NSImage imageNamed:@"toolbarFlattenRelationship"]];
   } else if ([itemIdentifier isEqualToString:@"Procedure"]) {
      [item setToolTip:@"Add a new stored procedure to the model"];
      [item setTarget:self];
      [item setAction:@selector(newStoredProcedure:)];
      [item setImage:[NSImage imageNamed:@"toolbarNewStoredProcedure"]];
   }
	
   return [item autorelease];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	NSString		*itemIdentifier = [theItem itemIdentifier];
	
   if ([itemIdentifier isEqualToString:@"Inspector"]) {
		return selectedObject != nil;
   } else if ([itemIdentifier isEqualToString:@"Browse Data"]) {
		return YES;
   } else if ([itemIdentifier isEqualToString:@"Obj-C"]) {
		return [self selectedObjectIsKindOfClass:[EOEntity class]] || [self selectedObjectIsKindOfClass:[EOModel class]];
   } else if ([itemIdentifier isEqualToString:@"SQL"]) {
		return [self selectedObjectIsKindOfClass:[EOEntity class]] || [self selectedObjectIsKindOfClass:[EOModel class]];
   } else if ([itemIdentifier isEqualToString:@"Entity"]) {
		return YES;
   } else if ([itemIdentifier isEqualToString:@"Attribute"]) {
		if (selectedEntity != nil) {
			[theItem setLabel:@"Attribute"];
			return YES;
		}
		if (selectedStoredProcedure != nil) {
			[theItem setLabel:@"Argument"];
			return YES;
		}
		[theItem setLabel:@"Attribute"];
		return NO;
   } else if ([itemIdentifier isEqualToString:@"Relationship"]) {
		return selectedEntity != nil;
   } else if ([itemIdentifier isEqualToString:@"Fetch"]) {
		return selectedEntity != nil;
   } else if ([itemIdentifier isEqualToString:@"Flatten"]) {
		return [selectedObject isKindOfClass:[EORelationship class]] && [modelOutline levelForRow:[modelOutline selectedRow]] >= 3;
   } else if ([itemIdentifier isEqualToString:@"Procedure"]) {
		return YES;
   }
	
	return YES;
}

@end
