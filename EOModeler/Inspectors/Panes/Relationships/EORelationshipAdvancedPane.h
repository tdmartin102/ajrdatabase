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
	IBOutlet NSMatrix			*optionalityMatrix;
	IBOutlet NSMatrix			*deleteRuleMatrix;
	IBOutlet NSButtonCell	*ownsDestinationCheck;
	IBOutlet NSButtonCell	*propagatesPKCheck;
}

- (void)setBatchSize:(id)sender;
- (void)selectOptionality:(id)sender;
- (void)selectDeleteRule:(id)sender;
- (void)toggleOwnsDestination:(id)sender;
- (void)togglePropagatesPK:(id)sender;

@end
