//
//  PreferencesModels.m
//  AJRDatabase
//
//  Created by Alex Raftis on Sun Sep 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <EOAccess/EOAccess.h>

#import "PreferencesModels.h"
#import "Preferences.h"
#import "Controller.h"
#import "Document.h"

@implementation PreferencesModels
{
    IBOutlet NSTableView    *searchPathTable;
    
    NSMutableArray          *pathArray;
}

//===================================================================================
//                        Private Methods
//===================================================================================


// We will try to unload any model in EOModelGroup that was loaded
// due to a search path.
// We need
// to AVOID unloading a model that was loaded specifically by this application
// that would be any model in a Document.
- (void)_unloadModelsForPath:(NSString *)path
{
    EOModelGroup    *defaultGroup = [EOModelGroup defaultModelGroup];
    NSMutableArray  *loadedModels;
    NSArray         *bundelModels;
    Document        *doc;
    Controller      *controller = [Controller defaultCountroller];
    EOModel *model;

    loadedModels = [NSMutableArray arrayWithCapacity:10];
    // identify models loaded specifically by the app
    for (doc in [controller documents]) {
        model = [doc model];
        if (model)
            [loadedModels addObject:model];
    }
    
    // identify models loaded by EOModelGroup
    bundelModels = [[defaultGroup models] copy];
    
    // remove models loaded from a bundle that were not loaded
    // by the app
    for (model in bundelModels) {
        if (! [loadedModels containsObject:model]) {
            if ([[[model path] stringByDeletingLastPathComponent] isEqualToString:path]) {
                [defaultGroup removeModel:model];
            }
        }
    }
}

//===================================================================================
//                        Public Methods
//===================================================================================

- (NSString *)name
{
	return @"Models";
}

- (NSString *)toolTip
{
	return @"Search paths for pre-loaded models";
}

- (BOOL)isPreferred
{
	return YES;
}

- (void)update
{
    NSArray *value;
	NSUserDefaults		*defaults = [NSUserDefaults standardUserDefaults];
    value = [defaults objectForKey:PrefsModelPathsKey];
    if (value)
        pathArray = [value mutableCopy];
    else
        pathArray = [NSMutableArray arrayWithCapacity:5];
    [searchPathTable reloadData];
 }

- (IBAction)addPath:(id)sender
{
    NSOpenPanel		*openPanel = [NSOpenPanel openPanel];
    
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    openPanel.canCreateDirectories = YES;
    openPanel.prompt = @"Choose";
    openPanel.directoryURL =  [NSURL fileURLWithPath:NSHomeDirectory()];
    
    [openPanel beginWithCompletionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSFileHandlingPanelOKButton) {
            NSString *path = openPanel.directoryURL.path;
            NSUserDefaults		*defaults = [NSUserDefaults standardUserDefaults];
            
            if ([path length]) {
                [pathArray addObject:path];
                
                // add models at path
                [[Controller defaultCountroller] addModelsAtPath:path];
                
                // update the preference
                [defaults setObject:[pathArray copy] forKey:PrefsModelPathsKey];
            }
        }
    }];
    [searchPathTable reloadData];
}

- (IBAction)removePath:(id)sender
{
    NSIndexSet *rowsSet;
    __block NSInteger removed;
    
    rowsSet = [searchPathTable selectedRowIndexes];
    if ([rowsSet count]) {
        NSUserDefaults		*defaults = [NSUserDefaults standardUserDefaults];
        removed = 0;
        [rowsSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *path;
            NSInteger row = idx - removed;
            path = [pathArray objectAtIndex:row];
            // try to remove the path from the cached bundles.  This probably wont
            // work, but is worth a try.
            [self _unloadModelsForPath:path];
            [pathArray removeObjectAtIndex:row - removed];
        }];
        
        // update the preference
        [defaults setObject:[pathArray copy] forKey:PrefsModelPathsKey];
    }
    [searchPathTable reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [pathArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
    return [pathArray objectAtIndex:row];
}

@end
