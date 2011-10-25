//
//  EOInternalTypeInspector.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

@class EOAttribute, EOAttributePane, EOInternalTypePane;

@interface EOInternalTypeInspector : NSView
{
	IBOutlet NSPopUpButton		*classPopUp;
	IBOutlet EOAttributePane	*attributePane;
	
	NSMutableArray					*inspectors;
	NSMutableDictionary			*inspectorsByName;
	AJRObjectBroker				*broker;
	
	EOAttribute						*attribute;
	EOInternalTypePane			*customPane;
	EOInternalTypePane			*currentPane;
	
	NSView							*previousView;
	NSView							*nextView;
}

- (void)populatePopUp;

- (void)update;

- (void)takeInspectorFrom:(id)sender;

- (void)setAttribute:(EOAttribute *)anAttribute;
- (EOAttribute *)attribute;

@end
