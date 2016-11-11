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

#import "EOSQLDateFormatter.h"

#import <EOControl/EOControl.h>

@implementation EOSQLDateFormatter

+ (Class)formattedClass
{
   return [NSDate class];
}

- (id)format:(id)value inAttribute:(EOAttribute *)attribute
{
	// Tom Martin 5/13/11  Use single quotes not double.
    // Tom Martin 10/9/12  Replace depreciated NSCalendarDate with NSDate methods.
    // Tom Martin 11/11/16 Replaced deprecated NSDateFormatter init
    NSDateFormatter *aFormatter;
    NSString *result;
    
    //aFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%d %H:%M:%S %z" allowNaturalLanguage:NO];
    aFormatter = [[NSDateFormatter alloc] init];
    aFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss z";
    result = [aFormatter stringFromDate:(NSDate *)value];
    [aFormatter release];
    return EOFormat(@"\'%@\'", result);
}

@end
