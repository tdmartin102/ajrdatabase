//
//  EOEntityStoredProceduresPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspectorPane.h"

@interface EOEntityStoredProceduresPane : EOInspectorPane
{
	IBOutlet NSTextField		*insertField;
	IBOutlet NSTextField		*deleteField;
	IBOutlet NSTextField		*fetchAllField;
	IBOutlet NSTextField		*fetchWithPKField;
	IBOutlet NSTextField		*getPKField;
}

- (void)setInsert:(id)sender;
- (void)setDelete:(id)sender;
- (void)setFetchAll:(id)sender;
- (void)setFetchWithPK:(id)sender;
- (void)setGetPK:(id)sender;

@end
