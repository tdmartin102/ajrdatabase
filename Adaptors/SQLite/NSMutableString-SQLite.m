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

#import "NSMutableString-SQLite.h"

/*
static NSString *OM_version_info = @"Version Info: NSMutableString-Extensions 3";
__VERSION_SHUT_UP
*/

@implementation NSMutableString (SQLiteExtensions)

- (void)_sqliteReplaceSubstring: (NSString*)substring withString: (NSString*)replacementString replaceAll: (BOOL)flag
{
   NSRange range = [self rangeOfString: substring];
   NSRange searchRange;

   while (range.length)
   {
      [self replaceCharactersInRange: range withString: replacementString];
      if (flag)
      {
         searchRange.location = range.location + [replacementString length];
         searchRange.length = [self length] - searchRange.location;
         range = [self rangeOfString: substring options: 0 range: searchRange];
      }
      else
      {
         range.length = 0;
      }
   }
}

- (void)_sqliteReplaceSubstring: (NSString*)substring withString: (NSString*)replacementString
{
   [self _sqliteReplaceSubstring: substring withString: replacementString replaceAll: NO];
}

@end
