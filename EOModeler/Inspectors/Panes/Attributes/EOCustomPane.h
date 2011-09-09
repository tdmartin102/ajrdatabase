//
//  EOCustomPane.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOInternalTypePane.h"

@interface EOCustomPane : EOInternalTypePane
{
	IBOutlet NSTextField		*externalWidthField;
	IBOutlet NSTextField		*classField;
	IBOutlet NSTextField		*factoryMethodField;
	IBOutlet NSTextField		*conversionMethodField;
	IBOutlet NSPopUpButton	*initArgumentPopUp;
}

- (void)setExternalWidth:(id)sender;
- (void)setClass:(id)sender;
- (void)setFactoryMethod:(id)sender;
- (void)setConversionMethod:(id)sender;
- (void)selectedInitArgument:(id)sender;

@end
