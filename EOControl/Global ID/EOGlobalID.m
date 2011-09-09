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

#import "EOGlobalID.h"

#import "EODefines.h"

// mont_rothstein @ yahoo.com 2005-09-11
// Added declaration of notification name.
NSString *EOGlobalIDChangedNotification = @"EOGlobalIDChangedNotification";


@implementation EOGlobalID : NSObject
{
}

- (BOOL)isTemporary
{
   [NSException raise:EOException format:@"Subclasses of EOGloabalID must implement %@.", NSStringFromSelector(_cmd)];
   return NO;
}

- (NSString *)entityName
{
   [NSException raise:EOException format:@"Subclasses of EOGloabalID must implement %@.", NSStringFromSelector(_cmd)];
   return nil;
}

- (id)valueForKey:(NSString *)key
{
   [NSException raise:EOException format:@"Subclasses of EOGloabalID must implement %@.", NSStringFromSelector(_cmd)];
   return nil;
}

- (NSDictionary *)valuesForKeys:(NSArray *)keys
{
	NSMutableDictionary	*values;
	int						x, numKeys;
	
	numKeys = [keys count];
	
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		[values takeValue:[self valueForKey:key] forKey:key];
	}
	
	return values;
}

- (id)copyWithZone:(NSZone *)zone
{
   return [self retain];
}

- (NSComparisonResult)compare:(id)other
{
   return [[self entityName] compare:[other entityName]];
}

@end
