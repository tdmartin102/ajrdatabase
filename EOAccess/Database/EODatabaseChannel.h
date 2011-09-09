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

@class EOAdaptorChannel, EOAdaptorContext, EODatabaseContext, EOEditingContext, EOEntity, EOFetchSpecification;

@interface  EODatabaseChannel : NSObject
{
   EODatabaseContext		*databaseContext;
   EOAdaptorChannel		*adaptorChannel;

   // Support during fetching
   Class						fetchClass;
	EOEntity					*fetchEntity;
   EOEditingContext		*editingContext;
   NSDictionary			*fetchedRow;
   NSMutableDictionary	*updatedObjects;
	
	BOOL						checkDelegateForRefresh:1;
   BOOL						refreshesObjects:1;
   BOOL						lockingObjects:1;
}

// Creating instances
- (id)initWithDatabaseContext:(EODatabaseContext *)aDatabaseContext;

// Accessing cooperating objects
- (EOAdaptorChannel *)adaptorChannel;
- (EODatabaseContext *)databaseContext;

// Fetching objects
- (void)selectObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
                           inEditingContext:(EOEditingContext *)editingContext;
- (id)fetchObject;
- (BOOL)isFetchInProgress;
- (void)cancelFetch;

// Accessing internal fetch state
- (void)setCurrentEntity:(EOEntity *)anEntity;
- (void)setCurrentEditingContext:(EOEditingContext *)aContext;
- (void)setIsLocking:(BOOL)flag;
- (BOOL)isLocking;
- (void)setIsRefreshingObjects:(BOOL)flag;
- (BOOL)isRefreshingObjects;

// Accessing the delegate
- (void)setDelegate:(id)delegate;
- (id)delegate;

// Aggregate functions...
- (int)countOfObjectsWithFetchSpecification:(EOFetchSpecification *)fetch;
- (id)maxValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch;
- (id)minValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch;
- (id)sumOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch;
- (id)averageOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch;

@end
