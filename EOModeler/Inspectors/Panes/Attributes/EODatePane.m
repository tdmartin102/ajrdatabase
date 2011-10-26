//
//  EODatePane.m
//  AJRDatabase
//
//  Created by Alex Raftis on 9/29/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EODatePane.h"

#import <EOAccess/EOAccess.h>

@implementation EODatePane

+ (void)load { }

+ (NSString *)name
{
	return @"Date";
}

+ (Class)inspectedClass
{
	return [NSCalendarDate class];
}

- (void)awakeFromNib
{
	[timeZoneChooser setTitle:@"Server Time Zone:"];
}

- (void)update
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[timeZoneChooser setTimeZone:[attribute serverTimeZone]];
}

- (void)updateAttribute
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[attribute setValueClassName:@"NSCalendarDate"];
}

- (void)selectTimeZone:(id)sender
{
	[[self selectedAttribute] setServerTimeZone:[sender timeZone]];
}

@end
