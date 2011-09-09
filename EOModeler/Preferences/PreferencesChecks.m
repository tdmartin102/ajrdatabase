//
//  PreferencesChecks.m
//  AJRDatabase
//
//  Created by Alex Raftis on Sun Sep 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "PreferencesChecks.h"

@implementation PreferencesChecks

- (NSString *)name
{
	return @"Checks";
}

- (NSString *)toolTip
{
	return @"Save time consistency checks";
}

- (BOOL)isPreferred
{
	return YES;
}

- (void)update
{
//	NSUserDefaults		*defaults = [NSUserDefaults standardUserDefaults];
}

@end
