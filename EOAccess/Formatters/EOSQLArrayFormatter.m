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

#import "EOSQLArrayFormatter.h"

#import "EOAttribute.h"

@implementation EOSQLArrayFormatter

+ (Class)formattedClass
{
   return [NSArray class];
}

- (id)format:(id)value inAttribute:(EOAttribute *)attribute;
{
   NSInteger		x, max;
   NSMutableString	*buffer = [[NSMutableString alloc] initWithString:@"("];

   for (x = 0, max = [value count]; x < max; x++) {
      if (x > 0) {
         [buffer appendString:@", "];
      }
		if (attribute == nil) {
			[buffer appendString:[[EOSQLFormatter formatterForValue:[value objectAtIndex:x] inAttribute:nil] format:[value objectAtIndex:x] inAttribute:nil]];
		} else {
			[buffer appendString:[attribute adaptorSqlStringForStandardValue:[attribute adaptorValueByConvertingAttributeValue:[value objectAtIndex:x]]]];
		}
   }

   [buffer appendString:@")"];

   return [buffer autorelease];
}

@end

