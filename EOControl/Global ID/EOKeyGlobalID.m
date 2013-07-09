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

#import "EOKeyGlobalID.h"

#import "EOAndQualifier.h"
#import "EOKeyValueQualifier.h"

#import <objc/objc-class.h>

@implementation EOKeyGlobalID

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
	   values = (id *)NSZoneMalloc([self zone], sizeof(id) * count);
	   keys = (NSString **)NSZoneMalloc([self zone], sizeof(id) * count);

		hash = [entityName hash];
	   for (x = 0; x < count; x++) {
		  values[x] = [someValues[x] retain];
		  keys[x] = [primaryKeys[x] retain];

			hash ^= [keys[x] hash];
			hash ^= [values[x] hash];
	   }
   }

   return self;
}

- (id)initWithEntityName:(NSString *)anEntityName keys:(id *)keyValues count:(int)aCount zone:(NSZone *)zone
{
	int			x;
	
	if (self = [super init])
	{
		count = aCount;
		
		entityName = [anEntityName retain];
		values = (id *)NSZoneMalloc(zone, sizeof(id) * count);
		
		hash = [entityName hash];
		for (x = 0; x < count; x++) {
			values[x] = [keyValues[x] retain];
			
			hash ^= [values[x] hash];
		}
	}
	
	return self;
}

+ (id)globalIDWithEntityName:(NSString *)anEntityName keys:(id *)keyValues keyCount:(unsigned)aCount zone:(NSZone *)zone;
{
	return [[[self alloc] initWithEntityName:anEntityName keys:(id *)keyValues count:aCount zone: zone] autorelease];
}

- (void)dealloc
{
   int		x;
   
   [entityName release];

   for (x = 0; x < count; x++) {
      if (values) [values[x] release];
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

- (NSUInteger)hash
{
	return hash;
}

- (BOOL)isEqual:(id)other
{
	if (other == self) return YES;
    if (other == nil) return NO;
	
   //if (((struct objc_class *)other)->isa == ((struct objc_class *)self)->isa) {
   // tom.martin @ riemer.com -- 2011/09/15
   if (object_getClass(other) ==  object_getClass(self)) {
      EOKeyGlobalID    *trueOther = other;
      int                     x;

		// Entity name's should be unique strings across all entities, since they'll be the exact same entity.
      if (entityName != trueOther->entityName) return NO;

      for (x = 0; x < count; x++) {
         if (![values[x] isEqual:trueOther->values[x]]) return NO;
      }

      return YES;
   }

   return NO;
}

- (NSString *)description
{
    NSMutableString	*buffer = [@"[EOKeyGlobalID: " mutableCopyWithZone:[self zone]];
    int					x;
    
    [buffer appendString:(entityName) ? entityName : @"No Entity Set"];
    [buffer appendString:@", ("];

    for (x = 0; x < count; x++) {
        if (x != 0) [buffer appendString:@", "];
        [buffer appendString:keys[x]];
        [buffer appendString:@"="];
        [buffer appendString:[values[x] description]];
   }

   [buffer appendString:@")]"];

   return [buffer autorelease];
}

- (NSString **)keys
{
   return keys;
}

- (id *)values
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
      subqualifier = [EOKeyValueQualifier qualifierWithKey:keys[x] value:values[x]];
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
         return values[x];
      }
   }

   return nil;
}

- (NSDictionary *)primaryKey
{
   NSMutableDictionary	*primaryKey = [NSMutableDictionary dictionary];
   int						x;

   for (x = 0; x < count; x++) {
      [primaryKey setObject:values[x] forKey:keys[x]];
   }

   return primaryKey;
}

- (NSComparisonResult)compare:(id)other
{
	if (other == self) return NSOrderedSame;
	
   if ([other isKindOfClass:[EOKeyGlobalID class]]) {
      EOKeyGlobalID		*o = other;
      int							x;
      int							result;

      for (x = 0; x < count; x++) {
         result = [(NSNumber *)values[x] compare:o->values[x]];
         if (result != NSOrderedSame) return result;
      }

      return NSOrderedSame;
   }
   return [super compare:other];
}

- (NSArray *)keyValuesArray
{
	return [NSArray arrayWithObjects: values count: count];
}

- (id *)keyValues
{
    return values;
}

- (unsigned int)keyCount
{
    return count;
}

@end
