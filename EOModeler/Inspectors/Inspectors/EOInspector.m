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

@implementation EOInspector

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
	[inspectorPanel setTitle:[NSString stringWithFormat:@"%@ (%@)", [self name], [pane name]]];
	
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
		toolbar = [[NSToolbar alloc] initWithIdentifier:[self name]];
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
    EOInspectorPane	*rootPane;

    id value;
	
	currentPane = [sender tag];
	pane = [[self inspectorPanes] objectAtIndex:currentPane];
	if (currentPane == 0)
        rootPane = pane;
    else
        rootPane = [[self inspectorPanes] objectAtIndex:0];
    value = [rootPane currentObject];
	[inspectorPanel setContentView:[pane view]];
	[inspectorPanel setTitle:[NSString stringWithFormat:@"%@ (%@)", [self name], [pane name]]];
    
    
    [pane updateWithSelectedObject:value];
}

- (NSView *)viewForPaneAtIndex:(unsigned int)index
{
	NSArray		*panes = [self inspectorPanes];
	
	return [[panes objectAtIndex:index] view];
}

- (NSUInteger)indexOfPaneWithName:(NSString *)aName
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
	
   item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
   [item setLabel:itemIdentifier];
   [item setPaletteLabel:itemIdentifier];
   [item setTarget:self];
	[item setAction:@selector(selectInspectorPane:)];
	[item setTag:[self indexOfPaneWithName:itemIdentifier]];
	[item setImage:[[self paneWithName:itemIdentifier] image]];

   return item;
}

@end


@implementation NSObject (EOInspector)

- (EOInspector *)inspector
{
	return nil;
}

@end
