/*%*%*%*%*
Copyright (C) 1995-2004 Alex J. Raftis

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

Or, contact the author,

Alex J. Raftis
709 Bay Area Blvd.
League City, TX 77573
mailto:alex@raftis.net
http://www.raftis.net/~alex/
 *%*%*%*%*/
//
//  EODebug.m
//  News2OpenBase
//
//  Created by Alex Raftis on Thu Oct 31 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "EODebug.h"

#import <EOControl/EOControl.h>

BOOL	EOAdaptorDebugEnabled = NO;
BOOL	EODatabaseContextDebugEnabled = NO;
BOOL	EORegistrationDebugEnabled = NO;

@interface EODebug
@end

@implementation EODebug

//static NSDictionary			*environment;
//static NSArray				*arguments;
//static NSUserDefaults		*defaults;

static void setBoolean(BOOL *boolean, NSString *key,NSDictionary *environment, NSArray *arguments, NSUserDefaults *defaults)
{
	int				index = [arguments indexOfObject:EOFormat(@"-%@", key)];
	NSString		*value = nil;
   
	if (index != NSNotFound)
	{
		// we found it as an argument
		if (index + 1 < [arguments count])
		{
			value = [arguments objectAtIndex:index + 1];
		}
	}
	
	if (! value)
	{
		// try environment
		value = [environment objectForKey:key];
	}
	if (! value)
	{
		// try defaults
		value = [defaults stringForKey:key];
	}

	if (value) 
	{
		if (([value caseInsensitiveCompare:@"yes"] == NSOrderedSame) ||
			([value caseInsensitiveCompare:@"true"] == NSOrderedSame))
		{
			*boolean = YES;
		} 
		else if (([value caseInsensitiveCompare:@"no"] == NSOrderedSame) ||
                 ([value caseInsensitiveCompare:@"false"] == NSOrderedSame)) 
		{
			*boolean = NO;
		}
   }
}

+ (void)load
{
	// Three places to check for things:
	//   arguments
	//   environment
	//   defaults
	NSDictionary		*environment;
	NSArray				*arguments;
	NSUserDefaults		*defaults;
	NSAutoreleasePool	*subpool = [[NSAutoreleasePool alloc] init];
	NSProcessInfo		*info = [NSProcessInfo processInfo];
   
	environment = [info environment];
	arguments = [info arguments];
	defaults = [NSUserDefaults standardUserDefaults];

	setBoolean(&EOAdaptorDebugEnabled, @"EOAdaptorDebugEnabled", environment, arguments, defaults);
	setBoolean(&EODatabaseContextDebugEnabled, @"EODatabaseContextDebugEnabled", environment, arguments, defaults);
	setBoolean(&EORegistrationDebugEnabled, @"EORegistrationDebugEnabled", environment, arguments, defaults);
	setBoolean(&EOMemoryDebug, @"EOMemoryDebug", environment, arguments, defaults);

	if (EOAdaptorDebugEnabled || EODatabaseContextDebugEnabled || EORegistrationDebugEnabled || EOMemoryDebug)
	{
		[EOLogger setLogDebug:YES];
		[EOLogger setLogInfo:YES];
	}
	
	[subpool release];
}

@end
