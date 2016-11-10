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
	IBOutlet NSTabView          *tabView;
	
	IBOutlet NSTextField		*nameField;
	IBOutlet NSPopUpButton      *modelsPopUp;
	IBOutlet NSTableView		*entitiesTable;
	IBOutlet NSMatrix			*toOneMatrix;
	IBOutlet NSPopUpButton      *joinTypePopUp;
	IBOutlet NSTableView		*sourceTable;
	IBOutlet NSTableView		*destinationTable;
	IBOutlet NSButton			*connectButton;
	
	IBOutlet NSTextField		*entityField;
	IBOutlet NSTextField		*definitionField;
}

- (IBAction)setName:(id)sender;
- (IBAction)selectModel:(id)sender;
- (IBAction)selectToOne:(id)sender;
- (IBAction)selectJoinType:(id)sender;
- (IBAction)selectDestinationEntity:(id)sender;
- (IBAction)selectSourceAttribute:(id)sender;
- (IBAction)selectDestinationAttribute:(id)sender;
- (IBAction)toggleJoin:(id)sender;

@end
