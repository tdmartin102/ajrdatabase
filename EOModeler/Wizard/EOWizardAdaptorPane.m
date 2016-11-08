//
//  EOWizardAdaptorPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 10/1/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOWizardAdaptorPane.h"

#import "EOModelWizard.h"

#import <EOAccess/EOAccess.h>

@implementation EOWizardAdaptorPane

- (void)awakeFromNib
{
    NSIndexSet  *indexSet;
    indexSet = [NSIndexSet indexSetWithIndex:[[EOAdaptor availableAdaptorNames] count]];
	[adaptorTable selectRowIndexes:indexSet byExtendingSelection:NO];
	[connectionBox setContentView:noneView];
	[self updateButtons];
}

- (void)selectAdaptor:(id)sender
{
	NSInteger		row = [adaptorTable selectedRow];
	NSArray	*names = [EOAdaptor availableAdaptorNames];
	
	if (row == [names count]) {
		[connectionBox setContentView:noneView];
		connectionPane = nil;
		[adaptorTable setNextKeyView:[modelWizard cancelButton]];
	} else {
		EOAdaptor		*adaptor = [EOAdaptor adaptorWithName:[names objectAtIndex:row]];
		NSView			*contentView;
		
		[connectionPane setModel:nil];
		connectionPane = nil;
		if (adaptor) {
			connectionPane = [[adaptor class] sharedConnectionPane];
			contentView = [connectionPane view];
			[connectionBox setContentView:contentView];
			[connectionPane setModel:[modelWizard model]];
			if (contentView) {
				[adaptorTable setNextKeyView:[contentView nextKeyView]];
				[[contentView previousKeyView] setNextKeyView:[modelWizard cancelButton]];
			} else {
				[adaptorTable setNextKeyView:[modelWizard cancelButton]];
			}
		}
	}
	
	[self updateButtons];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[EOAdaptor availableAdaptorNames] count] + 1;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSArray		*names = [EOAdaptor availableAdaptorNames];
	
	if (rowIndex == [names count]) {
		return @"None";
	}
	
	return [names objectAtIndex:rowIndex];
}

- (void)updateButtons
{
	NSInteger		row = [adaptorTable selectedRow];
	NSArray	*names = [EOAdaptor availableAdaptorNames];

	[[modelWizard previousButton] setEnabled:NO];
	[[modelWizard finishButton] setEnabled:YES];
	if (row == [names count]) {
		[[modelWizard nextButton] setEnabled:NO];
	} else {
		[[modelWizard nextButton] setEnabled:YES];
	}
}

- (BOOL)canGoNext
{
	NSInteger		row = [adaptorTable selectedRow];
	NSArray	*names = [EOAdaptor availableAdaptorNames];
	
	if (row == [names count]) {
		return NO;
	} else {
		EOModel			*model = [modelWizard model];
		EOAdaptor		*adaptor = [EOAdaptor adaptorWithModel:model];
		NSException		*exception = nil;
		
		NS_DURING
			[adaptor assertConnectionDictionaryIsValid];
		NS_HANDLER
			exception = localException;
		NS_ENDHANDLER
		
		if (exception) {
            NSAlert *alert;
            NSString *msg;
            
            msg = [NSString stringWithFormat:@"The following reason was provided: %lc%@%lc.\n\nWould you still like to create a model with this adaptor and connection information?", 0x201C, exception, 0x201D];
            alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Unable to connect to the database"];
            [alert setInformativeText:msg];
            [alert addButtonWithTitle:@"No"];
            [alert addButtonWithTitle:@"Yes"];
            
            [alert beginSheetModalForWindow:[adaptorTable window]
                          completionHandler:^(NSModalResponse returnCode){
                              if (returnCode == NSAlertAlternateReturn) {
                                  [NSApp stopModalWithCode:NSOKButton];
                              }
                          }];
			return NO;
		}
	}
	
	return YES;
}

@end
