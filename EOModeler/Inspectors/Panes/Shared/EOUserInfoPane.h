//
//  EOUserInfoPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspectorPane.h"

@interface EOUserInfoPane : EOInspectorPane
{
	IBOutlet NSTableView		*keyValueTable;
	IBOutlet NSTextView		*valueText;
	IBOutlet NSButton			*removeButton;
	IBOutlet NSButton			*addButton;

	NSMutableArray				*keys;
	NSMutableDictionary		*info;
	
	NSString						*editKey;
	
	BOOL							ignoreEdit;
}

- (void)selectRow:(id)sender;
- (void)add:(id)sender;
- (void)remove:(id)sender;

@end
