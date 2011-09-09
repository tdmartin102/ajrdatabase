//
//  PreferencesBundles.m
//  AJRDatabase
//
//  Created by Alex Raftis on Sun Sep 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "PreferencesBundles.h"

@implementation PreferencesBundles

- (NSString *)name
{
	return @"Bundles";
}

- (NSString *)toolTip
{
	return @"Search paths for EOModeler bundles";
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
