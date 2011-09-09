//
//  EditorStoredProcedures.h
//  AJRDatabase
//
//  Created by Alex Raftis on Sat Sep 25 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "Editor.h"

@interface EditorStoredProcedures : Editor
{
	IBOutlet NSTableView		*proceduresTable;
	id								editingObject;
}

- (void)selectStoredProcedure:(id)sender;

- (void)editStoredProcedure:(EOStoredProcedure *)storedProcedure;

@end
