//
//  EOAttributePane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOAttributePane.h"

#import "EOInternalTypeInspector.h"
#import "Document.h"

#import <EOAccess/EOAccess.h>

@implementation EOAttributePane

- (NSString *)name
{
	return @"General";
}

- (EOAttribute *)selectedAttribute
{
	id		selectedObject = [self selectedObject];
	if ([selectedObject isKindOfClass:[EOAttribute class]]) return selectedObject;
	return nil;
}

- (void)updateWithSelectedObject:(id)value
{
    EOAttribute		*attribute = nil;
    
    if (value) {
        if ([value isKindOfClass:[EOAttribute class]])
            attribute = value;
    }
    if (! attribute)
        attribute = [self selectedAttribute];

	
	if (attribute) {
        currentObject = attribute;
		Document		*document = [self currentDocument];
		
		[nameField setStringValue:[attribute name]];
		if ([attribute definition]) {
			[columnField setStringValue:[attribute definition]];
			[columnPopUp selectItemAtIndex:1];
		} else {
			[columnField setStringValue:[attribute columnName]];
			[columnPopUp selectItemAtIndex:0];
		}
		[externalTypeField setStringValue:[attribute externalType]];
		[internalTypeInspector setAttribute:attribute];
		[readOnlyCheck setState:[attribute isReadOnly]];
		[allowsNullCheck setState:[attribute allowsNull]];
		[readFormatField setStringValue:[attribute readFormat]];
		[writeFormatField setStringValue:[attribute writeFormat]];
		
		[externalTypeField removeAllItems];
		[externalTypeField addItemsWithObjectValues:[[[document adaptorClass] externalTypesWithModel:[document model]] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	}
}

- (void)setName:(id)sender
{
	[[self selectedAttribute] setName:[sender stringValue]];
}

- (void)selectColumn:(id)sender
{
	switch ([columnPopUp indexOfSelectedItem]) {
		case 0:
			[[self selectedAttribute] setDefinition:@""];
			[columnField setStringValue:[[self selectedAttribute] columnName]];
			break;
		case 1:
			[[self selectedAttribute] setColumnName:@""];
			[columnField setStringValue:[[self selectedAttribute] definition]];
			break;
	}
}

- (void)setColumn:(id)sender
{
	switch ([columnPopUp indexOfSelectedItem]) {
		case 0:
			[[self selectedAttribute] setColumnName:[sender stringValue]];
			break;
		case 1:
			[[self selectedAttribute] setDefinition:[sender stringValue]];
			break;
	}
}

- (void)setExternalType:(id)sender
{
	[[self selectedAttribute] setExternalType:[sender stringValue]];
}

- (void)toggleReadOnly:(id)sender
{
	[[self selectedAttribute] setReadOnly:[sender state]];
}

- (void)toggleAllowsNull:(id)sender
{
	[[self selectedAttribute] setAllowsNull:[sender state]];
}

- (void)setReadFormat:(id)sender
{
	[[self selectedAttribute] setReadFormat:[sender stringValue]];
}

- (void)setWriteFormat:(id)sender
{
	[[self selectedAttribute] setWriteFormat:[sender stringValue]];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	if (control == nameField) {
		return [[self selectedAttribute] validateName:[fieldEditor string]] == nil;
	}
	
	return YES;
}

@end
