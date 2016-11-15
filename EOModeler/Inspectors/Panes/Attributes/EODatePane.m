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
    NSString        *name;
    NSTimeZone      *tz;
    
    // There are a lot of text that WORKS just fine such as 'US/Eastern' which
    // are NOT in the list of 'knownTimeZoneName'  so we could translate it
    // but that might be pretty hard to do and come out correctly.  I think we
    // will just INSERT it into our listing.
    name = [[attribute serverTimeZone] name];
    if ([name length])
    {
        NSArray         *names;
        NSUInteger      i;
        BOOL            inserted;
        
        names = [timeZoneButton itemTitles];
        i = [names indexOfObject:name];
        if (i == NSNotFound)
        {
            // check to see if it is valid.
            tz = [NSTimeZone timeZoneWithName:name];
            if (tz)
            {
                // it is valid, but not listed, so lets add it.
                NSString *aName;
                i = 0;
                inserted = NO;
                for (aName in names)
                {
                    if ([name compare:aName] == NSOrderedAscending)
                    {
                        [timeZoneButton insertItemWithTitle:name atIndex:i];
                        break;
                    }
                    ++i;
                }
                if (! inserted)
                    [timeZoneButton addItemWithTitle:name];
                
            }
        }
    }
    
    [timeZoneButton selectItemWithTitle:name];
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
