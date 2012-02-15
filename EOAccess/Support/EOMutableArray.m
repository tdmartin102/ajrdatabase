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

#import "EOMutableArray.h"

#import "EOArrayFaultHandler.h"

#import <EOControl/EOEditingContext.h>
#import <EOControl/EOFault.h>
#import <EOControl/EOGlobalID.h>

#import <objc/runtime.h>

@implementation EOMutableArray

- (id)init
{
	if (self = [super init])
		array = [[NSMutableArray allocWithZone:[self zone]] init];
   return self;
}

- (void)dealloc
{
   if (isDeallocating) {
      deallocRequested = YES;
      return;
   }
   isDeallocating = YES;

   [array release]; array = nil;

   [super dealloc];
}

- (NSUInteger)count
{
   return [array count];
}

- (id)objectAtIndex:(NSUInteger)index
{
   return [array objectAtIndex:index];
}

- (void)addObject:(id)object
{
   [array addObject:object];
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index
{
   [array insertObject:object atIndex:index];
}

- (void)removeLastObject
{
   [array removeLastObject];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
   [array removeObjectAtIndex:index];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object
{
   [array replaceObjectAtIndex:index withObject:object];
}

- (void)refaultWithSourceGlobalID:(EOGlobalID *)sourceGlobalID
                 relationshipName:(NSString *)aRelationshipName
                   editingContext:(EOEditingContext *)anEditingContext
{
	EOFaultHandler		*newHandler;

	// Free and make sure everything is 0! This must be done, since we're about to change our class back into a EOFault.
	isDeallocating = YES;
	deallocRequested = NO;
	[array release]; array = nil;
	if (deallocRequested) {
		// This flag is set if dealloc is called when we release our array. This can occur when we're part of retain cycle.
		[super dealloc];
		return;
	}
	isDeallocating = NO;
	_padding = 0;

	newHandler = [[EOArrayFaultHandler allocWithZone:[self zone]] initWithSourceGlobalID:sourceGlobalID relationshipName:aRelationshipName editingContext:anEditingContext];
   
	//self->isa = [EOFault class];
	// tom.martin @ riemer.com 2011-12-5
	// using object_setClass is just a hair safer.
	object_setClass(self, [EOFault class]);

	[EOFault setFaultHandler:newHandler forFault:(EOFault *)self];
	[newHandler release];
}

@end
