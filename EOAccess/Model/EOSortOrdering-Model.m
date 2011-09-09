//
//  EOSortOrdering-Model.m
//  EOAccess/
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOSortOrdering-Model.h"

@implementation EOSortOrdering (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner
{
	NSString		*temp;
	
	[super init];
	
	key = [[properties objectForKey:@"key"] retain];
	temp = [properties objectForKey:@"selectorName"];
	if (temp) {
		selector = NSSelectorFromString(temp);
	}
	
	return self;
}

- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties
{
	[properties setObject:@"EOSortOrdering" forKey:@"class"];
	[properties setObject:key forKey:@"key"];
	[properties setObject:NSStringFromSelector(selector) forKey:@"selectorName"];
}

@end
