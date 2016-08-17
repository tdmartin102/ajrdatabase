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

#import "EOSQLFormatter.h"

#import "EOAdaptor.h"
#import "EOAttributeP.h"
#import "EODatabase.h"
#import "EODebug.h"
#import "EOEntity.h"
#import "EOModel.h"
#import "EOSQLNullFormatter.h"
#import "EOSQLArrayFormatter.h"
#import "EOSQLDateFormatter.h"
#import "EOSQLNullFormatter.h"
#import "EOSQLNumberFormatter.h"
#import "EOSQLObjectFormatter.h"
#import "EOSQLStringFormatter.h"


#import <EOControl/EOControl.h>

static NSMutableDictionary		*cache = nil;
static EOSQLFormatter			*nullFormatter;

@implementation  EOSQLFormatter

+ (void)initialize
{
   if (cache == nil) {
      cache = [[NSMutableDictionary alloc] init];
      nullFormatter = [[EOSQLNullFormatter alloc] init];

   	[EOSQLFormatter registerFormatter:[EOSQLArrayFormatter class]];
   	[EOSQLFormatter registerFormatter:[EOSQLDateFormatter class]];
   	[EOSQLFormatter registerFormatter:[EOSQLNullFormatter class]];
   	[EOSQLFormatter registerFormatter:[EOSQLNumberFormatter class]];
   	[EOSQLFormatter registerFormatter:[EOSQLObjectFormatter class]];
   	[EOSQLFormatter registerFormatter:[EOSQLStringFormatter class]];
	}
}

+ (Class)formattedClass
{
   [NSException raise:NSInternalInconsistencyException format:@"The subclass \"%@\" of EOSQLFormatter must implement +[EOSQLFormatter formattedClass].", [self class]];
   return Nil;
}

+ (Class)adaptorClass
{
   return [EOAdaptor class];
}

+ (void)registerFormatter:(Class)aFormatter
{
   EOSQLFormatter			*formatter = [[aFormatter alloc] init];
   NSMutableDictionary	*bucket;
   
   if (EORegistrationDebugEnabled) [EOLog logDebugWithFormat:@"Registered Formatter: %@\n", NSStringFromClass(aFormatter)];

   bucket = [cache objectForKey:[aFormatter adaptorClass]];
   if (bucket == nil) {
      bucket = [[NSMutableDictionary alloc] init];
      [cache setObject:bucket forKey:(id <NSCopying>)[aFormatter adaptorClass]];
      [bucket release];
   }
   [bucket setObject:formatter forKey:(id <NSCopying>)[aFormatter formattedClass]];
   [formatter release];
}

+ (EOSQLFormatter *)formatterForValue:(id)value inBucket:(NSMutableDictionary *)bucket
{
   NSEnumerator	*enumerator = [bucket keyEnumerator];
   Class				key;
   EOSQLFormatter	*formatter = nil;

   while ((key = [enumerator nextObject])) {
      formatter = [bucket objectForKey:key];
      if ([formatter canFormatValue:value]) {
         [bucket setObject:formatter forKey:(id <NSCopying>)[value class]];
         break;
      }
      formatter = nil;
   }

   return formatter;
}

+ (EOSQLFormatter *)formatterForValue:(id)value inAttribute:(EOAttribute *)attribute;
{
   return [self formatterForValue:value inAdaptor:[attribute _adaptor]];
}

+ (EOSQLFormatter *)formatterForValue:(id)value inAdaptor:(EOAdaptor *)adatpor;
{
   EOSQLFormatter			*formatter = nil;
   Class						adaptorClass = [adatpor class];
   NSMutableDictionary	*bucket = [cache objectForKey:adaptorClass];

   if (value == nil) return nullFormatter;

   //[EOLog logDebugWithFormat:@"%@, %@: ", [NSNull class], [value class]];
   
   formatter = [bucket objectForKey:[value class]];
   if (formatter == nil) {
      formatter = [self formatterForValue:value inBucket:bucket];
      if (formatter == nil) {
         NSMutableDictionary	*mainBucket = [cache objectForKey:[EOAdaptor class]];
         formatter = [self formatterForValue:value inBucket:mainBucket];
         if (formatter != nil) {
            [bucket setObject:formatter forKey:(id <NSCopying>)[value class]];
         }
      }
      
      if (formatter == nil) {
         [EOLog logWarningWithFormat:@"No formatter for object type: %@\n", NSStringFromClass([value class])];
         formatter = nullFormatter;
      }
   }

   //[EOLog logDebugWithFormat:@"%@\n", formatter];
   
   if ([formatter isKindOfClass:[EOSQLNullFormatter class]]) {
      //[EOLog logDebugWithFormat:@"break here\n"];
   }

   return formatter;
}

- (id)format:(id)value inAttribute:(EOAttribute *)attribute
{
   return value;
}

- (BOOL)canFormatValue:(id)value
{
   return [value isKindOfClass:[[self class] formattedClass]];
}

@end
