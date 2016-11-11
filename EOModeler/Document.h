//
//  Document.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/22/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <EOControl/EOControl.h>

@class EOModel, EOEntity, EOStoredProcedure, EditorView;
@class DataBrowser;
@class SQLGenerator;

extern NSString *DocumentSelectionDidChangeNotification;
extern NSString *DocumentDidBecomeKeyNotification;

extern NSString *StoredProcedures;

typedef enum _documentSaveResponse {
	DocumentDidSave = 0,
	DocumentDidCancel = 1,
	DocumentDidDiscard = 2,
	DocumentDidFail = 3
} DocumentSaveResponse;

typedef enum _documentSaveCallback {
    NoCallback = 0,
    TerminateCallback = 1,
    CloseCallback = 2
} DocumentSaveCallback;

@interface Document : NSObject <EOObserving, NSToolbarDelegate, NSOpenSavePanelDelegate, NSAlertDelegate>
{
	IBOutlet	NSWindow        *window;
	IBOutlet    NSOutlineView	*modelOutline;
	IBOutlet    EditorView		*editorView;
	
	EOModel						*model;
	Class						adaptorClass;
	EOEntity					*selectedEntity;
	EOStoredProcedure			*selectedStoredProcedure;
	id							selectedObject;
	
	NSArray						*entityNameCache;
	
	BOOL						untitled:1;
    NSArray                     *uiElements;
    DataBrowser                 *dataBrowser;
    SQLGenerator                *sqlGenerator;
}

+ (Document *)currentDocument;

- (instancetype)initWithPath:(NSString *)aPath;

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

- (IBAction)showDatabaseBrowser:(id)sender;
- (IBAction)generateObjCFiles:(id)sender;
- (IBAction)generateSQL:(id)sender;
- (IBAction)newEntity:(id)sender;
- (IBAction)newAttribute:(id)sender;
- (IBAction)newRelationship:(id)sender;
- (IBAction)newFetchSpecification:(id)sender;
- (IBAction)flattenRelationship:(id)sender;
- (IBAction)newStoredProcedure:(id)sender;

@end


@interface Document (OutlineView)

@end


@interface Document (Toolbar)

@end
