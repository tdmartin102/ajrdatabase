//
//  EOQualifier-Model.m
//  EOAccess/
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOQualifier-Model.h"

@implementation EOQualifier (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner
{
	NSString		*className;
	NSZone		*zone = [self zone];
	
	[super init];
	
	className = [properties objectForKey:@"class"];
	if ([className isEqualToString:@"EOAndQualifier"]) {
		[self release];
		return [[EOAndQualifier allocWithZone:zone] initWithPropertyList:properties owner:owner];
	} else if ([className isEqualToString:@"EOOrQualifier"]) {
		[self release];
		return [[EOOrQualifier allocWithZone:zone] initWithPropertyList:properties owner:owner];
	} else if ([className isEqualToString:@"EOKeyValueQualifier"]) {
		[self release];
		return [[EOKeyValueQualifier allocWithZone:zone] initWithPropertyList:properties owner:owner];
	} else if ([className isEqualToString:@"EOSQLQualifier"]) {
		[self release];
		return [[EOSQLQualifier allocWithZone:zone] initWithPropertyList:properties owner:owner];
	}
	
	return self;
}

- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties
{
}

@end

@implementation EOAndQualifier (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner
{
	NSArray		*parts;
	int			x;
	int numParts;
	
	[super init];
	
	parts = [properties objectForKey:@"qualifiers"];
	qualifiers = [[NSMutableArray allocWithZone:[self zone]] init];
	
	numParts = [parts count];
	for (x = 0; x < numParts; x++) {
		EOQualifier	*qualifier;
		
		qualifier = [[EOQualifier allocWithZone:[self zone]] initWithPropertyList:[parts objectAtIndex:x] owner:owner];
		[(NSMutableArray *)qualifiers addObject:qualifier];
		[qualifier release];
	}
	
	return self;
}

- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties
{
	NSMutableArray			*array;
	NSMutableDictionary	*dictionary;
	int						x;
	int numQualifiers;
	
	[properties setObject:@"EOAndQualifier" forKey:@"class"];
	
	array = [[NSMutableArray allocWithZone:[self zone]] init];
	numQualifiers = [qualifiers count];
	for (x = 0; x < numQualifiers; x++) {
		dictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
		[[qualifiers objectAtIndex:x] encodeIntoPropertyList:dictionary];
		[array addObject:dictionary];
		[dictionary release];
	}
	
	[properties setObject:array forKey:@"qualifiers"];
	[array release];
}

@end

@implementation EOOrQualifier (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner
{
	NSArray		*parts;
	int			x;
	int numParts;
	
	[super init];
	
	parts = [properties objectForKey:@"qualifiers"];
	qualifiers = [[NSMutableArray allocWithZone:[self zone]] init];
	
	numParts = [parts count];
	for (x = 0; x < numParts; x++) {
		EOQualifier	*qualifier;
		
		qualifier = [[EOQualifier allocWithZone:[self zone]] initWithPropertyList:[parts objectAtIndex:x] owner:owner];
		[(NSMutableArray *)qualifiers addObject:qualifier];
		[qualifier release];
	}
	
	return self;
}

- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties
{
	NSMutableArray			*array;
	NSMutableDictionary	*dictionary;
	int						x;
	int numQualifiers;
	
	[properties setObject:@"EOOrQualifier" forKey:@"class"];
	
	array = [[NSMutableArray allocWithZone:[self zone]] init];
	numQualifiers = [qualifiers count];
	for (x = 0; x < numQualifiers; x++) {
		dictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
		[[qualifiers objectAtIndex:x] encodeIntoPropertyList:dictionary];
		[array addObject:dictionary];
		[dictionary release];
	}
	
	[properties setObject:array forKey:@"qualifiers"];
	[array release];
}

@end

@interface EOQualifierVariable (Model)
+ (id)qualifierVariableWithProperty:(id)theProperty;
@end

@implementation EOQualifierVariable (Model)
- (id)initWithPropertyList:(NSDictionary *)properties
{
	return [self initWithKey: [properties objectForKey: @"_key"]];
}

+ (id)qualifierVariableWithProperty:(id)theProperty
{
	if ([theProperty isKindOfClass: [NSDictionary class]]) {
		NSString *className = [theProperty objectForKey:@"class"];
		if ([className isEqual: @"EOQualifierVariable"]) {
			return [[[self alloc] initWithPropertyList: theProperty] autorelease];
		}
	} else {
		return theProperty;
	}
	return nil;
}

@end

@implementation EOKeyValueQualifier (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner
{
	[super init];
	
	key = [[properties objectForKey:@"key"] retain];
	value = [[EOQualifierVariable qualifierVariableWithProperty:[properties objectForKey:@"value"]] retain];
	operation = NSSelectorFromString([properties objectForKey:@"selectorName"]);
	
	return self;
}

- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties
{
	[properties setObject:@"EOKeyValueQualifier" forKey:@"class"];
	[properties setObject:key forKey:@"key"];
	[properties setObject:[value description] forKey:@"value"];
	[properties setObject:NSStringFromSelector(operation) forKey:@"selectorName"];
}

@end

@implementation EOSQLQualifier (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner
{
	[super init];
	
	return self;
}

- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties
{
}

@end
