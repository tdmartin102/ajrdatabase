//
//  EODecimalNumberPane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EODecimalNumberPane.h"

#import <EOAccess/EOAccess.h>

@implementation EODecimalNumberPane

+ (void)load { }

+ (NSString *)name
{
	return @"Decimal Number";
}

+ (Class)inspectedClass
{
	return [NSDecimalNumber class];
}

- (void)update
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[precisionField setIntValue:[attribute precision]];
	[scaleField setIntValue:[attribute scale]];
}

- (void)updateAttribute
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[attribute setValueClassName:@"NSDecimalNumber"];
}

- (void)setScale:(id)sender
{
	[[self selectedAttribute] setScale:[sender intValue]];
}

- (void)setPrecision:(id)sender
{
	// william @ sente.ch 2005-07-28
//	[[self selectedAttribute] setScale:[sender intValue]];
    [[self selectedAttribute] setPrecision:[sender intValue]];
}

@end
