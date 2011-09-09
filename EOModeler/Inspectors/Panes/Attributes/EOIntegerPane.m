//
//  EOIntegerPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOIntegerPane.h"

#import <EOAccess/EOAccess.h>

@implementation EOIntegerPane

+ (void)load { }

+ (NSString *)name
{
	return @"Integer";
}

+ (Class)inspectedClass
{
	return [NSNumber class];
}

- (void)awakeFromNib
{
	[typePopUp setAutoenablesItems:NO];
}

- (BOOL)canInspectAttribute:(EOAttribute *)attribute
{
	return [[attribute valueClassName] isEqualToString:@"NSNumber"] && !([[attribute valueType] isEqualToString:@"f"] || [[attribute valueType] isEqualToString:@"d"]);
}

- (void)update
{
	EOAttribute		*attribute = [self selectedAttribute];
	NSString			*valueType = [attribute valueType];

	if ([[[attribute externalType] lowercaseString] hasPrefix:@"bool"]) {
		[[typePopUp itemWithTitle:@"Boolean"] setEnabled:YES];
		[[typePopUp itemWithTitle:@"Character"] setEnabled:NO];
	} else {
		[[typePopUp itemWithTitle:@"Boolean"] setEnabled:NO];
		[[typePopUp itemWithTitle:@"Character"] setEnabled:YES];
	}

	if ([valueType isEqualToString:@"c"]) {
		if ([[[attribute externalType] lowercaseString] hasPrefix:@"bool"]) {
			[typePopUp selectItemWithTitle:@"Boolean"];
		} else {
			[typePopUp selectItemWithTitle:@"Character"];
		}
	} else if ([valueType isEqualToString:@"C"]) {
		[typePopUp selectItemWithTitle:@"Unsigned Character"];
	} else if ([valueType isEqualToString:@"s"]) {
		[typePopUp selectItemWithTitle:@"Short"];
	} else if ([valueType isEqualToString:@"S"]) {
		[typePopUp selectItemWithTitle:@"Unsigned Short"];
	} else if ([valueType isEqualToString:@"i"]) {
		[typePopUp selectItemWithTitle:@"Integer"];
	} else if ([valueType isEqualToString:@"I"]) {
		[typePopUp selectItemWithTitle:@"Unsigned Integer"];
	} else if ([valueType isEqualToString:@"l"]) {
		[typePopUp selectItemWithTitle:@"Long"];
	} else if ([valueType isEqualToString:@"L"]) {
		[typePopUp selectItemWithTitle:@"Unsigned Long"];
	} else if ([valueType isEqualToString:@"q"]) {
		[typePopUp selectItemWithTitle:@"Long Long"];
	} else if ([valueType isEqualToString:@"Q"]) {
		[typePopUp selectItemWithTitle:@"Unsigned Long Long"];
	}
}

- (void)updateAttribute
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[attribute setValueClassName:@"NSNumber"];
	[attribute setValueType:@"i"];
}

- (void)selectType:(id)sender
{
	NSString		*title = [[sender selectedItem] title];
	
	if ([title isEqualToString:@"Boolean"]) {
		[[self selectedAttribute] setValueType:@"c"];
	} else if ([title isEqualToString:@"Character"]) {
		[[self selectedAttribute] setValueType:@"c"];
	} else if ([title isEqualToString:@"Unsigned Character"]) {
		[[self selectedAttribute] setValueType:@"C"];
	} else if ([title isEqualToString:@"Short"]) {
		[[self selectedAttribute] setValueType:@"s"];
	} else if ([title isEqualToString:@"Unsigned Short"]) {
		[[self selectedAttribute] setValueType:@"S"];
	} else if ([title isEqualToString:@"Integer"]) {
		[[self selectedAttribute] setValueType:@"i"];
	} else if ([title isEqualToString:@"Unsigned Integer"]) {
		[[self selectedAttribute] setValueType:@"I"];
	} else if ([title isEqualToString:@"Long"]) {
		[[self selectedAttribute] setValueType:@"l"];
	} else if ([title isEqualToString:@"Unsigned Long"]) {
		[[self selectedAttribute] setValueType:@"L"];
	} else if ([title isEqualToString:@"Long Long"]) {
		[[self selectedAttribute] setValueType:@"q"];
	} else if ([title isEqualToString:@"Unsigned Long Long"]) {
		[[self selectedAttribute] setValueType:@"Q"];
	}
}

@end
