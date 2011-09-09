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

#import "EOSortOrdering.h"

#import "EOLog.h"

SEL EOCompareAscending;
SEL EOCompareDescending;
SEL EOCompareCaseInsensitiveAscending;
SEL EOCompareCaseInsensitiveDescending;

@implementation EOSortOrdering

+ (void)load
{
	EOCompareAscending = @selector(compareAscending:);
	EOCompareDescending = @selector(compareDescending:);
	EOCompareCaseInsensitiveAscending = @selector(compareCaseInsensitiveAscending:);
	EOCompareCaseInsensitiveDescending = @selector(compareCaseInsensitiveDescending:);
}

+ (id)sortOrderingWithKey:(NSString *)aKey selector:(SEL)aSelector
{
   return [[[self alloc] initWithKey:aKey selector:aSelector] autorelease];
}

- (id)initWithKey:(NSString *)aKey selector:(SEL)aSelector
{
   [super init];

   key = [aKey retain];
   selector = aSelector;

   return self;
}

- (void)dealloc
{
   [key release];

   [super dealloc];
}

- (NSString *)key
{
   return key;
}

- (SEL)selector
{
   return selector;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4

+ (id)sortOrderingWithSortDescriptor:(NSSortDescriptor *)sortDescriptor
{
	[[[self alloc] initWithSortDescriptor:sortDescriptor] autorelease];
}

- (id)initWithSortDescriptor:(NSSortDescriptor *)sortDescriptor
{
	key = [[sortDescriptor key] retain];
	if ([sortDescriptor selector] == NULL) {
		selector = [sortDescriptor ascending] ? EOCompareAscending : EOCompareDescending;
	} else {
		if ([sortDescriptor selector] == @selector(caseInsensitiveCompare:)) {
			selector = [sortDescriptor ascending] ? EOCompareCaseInsensitiveAscending : EOCompareCaseInsensitiveDescending;
		} else {
			[EOLog log:EOLogWarning withFormat:@"Attempt to create an EOSortOrdering from an NSSortDescriptor with an unknown comparison selector (%S). Sort will default to ascending.", [sortDescriptor selector]];
			selector = [sortDescriptor selector];
		}
	}
	
	return self;
}

- (NSSortDescriptor *)sortDescriptor
{
	NSSortDescriptor	*descriptor = nil;
	SEL					direction = [self selector];
	
	if (direction == EOCompareAscending) {
		descriptor = [[NSSortDescriptor allocWithZone:[self zone]] initWithKey:[self key] ascending:YES];
	} else if (direction == EOCompareDescending) {
		descriptor = [[NSSortDescriptor allocWithZone:[self zone]] initWithKey:[self key] ascending:NO];
	} else if (direction == EOCompareCaseInsensitiveAscending) {
		descriptor = [[NSSortDescriptor allocWithZone:[self zone]] initWithKey:[self key] ascending:YES selector:@selector(caseInsensitiveCompare:)];
	} else if (direction == EOCompareCaseInsensitiveDescending) {
		descriptor = [[NSSortDescriptor allocWithZone:[self zone]] initWithKey:[self key] ascending:NO selector:@selector(caseInsensitiveCompare:)];
	}
	
	return [descriptor autorelease];
}

#endif

#pragma mark <EOKeyValueArchiving>

- (id)initWithKeyValueUnarchiver:(EOKeyValueUnarchiver *)unarchiver
{
    if ((self = [super init]) != nil) {
        NSString *s;
        
        key = [[unarchiver decodeObjectForKey:@"key"] copy];
        
        if ((s = [unarchiver decodeObjectForKey:@"selector"]) != nil)
            selector = NSSelectorFromString(s);
        else if ((s = [unarchiver decodeObjectForKey:@"selectorName"]) != nil) {
            if (![s hasSuffix:@":"]) s = [s stringByAppendingString:@":"];
            selector = NSSelectorFromString(s);
        }
    }
    return self;
}

- (void)encodeWithKeyValueArchiver:(EOKeyValueArchiver *)archiver 
{
    [archiver encodeObject:[self key] forKey:@"key"];
    [archiver encodeObject:NSStringFromSelector([self selector])
                    forKey:@"selectorName"];
}

@end


@implementation NSObject (EOSortOrdering)

- (NSComparisonResult)compareAscending:(id)other
{
	if ([self respondsToSelector:@selector(compare:)]) {
		return [(NSString *)self compare:other];
	}
	return [[self description] compare:[other description]];
}

- (NSComparisonResult)compareDescending:(id)other
{
	return -[self compareAscending:other];
}

- (NSComparisonResult)compareCaseInsensitiveAscending:(id)other
{
	return [[self description] caseInsensitiveCompare:[other description]];
}

- (NSComparisonResult)compareCaseInsensitiveDescending:(id)other
{
	return -[[self description] caseInsensitiveCompare:[other description]];
}

@end
