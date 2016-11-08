//
//  EOModelAdaptorPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 10/7/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspectorPane.h"

@class EOConnectionPane;

@interface EOModelAdaptorPane : EOInspectorPane
{
	IBOutlet NSTableView		*adaptorTable;
	IBOutlet NSBox				*connectionBox;
	IBOutlet NSView             *noneView;
	IBOutlet NSButton			*testButton;
	IBOutlet NSButton			*syncButton;
	
	EOConnectionPane			*connectionPane;
}

- (void)selectAdaptor:(id)sender;

- (void)testSettings:(id)sender;
- (void)syncAdaptor:(id)sender;

@end
