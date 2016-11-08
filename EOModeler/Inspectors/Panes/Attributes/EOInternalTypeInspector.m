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
#import "AJRObjectBroker.h"
#import <EOAccess/EOAccess.h>

@implementation EOInternalTypeInspector

- (instancetype)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        inspectors = [[NSMutableArray alloc] init];
        inspectorsByName = [[NSMutableDictionary alloc] init];
        broker = [[AJRObjectBroker alloc] initWithTarget:self action:@selector(registerInspector:) requestingClassesInheritedFromClass:[EOInternalTypePane class]];
    }
	
	return self;
}

- (void)awakeFromNib
{
	[self populatePopUp];
	previousView = [self previousKeyView];
	nextView = [self nextKeyView];
}

- (void)registerInspector:(Class)anInspector
{
	NSString					*name = [anInspector name];
	Class						InspectorClass = [anInspector inspectedClass];
	EOInternalTypePane	*inspector = [[anInspector alloc] initWithInspector:self];
	
	if (InspectorClass) {
		[inspectors addObject:inspector];
		[inspectorsByName setObject:inspector forKey:name];
	} else {
		[inspectors addObject:inspector];
		customPane = inspector;
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
	NSString			*className;
	EOInternalTypePane	*newPane = nil;
	int						x;

	if (attribute != anAttribute) {
		attribute = anAttribute;
	}
	
	className = [attribute valueClassName];
	if (className == nil)
    {
        className = @"__custom__";
        [attribute setValueClassName:className];
    }
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
