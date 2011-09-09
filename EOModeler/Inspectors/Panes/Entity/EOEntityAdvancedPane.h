//
//  EOEntityAdvancedPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspectorPane.h"

@interface EOEntityAdvancedPane : EOInspectorPane
{
	IBOutlet NSTextField		*batchSizeField;
	IBOutlet NSTextField		*externalQueryField;
	IBOutlet NSTextField		*qualifierField;
	IBOutlet NSTableView		*parentTable;
	IBOutlet NSButton			*parentButton;
	IBOutlet NSButton			*readOnlyCheck;
	IBOutlet NSButton			*cacheInMemoryCheck;
	IBOutlet NSButton			*abstractCheck;
	
	NSMutableArray				*entities;
}

- (void)setBatchSize:(id)sender;
- (void)setExternalQuery:(id)sender;
- (void)setQualifier:(id)sender;
- (void)selectParent:(id)sender;
- (void)toggleParent:(id)sender;
- (void)toggleReadOnly:(id)sender;
- (void)toggleCacheInMemory:(id)sender;
- (void)toggleAbstract:(id)sender;

@end
