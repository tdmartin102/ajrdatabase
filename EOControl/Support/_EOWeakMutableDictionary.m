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

#import "_EOWeakMutableDictionary.h"

@interface _EOWeakContainer : NSObject
{
   id				object;
}

// This breaks the rules and returns a retained object.
+ (_EOWeakContainer *)containerWithObject:(id)anObject;
- (id)object;

@end


@implementation _EOWeakContainer

+ (_EOWeakContainer *)containerWithObject:(id)anObject
{
    // yep, return the retained object
    _EOWeakContainer	*container = [_EOWeakContainer alloc];
    container->object = anObject;
    return container;
}

- (id)object
{
   return object;
}

@end


@implementation _EOWeakMutableDictionary

- (id)init
{
	if (self = [super init])
		dictionary = [[NSMutableDictionary alloc] init];

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

- (void)setObject:(id)object forKey:(id)key
{
    _EOWeakContainer	*container = [_EOWeakContainer containerWithObject:object];
    [dictionary setObject:container forKey:key];
    // the follwing release is correct because the above returns a retained object
    [container release];
}

- (void)removeObjectForKey:(id)key
{
   [dictionary removeObjectForKey:key];
}

- (NSEnumerator *)keyEnumerator
{
   return [dictionary keyEnumerator];
}

@end
