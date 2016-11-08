//
//  PreferencesGeneral.m
//  AJRDatabase
//
//  Created by Alex Raftis on Sun Sep 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "PreferencesGeneral.h"

@implementation PreferencesGeneral

- (NSString *)name
{
	return @"General";
}

- (NSString *)toolTip
{
	return @"General application settings";
}

- (BOOL)isPreferred
{
	return YES;
}

- (void)update
{
	[fetchLimitText setIntegerValue:[[NSUserDefaults standardUserDefaults] integerForKey:@"FetchLimit"]];
}

- (void)setFetchLimit:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setInteger:[sender intValue] forKey:@"FetchLimit"];
}

@end
