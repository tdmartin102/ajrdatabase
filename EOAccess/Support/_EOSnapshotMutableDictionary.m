//
//  _EOSnapshotMutableDictionary.m
//  EOAccess/
//
//  Created by Alex Raftis on 10/14/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "_EOSnapshotMutableDictionary.h"

#import "EODatabaseP.h"

@interface _EOSnapshotEnumerator : NSEnumerator
{
	NSEnumerator *enumerator;
}

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end


@implementation _EOSnapshotEnumerator

- (id)initWithDictionary:(NSDictionary *)dictionary
{
	enumerator = [[dictionary objectEnumerator] retain];
	return self;
}

- (void)dealloc
{
	[enumerator release];
	
	[super dealloc];
}

- (id)nextObject
{
	return [enumerator nextObject];
}

@end


@interface _EOReferenceCounter : NSObject
{
	@public
	
	int				referenceCount;
	id					object;
	NSTimeInterval	timestamp;
	NSDictionary	*toManyCache;
}

- (id)initWithObject:(id)anObject;
- (id)object;
- (int)referenceCount;
- (int)incrementReferenceCount;
- (int)decrementReferenceCount;

@end


@implementation _EOReferenceCounter

- (id)initWithObject:(id)anObject
{
    [super init];
	object = [anObject retain];
	referenceCount = 0;
	timestamp = [NSDate timeIntervalSinceReferenceDate];
	
	return self;
}

- (void) dealloc
{
    [object release];
    [super dealloc];
}

- (id)object
{
	return object;
}

- (int)referenceCount
{
	return referenceCount;
}

- (int)incrementReferenceCount
{
	referenceCount++;
	return referenceCount;
}

- (int)decrementReferenceCount
{
	referenceCount--;
	return referenceCount;
}

- (NSTimeInterval)timestamp
{
	return timestamp;
}

- (void)setTimestamp:(NSTimeInterval)aTimestamp;
{
	timestamp = aTimestamp;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"referenceCount = %d, %@", referenceCount, [object description]];
}

@end


@implementation _EOSnapshotMutableDictionary

- (id)init
{
	dictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
	
	return self;
}

- (void)dealloc
{
	[dictionary release];
	
	[super dealloc];
}

- (NSUInteger)count
{
   return [dictionary count];
}

- (id)objectForKey:(id)key
{
   return [[dictionary objectForKey:key] object];
}

- (id)objectForKey:(id)key after:(NSTimeInterval)timestamp
{
   _EOReferenceCounter	*container = [dictionary objectForKey:key];
	
	if (container) {
		if (container->timestamp < timestamp) return nil;
        return container->object;
	}
	
	return nil;
}

- (void)setObject:(id)object forKey:(id)key
{
   _EOReferenceCounter	*container = [dictionary objectForKey:key];
	
	if (!container) {
		container = [[_EOReferenceCounter allocWithZone:[self zone]] initWithObject:object];
		[dictionary setObject:container forKey:key];
		[container release];
	}
	else
		container->timestamp = [NSDate timeIntervalSinceReferenceDate];
}

- (void)removeObjectForKey:(id)key
{
// mont_rothstein @ yahoo.com 2005-12-07
// The below code wasn't quite right because it shouldn't be checking the reference count at all, it should simply delete the snapshot.  This method is only called by EODatabase's forgetSnapshotsForGlobalIDs: method, in which case the snapshot really does need to go away.
	[dictionary removeObjectForKey: key];
//   _EOReferenceCounter	*container = [dictionary objectForKey:key];
//	
//	if (container) {
//		if ([container decrementReferenceCount] == 0) {
//			// This isn't quite right, just yet.
//			//[dictionary removeObjectForKey:key];
//		}
//	} 
}

- (NSEnumerator *)keyEnumerator
{
   return [dictionary keyEnumerator];
}

- (NSEnumerator *)objectEnumerator
{
	return [[[_EOSnapshotEnumerator allocWithZone:[self zone]] initWithDictionary:self] autorelease];
}

- (NSTimeInterval)timestampForKey:(id)key
{
   _EOReferenceCounter	*container = [dictionary objectForKey:key];
	
	if (!container) return EODistantPastTimeInterval;
	
	return container->timestamp;
}

- (void)incrementReferenceCountForKey:(id)key
{
   _EOReferenceCounter	*container = [dictionary objectForKey:key];
	
	if (container) {
		container->referenceCount++;
	} 
}

- (void)decrementReferenceCountForKey:(id)key
{
   _EOReferenceCounter	*container = [dictionary objectForKey:key];
	
	if (container) {
		if (container->referenceCount >= 1) {
			container->referenceCount--;
		}
		if (container->referenceCount == 0 && ![EODatabase _isSnapshotRefCountingDisabled]) {
			[dictionary removeObjectForKey:key];
		}
	} 
}

- (NSString *)description
{
	return [dictionary description];
}

@end
