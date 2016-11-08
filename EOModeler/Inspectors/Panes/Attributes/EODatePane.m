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
	return [NSDate class];
}

- (void)awakeFromNib
{
    NSArray *names;
    
    // set the time zone names in the button
    // and select the local time zone as the default
    names = [NSTimeZone knownTimeZoneNames];
    [timeZoneButton removeAllItems];
    [timeZoneButton addItemsWithTitles:names];    
    [timeZoneButton selectItemWithTitle:[[NSTimeZone localTimeZone] name]];     
}

- (void)update
{
	EOAttribute		*attribute = [self selectedAttribute];
	
    [timeZoneButton selectItemWithTitle:[[attribute serverTimeZone] name]]; 
}

- (void)updateAttribute
{
	EOAttribute		*attribute = [self selectedAttribute];
	
	[attribute setValueClassName:@"NSDate"];
}

- (void)selectTimeZone:(id)sender
{
    NSString *name;
    
    name = [sender titleOfSelectedItem];
	[[self selectedAttribute] setServerTimeZone:[NSTimeZone timeZoneWithName:name]];
}

@end
