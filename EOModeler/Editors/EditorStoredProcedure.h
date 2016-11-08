//
//  EditorStoredProcedure.h
//  AJRDatabase
//
//  Created by Alex Raftis on Sat Sep 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "Editor.h"

@class EOAttribute;

@interface EditorStoredProcedure : Editor
{
	IBOutlet NSTableView		*procedureTable;

	id								editingObject;
	
	BOOL							needsToSetExternalTypes:1;
	BOOL							needsToSetValueClasses:1;
}

- (void)selectedArgument:(id)sender;
- (void)editArgument:(EOAttribute *)argument;

@end
