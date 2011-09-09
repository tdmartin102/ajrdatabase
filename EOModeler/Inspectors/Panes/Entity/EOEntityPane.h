//
//  EOEntityPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspectorPane.h"

@interface EOEntityPane : EOInspectorPane
{
	IBOutlet NSTextField		*nameField;
	IBOutlet NSTextField		*tableNameField;
	IBOutlet NSTextField		*classNameField;
	IBOutlet NSTableView		*propertiesTable;
}

- (void)setEntityName:(id)sender;
- (void)setTableName:(id)sender;
- (void)setClassName:(id)sender;

@end
