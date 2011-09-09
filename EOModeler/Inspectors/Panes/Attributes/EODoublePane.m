//
//  EODoublePane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EODoublePane.h"

#import <EOAccess/EOAccess.h>

@implementation EODoublePane

+ (void)load { }

+ (NSString *)name
{
	return @"Double";
}

+ (Class)inspectedClass
{
	return [NSNumber class];
}

- (BOOL)canInspectAttribute:(EOAttribute *)attribute
{
	return [[attribute valueClassName] isEqualToString:@"NSNumber"] && ([[attribute valueType] isEqualToString:@"f"] || [[attribute valueType] isEqualToString:@"d"]);
}

- (void)update
{
	EOAttribute		*attribute = [self selectedAttribute];
	NSString			*valueType = [attribute valueType];
	
	if ([valueType isEqualToString:@"f"]) {
		[typePopUp selectItemWithTitle:@"Floating Point"];
	} else if ([valueType isEqualToString:@"d"]) {
		[typePopUp selectItemWithTitle:@"Double Precision Floating Point"];
	} else {
		[typePopUp selectItemWithTitle:@"Floating Point"];
	}
}

- (void)updateAttribute
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[attribute setValueClassName:@"NSNumber"];
}

- (void)selectType:(id)sender
{
	NSString		*title = [[sender selectedItem] title];
	
	if ([title isEqualToString:@"Floating Point"]) {
		[[self selectedAttribute] setValueType:@"f"];
	} else if ([title isEqualToString:@"Double Precision Floating Point"]) {
		[[self selectedAttribute] setValueType:@"d"];
	}
}

@end
