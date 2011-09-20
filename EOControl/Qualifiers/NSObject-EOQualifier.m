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

#import "NSObject-EOQualifier.h"
#import "EOAutoreleasedMemory.h"

#import <fnmatch.h>
@interface NSString (EOQuaifierString)
- (char *)lossyASCIIString;
@end

@implementation NSString (EOQuaifierString)
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
- (char *)lossyASCIIString
{
	char		*buffer;
	NSData		*data;
	NSUInteger	len;
	
	data = [self dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	len = [data length];
	buffer = [EOAutoreleasedMemory autoreleasedMemoryWithCapacity:len + 1];
	if (len)
		[data getBytes:buffer length:[data length]];
	buffer[len]=0;
	return buffer;
}
#else
- (char *)lossyASCIIString { return [self lossyCString]; }
#endif
@end

@implementation NSObject (EOQualifier)

- (BOOL)qualifierEquals:(id)value
{
   return [self isEqual:value];
}

- (BOOL)qualifierNotEquals:(id)value
{
   return ![self isEqual:value];
}

- (BOOL)qualifierLessThan:(id)value
{
   return [(NSString *)self compare:value] < NSOrderedSame;
}

- (BOOL)qualifierLessThanOrEqual:(id)value
{
   return [(NSString *)self compare:value] <= NSOrderedSame;
}

- (BOOL)qualifierGreaterThan:(id)value
{
   return [(NSString *)self compare:value] > NSOrderedSame;
}

- (BOOL)qualifierGreaterThanOrEqual:(id)value
{
   return [(NSString *)self compare:value] >= NSOrderedSame;
}

- (BOOL)qualifierIn:(id)value
{
   if ([value isKindOfClass:[NSArray class]]) {
      return [value containsObject:self];
   }

   return [self qualifierEquals:value];
}

- (BOOL)qualifierLike:(id)value
{
   return fnmatch([[value description] lossyASCIIString], [[self description] lossyASCIIString], 0) != FNM_NOMATCH;
}

- (BOOL)qualifierCaseInsensitiveLike:(id)value
{
   return fnmatch([[[value description] lowercaseString] lossyASCIIString], [[[self description] lowercaseString] lossyASCIIString], 0) != FNM_NOMATCH;
}

- (BOOL)qualifierNotLike:(id)value
{
   return fnmatch([[value description] lossyASCIIString], [[self description] lossyASCIIString], 0) == FNM_NOMATCH;
}

- (BOOL)qualifierCaseInsensitiveNotLike:(id)value
{
   return fnmatch([[[value description] lowercaseString] lossyASCIIString], [[[self description] lowercaseString] lossyASCIIString], 0) == FNM_NOMATCH;
}

// mont_rothstein@yahoo.com 2006-01-22
// Added support for EOQualifierCaseInsensitiveEqual and EOQualifierCaseInsensitiveNotEqual.  Note: These are extensions to the WO 4.5 API.
- (BOOL)qualifierCaseInsensitiveEqual:(id)value;
{
	return [[[self description] lowercaseString] isEqualToString: [[value description] lowercaseString]];
}

- (BOOL)qualifierCaseInsensitiveNotEqual:(id)value;
{
	return ![self qualifierCaseInsensitiveEqual: value];
}


@end


@implementation NSNumber (EOQualifier)

- (BOOL)qualifierEquals:(id)value
{
   return [self isEqualToNumber:value];
}

@end
