//
//  Document.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/22/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <EOControl/EOControl.h>

@class EOModel, EOEntity, EOStoredProcedure, EditorView;

extern NSString *DocumentSelectionDidChangeNotification;
extern NSString *DocumentDidBecomeKeyNotification;

extern NSString *StoredProcedures;

typedef enum _documentSaveResponse {
	DocumentDidSave = 0,
	DocumentDidCancel = 1,
	DocumentDidDiscard = 2,
	DocumentDidFail = 3
} DocumentSaveResponse;

@interface Document : NSObject <EOObserving>
{
	IBOutlet	NSWindow			*window;
	IBOutlet NSOutlineView	*modelOutline;
	IBOutlet EditorView		*editorView;
	
	EOModel						*model;
	Class							adaptorClass;
	EOEntity						*selectedEntity;
	EOStoredProcedure			*selectedStoredProcedure;
	id								selectedObject;
	
	NSArray						*entityNameCache;
	
	BOOL							untitled:1;
}

+ (Document *)currentDocument;

- (id)initWithPath:(NSString *)aPath;

- (EOModel *)model;
- (EOEntity *)selectedEntity;
- (EOStoredProcedure *)selectedStoredProcedure;

- (void)selectModel:(id)sender selectObject:(BOOL)selectObject;
- (void)selectModel:(id)sender;
- (void)deleteSelection:(id)sender;

- (void)setSelectedEntity:(EOEntity *)anEntity;
- (void)setSelectedStoredProcedure:(EOStoredProcedure *)aStoredProcedure;
- (id)selectedObject;
- (void)setSelectedObject:(id)anObject;
- (BOOL)selectedObjectIsKindOfClass:(Class)aClass;

- (Class)adaptorClass;

- (BOOL)isDocumentEdited;
+ (void)reviewEditedDocuments;

- (void)refreshEntityNames;
- (NSArray *)possibleEntityNames;
- (EOEntity *)entityWithExternalName:(NSString *)aName;
- (void)addEntityWithTableName:(NSString *)aName;

@end


@interface Document (OutlineView)

@end


@interface Document (Toolbar)

@end
