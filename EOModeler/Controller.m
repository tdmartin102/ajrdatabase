//
//  Controller.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/22/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"

#import "Document.h"

#import "Additions.h"
#import "Preferences.h"

#import <EOAccess/EOAccess.h>
#import <EOInterface/EOInterface.h>

static Controller *defaultController;

@implementation Controller
{
    NSMutableArray *documents;
}

- (void)registerDocument:(Document *)doc
{
    [documents addObject:doc];
}

- (void)unRegisterDocument:(Document *)doc
{
    // This is NOT working. document is NOT freed.
    [documents removeObject:doc];
}

+ (Controller *)defaultCountroller
{
    return defaultController;
}

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

- (instancetype)init
{
    if ((self = [super init])) {
        NSArray             *pathArray;
        NSUserDefaults		*defaults;
        NSString            *path;

        documents = [[NSMutableArray alloc] initWithCapacity:20];
        defaultController = self;
        
        // load any models in our search path now, early, so that they are there
        // when a Document opens a model.
        defaults = [NSUserDefaults standardUserDefaults];
        pathArray = [defaults objectForKey:PrefsModelPathsKey];
        if (pathArray) {
            for (path in pathArray)
                [self addModelsAtPath:path];
        }

    }
    return self;
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
	Document * doc = [[Document alloc] init];
    [self registerDocument:doc];
}

- (void)openDocument:(id)sender
{
	NSOpenPanel		*openPanel = [NSOpenPanel openPanel];
	NSString			*path;
    NSURL               *anURL;
    NSArray             *files;
    Document            *doc;
	
	path = [[NSUserDefaults standardUserDefaults] objectForKey:@"OpenPanelPath"];
	if (path == nil) path = NSHomeDirectory();
    
    openPanel.canChooseDirectories = NO;
    openPanel.allowedFileTypes = @[@"eomodeld"];
    openPanel.allowsMultipleSelection = YES;
    openPanel.directoryURL = [NSURL fileURLWithPath:path];
    if ([openPanel runModal]) {
        files = openPanel.URLs;
        for (anURL in files)
        {
            doc = [[Document alloc] initWithPath:anURL.path];
            [self registerDocument:doc];
        }
        [[NSUserDefaults standardUserDefaults] setObject:openPanel.directoryURL.path forKey:@"OpenPanelPath"];
    }
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSURL       *url;
	NSArray		*windows;
	int			x;
    Document   *doc;
    BOOL        result = YES;
	
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
			Document		*document = (Document *)[window delegate];
			if ([[[document model] path] isEqualToString:[url path]]) {
				[window makeKeyAndOrderFront:self];
				return YES;
			}
		}
	}
	
    doc = [[Document alloc] initWithPath:[url path]];
    if (doc)
        [self registerDocument:doc];
    else
        result = NO;
    
   return result;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app 
{
	NSArray         *windows = [app windows];
	unsigned		needsSaving = 0;
	int             x;
    NSAlert         *alert;
    NSString        *msg;

	// Determine if there are any unsaved documents...
	
	for (x = 0; x < (const int)[windows count]; x++) {
		NSWindow		*window = [windows objectAtIndex:x];
		
		if ([[window delegate] isKindOfClass:[Document class]])
		{
			if ([(Document *)[window delegate] isDocumentEdited])
				needsSaving++;
		}
	}
	
	if (needsSaving > 0) {
		NSModalResponse	choice = NSAlertFirstButtonReturn;  // Meaning, review changes

		if (needsSaving > 1) { 
			// If we only have 1 unsaved document, we skip the "review changes?" panel
            msg = [NSString stringWithFormat:@"You have %d documents with unsaved changes. Do you want to review these changes before quitting/n/nIf you don't review your documents, all changes will be lost.", needsSaving];
            
            alert = [[NSAlert alloc] init];
            [alert setMessageText:@"EOModler"];
            [alert setInformativeText: msg];
            [alert addButtonWithTitle: @"Review Changes..."];
            [alert addButtonWithTitle: @"Discard Changes"];
            [alert addButtonWithTitle: @"Cancel"];

            choice = [alert runModal];
			if (choice == NSAlertThirdButtonReturn) return NSTerminateCancel; /* Cancel */
		}
		
		if (choice == NSAlertFirstButtonReturn) { /* Review unsaved; Quit Anyway falls through */
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
	[[Document currentDocument] addEntityWithTableName:[(NSMenuItem *)sender title]];
}

- (void)synchronizeEntity:(id)sender
{
}

- (void)closeDocument:(Document *)doc
{
    [self unRegisterDocument:doc];
}

- (NSArray *)documents
{
    return [documents copy];
}

- (void)addModelsAtPath:(NSString *)path
{
    EOModelGroup    *defaultGroup = [EOModelGroup defaultModelGroup];
    NSFileManager   *fm= [NSFileManager defaultManager];
    NSArray         *files;
    NSString        *file;
    BOOL            isDir;
    EOModel         *model;
    NSString        *aPath;
    
    if ([fm fileExistsAtPath:path isDirectory:&isDir])
    {
        if (isDir) {
            files = [fm contentsOfDirectoryAtPath:path error:NULL];
            for (file in files) {
                aPath = [path stringByAppendingPathComponent:file];
                if ([fm fileExistsAtPath:aPath isDirectory:&isDir]) {
                    if (isDir) {
                        if ((!([file hasPrefix:@"."] || [file hasSuffix:@"~.eomodeld"])) && [file hasSuffix:@".eomodeld"]) {
                            model = [(EOModel *)[EOModel alloc] initWithContentsOfFile:aPath];
                            if (model) {
                                [defaultGroup addModel:model];
                            }
                        }
                    }
                }
            }
        }
    }
}

@end
