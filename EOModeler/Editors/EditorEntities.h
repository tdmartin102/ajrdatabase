//
//  EditorEntities.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "Editor.h"

@class EOEntity;

@interface EditorEntities : Editor
{
	IBOutlet NSTableView		*entityTable;
}

- (void)selectEntity:(id)sender;

- (void)editEntity:(EOEntity *)entity;

@end
