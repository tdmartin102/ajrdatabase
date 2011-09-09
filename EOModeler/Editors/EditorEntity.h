//
//  EditorEntity.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/24/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "Editor.h"

@class EOAttribute, EORelationship;

@interface EditorEntity : Editor
{
	IBOutlet NSTextField		*entityAttributesText;
	IBOutlet NSTextField		*entityRelationshipsText;
	IBOutlet NSTableView		*entityAttributesTable;
	IBOutlet NSTableView		*entityRelationshipsTable;

	id								editingObject;

	BOOL							needsToSetExternalTypes:1;
	BOOL							needsToSetValueClasses:1;
}

- (void)editAttribute:(EOAttribute *)attribute;
- (void)editRelationship:(EORelationship *)relationship;

- (void)selectAttribute:(id)sender;
- (void)selectRelationship:(id)sender;

@end
