//
//  EOEditingContext-EOAccess.m
//  EOAccess
//
//  Created by Alex Raftis on 11/10/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOEditingContext-EOAccess.h"

#import "EOAdaptor.h"
#import "EOAdaptorChannel.h"
#import "EOAdaptorContext.h"
#import "EOAttributeP.h"
#import "EODatabase.h"
#import "EODatabaseChannel.h"
#import "EODatabaseContext.h"
#import "EOEntity.h"
#import "EOEntityClassDescription.h"
#import "EOModel.h"
#import "EOModelGroup.h"
#import "EOSQLExpression.h"
#import "EOStoredProcedure.h"
#import <EOControl/EOObjectStoreCoordinatorP.h>
// mont_rothstein @ yahoo.com 2004-12-05
// Added #import
#import "EOObjectStoreCoordinator-EOAccess.h"

@implementation EOEditingContext (EOAccess)

// Creating new objects
- (id)createAndInsertInstanceOfEntityNamed:(NSString *)entityName
{
	id                   newObject = nil;
	EOTemporaryGlobalID  *globalID;
	
	globalID = [[EOTemporaryGlobalID allocWithZone:[self zone]] initWithEntityName:entityName];
	newObject = [[EOClassDescription classDescriptionForEntityName:entityName] createInstanceWithEditingContext:self globalID:globalID zone:NULL];
	// william @ swats.org 2005-07-23
	// Moved release of global ID to after final use
	[self insertObject:newObject withGlobalID:globalID];
	[globalID release];

	return newObject;
}

// Fetching multiple objects
- (NSArray *)objectsForEntityNamed:(NSString *)entityName;
{
	return [self objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:entityName qualifier:nil sortOrderings:nil]];
}

- (NSArray *)objectsForEntityNamed:(NSString *)entityName qualifierFormat:(NSString *)format, ...;
{
	va_list		ap;
	EOQualifier	*qualifier;
	
	va_start(ap, format);
	qualifier = [EOQualifier qualifierWithQualifierFormat:format varargList:ap];
	va_end(ap);
	
	return [self objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:entityName qualifier:qualifier sortOrderings:nil]];
}

- (NSArray *)objectsMatchingValue:(id)value forKey:(NSString *)key entityNamed:(NSString *)entityName
{
	EOQualifier		*qualifier;
	
	qualifier = [EOKeyValueQualifier qualifierWithKey:key operation:EOQualifierEquals value:value];
	
	return [self objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:entityName qualifier:qualifier sortOrderings:nil]];
}

- (NSArray *)objectsMatchingValues:(NSDictionary *)dictionary entityNamed:(NSString *)entityName;
{
	EOQualifier		*qualifier;
	
	qualifier = [EOQualifier qualifierToMatchAllValues:dictionary];
	
	return [self objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:entityName qualifier:qualifier sortOrderings:nil]];
}

- (NSArray *)objectsOfClass:(Class)aClass;
{
	return [self objectsForEntityNamed:[[self entityForClass:aClass] name]];
}

- (NSArray *)objectsWithFetchSpecificationNamed:(NSString *)fetchName entityNamed:(NSString *)entityName bindings:(NSDictionary *)bindings
{
	EOFetchSpecification		*fetch;
	
	fetch = [[self modelGroup] fetchSpecificationNamed:fetchName entityNamed:entityName];
	if (fetch != nil) {
		/*! @todo EOEditingContex: objectsWithFetchSpecificationNamed:entityNamed:bindings: */
	}
	
	return nil;
}

- (id)_objectForFetchSpecification:(EOFetchSpecification *)fetch
{
	NSArray		*someObjects = [self objectsWithFetchSpecification:fetch];
	
	if ([someObjects count] == 0) {
		return nil;
	} else if ([someObjects count] == 1) {
		return [someObjects lastObject];
	}
	
	[NSException raise:EOMoreThanOneException format:@"Found more than one object during fetch with fetch specification: %@", fetch];
	
	return nil;
}

// Fetching single objects
- (id)objectForEntityNamed:(NSString *)entityName qualifierFormat:(NSString *)format, ...
{
	va_list		args;
	EOQualifier	*qualifier;
	
	va_start(args, format);
	qualifier = [EOQualifier qualifierWithQualifierFormat:format varargList:args];
	va_end(args);
	
	return [self _objectForFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:entityName qualifier:qualifier sortOrderings:nil]];
}

- (id)objectMatchingValue:(id)value forKey:(NSString *)key entityNamed:(NSString *)entityName
{
	EOQualifier		*qualifier;
	
	qualifier = [EOKeyValueQualifier qualifierWithKey:key operation:EOQualifierEquals value:value];
	
	return [self _objectForFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:entityName qualifier:qualifier sortOrderings:nil]];
}

- (id)objectMatchingValues:(NSDictionary *)values entityNamed:(NSString *)entityName
{
	EOQualifier		*qualifier;
	
	qualifier = [EOQualifier qualifierToMatchAllValues:values];
	
	return [self _objectForFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:entityName qualifier:qualifier sortOrderings:nil]];
}

- (id)objectWithFetchSpecificationNamed:(NSString *)fetchName entityNamed:(NSString *)entityName bindings:(NSDictionary *)bindings;
{
	EOFetchSpecification		*fetch;
	
	fetch = [[self modelGroup] fetchSpecificationNamed:fetchName entityNamed:entityName];
	if (fetch != nil) {
		/*! @todo EOEditingContex: objectsWithFetchSpecificationNamed:entityNamed:bindings: */
		return [self _objectForFetchSpecification:fetch];
	}
	
	return nil;
}

- (id)objectWithPrimaryKey:(NSDictionary *)primaryKey entityNamed:(NSString *)entityName
{
	return [self objectMatchingValues:primaryKey entityNamed:entityName];
}

- (id)objectWithPrimaryKeyValue:(id)value entityNamed:(NSString *)entityName
{
	EOEntity		*entity = [self entityNamed:entityName];
	NSArray		*pkAttributes;
	
	if (entity == nil) return nil;
	
	pkAttributes = [entity primaryKeyAttributeNames];
	if ([pkAttributes count] > 1) return nil;
	
	return [self objectMatchingValue:value forKey:[pkAttributes objectAtIndex:0] entityNamed:entityName];
}

- (EOAdaptorChannel *)_openAdaptorChannelForModel:(EOModel *)model
{
	EODatabaseContext		*databaseContext;
	EODatabaseChannel		*databaseChannel;
	EOAdaptorChannel		*adaptorChannel;

	databaseContext = [EODatabaseContext registeredDatabaseContextForModel:model editingContext:self];
	if (databaseContext == nil) return nil;
	
	databaseChannel = [databaseContext availableChannel];
	adaptorChannel = [databaseChannel adaptorChannel];
	if (![adaptorChannel isOpen]) {
		[adaptorChannel openChannel];
	}
	
	return adaptorChannel;
}

// Fetching raw rows
- (NSDictionary *)executeStoredProcedureNamed:(NSString *)storedProcedureName arguments:(NSDictionary *)arguments
{
	EOStoredProcedure		*storedProcedure;
	EOAdaptorChannel		*adaptorChannel;
	
	storedProcedure = [[self modelGroup] storedProcedureNamed:storedProcedureName];
	if (storedProcedure == nil) return nil;
	
	adaptorChannel = [self _openAdaptorChannelForModel:[storedProcedure model]];
	if (adaptorChannel == nil) return nil;

	[adaptorChannel executeStoredProcedure:storedProcedure withValues:arguments];
	if ([adaptorChannel isFetchInProgress]) [adaptorChannel cancelFetch];
	
	return [adaptorChannel returnValuesForLastStoredProcedureInvocation];
}

- (id)objectFromRawRow:(NSDictionary *)row entityNamed:(NSString *)entityName
{
	return [self faultForRawRow:row entityNamed:entityName];
}

- (NSArray *)rawRowsForEntityNamed:(NSString *)entityName qualifierFormat:(NSString *)format, ...
{
    EOEntity			*entity;
    EOAdaptorChannel	*channel;
    EOQualifier			*qualifier;
    va_list             ap;
    NSMutableArray		*rows;
    NSDictionary		*row;

    entity = [self entityNamed:entityName];
    if (entity == nil) return nil;
    
    channel = [self _openAdaptorChannelForModel:[entity model]];
    if (channel == nil) return nil;
    
    va_start(ap, format);
    qualifier = [EOQualifier qualifierWithQualifierFormat:format varargList:ap];
    va_end(ap);

    [channel selectAttributes:[entity attributes] fetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:entityName qualifier:qualifier sortOrderings:nil] lock:NO entity:entity];
    
    rows = [[[NSMutableArray alloc] init] autorelease];
    
    while ((row = [channel fetchRowWithZone:nil]) != nil) {
        [rows addObject:row];
    }
    
    return rows;
}

- (NSArray *)rawRowsMatchingValue:(id)value forKey:(NSString *)key entityNamed:(NSString *)entityName
{
	EOEntity				*entity;
	EOAdaptorChannel	*channel;
	EOQualifier			*qualifier;
	NSMutableArray		*rows;
	NSDictionary		*row;
	NSZone				*zone = [self zone];
	
	entity = [self entityNamed:entityName];
	if (entity == nil) return nil;
	
	channel = [self _openAdaptorChannelForModel:[entity model]];
	if (channel == nil) return nil;
	
	qualifier = [EOKeyValueQualifier qualifierWithKey:key operation:EOQualifierEquals value:value];
	
	[channel selectAttributes:[entity attributes] fetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:entityName qualifier:qualifier sortOrderings:nil] lock:NO entity:entity];
	
	rows = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];
	
	while ((row = [channel fetchRowWithZone:zone]) != nil) {
		[rows addObject:row];
	}
	
	return rows;
}

- (NSArray *)rawRowsMatchingValues:(NSDictionary *)values entityNamed:(NSString *)entityName;
{
	EOEntity				*entity;
	EOAdaptorChannel	*channel;
	EOQualifier			*qualifier;
	NSMutableArray		*rows;
	NSDictionary		*row;
	NSZone				*zone = [self zone];
	
	entity = [self entityNamed:entityName];
	if (entity == nil) return nil;
	
	channel = [self _openAdaptorChannelForModel:[entity model]];
	if (channel == nil) return nil;
	
	qualifier = [EOQualifier qualifierToMatchAllValues:values];
	
	[channel selectAttributes:[entity attributes] fetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:entityName qualifier:qualifier sortOrderings:nil] lock:NO entity:entity];
	
	rows = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];
	
	while ((row = [channel fetchRowWithZone:zone]) != nil) {
		[rows addObject:row];
	}
	
	return rows;
}

- (NSArray *)rawRowsWithSQL:(NSString *)sqlString modelNamed:(NSString *)modelName
{
	EOModel				*model;
	EOAdaptorChannel	*channel;
	NSMutableArray		*rows;
	NSDictionary		*row;
	NSZone				*zone = [self zone];
	EOSQLExpression	*expression;

	model = [[self modelGroup] modelNamed:modelName];
	if (model == nil) return nil;

	channel = [self _openAdaptorChannelForModel:model];
	if (channel == nil) return nil;

	expression = [[[[[channel adaptorContext] adaptor] expressionClass] allocWithZone:zone] init];
	[expression setStatement:sqlString];
	
	[channel evaluateExpression:expression];

	rows = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];
	while ((row = [channel fetchRowWithZone:zone]) != nil) {
		[rows addObject:row];
	}
    [expression release];

	return rows;
}

- (NSArray *)rawRowsWithStoredProcedureNamed:(NSString *)storedProcedureName arguments:(NSDictionary *)arguments;
{
	EOStoredProcedure		*storedProcedure;
	EOAdaptorChannel		*adaptorChannel;
	NSMutableArray			*rows;
	NSDictionary			*row;
	NSZone					*zone = [self zone];
	
	storedProcedure = [[self modelGroup] storedProcedureNamed:storedProcedureName];
	if (storedProcedure == nil) return nil;
	
	adaptorChannel = [self _openAdaptorChannelForModel:[storedProcedure model]];
	if (adaptorChannel == nil) return nil;
	
	[adaptorChannel executeStoredProcedure:storedProcedure withValues:arguments];

	rows = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];
	while ((row = [adaptorChannel fetchRowWithZone:zone]) != nil) {
		[rows addObject:row];
	}
	
	return rows;
}

// Accessing the EOF stack
- (void)connectWithModelNamed:(NSString *)modelName connectionDictionaryOverrides:(NSDictionary *)overrides
{
	/*! @todo EOEditingContext: connectWithModelNamed:connectionDictionaryOverrides:*/
}

- (EODatabaseContext *)databaseContextForModelNamed:(NSString *)modelName
{
	// mont_rothsetin @ yahoo.com 2004-12-20
	// Added implementation of this method
	EOModel *model;

	model = [[self modelGroup] modelNamed: modelName];
	return [EODatabaseContext registeredDatabaseContextForModel:model editingContext:self];
}

// Accessing object data
- (NSDictionary *)destinationKeyForSourceObject:(id)object relationshipNamed:(NSString *)relationshipName
{
	/*! @todo EOEditingContext: destinationKeyForSourceObject:relationshipNamed: */
	return nil;
}

- (id)localInstanceOfObject:(id)object
{
	/*! @todo EOEditingContext: localInstanceOfObject:*/
	return nil;
}

- (NSArray *)localInstancesOfObjects:(NSArray *)objects
{
	/*! @todo EOEditingContext: localInstancesOfObjects:*/
	return nil;
}

- (NSDictionary *)primaryKeyForObject:(id)object
{
	EOGlobalID		*globalID = [self globalIDForObject:object];
	
   if ([globalID isTemporary]) {
      NSMutableDictionary	*primaryKey = [[[NSMutableDictionary allocWithZone:[object zone]] init] autorelease];
		NSClassDescription	*classDescription = [object classDescription];
		EOEntity					*entity = [(EOEntityClassDescription *)classDescription entity];
      NSArray					*primaryKeyAttributes = [entity primaryKeyAttributeNames];
      EOAttribute				*attribute;
      NSString					*key;
      NSInteger					x, max;
      id							value;
		
      for (x = 0, max = [primaryKeyAttributes count]; x < max; x++) {
         key = [primaryKeyAttributes objectAtIndex:x];
         attribute = [entity attributeNamed:key];
         if ([attribute _isClassProperty]) {
            value = [object valueForKey:key];
         } else {
            value = [globalID valueForKey:key];
         }
         if (value == nil) {
            break;
         } else {
            [primaryKey setObject:value forKey:key];
         }
      }
		
      if (x == max) {
         return primaryKey;
      } else {
         primaryKey = nil;
      }
		
      return nil;
   } else {
      return [(EOKeyGlobalID *)globalID primaryKey];
   }
}

// Accessing model information
- (EOEntity *)entityForClass:(Class)classObject
{
	NSClassDescription	*description = [EOClassDescription classDescriptionForClass:classObject];

	if ([description isKindOfClass:[EOEntityClassDescription class]]) {
		return [(EOEntityClassDescription *)description entity];
	}
	
	return nil;
}

- (EOEntity *)entityForObject:(id)object
{
	return [[self modelGroup] entityForObject:object];
}

- (EOEntity *)entityNamed:(NSString *)entityName
{
	return [[self modelGroup] entityNamed:entityName];
}

- (EOModelGroup *)modelGroup
{
	EOCooperatingObjectStore	*root = (EOCooperatingObjectStore *)[self rootObjectStore];
	EOModelGroup					*modelGroup = nil;
	
	if ([root respondsToSelector:@selector(modelGroup)]) {
		modelGroup = [(id)root modelGroup];
	} else if ([root isKindOfClass:[EODatabaseContext class]]) {
		NSArray     *models = [[(EODatabaseContext *)root database] models];
		NSInteger	x, max = [models count];
		
		for (x = 0; x < max && modelGroup == nil; x++) {
			modelGroup = [[models objectAtIndex:x] modelGroup];
		}
	}
	
	if (modelGroup == nil) {
		modelGroup = [EOModelGroup defaultGroup];
	}
	
	return modelGroup;
}

// mont_rothstein @ yahoo.com 2004-12-03
// These convience methods for stored procedures had not been updated since before the object store
// structure changed.  These will now all work properly.
- (EODatabaseChannel *)_channelWithFetchSpec:(EOFetchSpecification *)fetch
{
	return (EODatabaseChannel *)[(EODatabaseContext *)[(EOObjectStoreCoordinator *)objectStore objectStoreForFetchSpecification: fetch] availableChannel];
}

- (int)countOfObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
	return [[self _channelWithFetchSpec: fetch] countOfObjectsWithFetchSpecification:fetch];
}

- (id)maxValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
	return [[self _channelWithFetchSpec: fetch] maxValueForAttributeNamed:attributeName fromObjectsWithFetchSpecification:fetch];
}

- (id)minValueForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
	return [[self _channelWithFetchSpec: fetch] minValueForAttributeNamed:attributeName fromObjectsWithFetchSpecification:fetch];
}

- (id)sumOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
	return [[self _channelWithFetchSpec: fetch] sumOfValuesForAttributeNamed:attributeName fromObjectsWithFetchSpecification:fetch];
}

- (id)averageOfValuesForAttributeNamed:(NSString *)attributeName fromObjectsWithFetchSpecification:(EOFetchSpecification *)fetch
{
	return [[self _channelWithFetchSpec: fetch] averageOfValuesForAttributeNamed:attributeName fromObjectsWithFetchSpecification:fetch];
}


// mont_rothsetin @ yahoo.com 2004-12-03
// Added new convience methods for executing stored procedures.

// mont_rothstein @ yahoo.com 2004-12-03
// Added this for assistance with executing stored procedures.
- (EODatabaseChannel *)_channelWithEntityNamed:(NSString *)entityName
{
	return (EODatabaseChannel *)[(EODatabaseContext *)[(EOObjectStoreCoordinator *)objectStore _objectStoreForEntityNamed: entityName] availableChannel];
}

// mont_rothstein @ yahoo.com 2004-12-03
// Added this method as a convenience for executing stored procedures.
- (void)executeStoredProcedure:(EOStoredProcedure *)storedProcedure withValues:(NSDictionary *)values forEntityNamed:(NSString *)entityName
{
	[[[self _channelWithEntityNamed: entityName] adaptorChannel] executeStoredProcedure: storedProcedure withValues: values];
}

// mont_rothstein @ yahoo.com 2004-12-03
// Added this method as a convenience for getting the return values of stored procedures.
- (NSDictionary *)returnValuesForLastStoredProcedureInvocationForEntityNamed:(NSString *)entityName
{
	return [[[self _channelWithEntityNamed: entityName] adaptorChannel] returnValuesForLastStoredProcedureInvocation];
}


// Tom.Martin @ Riemer,com 2012-03-20
// This is NOT part of the API, but for now this is the only way I can think of sharing this
// information among all the database contexts such that all the relationship changes needed 
// for one object could be accessed.  This is important because if an object is removed from
// one to-many and then added to another the ORDER of the operations is critical.
- (NSDictionary *)updatedRelationshipsForMember:(EOGlobalID *)memberGID
{
    return [toManyUpdatedMembers objectForKey:memberGID];
}

@end
