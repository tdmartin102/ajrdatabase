//
//  Controller.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/22/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"

#import "Document.h"

#import <EOAccess/EOAccess.h>
#import <EOInterface/EOInterface.h>

@implementation Controller

+ (void)initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		@"1000", @"FetchLimit",
		@"NO", @"InspectorOpen",
		[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], @"OpenPanelPath",
		[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"], @"SavePanelPath",
		nil]
	];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	[EOLogger setLogInfo:YES];
	[EOLogger setLogWarning:YES];
	[EOLogger setLogError:YES];
//	EOQualifier		*qualifier;
//	
//	NS_DURING
//		qualifier = [EOQualifier qualifierWithQualifierFormat:@"firstName in ('alex', 'janet', 'mike', 'pat')"];
//		AJRPrintf(@"qualifier = %@\n", qualifier);
//		qualifier = [EOQualifier qualifierWithQualifierFormat:@"firstName in (%@)", [NSArray arrayWithObjects:@"alex", @"janet", @"mike", @"pat", nil]];
//		AJRPrintf(@"qualifier = %@\n", qualifier);
//	NS_HANDLER
//		AJRPrintf(@"error: %@\n", localException);
//		exit(1);
//	NS_ENDHANDLER
//	exit(1);
}

- (void)newDocument:(id)sender
{
	[[Document alloc] init];
}

- (void)openDocument:(id)sender
{
	NSOpenPanel		*openPanel = [NSOpenPanel openPanel];
	NSString			*path;
	
	[openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"eomodeld"]];
	[openPanel setAllowsMultipleSelection:YES];
	
	path = [[NSUserDefaults standardUserDefaults] objectForKey:@"OpenPanelPath"];
	if (path == nil) path = NSHomeDirectory();
	
	if ([openPanel runModalForDirectory:path file:@"" types:[NSArray arrayWithObject:@"eomodeld"]]) {
		int			x;
		NSArray		*files = [openPanel filenames];
		
		for (x = 0; x < (const int)[files count]; x++) {
			[[Document alloc] initWithPath:[files objectAtIndex:x]];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:[openPanel directory] forKey:@"OpenPanelPath"];
	}
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
   NSURL       *url;
	NSArray		*windows;
	int			x;
	
	AJRPrintf(@"adaptors: %@\n", [EOAdaptor availableAdaptorNames]);
	
   if ([filename isKindOfClass:[NSURL class]]) {
      url = (NSURL *)filename;
   } else {
      url = [NSURL fileURLWithPath:filename];
   }
	
	windows = [NSApp windows];
	for (x = 0; x < (const int)[windows count]; x++) {
		NSWindow		*window = [windows objectAtIndex:x];
		if ([[window delegate] isKindOfClass:[Document class]]) {
			Document		*document = [window delegate];
			if ([[[document model] path] isEqualToString:[url path]]) {
				[window makeKeyAndOrderFront:self];
				return YES;
			}
		}
	}
	
   return [[Document allocWithZone:[self zone]] initWithPath:[url path]] != nil;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app 
{
	NSArray		*windows = [app windows];
	unsigned		needsSaving = 0;
	int			x;
	
	// Determine if there are any unsaved documents...
	
	for (x = 0; x < (const int)[windows count]; x++) {
		NSWindow		*window = [windows objectAtIndex:x];
		
		if ([[window delegate] isKindOfClass:[Document class]] && [[window delegate] isDocumentEdited]) {
			needsSaving++;
		}
	}
	
	if (needsSaving > 0) {
		int	choice = NSAlertDefaultReturn;  // Meaning, review changes

		if (needsSaving > 1) { 
			// If we only have 1 unsaved document, we skip the "review changes?" panel
			choice = NSRunAlertPanel([NSString stringWithFormat:@"You have %d documents with unsaved changes. Do you want to review these changes before quitting?", needsSaving], @"If you don't review your documents, all changes will be lost.", @"Review Changes...", @"Discard Changes", @"Cancel");
			
			if (choice == NSAlertOtherReturn) return NSTerminateCancel; /* Cancel */
		}
		
		if (choice == NSAlertDefaultReturn) { /* Review unsaved; Quit Anyway falls through */
			[Document reviewEditedDocuments];
			return NSTerminateLater;
		}
	}

	return NSTerminateNow;
}

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu
{
	Document		*document = [Document currentDocument];
	
	return [[document possibleEntityNames] count] + 2;
}

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
	Document		*document = [Document currentDocument];
	
	if (document) {
		NSArray		*names = [document possibleEntityNames];

		if (index == 0) {
			[item setTitle:@"Refresh Table Names"];
			[item setTarget:self];
			[item setAction:@selector(refreshEntityNames:)];
		} else if (index == 1) {
		} else {
			EOEntity		*entity = [document entityWithExternalName:[names objectAtIndex:index - 2]];
			
			[item setTarget:self];
			if (entity) {
				[item setTitle:[entity name]];
				[item setAction:@selector(synchronizeEntity:)];
				[item setImage:[NSImage imageNamed:@"synchronizeEntity"]];
			} else {
				[item setTitle:[names objectAtIndex:index - 2]];
				[item setAction:@selector(createNewEntity:)];
				[item setImage:[NSImage imageNamed:@"menuNewEntity"]];
			}
		}
		
		
		return YES;
	}
	
	return NO;
}

- (void)refreshEntityNames:(id)sender
{
	[[Document currentDocument] refreshEntityNames];
}

- (void)createNewEntity:(id)sender
{
	[[Document currentDocument] addEntityWithTableName:[(id <NSMenuItem>)sender title]];
}

- (void)synchronizeEntity:(id)sender
{
}

@end
