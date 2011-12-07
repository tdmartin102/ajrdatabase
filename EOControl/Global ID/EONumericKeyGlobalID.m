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

#import "EONumericKeyGlobalID.h"

#import "EOAndQualifier.h"
#import "EOFormat.h"
#import "EOKeyValueQualifier.h"

#import <objc/objc-class.h>

@implementation EONumericKeyGlobalID


+ (id)globalIDWithEntityName:(NSString *)anEntityName keys:(NSString **)primaryKeys values:(id *)someValues count:(int)aCount
{
   return [[[self alloc] initWithEntityName:anEntityName keys:primaryKeys values:someValues count:aCount] autorelease];
}

- (id)initWithEntityName:(NSString *)anEntityName keys:(NSString **)primaryKeys values:(id *)someValues count:(int)aCount
{
	int			x;

	if (self = [super init])
	{
	   count = aCount;
		
	   entityName = [anEntityName retain];
	   values = (unsigned long long *)NSZoneMalloc([self zone], sizeof(unsigned long long) * count);
	   keys = (NSString **)NSZoneMalloc([self zone], sizeof(id) * count);
		
		hash = [entityName hash];
		// This uses random to prevent the hash values from being sequential. This happens, for example, if you fetch a large number of items from the same entity in a database. This creates serious slow downs in NSDictionary's hash table. By using call srandom() on the first item and then hashing xor'd with random(), we always produce the same number, but get something "random" enough to prevent the slow down in NSDictionary.
	   for (x = 0; x < count; x++) {
		   // mont_rothstein @ yahoo.com 2004-12-03
		   // If the value at someValues[x] is nil, then we need to return nil because there isn't
		   // enough data to create the global ID.  This happens when there is a NULL in the database.
		   if (someValues[x] == nil) return nil;
		   values[x] = [someValues[x] unsignedLongLongValue];
		  keys[x] = [primaryKeys[x] retain];
			if (x == 0) {
				srandom([someValues[x] unsignedLongValue]);
			}
			hash ^= random();
	   }
	}
	
	return self;
}

- (void)dealloc
{
   int		x;
   
   [entityName release];
	
   for (x = 0; x < count; x++) {
      if (keys) [keys[x] release];
   }
   if (values != NULL) NSZoneFree([self zone], values);
   if (keys != NULL) NSZoneFree([self zone], keys);
	
   [super dealloc];
}

- (BOOL)isTemporary
{
   return NO;
}

- (unsigned)hash
{
	return hash;
}

- (BOOL)isEqual:(id)other
{
	if (other == self) return YES;
	
	//if (((struct objc_class *)other)->isa == ((struct objc_class *)self)->isa) {
	// tom.martin @ riemer.com -- 2011/09/15
	if (((Class)other)->isa == ((Class)self)->isa) {
		EONumericKeyGlobalID    *trueOther = other;
		//int                     x;
	// Entity name's should be unique strings across all entities, since they'll be the exact same entity.
	if (entityName != trueOther->entityName) return NO;		
      return memcmp(values, trueOther->values, sizeof(unsigned long long) * count) == 0;
   }
	
   return NO;
}

- (NSString *)description
{
   NSMutableString	*buffer = [@"[EONumericKeyGlobalID:" mutableCopyWithZone:[self zone]];
   int					x;
	
   for (x = 0; x < count; x++) {
      if (x != 0) [buffer appendString:@", "];
      [buffer appendString:keys[x]];
      [buffer appendString:@"="];
      [buffer appendString:EOFormat(@"%qu", values[x])];
   }
	
   [buffer appendString:@"]"];
	
   return buffer;
}

- (NSString **)keys
{
   return keys;
}

- (unsigned long long *)values
{
   return values;
}

- (NSString *)entityName
{
   return entityName;
}

- (EOQualifier *)buildQualifier
{
   int				x;
   EOQualifier		*qualifier = nil;
   EOQualifier		*subqualifier;
	
   for (x = 0; x < count; x++) {
      subqualifier = [EOKeyValueQualifier qualifierWithKey:keys[x] value:[NSNumber numberWithUnsignedLongLong:values[x]]];
      if (x == 0) {
         qualifier = subqualifier;
      } else {
         qualifier = [EOAndQualifier qualifierFor:qualifier and:subqualifier];
      }
   }
	
   return qualifier;
}

- (id)valueForKey:(NSString *)key
{
   int     x;
	
   for (x = 0; x < count; x++) {
      if ([keys[x] isEqual:key]) {
         return [NSNumber numberWithUnsignedLongLong:values[x]];
      }
   }
	
   return nil;
}

- (NSDictionary *)primaryKey
{
   NSMutableDictionary	*primaryKey = [NSMutableDictionary dictionary];
   int						x;
	
   for (x = 0; x < count; x++) {
      [primaryKey setObject:[NSNumber numberWithUnsignedLongLong:values[x]] forKey:keys[x]];
   }
	
   return primaryKey;
}

- (NSComparisonResult)compare:(id)other
{
	if (other == self) return NSOrderedSame;
	
   if ([other isKindOfClass:[EONumericKeyGlobalID class]]) {
      EONumericKeyGlobalID		*o = other;
      int							x;
		
      for (x = 0; x < count; x++) {
         if (values[x] < o->values[x]) return NSOrderedDescending;
         if (values[x] > o->values[x]) return NSOrderedAscending;
      }
		
      return NSOrderedSame;
   }

   return [super compare:other];
}

@end
