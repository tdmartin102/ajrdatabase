//
//  Document.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/22/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "Document.h"

#import "Additions.h"
#import "Controller.h"
#import "DataBrowser.h"
#import "EOInspectorPanel.h"
#import "EOModelWizard.h"
#import "EditorEntities.h"
#import "EditorEntity.h"
#import "EditorStoredProcedures.h"
#import "EditorStoredProcedure.h"
#import "EditorView.h"
#import "IconHeaderCell.h"
#import "ModelOutlineCell.h"
#import "NSTableView-ColumnVisibility.h"
#import "SQLGenerator.h"

#import <EOAccess/EOAccess.h>

#import <objc/message.h>
#import <objc/objc-class.h>

//#import <EOControl/NSArray+CocoaDevUsersAdditions.h>


NSString *DocumentSelectionDidChangeNotification = @"DocumentSelectionDidChangeNotification";
NSString *DocumentDidBecomeKeyNotification = @"DocumentDidBecomeKeyNotification";

NSString *StoredProcedures = @"Stored Procedures";

@interface EOModel (Private)

- (void)_setPath:(NSURL *)aPath;
- (void)_revert;

@end


@implementation Document

+ (Document *)currentDocument
{
	NSArray		*windows = [NSApp windows];
	int			x;
	
	// First, see if the key window is correct.
	if ([[[NSApp keyWindow] delegate] isKindOfClass:[Document class]]) {
		return (Document *)[[NSApp keyWindow] delegate];
	}
	
	// Nope, so just return any document attached to any window.
	for (x = 0; x < (const int)[windows count]; x++) {
		NSWindow		*aWindow = [windows objectAtIndex:x];
		
		if ([[aWindow delegate] isKindOfClass:[Document class]]) return (Document *)[aWindow delegate];
	}
	
	return nil;
}

- (instancetype)initWithPath:(NSString *)path createModel:(BOOL)createModel
{
	NSToolbar		*toolbar;
	NSString        *adaptorName;
    NSBundle        *bundle;
    NSArray         *anArray;

    self = [super init];
    if (! self)
        return nil;
	
	if (createModel) {
		EOModelWizard		*wizard = [[EOModelWizard alloc] init];
		model = [wizard run];
		if (model == nil) {
			self = nil;
			return nil;
		}
		untitled = YES;
		
		if (![[model name] hasPrefix:@"Untitled"]) {
			[model _setPath:[NSURL fileURLWithPath:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"SavePanelPath"] stringByAppendingPathComponent:[model name]] stringByAppendingPathExtension:@"eomodeld"]]];
		}
		
		path = [model path];
	} else {
		model = [[EOModelGroup defaultModelGroup] modelWithPath:path];
		if (!model) {
            NSAlert             *alert;
            alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Error"];
            [alert setInformativeText: [NSString stringWithFormat:@"Unable to open model %@", model]];
            [alert addButtonWithTitle: @"Okay"];
            [alert runModal];
            self = nil;
			return nil;
		}
		[model loadAllModelObjects];
	
		// And update our recent documents menu
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];
	}
	[model setUndoManager:[[NSUndoManager alloc] init]];

	adaptorName = [model adaptorName];
	AJRPrintf(@"adaptorName: %@\n", adaptorName);
	if (adaptorName && ![adaptorName isEqualToString:@"None"]) {
		adaptorClass = [[EOAdaptor adaptorWithModel:model] class];
	}
	
	// Make sure we're listening to changes in the model.
	[EOObserverCenter addObserver:self forObject:model];
	
	// Load the nib
    bundle = [NSBundle bundleForClass:[self class]];
    [bundle loadNibNamed:@"Document" owner:self topLevelObjects:&anArray];
    uiElements = anArray;

	// Select the initial editor.
	[editorView displayEditorNamed:@"Entities"];
	[[[modelOutline tableColumns] objectAtIndex:0] morphDataCellToClass:[ModelOutlineCell class]];

	// Create our toolbar
   toolbar = [[NSToolbar alloc] initWithIdentifier:@"Editor"];
   [toolbar setDelegate:self];
   [toolbar setAllowsUserCustomization:YES];
   [toolbar setAutosavesConfiguration:YES];
   [window setToolbar:toolbar];

	// If the inspector was previously open, go a head and open it.
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"InspectorOpen"] hasPrefix:@"Y"]) {
		[self showInspector:self];
	}
	
	// Make sure the outline view, which always has a single root item, is expands the root item.
	[modelOutline expandItem:[modelOutline itemAtRow:0]];
	[modelOutline expandItem:StoredProcedures];
	[modelOutline setIndentationPerLevel:15.0];
	
	// Set the window title and display the window.
	[window setTitleWithRepresentedFilename:path];
	[window setDocumentEdited:untitled];
	[window makeKeyAndOrderFront:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateModelTable) name:EOModelDidChangeNameNotification object:model];
	// Listen for our own object changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectDidChange:) name:@"ObjectDidChange" object:self];
	
	[self setSelectedObject:model];
    
	return self;
}

- (instancetype)init
{
	self = [self initWithPath:nil createModel:YES];
	
	return self;
}

- (instancetype)initWithPath:(NSString *)aPath
{
	return [self initWithPath:aPath createModel:NO];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_updateModelTable
{
	id              item = [modelOutline itemAtRow:[modelOutline selectedRow]];
	NSUInteger		index;
	
	[modelOutline reloadData];
	
	index = [modelOutline rowForItem:item];
    [modelOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];

	[self selectModel:modelOutline selectObject:NO];
}

- (EOModel *)model
{
	return model;
}

- (EOEntity *)selectedEntity
{
	return selectedEntity;
}

- (EOStoredProcedure *)selectedStoredProcedure
{
	return selectedStoredProcedure;
}

- (void)selectModel:(id)sender selectObject:(BOOL)selectObject
{
	NSInteger		row = [sender selectedRow];
	
	if (row != NSNotFound) {
		id			item = [sender itemAtRow:row];

		if ([item isKindOfClass:[EOModel class]]) {
			[editorView displayEditorNamed:@"Entities"];
			[self setSelectedEntity:nil];
			[self setSelectedStoredProcedure:nil];
		} else if ([item isKindOfClass:[EOEntity class]]) {
			[editorView displayEditorNamed:@"Entity"];
			[self setSelectedEntity:item];
			[self setSelectedStoredProcedure:nil];
		} else if ([item isKindOfClass:[EORelationship class]]) {
			[editorView displayEditorNamed:@"Entity"];
			[self setSelectedEntity:(EOEntity *)[item destinationEntity]];
			[self setSelectedStoredProcedure:nil];
		} else if ([item isKindOfClass:[NSString class]] && [item isEqualToString:StoredProcedures]) {
			[editorView displayEditorNamed:StoredProcedures];
			[self setSelectedEntity:nil];
			[self setSelectedStoredProcedure:nil];
		} else if ([item isKindOfClass:[EOStoredProcedure class]]) {
			[editorView displayEditorNamed:@"Stored Procedure"];
			[self setSelectedEntity:nil];
			[self setSelectedStoredProcedure:item];
		} else if ([item isKindOfClass:[EOFetchSpecification class]]) {
			[editorView displayEditorNamed:@"Fetch Specification"];
			[self setSelectedEntity:(EOEntity *)[item entity]];
			[self setSelectedStoredProcedure:nil];
		}
		
		if (selectObject) [self setSelectedObject:item];
	}
}

- (void)selectModel:(id)sender
{
	[self selectModel:sender selectObject:YES];
}

- (void)objectWillChange:(id)object
{
	static NSArray		*modes = nil;
	
	if (modes == nil) {
		modes = [[NSArray alloc] initWithObjects:NSDefaultRunLoopMode, nil];
	}
	
	[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:@"ObjectDidChange" object:self userInfo:[NSDictionary dictionaryWithObject:object forKey:@"object"]] postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender forModes:modes];

	if (([object isKindOfClass:[EOJoin class]] && [[self selectedObject] isKindOfClass:[EORelationship class]] && [[[self selectedObject] joins] containsObject:object]) || ([self selectedObject] == object)) {
		// This'll get the inspector updating the change.
		[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:DocumentSelectionDidChangeNotification  object:self userInfo:[NSDictionary dictionaryWithObject:selectedObject forKey:@"object"]] postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender forModes:modes];
	}

	if ([object isKindOfClass:[EOModel class]]) {
		//AJRPrintf(@"Schedule update in %@\n", modelOutline);
		[[NSNotificationQueue defaultQueue] enqueueNotification:[NSNotification notificationWithName:DocumentSelectionDidChangeNotification  object:self userInfo:[NSDictionary dictionaryWithObject:selectedObject forKey:@"object"]] postingStyle:NSPostWhenIdle coalesceMask:NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender forModes:modes];
	}

	// Give the editors a chance to anticipate the object change
	[editorView objectWillChange:object];
}

- (void)objectDidChange:(NSNotification *)notification
{
	id		object = [[notification userInfo] objectForKey:@"object"];
	
	//AJRPrintf(@"change (Document): %@\n", object);
	[window setDocumentEdited:[[model undoManager] canUndo]];
	[editorView objectDidChange:object];

	if ([object isKindOfClass:[EOModel class]]) {
		//AJRPrintf(@"Schedule update in %@\n", modelOutline);
		[self _updateModelTable];
	}
}

- (BOOL)selectedObjectIsKindOfClass:(Class)aClass
{
	id			object = [self selectedObject];
	
	if ([object isKindOfClass:[NSArray class]]) {
		return [[object lastObject] isKindOfClass:aClass];
	}
	
	return [object isKindOfClass:aClass];
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)item
{
	switch ([item tag]) {
		// File menu
		case 1004:		// save
			return YES;
		case 1005:		// save as
			return YES;
		case 1006:		// revert
			return [window isDocumentEdited];
			
		// Edit menu
		case 2001:		// undo
			return [[model undoManager] canUndo];
		case 2002:		// redo
			return [[model undoManager] canRedo];
			
		// Property menu
		case 3001:		// Add Entity
			return YES;
		case 3002:		// Add Attribute
			return selectedEntity != nil;
		case 3003:		// Add Relationship
			return selectedEntity != nil;
		case 3004:		// Add Fetch Specification
			return selectedEntity != nil;
		case 3005:		// Add Stored Procedure
			return YES;
		case 3006:		// Add Argument
			return selectedStoredProcedure != nil;
		case 3007:		// Create Subclass
			return NO;
		case 3008:		// Join in Many-to-Manu
			return NO;
		case 3009:		// Flatten relationship
			return [selectedObject isKindOfClass:[EORelationship class]] && [modelOutline levelForRow:[modelOutline selectedRow]] >= 3;
		case 3010:		// Generate SQL
			return [self selectedObjectIsKindOfClass:[EOEntity class]] || [self selectedObjectIsKindOfClass:[EOModel class]];
		case 3011:		// Generate Obj-C Files
			return [self selectedObjectIsKindOfClass:[EOEntity class]] || [self selectedObjectIsKindOfClass:[EOModel class]];
	}

	return NO;
}

- (void)setSelectedEntity:(EOEntity *)entity
{
	if (entity != selectedEntity) {
		selectedEntity = entity;
		
		[editorView update];
	}
}

- (void)setSelectedStoredProcedure:(EOStoredProcedure *)aStoredProcedure
{
	if (aStoredProcedure != selectedStoredProcedure) {
		selectedStoredProcedure = aStoredProcedure;
		
		[editorView update];
	}
}

- (id)selectedObject
{
	return selectedObject;
}

- (void)setSelectedObject:(id)anObject
{
	if (selectedObject != anObject) {
		selectedObject = anObject;
		
		if (selectedObject == nil) {
			NSInteger		row = [modelOutline selectedRow];
			
			if (row != NSNotFound) {
				selectedObject = [modelOutline itemAtRow:row];
			}
		}
        
        if (selectedObject)
            [[NSNotificationCenter defaultCenter] postNotificationName:DocumentSelectionDidChangeNotification object:self
                                                              userInfo:@{@"object" : selectedObject}];
		
		[[window toolbar] validateVisibleItems];
	}
}

- (void)revertDocumentToSaved:(id)sender
{
	[model _revert];
	[window setDocumentEdited:NO];
	[modelOutline reloadData];
	[modelOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[self selectModel:modelOutline];
}

- (void)undoEdit:(id)sender
{
	if (![window makeFirstResponder:window]) [window endEditingFor:nil];
	[[model undoManager] undo];
	[window setDocumentEdited:[[model undoManager] canUndo]];
}

- (void)redoEdit:(id)sender
{
	if (![window makeFirstResponder:window]) [window endEditingFor:nil];
	[[model undoManager] redo];
	[window setDocumentEdited:[[model undoManager] canUndo]];
}

- (void)showDatabaseBrowser:(id)sender
{
    DataBrowser *d;
	d = [[DataBrowser alloc] initWithModel:model];
    [d self];
}

- (void)generateSQL:(id)sender
{
	NSArray		*entities = [model entities];
	
	if ([self selectedObjectIsKindOfClass:[EOEntity class]]) {
		entities = [self selectedObject];
		if ([entities isKindOfClass:[EOEntity class]]) entities = [NSArray arrayWithObject:entities];
	}
	[(SQLGenerator *)[[SQLGenerator alloc] initWithModel:model entities:entities] run];
}

- (void)generateObjCFromEntities:(NSArray *)entities at:(NSString *)outputPath
{
	int			x;
	BOOL			done = NO;
	
	for (x = 0; x < (const int)[entities count]; x++) {
		EOEntity		*entity = [entities objectAtIndex:x];
		NSString		*className = [entity className];
		NSString		*implementationFile;
		NSString		*interfaceFile;
		NSString		*implementation;
		NSString		*interface;
		
		if ([className isEqualToString:@"EOGenericRecord"] || [className isEqualToString:@"EOGenericRecord"]) continue;

		implementationFile = [[outputPath stringByAppendingPathComponent:className] stringByAppendingPathExtension:@"m"];
		interfaceFile = [[outputPath stringByAppendingPathComponent:className] stringByAppendingPathExtension:@"h"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:implementationFile] || 
			 [[NSFileManager defaultManager] fileExistsAtPath:interfaceFile]) {
			switch (NSRunAlertPanel(@"Objective-C class files already exist", @"Would you like to overwrite %@.[hm]?", @"No", @"Yes", @"Cancel", className)) {
				case NSOKButton: 
					continue;
				case NSAlertAlternateReturn: 
					break;
				case NSAlertOtherReturn:
					done = YES;
					break;
			}
		}

		if (done) break;
		
		implementation = [entity objectiveCImplementation];
		interface = [entity objectiveCInterface];
		
        if (![implementation writeToFile:implementationFile atomically:YES 
                                    encoding:NSUTF8StringEncoding error:NULL]) {

			if (NSRunAlertPanel(@"Error writing Objective-C implementation", @"Unable to write to file: %@: %s", @"Continue", @"Cancel", nil, implementationFile, strerror(errno)) == NSOKButton) {
				continue;
			} else {
				break;
			}
		}
		
		if (![interface writeToFile:interfaceFile atomically:YES 
                           encoding:NSUTF8StringEncoding error:NULL]) {
			if (NSRunAlertPanel(@"Error writing Objective-C interface", @"Unable to write to file: %@: %s", @"Continue", @"Cancel", nil, implementationFile, strerror(errno)) == NSOKButton) {
				continue;
			} else {
				break;
			}
		}
	}
}

- (void)generateObjCFiles:(id)sender
{
	NSOpenPanel		*openPanel = [NSOpenPanel openPanel];
	
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    openPanel.canCreateDirectories = YES;
    openPanel.prompt = @"Choose";
    openPanel.directoryURL = [NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] objectForKey:@"OpenPanelPath"]];
    openPanel.delegate = self;
    
    [openPanel beginSheet:window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSOKButton) {
            NSArray		*entities;
            
            [[NSUserDefaults standardUserDefaults] setObject:openPanel.directoryURL.path forKey:@"OpenPanelPath"];
            
            if ([selectedObject isKindOfClass:[NSArray class]]) {
                entities = [selectedObject copy];
            } else if ([selectedObject isKindOfClass:[EOModel class]]) {
                entities = [[selectedObject entities] copy];
            } else {
                entities = [NSArray arrayWithObject:selectedObject] ;
            }
            
            [self generateObjCFromEntities:entities at:openPanel.directoryURL.path];
        }
    }];
}

- (void)newEntity:(id)sender
{
	EOEntity			*entity;
	NSString			*name;
	int				count = 1;
	
	entity = [[EOEntity alloc] init];
	
	name = @"Entity";
	while ([model entityNamed:name]) {
		name = [NSString stringWithFormat:@"Entity%d", count++];
	}
	
	[entity setName:name];
	[model addEntity:entity];
	
	[modelOutline reloadData];
	[modelOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[self selectModel:modelOutline];
	[[editorView currentEditor] performSelector:@selector(editEntity:) withObject:entity afterDelay:0.01];
}

- (void)newAttribute:(id)sender
{
	EOEntity				*entity = [self selectedEntity];
	EOStoredProcedure	*storedProcedure = [self selectedStoredProcedure];
	
	if (entity) {
		EOAttribute		*attribute;
		NSString			*name;
		int				count = 1;
		NSMutableArray	*temp;
		
		attribute = [[EOAttribute alloc] init];
		name = @"attribute";
		while ([entity attributeNamed:name]) {
			name = [NSString stringWithFormat:@"attribute%d", count++];
		}
		[attribute setName:name];
		[attribute setAllowsNull:YES];
		[entity addAttribute:attribute];
		
		temp = [[entity attributesUsedForLocking] mutableCopy];
		[temp addObject:attribute];
		[entity setAttributesUsedForLocking:temp];
		
		temp = [[entity classProperties] mutableCopy];
		[temp addObject:attribute];
		[entity setClassProperties:temp];
		
        [modelOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:[modelOutline rowForItem:entity]] byExtendingSelection:NO];
		[editorView displayEditorNamed:@"Entity"];
		[[editorView currentEditor] performSelector:@selector(editAttribute:) withObject:attribute afterDelay:0.01];
	} else if (storedProcedure) {
		EOAttribute		*argument;
		
		argument = [[EOAttribute alloc] init];
		[argument setName:@"argument"];
		[argument setAllowsNull:YES];
		[argument setParameterDirection:EOInParameter];
		[storedProcedure addArgument:argument];
        
        [modelOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:
                                        [modelOutline rowForItem:storedProcedure]] 
                                                byExtendingSelection:NO];
		[editorView displayEditorNamed:@"Stored Procedure"];
		[[editorView currentEditor] performSelector:@selector(editArgument:) withObject:argument afterDelay:0.01];
	} else {
		NSBeep();
	}
}

- (void)newRelationship:(id)sender
{
	EOEntity		*entity = [self selectedEntity];
	
	if (entity) {
		EORelationship		*relationship;
		NSString				*name;
		int					count = 1;
		NSMutableArray		*temp;
		
		relationship = [[EORelationship alloc] init];
		name = @"relationship";
		while ([entity relationshipNamed:name]) {
			name = [NSString stringWithFormat:@"relationship%d", count++];
		}
		[relationship setName:name];
		[entity addRelationship:relationship];
		
		temp = [[entity classProperties] mutableCopy];
		[temp addObject:relationship];
		[entity setClassProperties:temp];
        
        [modelOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:[modelOutline rowForItem:entity]]
                byExtendingSelection:NO];
		[editorView displayEditorNamed:@"Entity"];
		[[editorView currentEditor] performSelector:@selector(editRelationship:) withObject:relationship afterDelay:0.01];
	} else {
		NSBeep();
	}
}

- (void)newFetchSpecification:(id)sender
{
}

- (void)flattenRelationship:(id)sender
{
	EORelationship		*relationship = [modelOutline itemAtRow:[modelOutline selectedRow]];
	NSMutableArray		*array = [NSMutableArray arrayWithObject:relationship];
	id						object;
	NSString				*definition;
	NSString				*name;
	int					count = 1;
	
	
	object = relationship;
	while ([object = [modelOutline parentForItem:object] isKindOfClass:[EORelationship class]]) {
		[array insertObject:object atIndex:0];
	}

	definition = [[array valueForKey:@"name"] componentsJoinedByString:@"."];

	relationship = [[EORelationship allocWithZone:[object zone]] init];
	name = [[array valueForKey:@"name"] componentsJoinedByString:@"_"];
	while ([object relationshipNamed:name]) {
		name = [NSString stringWithFormat:@"%@%d", [[array valueForKey:@"name"] componentsJoinedByString:@"_"], count++];
	}
	[relationship setName:name];
	[relationship setDefinition:definition];
	[object addRelationship:relationship];
	
	array = [[object classProperties] mutableCopy];
	[array addObject:relationship];
	[object setClassProperties:array];
    
    [modelOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:[modelOutline rowForItem:object]]
              byExtendingSelection:NO];
	[self selectModel:modelOutline];
	[[editorView currentEditor] performSelector:@selector(editRelationship:) withObject:relationship afterDelay:0.01];
}

- (void)newStoredProcedure:(id)sender
{
	EOStoredProcedure	*storedProcedure;
	NSString				*name;
	int					count = 1;
	
	storedProcedure = [[EOStoredProcedure alloc] init];
	
	name = @"StoredProcedure";
	while ([model storedProcedureNamed:name]) {
		name = [NSString stringWithFormat:@"StoredProcedure%d", count++];
	}
	
	[storedProcedure setName:name];
	[model addStoredProcedure:storedProcedure];
	
	[modelOutline reloadData];
	[modelOutline selectRowIndexes:
        [NSIndexSet indexSetWithIndex:[modelOutline rowForItem:StoredProcedures]] 
        byExtendingSelection:NO];
	[self selectModel:modelOutline];
	[[editorView currentEditor] performSelector:@selector(editStoredProcedure:) withObject:storedProcedure afterDelay:0.01];
}

- (Class)adaptorClass
{
	return adaptorClass;
}

- (void)deleteSelection:(id)sender
{
	if ([[window firstResponder] isKindOfClass:[NSTextView class]]) {
		[NSApp sendAction:@selector(delete:) to:nil from:sender];
	} else {
		[editorView deleteSelection:self];
	}
}

- (BOOL)processKeyDown:(NSEvent *)event
{
	if ([event type] == NSKeyDown) {
		unichar	character = [[event characters] characterAtIndex:0];
		
		if (character == NSDeleteCharacter || character == NSDeleteCharFunctionKey || character == NSDeleteFunctionKey) {
			[self deleteSelection:self];
			return YES;
		}
	}
	
	return NO;
}

- (void)_documentSaveCallbackHandler:(DocumentSaveCallback)callback returnCode:(int)returnCode
{
    switch (callback)
    {
        case NoCallback:
            break;
        case TerminateCallback:
            [self terminateWithResponse:returnCode];
            break;
        case CloseCallback:
            [self closeWithResponse:returnCode];
            break;
    }
}

- (void)saveDocumentPromptingForName:(BOOL)promptForName callback:(DocumentSaveCallback)callback
{
	if (promptForName || untitled) {
		NSSavePanel		*savePanel = [NSSavePanel savePanel];
		NSString		*savePath;
		
        savePanel.allowedFileTypes = @[@"eomodeld"];
		
		savePath = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavePanelPath"];
		if (savePath == nil) savePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
		
		[savePanel setCanSelectHiddenExtension:YES];
        savePanel.directoryURL = [NSURL fileURLWithPath:savePath];
        savePanel.nameFieldStringValue = [[model path] lastPathComponent];
        savePanel.delegate = self;
        
        [savePanel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                NSException		*exception = nil;
                
                [[NSUserDefaults standardUserDefaults] setObject:savePanel.directoryURL.path forKey:@"SavePanelPath"];
                
                @try {
                    [model writeToFile:savePanel.URL.path];
                    [window setTitleWithRepresentedFilename:[model path]];
                    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:[model path]]];
                    [window setDocumentEdited:NO];
                    untitled = NO;

                } @catch (NSException *oops) {
                    exception = oops;
                }
                
                if (exception) {
                    NSRunAlertPanel(@"Error", @"Unable to save model: %@", nil, nil, nil, exception);
                }
                if (callback) {
                    if (exception == nil)
                        [self _documentSaveCallbackHandler:callback returnCode:DocumentDidSave];
                    else
                        [self _documentSaveCallbackHandler:callback returnCode:DocumentDidFail];
                }
            } else {
                if (callback)
                    [self _documentSaveCallbackHandler:callback returnCode:DocumentDidCancel];
            }
        }];
	} else {
		[model writeToFile:[model path]];
		[window setDocumentEdited:NO];
	}
}

- (void)saveDocumentAs:(id)sender
{
	[self saveDocumentPromptingForName:YES callback:NoCallback];
}

- (void)saveDocument:(id)sender
{
	[self saveDocumentPromptingForName:NO callback:NoCallback];
}

- (void)willEndCloseSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(DocumentSaveCallback)callback
{
	if (returnCode == NSAlertSecondButtonReturn) {
		// Don't save
		[window close];
		if (callback)
            [self _documentSaveCallbackHandler:(DocumentSaveCallback)callback returnCode:DocumentDidDiscard];
	}
}

- (void)didEndCloseSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(DocumentSaveCallback)callback
{
	if (returnCode == NSAlertFirstButtonReturn) {
		// Save
		[self saveDocumentPromptingForName:NO callback:callback];
	} else if (returnCode == NSAlertThirdButtonReturn) {
		// Cancel
		if (callback)
            [self _documentSaveCallbackHandler:(DocumentSaveCallback)callback returnCode:DocumentDidCancel];
	}
}

- (void)closeWithResponse:(DocumentSaveResponse)response
{
	switch (response) {
		case DocumentDidSave:
		case DocumentDidDiscard:
			// The document was saved, or the user decided to discard the changes, so close the window, which, will also cause us to be freed.
			[window close];
			break;
		case DocumentDidFail:
		case DocumentDidCancel:
			// The user either cancelled the close or the save failed, in which case we should allow them to make another attempt.
			break;
	}
}

- (void)promptForWindowShouldCloseWithCallback:(DocumentSaveCallback)callback
{
    NSAlert *alert;
    alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Do you want to save changes to this document before closing?"];
    [alert setInformativeText:@"If you don't save, your changes will be lost."];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Don't Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setDelegate:self];

    [alert beginSheetModalForWindow:window
                  completionHandler:^(NSModalResponse returnCode){
                      [self _documentSaveCallbackHandler:callback returnCode:(int)returnCode];
                      [self didEndCloseSheet:window returnCode:(int)returnCode contextInfo:callback];
                  }];
}

- (BOOL)windowShouldClose:(id)sender
{
	if ([window isDocumentEdited]) {
		[self promptForWindowShouldCloseWithCallback:CloseCallback];
		return NO;
	}
	
	return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[window setDelegate:nil];
	window = nil;
    editorView = nil;
    modelOutline = nil;
    // should we be releasing ourself?  seems awkward, plus there is no real way to do that in ARC
    // self = nil;
    // [self release];
    uiElements = nil;
    [(Controller *)[NSApp delegate] closeDocument:self];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:DocumentDidBecomeKeyNotification object:self];
}

- (void)windowDidResignKey:(NSNotification *)aNotification
{
	if (![window makeFirstResponder:window]) [window endEditingFor:nil];
}

- (void)windowDidResignMain:(NSNotification *)aNotification
{
	if (![window makeFirstResponder:window]) [window endEditingFor:nil];
}

- (BOOL)isDocumentEdited
{
	return [window isDocumentEdited];
}

- (void)terminateWithResponse:(DocumentSaveResponse)response
{
	switch (response) {
		case DocumentDidSave:
		case DocumentDidDiscard:
			// The document was saved, or the user decided to discard the changes, so close the window, which, will also cause us to be freed.
			[window close];
			// Also, continue the search for the next document to attempt to save.
			[Document reviewEditedDocuments];
			break;
		case DocumentDidFail:
		case DocumentDidCancel:
			// Let the application know that we've stopped the termination.
			[NSApp replyToApplicationShouldTerminate:NO];
			break;
	}
}

+ (void)reviewEditedDocuments
{
    NSWindow		*aWindow;
    
    for (aWindow in [NSApp windows]) {
        Document		*document = (Document *)[aWindow delegate];
		
		if ([document isKindOfClass:[Document class]] && [document isDocumentEdited]) {
			[document promptForWindowShouldCloseWithCallback:TerminateCallback];
			return;
		}
	}
	
	// If we reach this point, there's not documents left to try and save, so report that it's OK to terminate the applications.
	[NSApp replyToApplicationShouldTerminate:YES];
}

- (void)refreshEntityNames
{
	entityNameCache = nil;
}

- (NSArray *)possibleEntityNames
{
	if (entityNameCache == nil) {
        @try {
            EOAdaptor			*adaptor = [EOAdaptor adaptorWithModel:model];
            EOAdaptorContext	*context = [adaptor createAdaptorContext];
            EOAdaptorChannel	*channel;
            NSArray             *tempArray;
            
            channel = [[context channels] lastObject];
            if (!channel)
                channel = [context createAdaptorChannel];
            
            if (![channel isOpen])
                [channel openChannel];
            tempArray = [[channel describeTableNames] mutableCopy];
            // sort them
            entityNameCache = [tempArray sortedArrayUsingSelector:@selector(compare:)];
        } @catch (NSException *exception) {
            AJRPrintf(@"Exception during entity name fetch: %@\n", exception);
            entityNameCache = [[NSArray alloc] init];
        }
    }
	
	return entityNameCache;
}

- (EOEntity *)entityWithExternalName:(NSString *)aName
{
    EOEntity	*entity;
    
    for (entity in [model entities]) {
        if ([[entity externalName] caseInsensitiveCompare:aName] == NSOrderedSame) {
            return entity;
        }
    }
    
	return nil;
}

- (void)addEntityWithTableName:(NSString *)aName
{
	EOAdaptor			*adaptor = [EOAdaptor adaptorWithModel:model];
	EOAdaptorContext	*context = [adaptor createAdaptorContext];
	EOAdaptorChannel	*channel;
	EOModel				*tempModel;
	NSArray				*entities;
    EOEntity            *entity;
    
	channel = [[context channels] lastObject];
	if (!channel) channel = [context createAdaptorChannel];
	
	if (![channel isOpen]) [channel openChannel];
	tempModel = [channel describeModelWithTableNames:[NSArray arrayWithObject:aName]];
	
	entities = [[tempModel entities] copy];
    for (entity in entities) {
        [tempModel removeEntity:entity];
        [entity setClassName:[entity name]];
        [model addEntity:entity];
    }
}

@end
