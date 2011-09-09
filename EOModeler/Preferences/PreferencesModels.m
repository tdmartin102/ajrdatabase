//
//  PreferencesModels.m
//  AJRDatabase
//
//  Created by Alex Raftis on Sun Sep 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "PreferencesModels.h"

@implementation PreferencesModels

- (NSString *)name
{
	return @"Models";
}

- (NSString *)toolTip
{
	return @"Search paths for pre-loaded models";
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
