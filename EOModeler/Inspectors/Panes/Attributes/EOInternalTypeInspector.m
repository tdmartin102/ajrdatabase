//
//  EOInternalTypeInspector.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInternalTypeInspector.h"

#import "EOInternalTypePane.h"
#import "Additions.h"

#import <EOAccess/EOAccess.h>

@implementation EOInternalTypeInspector

- (id)initWithFrame:(NSRect)frame
{
	[super initWithFrame:frame];
	
	inspectors = [[NSMutableArray allocWithZone:[self zone]] init];
	inspectorsByName = [[NSMutableDictionary allocWithZone:[self zone]] init];
	broker = [[AJRObjectBroker allocWithZone:[self zone]] initWithTarget:self action:@selector(registerInspector:) requestingClassesInheritedFromClass:[EOInternalTypePane class]];
	
	return self;
}

- (void)dealloc
{
	[inspectors release];
	[inspectorsByName release];
	[broker release];
	
	[attribute release];
	currentPane = nil;
	
	[previousView release];
	[nextView release];

	[super dealloc];
}

- (void)awakeFromNib
{
	[self populatePopUp];
	previousView = [[self previousKeyView] retain];
	nextView = [[self nextKeyView] retain];
}

- (void)registerInspector:(Class)anInspector
{
	NSString					*name = [anInspector name];
	Class						InspectorClass = [anInspector inspectedClass];
	EOInternalTypePane	*inspector = [[anInspector allocWithZone:[self zone]] initWithInspector:self];
	
	if (InspectorClass) {
		[inspectors addObject:inspector];
		[inspectorsByName setObject:inspector forKey:name];
	} else {
		[inspectors addObject:inspector];
		customPane = [inspector retain];
		[inspectorsByName setObject:inspector forKey:name];
	}
	
	[EOLog log:EOLogInfo withFormat:@"Registered Internal Type Pane: %@\n", name];
}

- (void)populatePopUp
{
	NSArray		*names;
	
	names = [[inspectorsByName allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	[classPopUp removeAllItems];
	[classPopUp addItemsWithTitles:names];
}

- (void)update
{
	[currentPane update];
}

- (void)updateView
{
	if ([[self subviews] count]) {
		[[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	[self addSubview:[currentPane view]];
	
	if ([[currentPane view] nextKeyView] == nil) {
		[previousView setNextKeyView:nextView];
	} else {
		[previousView setNextKeyView:[[currentPane view] nextKeyView]];
		[[[currentPane view] previousKeyView] setNextKeyView:nextView];
	}
}

- (void)takeInspectorFrom:(id)sender
{
	NSString					*name = [[sender selectedItem] title];
	EOInternalTypePane	*pane = [inspectorsByName objectForKey:name];
	
	if (pane && pane != currentPane) {
		currentPane = pane;
		[currentPane updateAttribute];

		[self updateView];
		[currentPane update];
	}
}

- (void)setAttribute:(EOAttribute *)anAttribute
{
	NSString					*className;
	EOInternalTypePane	*newPane = nil;
	int						x;

	if (attribute != anAttribute) {
		[attribute release];
		attribute = [anAttribute retain];
	}
	
	className = [attribute valueClassName];
	if (className == nil) className = @"__custom__";
	
	for (x = 0; x < (const int)[inspectors count]; x++) {
		newPane = [inspectors objectAtIndex:x];
		if ([newPane canInspectAttribute:attribute]) break;
	}
	if (x == [inspectors count]) {
		newPane = customPane;
	}
	
	if (newPane != currentPane) {
		currentPane = newPane;
		[self updateView];
		[classPopUp selectItemWithTitle:[currentPane name]];
	}
	
	[currentPane update];
}

- (EOAttribute *)attribute
{
	return attribute;
}

@end
