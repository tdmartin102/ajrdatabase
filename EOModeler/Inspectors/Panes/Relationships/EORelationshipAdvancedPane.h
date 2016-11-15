//
//  EORelationshipAdvancedPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspectorPane.h"

@interface EORelationshipAdvancedPane : EOInspectorPane
{
	IBOutlet NSTextField		*batchSizeField;
    IBOutlet NSTextField        *nameField;
	IBOutlet NSMatrix			*optionalityMatrix;
	IBOutlet NSMatrix			*deleteRuleMatrix;
	IBOutlet NSButtonCell       *ownsDestinationCheck;
	IBOutlet NSButtonCell       *propagatesPKCheck;
}

- (IBAction)setBatchSize:(id)sender;
- (IBAction)selectOptionality:(id)sender;
- (IBAction)selectDeleteRule:(id)sender;
- (IBAction)toggleOwnsDestination:(id)sender;
- (IBAction)togglePropagatesPK:(id)sender;

@end
