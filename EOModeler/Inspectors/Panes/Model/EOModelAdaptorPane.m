//
//  EOModelAdaptorPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 10/7/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOModelAdaptorPane.h"

#import <EOAccess/EOAccess.h>

@implementation EOModelAdaptorPane

- (NSString *)name
{
	return @"Adaptor";
}

- (void)awakeFromNib
{
    NSIndexSet *indexSet;
    indexSet = [NSIndexSet indexSetWithIndex:[[EOAdaptor availableAdaptorNames] count]];
	[adaptorTable selectRowIndexes:indexSet byExtendingSelection:NO];
	[connectionBox setContentView:noneView];
}

- (void)selectAdaptor:(id)sender
{
	int		row = [adaptorTable selectedRow];
	NSArray	*names = [EOAdaptor availableAdaptorNames];
	EOModel	*model = [self selectedObject];
	
	if (row == [names count]) {
		[model setAdaptorName:nil];
	} else {
		[model setAdaptorName:[names objectAtIndex:row]];
	}
	
	[self update];
}

- (void)update
{
	EOModel		*model = [self selectedObject];
	NSString		*adaptorName;
	
	adaptorName = [model adaptorName];
	if (adaptorName == nil) {
        NSIndexSet *indexSet;
        indexSet = [NSIndexSet indexSetWithIndex:[[EOAdaptor availableAdaptorNames] count]];
		[adaptorTable selectRowIndexes:indexSet byExtendingSelection:NO];
		[connectionBox setContentView:noneView];
		[connectionPane release]; connectionPane = nil;
//		[adaptorTable setNextKeyView:[modelWizard cancelButton]];
	} else {
		EOAdaptor		*adaptor = [EOAdaptor adaptorWithModel:model];
		NSView			*contentView;
        NSIndexSet      *indexSet;
        
        indexSet = [NSIndexSet indexSetWithIndex:
                    [[EOAdaptor availableAdaptorNames] indexOfObject:[adaptor name]]];
        
		
		[adaptorTable selectRowIndexes:indexSet byExtendingSelection:NO];
		
		[connectionPane setModel:nil];
		[connectionPane release]; connectionPane = nil;
		
		if (adaptor) {
			connectionPane = [[[adaptor class] sharedConnectionPane] retain];
			contentView = [connectionPane smallView];
			if (contentView == nil) contentView = [connectionPane view];
			[connectionBox setContentView:contentView];
			[connectionPane setModel:model];
//			if (contentView) {
//				[adaptorTable setNextKeyView:[contentView nextKeyView]];
//				[[contentView previousKeyView] setNextKeyView:[modelWizard cancelButton]];
//			} else {
//				[adaptorTable setNextKeyView:[modelWizard cancelButton]];
//			}
		}
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[EOAdaptor availableAdaptorNames] count] + 1;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSArray		*names = [EOAdaptor availableAdaptorNames];
	
	if (rowIndex == [names count]) {
		return @"None";
	}
	
	return [names objectAtIndex:rowIndex];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
}

- (void)testSettings:(id)sender
{
	int		row = [adaptorTable selectedRow];
	NSArray	*names = [EOAdaptor availableAdaptorNames];
	
	if (row != [names count]) {
		EOModel			*model = [self selectedObject];
		EOAdaptor		*adaptor = [EOAdaptor adaptorWithModel:model];
		NSException		*exception = nil;
		
		NS_DURING
			[adaptor assertConnectionDictionaryIsValid];
		NS_HANDLER
			exception = [localException retain];
		NS_ENDHANDLER
		
		if (exception) {
			NSBeginAlertSheet(@"Unable to connect to the database", @"OK", nil, nil, [adaptorTable window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, 
				[NSString stringWithFormat:@"The following reason was provided: %@.", exception]);
			[exception release];
		} else {
			NSBeginAlertSheet(@"Database connection successful", @"OK", nil, nil, [adaptorTable window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"The adaptor was able to successfully make a connection to the database.");
		}
	}
}

- (void)syncAdaptor:(id)sender
{
			NSBeginAlertSheet(@"Unimplemented feature", @"OK", nil, nil, [adaptorTable window], self, @selector(sheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"This feature is currently unimplemented. Please check the external types of your attributes manually.");
}

@end
