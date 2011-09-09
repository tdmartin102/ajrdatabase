//
//  EOEntityStoredProceduresPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOEntityStoredProceduresPane.h"

#import <EOAccess/EOAccess.h>

@implementation EOEntityStoredProceduresPane

- (NSString *)name
{
	return @"Stored Procedures";
}

static inline void safeSet(NSTextField *field, NSString *value) 
{
	[field setStringValue:value ? value : @""];
}

- (void)update
{
	EOEntity		*entity = [self selectedEntity];
	
	safeSet(insertField, [[entity storedProcedureForOperation:EOInsertProcedureOperation] name]);
	safeSet(deleteField, [[entity storedProcedureForOperation:EODeleteProcedureOperation] name]);
	safeSet(fetchAllField, [[entity storedProcedureForOperation:EOFetchAllProcedureOperation] name]);
	safeSet(fetchWithPKField, [[entity storedProcedureForOperation:EOFetchWithPrimaryKeyProcedureOperation] name]);
	safeSet(getPKField, [[entity storedProcedureForOperation:EONextPrimaryKeyProcedureOperation] name]);
}

- (void)setInsert:(id)sender
{
	[[self selectedEntity] setStoredProcedure:[[EOModelGroup defaultModelGroup] storedProcedureNamed:[sender stringValue]] forOperation:EOInsertProcedureOperation];
}

- (void)setDelete:(id)sender
{
	[[self selectedEntity] setStoredProcedure:[[EOModelGroup defaultModelGroup] storedProcedureNamed:[sender stringValue]] forOperation:EODeleteProcedureOperation];
}

- (void)setFetchAll:(id)sender
{
	[[self selectedEntity] setStoredProcedure:[[EOModelGroup defaultModelGroup] storedProcedureNamed:[sender stringValue]] forOperation:EOFetchAllProcedureOperation];
}

- (void)setFetchWithPK:(id)sender
{
	[[self selectedEntity] setStoredProcedure:[[EOModelGroup defaultModelGroup] storedProcedureNamed:[sender stringValue]] forOperation:EOFetchWithPrimaryKeyProcedureOperation];
}

- (void)setGetPK:(id)sender
{
	[[self selectedEntity] setStoredProcedure:[[EOModelGroup defaultModelGroup] storedProcedureNamed:[sender stringValue]] forOperation:EONextPrimaryKeyProcedureOperation];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	NSString		*string = [fieldEditor string];
	
	if ([string length] == 0) return YES;
	
	if ([[EOModelGroup defaultModelGroup] storedProcedureNamed:string] != nil) return YES;
	
	//NSRunAlertPanel(@"Error", @"There are no models containing the stored procedure named \"%@\".", nil, nil, nil, string);
	
	return NO;
}

@end
