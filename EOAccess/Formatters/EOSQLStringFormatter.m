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

#import "EOSQLStringFormatter.h"

#import "EOAttribute.h"
#import "EOEntity.h"
#import "EOModel.h"

#import <EOControl/EOControl.h>

@implementation EOSQLStringFormatter

+ (Class)formattedClass
{
   return [NSString class];
}

// mont_rothstein @ yahoo.com 10/27/04
// Changed from double quotes to single quotes around the value.  SQL uses single quotes around strings, not double quotes.  Inserts were failing.
- (id)format:(id)value inAttribute:(EOAttribute *)attribute
{
   NSInteger			x, length;
   NSMutableString	*work = [NSMutableString string];
   NSInteger			last = 0;
   unichar				c;
   NSString				*escape;

   [work appendString:@"\'"];
   length = [(NSString *)value length];
   for (x = 0; x < length; x++) {
      c = [value characterAtIndex:x];
      escape = nil;
      if (c < ' ') {
         escape = EOFormat(@"\\%03d", c);
      } else if (c == '\\') {
         escape = @"\\\\";
      } else if (c == '\'') {
         escape = @"\\\'";
      } else if (c >= 127) {
         escape = EOFormat(@"\\%03d", c);
      }
      if (escape) {
         [work appendString:[value substringWithRange:(NSRange){last, x - last}]];
         last = x + 1;
         [work appendString:escape];
      }
   }

   if (last < length) {
      [work appendString:[value substringWithRange:(NSRange){last, length - last}]];
   }

   [work appendString:@"\'"];
   
   return work;
}

@end
