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

#import <Foundation/Foundation.h>

/*!
 @class EOAutoreleasedMemory

 @discussion Allocations and returns a pointer to a block of memory. This is similar to how <EM>malloc()</EM> and related functions work, except that the memory is also added to a container object which is added into the autorelease pool. This allows you to return items from methods or functions which are not objects, but which still conform to Apple's retain/release/autorelease mechanism.
 */

@interface EOAutoreleasedMemory : NSObject
{
    void			*mutableBytes;
    NSUInteger		length;	/* Number of bytes used up... */
}

/*!
 @method autoreleasedMemoryWithCapacity:

 @discussion Returns a block of memory guaranteed to be at least capacity bytes of size. The memory is allocation with NSZoneMalloc from the default allocation zone. Make sure that if you return a pointer generated with this method call from one of your own methods that you document the fact that the data at the memory must be copied to be retained.

 @result Allocated memory which will be freed on the next clean up of the autorelease pool.
 */
+ (void *)autoreleasedMemoryWithCapacity:(NSUInteger)capacity;

@end
