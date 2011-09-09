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

#import <EOAccess/EOPropertyListEncoding.h>
#import <EOControl/NSClassDescription-EO.h>
#import <EOControl/EOQualifier.h>
#import <EOControl/EOObserver.h>

typedef enum _eoJoinSemantic {
   EOInnerJoin = 0,
   EOFullOuterJoin = 1,
   EOLeftOuterJoin = 2,
   EORightOuterJoin = 3
} EOJoinSemantic;

@class EOGlobalID, EOEntity, EOJoin, EOSQLExpression;

extern NSString *EORelationshipDidChangeNameNotification;

@interface EORelationship : NSObject <EOObserving, EOPropertyListEncoding>
{
	EOEntity				*entity;
	NSString				*name;
	EOEntity				*destinationEntity;
	int						joinSemantic;
	NSMutableArray			*joins;
	NSString				*definition;
	unsigned int			batchSize;
	NSMutableDictionary	*userInfo;
	EODeleteRule			deleteRule:3;
	BOOL					isToMany:1;
	BOOL					isMandatory:1;
	BOOL					definitionIsInitialized:1;
	BOOL					ownsDestination:1;
	BOOL					propagatesPrimaryKey:1;
	BOOL					isClassProperty:1;

#if !defined(STRICT_EOF)
	// mont_rothstein @ yahoo.com 2004-12-20
	NSMutableArray			*sortOrderings; // Sort orderings are used by faults when fetching.
	
	// mont_rothstein @ yahoo.com 2005-03-16
	EOQualifier				*restrictingQualifier; // User by faults when fetching
#endif
}

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;

- (void)awakeWithPropertyList:(NSDictionary *)properties;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;

// Accessing the relationship name
- (void)beautifyName;
- (NSString *)name;
- (void)setName:(NSString *)name;
- (NSException *)validateName:(NSString *)aName;

// Using joins
- (void)addJoin:(EOJoin *)join;
- (NSArray *)joins;
- (EOJoinSemantic)joinSemantic;
- (void)removeJoin:(EOJoin *)join;
- (void)setJoinSemantic:(EOJoinSemantic)semantic;

// Accessing attributes joined on
- (NSArray *)destinationAttributes;
- (NSArray *)sourceAttributes;

// Accessing the definition
- (NSArray *)componentRelationships;
- (void)setDefinition:(NSString *)definition;
- (NSString *)definition;

// Accessing the entities joined
- (EORelationship *)anyInverseRelationship;
- (EOEntity *)destinationEntity;
- (EOEntity *)entity;
- (EORelationship *)inverseRelationship;
- (void)setEntity:(EOEntity *)anEntity;

// Checking the relationship type
- (BOOL)isCompound;
- (BOOL)isFlattened;
- (BOOL)isMandatory;
- (void)setIsMandatory:(BOOL)flag;
- (NSException *)validateValue:(id *)value;

// Accessing whether the relationship is to-many
- (BOOL)isToMany;
- (void)setToMany:(BOOL)flag;

//	Relationship qualifiers
- (EOQualifier *)qualifierWithSourceRow:(NSDictionary *)row;
- (EOQualifier *)qualifierWithSourceData:(id)data 
							   operation:(EOQualifierOperation)operation;

// Checking references
- (BOOL)referencesProperty:(id)property;

// Controlling batch fetches
- (unsigned int)numberOfToManyFaultsToBatchFetch;
- (void)setNumberOfToManyFaultsToBatchFetch:(unsigned int)size;

// Accessing the user dictionary
- (void)setUserInfo:(NSDictionary *)someInfo;
- (NSDictionary *)userInfo;

// Taking action upon a change
- (void)setDeleteRule:(EODeleteRule)rule;
- (EODeleteRule)deleteRule;
- (void)setPropagatesPrimaryKey:(BOOL)flag;
- (BOOL)propagatesPrimaryKey;
- (void)setOwnsDestination:(BOOL)flag;
- (BOOL)ownsDestination;

#if !defined(STRICT_EOF)
// mont_rothstein @ yahoo.com 2004-12-20
// Added sortOrderings method to be used by faults when fetching.
- (NSArray *)sortOrderings;

// mont_rothstein @ yahoo.com 2005-03-16
// Added restrictingQualifier to be used by faults when fetching.
- (void)setRestrictingQualifier:(EOQualifier *)qualifier;
- (EOQualifier *)restrictingQualifier;

#endif

@end
