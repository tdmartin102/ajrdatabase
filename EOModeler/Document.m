//
//  Document.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/22/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "Document.h"

#import "DataBrowser.h"
#import "EOInspectorPanel.h"
#import "EOModelWizard.h"
#import "EditorEntities.h"
#import "EditorView.h"
#import "IconHeaderCell.h"
#import "ModelOutlineCell.h"
#import "NSOutlineView-Extensions.h"
#import "NSTableView-ColumnVisibility.h"
#import "SQLGenerator.h"

#import <EOAccess/EOAccess.h>
#import <EOControl/NSArray+CocoaDevUsersAdditions.h>


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
		return [[NSApp keyWindow] delegate];
	}
	
	// Nope, so just return any document attached to any window.
	for (x = 0; x < (const int)[windows count]; x++) {
		NSWindow		*aWindow = [windows objectAtIndex:x];
		
		if ([[aWindow delegate] isKindOfClass:[Document class]]) return [aWindow delegate];
	}
	
	return nil;
}

- (id)initWithPath:(NSString *)path createModel:(BOOL)createModel
{
	NSToolbar		*toolbar;
	NSString			*adaptorName;
	
	[super init];
	
	if (createModel) {
		EOModelWizard		*wizard = [[EOModelWizard alloc] init];
		model = [[wizard run] retain];
		if (model == nil) {
			[self release];
			return nil;
		}
		untitled = YES;
		
		if (![[model name] hasPrefix:@"Untitled"]) {
			[model _setPath:[NSURL fileURLWithPath:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"SavePanelPath"] stringByAppendingPathComponent:[model name]] stringByAppendingPathExtension:@"eomodeld"]]];
		}
		
		path = [model path];
	} else {
		model = [[[EOModelGroup defaultModelGroup] modelWithPath:path] retain];
		if (!model) {
			NSRunAlertPanel(@"Error", @"Unable to open model %@", nil, nil, nil, model);
			[self release];
			return nil;
		}
		[model loadAllModelObjects];
	
		// And update our recent documents menu
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];
	}
	[model setUndoManager:[[[NSUndoManager allocWithZone:[self zone]] init] autorelease]];

	adaptorName = [model adaptorName];
	AJRPrintf(@"adaptorName: %@\n", adaptorName);
	if (adaptorName && ![adaptorName isEqualToString:@"None"]) {
		adaptorClass = [[EOAdaptor adaptorWithModel:model] class];
	}
	
	// Make sure we're listening to changes in the model.
	[EOObserverCenter addObserver:self forObject:model];
	
	// Load the nib
	[NSBundle loadNibNamed:@"Document" owner:self];
	
	// Select the initial editor.
	[editorView displayEditorNamed:@"Entities"];
	[[[modelOutline tableColumns] objectAtIndex:0] morphDataCellToClass:[ModelOutlineCell class]];

	// Create our toolbar
   toolbar = [[NSToolbar allocWithZone:[self zone]] initWithIdentifier:@"Editor"];
   [toolbar setDelegate:self];
   [toolbar setAllowsUserCustomization:YES];
   [toolbar setAutosavesConfiguration:YES];
   [window setToolbar:toolbar];
   [toolbar release];

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

- (id)init
{
	[self initWithPath:nil createModel:YES];
	
	return self;
}

- (id)initWithPath:(NSString *)aPath
{
	return [self initWithPath:aPath createModel:NO];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[selectedEntity release];
	[selectedStoredProcedure release];
	[entityNameCache release];
	
	[super dealloc];
}

- (void)_updateModelTable
{
	id			item = [modelOutline itemAtRow:[modelOutline selectedRow]];
	int		index;
	
	[modelOutline reloadData];
	
	index = [modelOutline rowForItem:item];
	[modelOutline selectRow:index byExtendingSelection:NO];
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
	int		row = [sender selectedRow];
	
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

	if (([object isKindOfClass:[EOJoin class]] && [[self selectedObject] isKindOfClass:[EORelationship class]] && [[[self selectedObject] joins] containsObjectIdenticalTo:object]) || ([self selectedObject] == object)) {
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

- (BOOL)validateMenuItem:(id <NSMenuItem>)item
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
		[selectedEntity release];
		selectedEntity = [entity retain];
		
		[editorView update];
	}
}

- (void)setSelectedStoredProcedure:(EOStoredProcedure *)aStoredProcedure
{
	if (aStoredProcedure != selectedStoredProcedure) {
		[selectedStoredProcedure release];
		selectedStoredProcedure = [aStoredProcedure retain];
		
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
		[selectedObject release];
		selectedObject = [anObject retain];
		
		if (selectedObject == nil) {
			int		row = [modelOutline selectedRow];
			
			if (row != NSNotFound) {
				selectedObject = [[modelOutline itemAtRow:row] retain];
			}
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DocumentSelectionDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObject:selectedObject forKey:@"object"]];
		
		[[window toolbar] validateVisibleItems];
	}
}

- (void)revertDocumentToSaved:(id)sender
{
	[model _revert];
	[window setDocumentEdited:NO];
	[modelOutline reloadData];
	[modelOutline selectRow:0 byExtendingSelection:NO];
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
	[[DataBrowser alloc] initWithModel:model];
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
		
		if (![implementation writeToFile:implementationFile atomically:YES]) {
			if (NSRunAlertPanel(@"Error writing Objective-C implementation", @"Unable to write to file: %@: %s", @"Continue", @"Cancel", nil, implementationFile, strerror(errno)) == NSOKButton) {
				continue;
			} else {
				break;
			}
		}
		
		if (![interface writeToFile:interfaceFile atomically:YES]) {
			if (NSRunAlertPanel(@"Error writing Objective-C interface", @"Unable to write to file: %@: %s", @"Continue", @"Cancel", nil, implementationFile, strerror(errno)) == NSOKButton) {
				continue;
			} else {
				break;
			}
		}
	}
	
	[entities release];
}

- (void)generateObjCPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)info
{
	if (returnCode == NSOKButton) {
		NSArray		*entities;
		
		[[NSUserDefaults standardUserDefaults] setObject:[panel directory] forKey:@"OpenPanelPath"];
		
		if ([selectedObject isKindOfClass:[NSArray class]]) {
			entities = [selectedObject copy];
		} else if ([selectedObject isKindOfClass:[EOModel class]]) {
			entities = [[selectedObject entities] copy];
		} else {
			entities = [[NSArray arrayWithObject:selectedObject] retain];
		}

		[self generateObjCFromEntities:entities at:[panel directory]];
	}
}

- (void)generateObjCFiles:(id)sender
{
	NSOpenPanel		*openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanCreateDirectories:YES];
	[openPanel setPrompt:@"Choose"];
	
	[openPanel beginSheetForDirectory:[[NSUserDefaults standardUserDefaults] objectForKey:@"OpenPanelPath"] file:@"" modalForWindow:window modalDelegate:self didEndSelector:@selector(generateObjCPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)newEntity:(id)sender
{
	EOEntity			*entity;
	NSString			*name;
	int				count = 1;
	
	entity = [[EOEntity allocWithZone:[self zone]] init];
	
	name = @"Entity";
	while ([model entityNamed:name]) {
		name = AJRFormat(@"Entity%d", count++);
	}
	
	[entity setName:name];
	[model addEntity:entity];
	
	[modelOutline reloadData];
	[modelOutline selectRow:0 byExtendingSelection:NO];
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
		
		attribute = [[EOAttribute allocWithZone:[entity zone]] init];
		name = @"attribute";
		while ([entity attributeNamed:name]) {
			name = AJRFormat(@"attribute%d", count++);
		}
		[attribute setName:name];
		[attribute setAllowsNull:YES];
		[entity addAttribute:attribute];
		[attribute release];
		
		temp = [[entity attributesUsedForLocking] mutableCopy];
		[temp addObject:attribute];
		[entity setAttributesUsedForLocking:temp];
		[temp release];
		
		temp = [[entity classProperties] mutableCopy];
		[temp addObject:attribute];
		[entity setClassProperties:temp];
		[temp release];
		
		[modelOutline selectRow:[modelOutline rowForItem:entity] byExtendingSelection:NO];
		[editorView displayEditorNamed:@"Entity"];
		[[editorView currentEditor] performSelector:@selector(editAttribute:) withObject:attribute afterDelay:0.01];
	} else if (storedProcedure) {
		EOAttribute		*argument;
		
		argument = [[EOAttribute allocWithZone:[entity zone]] init];
		[argument setName:@"argument"];
		[argument setAllowsNull:YES];
		[argument setParameterDirection:EOInParameter];
		[storedProcedure addArgument:argument];
		[argument release];

		[modelOutline selectRow:[modelOutline rowForItem:storedProcedure] byExtendingSelection:NO];
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
		
		relationship = [[EORelationship allocWithZone:[entity zone]] init];
		name = @"relationship";
		while ([entity relationshipNamed:name]) {
			name = AJRFormat(@"relationship%d", count++);
		}
		[relationship setName:name];
		[entity addRelationship:relationship];
		[relationship release];
		
		temp = [[entity classProperties] mutableCopy];
		[temp addObject:relationship];
		[entity setClassProperties:temp];
		[temp release];
		
		[modelOutline selectRow:[modelOutline rowForItem:entity] byExtendingSelection:NO];
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
		name = AJRFormat(@"%@%d", [[array valueForKey:@"name"] componentsJoinedByString:@"_"], count++);
	}
	[relationship setName:name];
	[relationship setDefinition:definition];
	[object addRelationship:relationship];
	[relationship release];
	
	array = [[object classProperties] mutableCopy];
	[array addObject:relationship];
	[object setClassProperties:array];
	[array release];
	
	[modelOutline selectRow:[modelOutline rowForItem:object] byExtendingSelection:NO];
	[self selectModel:modelOutline];
	[[editorView currentEditor] performSelector:@selector(editRelationship:) withObject:relationship afterDelay:0.01];
}

- (void)newStoredProcedure:(id)sender
{
	EOStoredProcedure	*storedProcedure;
	NSString				*name;
	int					count = 1;
	
	storedProcedure = [[EOStoredProcedure allocWithZone:[self zone]] init];
	
	name = @"StoredProcedure";
	while ([model storedProcedureNamed:name]) {
		name = AJRFormat(@"StoredProcedure%d", count++);
	}
	
	[storedProcedure setName:name];
	[model addStoredProcedure:storedProcedure];
	
	[modelOutline reloadData];
	[modelOutline selectRow:[modelOutline rowForItem:StoredProcedures] byExtendingSelection:NO];
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

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(SEL)callback
{
	if (returnCode == NSOKButton) {
		NSException		*exception = nil;
		
		[[NSUserDefaults standardUserDefaults] setObject:[sheet directory] forKey:@"SavePanelPath"];
		
		NS_DURING
			[model writeToFile:[sheet filename]];
			[window setTitleWithRepresentedFilename:[model path]];
			[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:[model path]]];
			[window setDocumentEdited:NO];
			untitled = NO;
		NS_HANDLER
			exception = [localException retain];
		NS_ENDHANDLER
		
		if (exception) {
			NSRunAlertPanel(@"Error", @"Unable to save model: %@", nil, nil, nil, exception);
			[exception release];
		}
		if (callback) {
			if (exception == nil) objc_msgSend(self, callback, DocumentDidSave);
			else objc_msgSend(self, callback, DocumentDidFail);
		}
	} else {
		if (callback) objc_msgSend(self, callback, DocumentDidCancel);
	}
}

- (void)saveDocumentPromptingForName:(BOOL)promptForName callback:(SEL)callback
{
	if (promptForName || untitled) {
		NSSavePanel		*savePanel = [NSSavePanel savePanel];
		NSString			*savePath;
		
		[savePanel setRequiredFileType:@"eomodeld"];
		
		savePath = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavePanelPath"];
		if (savePath == nil) savePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
		
		[savePanel setCanSelectHiddenExtension:YES];
		[savePanel beginSheetForDirectory:savePath file:[[model path] lastPathComponent] modalForWindow:window modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:callback];
	} else {
		[model writeToFile:[model path]];
		[window setDocumentEdited:NO];
	}
}

- (void)saveDocumentAs:(id)sender
{
	[self saveDocumentPromptingForName:YES callback:NULL];
}

- (void)saveDocument:(id)sender
{
	[self saveDocumentPromptingForName:NO callback:NULL];
}

- (void)willEndCloseSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(SEL)callback
{
	if (returnCode == NSAlertAlternateReturn) {
		// Don't save
		[window close];
		if (callback) objc_msgSend(self, callback, DocumentDidDiscard);
	}
}

- (void)didEndCloseSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(SEL)callback 
{
	if (returnCode == NSAlertDefaultReturn) {
		// Save
		[self saveDocumentPromptingForName:NO callback:callback];
	} else if (returnCode == NSAlertOtherReturn) {
		// Cancel
		if (callback) objc_msgSend(self, callback, DocumentDidCancel);
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

- (void)promptForWindowShouldCloseWithCallback:(SEL)callback
{
	NSBeginAlertSheet(@"Do you want to save changes to this document before closing?", @"Save", @"Don't Save", @"Cancel", window, self, @selector(willEndCloseSheet:returnCode:contextInfo:), @selector(didEndCloseSheet:returnCode:contextInfo:), callback, @"If you don't save, your changes will be lost.");
}

- (BOOL)windowShouldClose:(id)sender
{
	if ([window isDocumentEdited]) {
		[self promptForWindowShouldCloseWithCallback:@selector(closeWithResponse:)];
		return NO;
	}
	
	return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
	[window setDelegate:nil];
	window = nil;
	[self release];
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
	NSArray	*windows = [NSApp windows];
	int		x;
	
	for (x = 0; x < (const int)[windows count]; x++) {
		NSWindow		*aWindow = [windows objectAtIndex:x];
		Document		*document = [aWindow delegate];
		
		if ([document isKindOfClass:[Document class]] && [document isDocumentEdited]) {
			[document promptForWindowShouldCloseWithCallback:@selector(terminateWithResponse:)];
			return;
		}
	}
	
	// If we reach this point, there's not documents left to try and save, so report that it's OK to terminate the applications.
	[NSApp replyToApplicationShouldTerminate:YES];
}

- (void)refreshEntityNames
{
	[entityNameCache release]; entityNameCache = nil;
}

- (NSArray *)possibleEntityNames
{
	if (entityNameCache == nil) {
		NS_DURING
			EOAdaptor			*adaptor = [EOAdaptor adaptorWithModel:model];
			EOAdaptorContext	*context = [adaptor createAdaptorContext];
			EOAdaptorChannel	*channel;
			
			channel = [[context channels] lastObject];
			if (!channel) channel = [context createAdaptorChannel];
			
			if (![channel isOpen]) [channel openChannel];
			entityNameCache = [[channel describeTableNames] mutableCopy];
		NS_HANDLER
			AJRPrintf(@"Exception during entity name fetch: %@\n", localException);
			entityNameCache = [[NSArray alloc] init];
		NS_ENDHANDLER
	}
	
	return entityNameCache;
}

- (EOEntity *)entityWithExternalName:(NSString *)aName
{
	int			x;
	NSArray		*entities = [model entities];
	
	for (x = 0; x < (const int)[entities count]; x++) {
		EOEntity		*entity = [entities objectAtIndex:x];
		
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
	int					x;
	
	channel = [[context channels] lastObject];
	if (!channel) channel = [context createAdaptorChannel];
	
	if (![channel isOpen]) [channel openChannel];
	tempModel = [channel describeModelWithTableNames:[NSArray arrayWithObject:aName]];
	
	entities = [[tempModel entities] copy];
	for (x = 0; x < (const int)[entities count]; x++) {
		EOEntity		*entity = [entities objectAtIndex:x];
		[tempModel removeEntity:entity];
		[entity setClassName:[entity name]];
		[model addEntity:entity];
	}
	[entities release];
}

@end
