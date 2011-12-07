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

#import "_EOSelectorTable.h"

typedef struct _eoHashItem {
   NSString		*key;
   SEL			selector;
   int			retainCount;
   NSZone		*zone;
} EOHashItem;

static NSUInteger _eoHash(NSHashTable *table, const void *item)
{
   return [((EOHashItem *)item)->key hash];
}

static BOOL _eoIsEqual(NSHashTable *table, const void *item1, const void *item2)
{
   return [((EOHashItem *)item1)->key isEqual:((EOHashItem *)item2)->key];
}

static void _eoRetain(NSHashTable *table, const void *item)
{
   ((EOHashItem *)item)->retainCount++;
}

static void _eoRelease(NSHashTable *table, void *item)
{
   ((EOHashItem *)item)->retainCount--;
   if (((EOHashItem *)item)->retainCount == 0) {
      [((EOHashItem *)item)->key release];
      NSZoneFree(((EOHashItem *)item)->zone, item);
   }
}

static NSString *_eoDescribe(NSHashTable *table, const void *item)
{
   return NSStringFromSelector(((EOHashItem *)item)->selector);
}

static NSHashTableCallBacks _eoHashTableCallbacks = {
   _eoHash,
   _eoIsEqual,
   _eoRetain,
   _eoRelease,
   _eoDescribe
};

@implementation _EOSelectorTable

- (id)init
{
	if (self = [super init])
		table = NSCreateHashTable(_eoHashTableCallbacks, 0);
	return self;
}

- (void)dealloc
{
   NSFreeHashTable(table);
   
   [super dealloc];
}

- (void)setSelector:(SEL)selector forKey:(NSString *)key
{
   NSZone			*zone = [self zone];
   EOHashItem		*newItem = NSZoneMalloc(zone, sizeof(EOHashItem));

   newItem->key = [key copyWithZone:zone];
   newItem->selector = selector;
   newItem->retainCount = 0;
   newItem->zone = zone;

   NSHashInsert(table, newItem);
}

- (SEL)selectorForKey:(NSString *)key
{
   EOHashItem	keyItem = { key, NULL, 0, NULL };
   EOHashItem	*item;

   item = NSHashGet(table, &keyItem);

   if (item != NULL) return item->selector;

   return NULL;
}

@end
