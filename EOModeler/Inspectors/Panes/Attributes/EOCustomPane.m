//
//  EOCustomPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOCustomPane.h"

#import <EOAccess/EOAccess.h>

@implementation EOCustomPane

+ (void)load { }

+ (NSString *)name
{
	return @"Custom";
}

+ (Class)inspectedClass
{
	return Nil;
}

- (void)update
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[externalWidthField setIntValue:[attribute width]];
	[classField setStringValue:[attribute valueClassName]];
	[factoryMethodField setStringValue:[attribute valueFactoryMethodName]];
	[conversionMethodField setStringValue:[attribute adaptorValueConversionMethodName]];
	[initArgumentPopUp selectItemAtIndex:[attribute factoryMethodArgumentType]];
}

- (void)updateAttribute
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[attribute setValueClassName:nil];
	[attribute setValueFactoryMethodName:@"objectWithArchiveData:"];
	[attribute setAdaptorValueConversionMethodName:@"archiveData"];
	[attribute setFactoryMethodArgumentType:EOFactoryMethodArgumentIsNSData];
}

- (void)setExternalWidth:(id)sender
{
	[[self selectedAttribute] setWidth:[sender intValue]];
}

- (void)setClass:(id)sender
{
	[[self selectedAttribute] setValueClassName:[sender stringValue]];
}

- (void)setFactoryMethod:(id)sender
{
	[[self selectedAttribute] setValueFactoryMethodName:[sender stringValue]];
}

- (void)setConversionMethod:(id)sender
{
	[[self selectedAttribute] setAdaptorValueConversionMethodName:[sender stringValue]];
}

- (void)selectedInitArgument:(id)sender
{
	[[self selectedAttribute] setFactoryMethodArgumentType:(EOFactoryMethodArgumentType)[[sender selectedItem] tag]];
}

@end
