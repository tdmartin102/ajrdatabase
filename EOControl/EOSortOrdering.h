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

#import <Foundation/Foundation.h>
#import <EOControl/EOKeyValueArchiver.h>
// mont_rothstein @ yahoo.com 2005-01-10
// Added #import because sortUsingKeyOrderArray: is defined here in WO 4.5 API
#import "NSArray-EO.h"

// mont_rothstein @ yahoo.com 2005-01-10
// Added #ifndef to prevent redefinition errors
#ifndef __EOSortOrdering__
#define __EOSortOrdering__

extern SEL EOCompareAscending;
extern SEL EOCompareDescending;
extern SEL EOCompareCaseInsensitiveAscending;
extern SEL EOCompareCaseInsensitiveDescending;

@class EOSQLExpression, EOEntity;

@interface EOSortOrdering : NSObject <EOKeyValueArchiving>
{
   NSString		*key;
   SEL			selector;
}

+ (id)sortOrderingWithKey:(NSString *)key selector:(SEL)aSelector;
- (id)initWithKey:(NSString *)key selector:(SEL)aSelector;

- (NSString *)key;
- (SEL)selector;

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4
+ (id)sortOrderingWithSortDescriptor:(NSSortDescriptor *)sortDescriptor;
- (id)initWithSortDescriptor:(NSSortDescriptor *)sortDescriptor;
- (NSSortDescriptor *)sortDescriptor;
#endif

@end


@interface NSObject (EOSortOrdering)

- (NSComparisonResult)compareAscending:(id)other;
- (NSComparisonResult)compareDescending:(id)other;
- (NSComparisonResult)compareCaseInsensitiveAscending:(id)other;
- (NSComparisonResult)compareCaseInsensitiveDescending:(id)other;

@end


@interface NSArray (EOKeyBasedSorting)
- (NSArray *)sortedArrayUsingKeyOrderArray:(NSArray *)order;
@end

#endif // __EOSortOrdering__
