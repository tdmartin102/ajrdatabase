//
//  EOInspector.m
//  AJRDatabase
//
//  Created by Alex Raftis on Sun Sep 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspector.h"

#import "EOInspectorPane.h"
#import "EOInspectorPanel.h"

#import <AJRFoundation/AJRFoundation.h>

@implementation EOInspector

- (void)dealloc
{
	[toolbar release];
	
	[super dealloc];
}

- (NSString *)name
{
	return NSStringFromClass([self class]);
}

- (void)activateInPanel:(EOInspectorPanel *)aPanel
{
	EOInspectorPane		*pane;
	id							object;
	
	inspectorPanel = aPanel;
	
	[inspectorPanel setToolbar:[self toolbar]];
	pane = [[self inspectorPanes] objectAtIndex:currentPane];
	[inspectorPanel setContentView:[pane view]];
	[inspectorPanel setTitle:AJRFormat(@"%@ (%@)", [self name], [pane name])];
	
	object = [inspectorPanel firstResponder];
	[pane update];
	[inspectorPanel makeFirstResponder:object];
}

- (EOInspectorPanel *)inspectorPanel
{
	return inspectorPanel;
}

- (NSArray *)inspectorPanes
{
	return [NSArray array];
}

- (NSToolbar *)toolbar
{
	if (toolbar == nil) {
		toolbar = [[NSToolbar allocWithZone:[self zone]] initWithIdentifier:[self name]];
		[toolbar setDelegate:self];
		[toolbar setAllowsUserCustomization:NO];
		[toolbar setAutosavesConfiguration:YES];
		[toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	}
	
	return toolbar;
}

- (void)selectInspectorPane:(id)sender
{
	EOInspectorPane	*pane;
	
	currentPane = [sender tag];
	pane = [[self inspectorPanes] objectAtIndex:currentPane];
	
	[inspectorPanel setContentView:[pane view]];
	[inspectorPanel setTitle:AJRFormat(@"%@ (%@)", [self name], [pane name])];
	[pane update];
}

- (NSView *)viewForPaneAtIndex:(unsigned int)index
{
	NSArray		*panes = [self inspectorPanes];
	
	return [[panes objectAtIndex:index] view];
}

- (unsigned int)indexOfPaneWithName:(NSString *)aName
{
	NSArray		*panes = [self inspectorPanes];
	int			x;
	
	for (x = 0; x < (const int)[panes count]; x++) {
		EOInspectorPane	*pane = [panes objectAtIndex:x];
		if ([[pane name] isEqualToString:aName]) return x;
	}
	
	return NSNotFound;
}

- (EOInspectorPane *)paneWithName:(NSString *)aName
{
	NSArray		*panes = [self inspectorPanes];
	int			x;
	
	for (x = 0; x < (const int)[panes count]; x++) {
		EOInspectorPane	*pane = [panes objectAtIndex:x];
		if ([[pane name] isEqualToString:aName]) return pane;
	}
	
	return nil;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
   return [[self inspectorPanes] valueForKey:@"name"];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
   return [[self inspectorPanes] valueForKey:@"name"];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
   NSToolbarItem        *item;
	
   item = [[NSToolbarItem allocWithZone:[self zone]] initWithItemIdentifier:itemIdentifier];
   [item setLabel:itemIdentifier];
   [item setPaletteLabel:itemIdentifier];
   [item setTarget:self];
	[item setAction:@selector(selectInspectorPane:)];
	[item setTag:[self indexOfPaneWithName:itemIdentifier]];
	[item setImage:[[self paneWithName:itemIdentifier] image]];

   return [item autorelease];
}

@end


@implementation NSObject (EOInspector)

- (EOInspector *)inspector
{
	return nil;
}

@end
