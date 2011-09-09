//
//  EOAttributePane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInspectorPane.h"

@class EOInternalTypeInspector;

@interface EOAttributePane : EOInspectorPane
{
	IBOutlet NSTextField					*nameField;
	IBOutlet NSTextField					*columnField;
	IBOutlet NSPopUpButton				*columnPopUp;
	IBOutlet NSComboBox					*externalTypeField;
	IBOutlet EOInternalTypeInspector	*internalTypeInspector;
	IBOutlet NSButton						*readOnlyCheck;
	IBOutlet NSButton						*allowsNullCheck;
	IBOutlet NSTextField					*readFormatField;
	IBOutlet NSTextField					*writeFormatField;
}

- (void)setName:(id)sender;
- (void)selectColumn:(id)sender;
- (void)setColumn:(id)sender;
- (void)setExternalType:(id)sender;
- (void)toggleReadOnly:(id)sender;
- (void)toggleAllowsNull:(id)sender;
- (void)setReadFormat:(id)sender;
- (void)setWriteFormat:(id)sender;

@end
