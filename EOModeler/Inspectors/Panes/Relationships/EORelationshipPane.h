//
//  EORelationshipPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspectorPane.h"

@interface EORelationshipPane : EOInspectorPane
{
	IBOutlet NSTabView		*tabView;
	
	IBOutlet NSTextField		*nameField;
	IBOutlet NSPopUpButton	*modelsPopUp;
	IBOutlet NSTableView		*entitiesTable;
	IBOutlet NSMatrix			*toOneMatrix;
	IBOutlet NSPopUpButton	*joinTypePopUp;
	IBOutlet NSTableView		*sourceTable;
	IBOutlet NSTableView		*destinationTable;
	IBOutlet NSButton			*connectButton;
	
	IBOutlet NSTextField		*entityField;
	IBOutlet NSTextField		*definitionField;
}

- (void)setName:(id)sender;
- (void)selectModel:(id)sender;
- (void)selectToOne:(id)sender;
- (void)selectJoinType:(id)sender;
- (void)selectDestinationEntity:(id)sender;
- (void)selectSourceAttribute:(id)sender;
- (void)selectDestinationAttribute:(id)sender;
- (void)toggleJoin:(id)sender;

@end
