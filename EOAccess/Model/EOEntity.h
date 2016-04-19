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
#import <EOControl/EOObserver.h>

@class EOAttribute, EOEntityClassDescription, EOFetchSpecification, EOGlobalID, EOModel, EOQualifier, EORelationship, EOStoredProcedure;

extern NSString *EOFetchAllProcedureOperation;
extern NSString *EOFetchWithPrimaryKeyProcedureOperation;
extern NSString *EOInsertProcedureOperation;
extern NSString *EODeleteProcedureOperation;
extern NSString *EONextPrimaryKeyProcedureOperation;

extern NSString *EOEntityDidChangeNameNotification;

@interface EOEntity : NSObject <EOPropertyListEncoding, EOObserving>
{
   EOModel					*model;

   NSString					*name;

	EOEntity					*parentEntity;
	NSMutableArray			*subentities;
	NSString					*externalQuery;
	EOQualifier				*restrictingQualifier;
   NSMutableArray			*attributes;
	NSArray					*attributeNames;
   NSMutableDictionary	*attributeIndex;
   NSMutableArray			*attributesUsedForLocking;
   NSMutableArray			*attributesToFetch;
   NSString					*className;
   Class         			objectClass;
   NSMutableArray			*classProperties;
	NSMutableArray			*classPropertyNames;
   NSMutableArray			*classAttributes;
   NSMutableArray			*classRelationships;
   NSMutableArray			*classRelationshipsToOne;
   NSMutableArray			*classRelationshipsToMany;
   NSString					*externalName;
   NSMutableArray			*primaryKeyAttributes;
   NSMutableArray			*primaryKeyAttributeNames;
	NSString				* __strong *primaryKeyNames;
	id						__strong *primaryKeyValues;
   NSMutableArray			*relationships;
   NSMutableDictionary	*relationshipIndex;
   NSString					*valueClassName;
	NSDictionary			*userInfo;
	NSMutableDictionary	*storedProcedures;
	NSMutableDictionary	*fetchSpecifications;
	unsigned int			batchSize;

   BOOL	      			initialized:1;
   BOOL						primaryKeyIsPrivate:1;
	BOOL						primaryKeyIsNumeric:1;
	BOOL						readOnly:1;
	BOOL						cachesObjects:1;
	BOOL						isAbstractEntity:1;
	BOOL						attributesNeedSorting:1;
	BOOL						relationshipsNeedSorting:1;
}

// Property list encoding
- (void)awakeWithPropertyList:(NSDictionary *)propertyList;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;
- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;
	
// Accessing the name
- (void)setName:(NSString *)aName;
- (NSString *)name;
- (NSException *)validateName:(NSString *)aName;
- (void)beautifyName;

// Accessing the model
- (EOModel *)model;

// Specifying fetching behavior for the entity
- (void)setExternalQuery:(NSString *)aQuery;
- (NSString *)externalQuery;
- (void)setRestrictingQualifier:(EOQualifier *)qualifier;
- (EOQualifier *)restrictingQualifier;

// Accessing primary key qualifiers
- (EOQualifier *)qualifierForPrimaryKey:(NSDictionary *)pk;
- (BOOL)isQualifierForPrimaryKey:(EOQualifier *)aQualifier;

//Accessing attributes
- (void)addAttribute:(EOAttribute *)attribute;
- (EOAttribute *)anyAttributeNamed:(NSString *)aName;
- (EOAttribute *)attributeNamed:(NSString *)aName;
- (NSArray *)attributes;
- (void)removeAttribute:(EOAttribute *)attribute;
- (NSArray *)attributesToFetch;

// Accessing relationships
- (void)addRelationship:(EORelationship *)relationship;
- (EORelationship *)anyRelationshipNamed:(NSString *)name;
- (NSArray *)relationships;
- (EORelationship *)relationshipNamed:(NSString *)name;
- (void)removeRelationship:(EORelationship *)relationship;

// Checking referential integrity
- (NSArray *)externalModelsReferenced;
- (BOOL)referencesProperty:(id)property;

// Accessing primary keys
- (EOGlobalID *)globalIDForRow:(NSDictionary *)row;
- (BOOL)isPrimaryKeyValidInObject:(id)object;
- (NSDictionary *)primaryKeyForGlobalID:(EOGlobalID *)globalID;
- (NSDictionary *)primaryKeyForRow:(NSDictionary *)row;

// Accessing primary key attributes
- (void)setPrimaryKeyAttributes:(NSArray *)someAttributes;
- (NSArray *)primaryKeyAttributes;
- (NSArray *)primaryKeyAttributeNames;
- (NSString *)primaryKeyRootName;
- (BOOL)isValidPrimaryKeyAttribute:(EOAttribute *)attribute;

// Accessing class properties
- (void)setClassProperties:(NSArray *)properties;
- (NSArray *)classProperties;
- (NSArray *)classPropertyNames;
- (BOOL)isValidClassProperty:(id)property;

// Accessing the enterprise object class
- (EOEntityClassDescription *)classDescriptionForInstances;
- (void)setClassName:(NSString *)className;
- (NSString *)className;

// Accessing locking attributes
- (void)setAttributesUsedForLocking:(NSArray *)someAttributes;
- (NSArray *)attributesUsedForLocking;
- (BOOL)isValidAttributeUsedForLocking:(EOAttribute *)anAttribute;

// Accessing external name
- (void)setExternalName:(NSString *)externalName;
- (NSString *)externalName;

// Accessing whether an entity is read only
- (void)setReadOnly:(BOOL)flag;
- (BOOL)isReadOnly;

// Accessing the user dictionary
- (void)setUserInfo:(NSDictionary *)someInfo;
- (NSDictionary *)userInfo;

// Working with stored procedures
/*! @todo EOEntity: Stored Procedure operations */
- (void)setStoredProcedure:(EOStoredProcedure *)storedProcedure forOperation:(NSString *)operation;
- (EOStoredProcedure *)storedProcedureForOperation:(NSString *)operation;

// Working with fetch specifications
/*! @todo EOEntity: Read / Restore fetch specifications */
- (void)addFetchSpecification:(EOFetchSpecification *)fetch withName:(NSString *)aName;
- (EOFetchSpecification *)fetchSpecificationNamed:(NSString *)aName;
- (NSArray *)fetchSpecificationNames;
- (void)removeFetchSpecificationNamed:(NSString *)aName;

// Working with entity inheritance hierarchies
/*! @todo EOEntity: inheritance. */
- (EOEntity *)parentEntity;
- (NSArray *)subEntities;
- (void)addSubEntity:(EOEntity *)subentity;
- (void)removeSubEntity:(EOEntity *)subentity;
- (void)setIsAbstractEntity:(BOOL)flag;
- (BOOL)isAbstractEntity;
	
// Specifying fault behavior
/*! @todo EOEntity: batch fetching */
- (void)setMaxNumberOfInstancesToBatchFetch:(unsigned int)size;
- (unsigned int)maxNumberOfInstancesToBatchFetch;

// Caching objects
/*! @todo Entity: object caching */
- (void)setCachesObjects:(BOOL)flag;
- (BOOL)cachesObjects;

@end
