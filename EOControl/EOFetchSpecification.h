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

@class EOQualifier;

@interface EOFetchSpecification : NSObject <NSCoding, NSCopying, EOKeyValueArchiving>
{
   NSString					*entityName;
   NSString					*rootEntityName;
   EOQualifier				*qualifier;
   NSArray					*sortOrderings;
	NSDictionary			*hints;
	unsigned int			fetchLimit;
	NSArray					*prefetchingRelationshipKeyPaths;
	NSArray					*rawRowKeyPaths;
	NSMutableDictionary  *userInfo;
   BOOL						usesDistinct:1;
   BOOL						refreshObjects:1;
	BOOL						locksObjects:1;
	BOOL						isDeep:1;
	BOOL						fetchesRawRows:1;
	BOOL						requiresAllQualifierBindingVariables:1;
	BOOL						promptsAfterFetchLimit:1;
}

// Creating instances
+ (id)fetchSpecificationWithEntityName:(NSString *)entityName qualifier:(EOQualifier *)qualifier sortOrderings:(NSArray *)sortOrderings;
+ (EOFetchSpecification *)fetchSpecificationNamed:(NSString *)name entityNamed:(NSString *)entityName;
- (EOFetchSpecification *)fetchSpecificationWithQualifierBindings:(NSDictionary *)bindings;
- (id)initWithEntityName:(NSString *)entityName qualifier:(EOQualifier *)qualifier sortOrderings:(NSArray *)sortOrderings usesDistinct:(BOOL)distinctFlag isDeep:(BOOL)isDeepFlag hints:(NSDictionary *)hints;

// Setting the qualifier
- (void)setQualifier:(EOQualifier *)qualifier;
- (EOQualifier *)qualifier;

// Sorting
- (void)setSortOrderings:(NSArray *)sortOrderings;
- (NSArray *)sortOrderings;

// Removing duplicates
- (void)setUsesDistinct:(BOOL)flag;
- (BOOL)usesDistinct;

// Fetching objects in an inheritance hierarchy
- (void)setIsDeep:(BOOL)flag;
- (BOOL)isDeep;
- (void)setEntityName:(NSString *)aName;
- (NSString *)entityName;

// Controlling fetching behavior
- (void)setFetchLimit:(int)aLimit;
- (int)fetchLimit;
- (void)setFetchesRawRows:(BOOL)flag;
- (BOOL)fetchesRawRows;
- (void)setPrefetchingRelationshipKeyPaths:(NSArray *)somePaths;
- (NSArray *)prefetchingRelationshipKeyPaths;
- (void)setPromptsAfterFetchLimit:(BOOL)flag;
- (BOOL)promptsAfterFetchLimit;
- (void)setRawRowKeyPaths:(NSArray *)somePaths;
- (NSArray *)rawRowKeyPaths;
- (void)setRequiresAllQualifierBindingVariables:(BOOL)flag;
- (BOOL)requiresAllQualifierBindingVariables;
- (void)setHints:(NSDictionary *)hints;
- (NSDictionary *)hints;
	
// Locking objects
- (void)setLocksObjects:(BOOL)flag;
- (BOOL)locksObjects;

// Refreshing refetched objects
- (void)setRefreshesObjects:(BOOL)flag;
- (void)setRefreshesRefetchedObjects:(BOOL)flag;  // EOF 4.5 API

- (BOOL)refreshesObjects;
- (BOOL)refreshesRefetchedObjects;  // EOF 4.5 API
@end
