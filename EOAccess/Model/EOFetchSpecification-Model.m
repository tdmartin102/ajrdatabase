//
//  EOFetchSpecification-Model.m
//  EOAccess/
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOFetchSpecification-Model.h"

#import "EOQualifier-Model.h"
#import "EOModelGroup.h"
#import "EOEntity.h"

#import <EOControl/EOSortOrdering.h>

@implementation EOFetchSpecification (Model)

+ (EOFetchSpecification*) fetchSpecificationNamed: (NSString*)name entityNamed: (NSString*)anEntityName
{
	EOModelGroup *theGroup = [EOModelGroup defaultModelGroup];
	EOEntity *theEntity = [theGroup entityNamed: anEntityName];
	
	return [theEntity fetchSpecificationNamed: name];
}

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner
{
	NSArray		*array;
	
	if ((self = [super init]) == nil)
		return nil;
	
	entityName = [[properties objectForKey:@"entityName"] retain];
	fetchLimit = [[properties objectForKey:@"fetchLimit"] intValue];
	isDeep = [[properties objectForKey:@"isDeep"] hasPrefix:@"Y"];
	locksObjects = [[properties objectForKey:@"locksObjects"] hasPrefix:@"Y"];
	promptsAfterFetchLimit = [[properties objectForKey:@"promptsAfterFetchLimit"] hasPrefix:@"Y"];
	refreshObjects = [[properties objectForKey:@"refreshesRefetchedObjects"] hasPrefix:@"Y"]; 
	requiresAllQualifierBindingVariables = [[properties objectForKey:@"requiresAllQualifierBindingVariables"] hasPrefix:@"Y"];
	usesDistinct = [[properties objectForKey:@"usesDistinct"] hasPrefix:@"Y"];
	
	if ([properties objectForKey:@"qualifier"]) {
		qualifier = [[EOQualifier allocWithZone:[self zone]] initWithPropertyList:[properties objectForKey:@"qualifier"] owner:self];
	}
	
	array = [properties objectForKey:@"sortOrderings"];
	if ([array count]) {
		int			x;
		int numProperties;
		
		sortOrderings = [[NSMutableArray allocWithZone:[self zone]] init];
		numProperties = [array count];
		for (x = 0; x < numProperties; x++) {
			EOSortOrdering	*ordering;
			
			ordering = [[EOSortOrdering allocWithZone:[self zone]] initWithPropertyList:[array objectAtIndex:x] owner:self];
			[(NSMutableArray *)sortOrderings addObject:ordering];
			[ordering release];
		}
	}
	
	return self;
}

- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties
{
	[properties setObject:@"EOFetchSpecification" forKey:@"class"];
	[properties setObject:[NSNumber numberWithInt:fetchLimit] forKey:@"fetchLimit"];
	if (isDeep) [properties setObject:@"YES" forKey:@"isDeep"];
	if (locksObjects) [properties setObject:@"YES" forKey:@"locksObjects"];
	if (promptsAfterFetchLimit) [properties setObject:@"YES" forKey:@"promptsAfterFetchLimit"];
	if (refreshObjects) [properties setObject:@"YES" forKey:@"refreshesRefetchedObjects"];
	if (requiresAllQualifierBindingVariables) [properties setObject:@"YES" forKey:@"requiresAllQualifierBindingVariables"];
	if (usesDistinct) [properties setObject:@"YES" forKey:@"usesDistinct"];
	[properties setObject:entityName forKey:@"entityName"];
	
	if (qualifier) {
		NSMutableDictionary	*workDictionary;
		
		workDictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
		[qualifier encodeIntoPropertyList:workDictionary];
		[properties setObject:workDictionary forKey:@"qualifier"];
		[workDictionary release];
	}
	
	if ([sortOrderings count]) {
		int						x;
		int numSortOrderings;
		NSMutableArray			*workArray;
		NSMutableDictionary	*workDictionary;
		
		workArray = [[NSMutableArray allocWithZone:[self zone]] init];
		numSortOrderings = [sortOrderings count];
		for (x = 0; x < numSortOrderings; x++) {
			workDictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
			[[sortOrderings objectAtIndex:x] encodeIntoPropertyList:workDictionary];
			[workArray addObject:workDictionary];
			[workDictionary release];
		}
		[properties setObject:workArray forKey:@"sortOrderings"];
		[workArray release];
	}
}

- (void)_setEntity:(EOEntity *)anEntity
{
	[userInfo setObject:anEntity forKey:@"_entity"];
}

- (EOEntity *)entity
{
	return [userInfo objectForKey:@"_entity"];
}

- (void)setName:(NSString *)name
{
	[userInfo setObject:name forKey:@"_name"];
}

- (NSString *)name
{
	return [userInfo objectForKey:@"_name"];
}

@end
