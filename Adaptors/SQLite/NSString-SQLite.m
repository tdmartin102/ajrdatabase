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

#import "NSString-SQLite.h"

#import "NSMutableString-SQLite.h"

@implementation NSString (AJRExtensions)

- (NSString *)_sqliteTrimmedString
{
	NSCharacterSet 	*ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	unsigned int 		length = [self length];
	int 				index;
	NSRange 		range = { 0.0, 0.0 };

	if (length == 0) return self;

	for (index = 0; index < length; index++) {
		if (![ws characterIsMember:[self characterAtIndex:index]]) {
			range.location = index;
			break;
		}
	}
	
	for (index = length - 1; index >= 0; index--) {
		if (![ws characterIsMember:[self characterAtIndex:index]]) {
			range.length = index - range.location + 1;
			break;
		}
	}

	return [self substringWithRange:range];
}

- (NSString*)_sqliteStringByReplacingSubstring:(NSString*)substring withString:(NSString*)replacementString replaceAll:(BOOL)flag
{
   NSMutableString *substituted = [[self mutableCopy] autorelease];

   [substituted _sqliteReplaceSubstring:substring withString:replacementString replaceAll:flag];

   return substituted;
}

- (NSString*)_sqliteStringByReplacingSubstring:(NSString*)substring withString:(NSString*)replacementString
{
   return [self _sqliteStringByReplacingSubstring:substring withString:replacementString replaceAll:NO];
}

@end
