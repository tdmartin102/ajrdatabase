//
//  NSArray-EO.m
//  EOControl
//
//  Created by Alex Raftis on 11/8/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSArray-EO.h"

#import "EOFormat.h"
#import "EOQualifier.h"
#import "EOSortOrdering.h"

static NSComparisonResult _eoSorter(id one, id two, void *context)
{
	NSArray					*orderings = (NSArray *)context;
	int						x;
	int numOrderings;
	EOSortOrdering			*ordering;
	SEL						selector;
	NSString					*key;
	NSComparisonResult		result;
	id						value1;
	id						value2;
	
	numOrderings = [orderings count];
	
	for (x = 0; x < numOrderings; x++) {
		ordering = [orderings objectAtIndex:x];
		selector = [ordering selector];
		// mont_rothstein @ yahoo.com 2004-12-20
		// Added initialization of key
		key = [ordering key];
		
		if (selector == NULL) continue;
		
		value1 = [one valueForKey:key];
		value2 = [two valueForKey:key];
		
		// mont_rothstein @ yahoo.com 2005-03-17
		// Added handling of NULL values.
		if ((value1 == nil) && (value2 == nil)) continue;
		else if (value1 == nil) return NSOrderedAscending;
		else if (value2 == nil) return NSOrderedDescending;
		
		result = (NSInteger)[value1 performSelector:selector withObject: value2];
		if (result != NSOrderedSame) {
			return result;
		}
	}
	
	return NSOrderedSame;
}

// mont_rothstein @ yahoo.com 2005-01-08
// Moved filteredArrayUsingQualifier: into EOQualifierExtras category from EO category
// to mirror move of interface declaration to EOQualifier.h as per WO 4.5 API.
@implementation NSArray (EOQualifierExtras)

- (NSArray *)filteredArrayUsingQualifier:(EOQualifier *)qualifier
{
	NSMutableArray		*array = [[NSMutableArray alloc] initWithCapacity:[self count]];
	int					x;
	int max;
	
	max = [self count];
	
	for (x = 0; x < max; x++) {
		// mont_rothstein @ yahoo.com 2005-06-20
		// This was trying to access array instead of self.
		id		object = [self objectAtIndex:x];
		
		if ([qualifier evaluateWithObject:object]) {
			[array addObject:object];
		}
	}
	
	return [array autorelease];
}

@end


// mont_rothstein @ yahoo.com 2005-01-08
// Moved sortedArrayUsingKeyOrderArray: from EO category or here to match move of
// interface declaration to EOSortOrdering.h as per WO 4.5 API
@implementation NSArray (EOKeyBasedSorting)

- (NSArray *)sortedArrayUsingKeyOrderArray:(NSArray *)order
{
	return [self sortedArrayUsingFunction:_eoSorter context:order];
}

@end


@implementation NSArray (EO)

- (id)computeAvgForKey:(NSString *)key
{
	return [[self computeSumForKey:key] decimalNumberByDividingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithInt:[self count]]];
}

- (id)computeCountForKey:(NSString *)key
{
	return [NSNumber numberWithInt:[self count]];
}

- (id)computeMaxForKey:(NSString *)key
{
	id			max = nil;
	int		x;
	int numObjects;
	
	numObjects = [self count];
	
	for (x = 0; x < numObjects; x++) {
		id		value = [[self objectAtIndex:x] valueForKeyPath:key];
		
		if (max == nil) max = value;
		else if ([(NSNumber *)value compare:max] > 0) max = value;
	}
	
	return max;
}

- (id)computeMinForKey:(NSString *)key
{
	id			min = nil;
	int		x;
	int max;
	
	max = [self count];
	
	for (x = 0; x < max; x++) {
		id		value = [[self objectAtIndex:x] valueForKeyPath:key];
		
		if (min == nil) min = value;
		else if ([(NSNumber *)value compare:min] < 0) min = value;
	}
	
	return min;
}

- (id)computeSumForKey:(NSString *)key
{
	NSDecimalNumber	*number = [NSDecimalNumber zero];
	int					x;
	int max;
	
	if ([self count] == 0) return number;
	
	max = [self count];
	
	for (x = 0; x < max; x++) {
		id		value = [[self objectAtIndex:x] valueForKeyPath:key];
		
		number = [number decimalNumberByAdding:(NSDecimalNumber *)[NSDecimalNumber numberWithDouble:[value floatValue]]];
	}
	
	return number;
}

- (id)_aggregateForKey:(NSString *)key
{
	NSRange		range = [key rangeOfString:@"."];
	NSString		*function;
	SEL			selector;
	
	if (range.location == NSNotFound) {
		[NSException raise:NSInternalInconsistencyException format:@"aggregate key passed to valueForKey: in NSArray must follow the form: @<function>.<key>"];
	}
	
	function = [key substringWithRange:(NSRange){1, range.location - 1}];
	key = [key substringFromIndex:range.location + range.length];
	
	selector = NSSelectorFromString(EOFormat(@"compute%@ForKey:", [function capitalizedString]));
	if (selector == NULL) {
		[NSException raise:NSInternalInconsistencyException format:@"No aggregate function named %@", function];
	}
	
	return [self performSelector:selector withObject:key];
}

- (id)valueForKey:(NSString *)key
{
	NSMutableArray		*result;
	int					x;
	int max;

	if ([key hasPrefix:@"@"]) {
		return [self _aggregateForKey:key];
	}
	/*! @todo Determine if this should be done, or if it breaks things.  It was done to allow count to be called on arrays from .wod files but something in the EOF docs sounded like it possibly shouldn't be done. */
	// mont_rothstein @ yahoo.com 2004-12-20
	// Added special handling for count
	else if ([key isEqualToString: @"count"])
	{
		return [NSNumber numberWithInt: [self count]];
	}
	
	result = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:[self count]];
	
	max = [self count];
	
	for (x = 0; x < max; x++) {
		id			value = [[self objectAtIndex:x] valueForKey:key];
		
		if (value) {
			[result addObject:value];
		} else {
			[result addObject:[NSNull null]];
		}
	}
	
	return [result autorelease];
}

- (id)shallowCopy
{
	return [[[NSArray allocWithZone:[self zone]] initWithArray:self copyItems:NO] autorelease];
}


@end


@implementation NSMutableArray (EOSortOrdering)

- (void)sortUsingKeyOrderArray:(NSArray *)sortOrderings
{
   [self sortUsingFunction:_eoSorter context:sortOrderings];
}

@end


