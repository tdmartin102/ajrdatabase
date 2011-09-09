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

#import "EOAutoreleasedMemory.h"

#define defaultMallocMemoryCapacity 500
#define mallocMemoryKey @"NSAutoreleaseMalloc"

@implementation EOAutoreleasedMemory

- (id)initWithCapacity:(unsigned int)cap
{
   [super init];
   mutableBytes = NSZoneMalloc(NULL, cap);
   length = 0;
   return self;
}

- (unsigned int)remainingCapacity
{ /* This method only correct for instances created with defaultMallocMemoryCapacity */ 
    return defaultMallocMemoryCapacity - length;
}

- (void *)mallocMemoryWithCapacity:(unsigned)cap\
{
    void *ret = mutableBytes + length;
    length += cap;
    return ret;
}

- (void)dealloc
{
   NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
   
   if ([[threadDictionary objectForKey:mallocMemoryKey] nonretainedObjectValue] == self) { 
      [threadDictionary removeObjectForKey:mallocMemoryKey];
   }

   NSZoneFree(NULL, mutableBytes);
   [super dealloc];
}

+ (void *)autoreleasedMemoryWithCapacity:(unsigned)cap
{
   EOAutoreleasedMemory *toBeUsed = nil;

   if (cap > defaultMallocMemoryCapacity) {	/* Definitely need a new one... */
      toBeUsed = [[[EOAutoreleasedMemory allocWithZone:NULL] initWithCapacity:cap] autorelease]; 
      return [toBeUsed mallocMemoryWithCapacity:cap];
   } else {
      unsigned remainingCapacityInExistingOne;
      NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
      toBeUsed = [[threadDictionary objectForKey:mallocMemoryKey] nonretainedObjectValue];
      remainingCapacityInExistingOne = toBeUsed ? [toBeUsed remainingCapacity] : 0;
      
      if (cap > remainingCapacityInExistingOne) { /* Not enough room in existing one... */
         if (defaultMallocMemoryCapacity - cap > remainingCapacityInExistingOne) { /* The new one will have more room; install it as the default */
            toBeUsed = [[[EOAutoreleasedMemory allocWithZone:NULL] initWithCapacity:defaultMallocMemoryCapacity] autorelease];
            [threadDictionary setObject:[NSValue valueWithNonretainedObject:toBeUsed] forKey:mallocMemoryKey];
         } else { /* The new one will have less room; might as well not install it and just use it here... */
            toBeUsed = [[[EOAutoreleasedMemory allocWithZone:NULL] initWithCapacity:cap] autorelease]; 
         }
      }
      return [toBeUsed mallocMemoryWithCapacity:cap];
    }
}

@end

