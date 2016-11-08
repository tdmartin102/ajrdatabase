//
//  EOWizardTablesPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 10/6/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOWizardTablesPane.h"

#import "EOModelWizard.h"

#import <EOAccess/EOAccess.h>

@implementation EOWizardTablesPane

- (void)update
{
	EOModel		*model = [modelWizard model];
	
	if (model) {
		EOAdaptor			*adaptor = [EOAdaptor adaptorWithModel:model];
		EOAdaptorContext	*context = [adaptor createAdaptorContext];
		EOAdaptorChannel	*channel;
		
		channel = [[context channels] lastObject];
		if (!channel) channel = [context createAdaptorChannel];
		
		if (![channel isOpen]) [channel openChannel];
		tableNames = [channel describeTableNames];
	}
}

- (NSView *)view
{
	if (view == nil) {
		[super view];
		[tablesTable selectAll:self];
	}
	
	return view;
}

- (void)updateButtons
{
	[[modelWizard previousButton] setEnabled:YES];
	[[modelWizard finishButton] setEnabled:YES];
	[[modelWizard nextButton] setEnabled:[modelWizard assignStoredProcedures]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [tableNames count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [tableNames objectAtIndex:rowIndex];
}

- (BOOL)canGoNext
{
	NSMutableArray		*names = [[NSMutableArray alloc] init];
	NSIndexSet			*set = [tablesTable selectedRowIndexes];
	NSInteger			index;
	
	index = [set firstIndex];
	while (index != NSNotFound) {
		[names addObject:[tableNames objectAtIndex:index]];
		index = [set indexGreaterThanIndex:index];
	}
	
	if ([names count]) {
		EOModel				*model = [modelWizard model];
		EOAdaptor			*adaptor = [EOAdaptor adaptorWithModel:model];
		EOAdaptorContext	*context = [adaptor createAdaptorContext];
		EOAdaptorChannel	*channel;
		EOModel				*tempModel;
		NSArray				*entities;
		int					x;

		channel = [[context channels] lastObject];
		if (!channel) channel = [context createAdaptorChannel];
		
		if (![channel isOpen]) [channel openChannel];
		tempModel = [channel describeModelWithTableNames:names];
		
		entities = [[tempModel entities] copy];
		for (x = 0; x < (const int)[entities count]; x++) 
        {
			EOEntity		*entity = [entities objectAtIndex:x];
			[tempModel removeEntity:entity];
			if ([modelWizard assignCustomObjects]) {
				[entity setClassName:[entity name]];
			}
			[model addEntity:entity];
		}
		[model setName:[tempModel name]];
	}
		
	return YES;
}

@end
