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

#import "EOEntityP.h"

#import "EOAttributeP.h"
#import "EOEntityClassDescription.h"
#import "EOFetchSpecification-ModelPrivate.h"
#import "EODatabase.h"
#import "EOModelP.h"
#import "EORelationshipP.h"
#import "NSString-EOAccess.h"
#import "EOModelGroup.h"

#import <EOControl/EOControl.h>
#import <EOControl/EONumericKeyGlobalID.h>

NSString *EOFetchAllProcedureOperation = @"EOFetchAllProcedure";
NSString *EOFetchWithPrimaryKeyProcedureOperation = @"EOFetchWithPrimaryKeyProcedure";
NSString *EOInsertProcedureOperation = @"EOInsertProcedure";
NSString *EODeleteProcedureOperation = @"EODeleteProcedure";
NSString *EONextPrimaryKeyProcedureOperation = @"EONextPrimaryKeyProcedure";

NSString *EOEntityDidChangeNameNotification = @"EOEntityDidChangeNameNotification";

@interface EOModel (Private)

- (NSMutableDictionary *)_propertiesForEntityNamed:(NSString *)aName;

@end

@implementation EOEntity

- (id)init
{
	if ((self = [super init]) == nil)
		return nil;
	initialized = YES;
	subentities = [[NSMutableArray allocWithZone:[self zone]] init];
	attributes = [[NSMutableArray allocWithZone:[self zone]] init];
	attributeIndex = [[NSMutableDictionary allocWithZone:[self zone]] init];
	attributesUsedForLocking = [[NSMutableArray allocWithZone:[self zone]] init];
	attributesToFetch = [[NSMutableArray allocWithZone:[self zone]] init];
	// mont_rothstein @ yahoo.com 2004-12-20
	// Moved the below line to _initializeClassProperties so we can use it as a flag for
	// whether initialization has been done or not.
	//   classProperties = [[NSMutableArray allocWithZone:[self zone]] init];
	classPropertyNames = [[NSMutableArray allocWithZone:[self zone]] init];
	classAttributes = [[NSMutableArray allocWithZone:[self zone]] init];
	classRelationships = [[NSMutableArray allocWithZone:[self zone]] init];
	classRelationshipsToOne = [[NSMutableArray allocWithZone:[self zone]] init];
	classRelationshipsToMany = [[NSMutableArray allocWithZone:[self zone]] init];
	primaryKeyAttributes = [[NSMutableArray allocWithZone:[self zone]] init];
	primaryKeyAttributeNames = [[NSMutableArray allocWithZone:[self zone]] init];
	relationships = [[NSMutableArray allocWithZone:[self zone]] init];
	relationshipIndex = [[NSMutableDictionary allocWithZone:[self zone]] init];
	storedProcedures = [[NSMutableDictionary allocWithZone:[self zone]] init];
	userInfo = [[NSMutableDictionary allocWithZone:[self zone]] init];
	primaryKeyIsNumeric = NO;
	className = [@"EOGenericRecord" retain];

	return self;
}

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner
{
	if (self = [self init])
    {
        initialized = NO;
        // Tom Martin 5/11/11
        // we don't juar set the model = owner.  We need to fully add the entity to the model
        // I removed the addEntity call from EOModel._setupEntities as well.  This means that
        // this method will FULLY init the entity.
        // model = owner; // Not retained. 
        name = [[properties objectForKey:@"name"] retain];
        className = [[properties objectForKey:@"className"] retain];
        if ([owner isKindOfClass:[EOModel class]])
            [owner addEntity:self];
        }
   return self;
}

- (void)dealloc
{
   // model not retained.
	[subentities release];
   [name release];
   [attributes release];
   [attributeIndex release];
   [attributesUsedForLocking release];
   [attributesToFetch release];
   [classProperties release];
   // mont_rothstein @ yahoo.com 2005-12-05
   // Applied anon patch for missing retain/release on classPropertyNames
   [classPropertyNames release];
   [classRelationships release];
   [classRelationshipsToOne release];
   [classRelationshipsToMany release];
   [primaryKeyAttributes release];
   [relationships release];
   [relationshipIndex release];
	[storedProcedures release];
	[fetchSpecifications release];
	[attributeNames release];

   [super dealloc];
}

- (void)_addRelationshipFromProperties:(NSDictionary *)relationshipProperties
{
	EORelationship *relationship;
	
	relationship = [[EORelationship allocWithZone:[self zone]] initWithPropertyList:relationshipProperties owner:self];
	[self addRelationship:relationship];

	// mont_rothstein @ yahoo.com 2004-12-06
	// Added code to set the _isClassProperty flag on the relationship
	if ([classRelationships containsObject: [relationship name]])
	{
		[relationship _setIsClassProperty: YES];
	}

	[relationship release];
}

/*!
 * Does final setup for the entity, if initialied == NO.
 */
- (void)_initialize
{
   if (!initialized) {
      [self awakeWithPropertyList:[model _propertiesForEntityNamed:name]];
   }
}

- (NSMutableArray *)_uniqueProperties:(NSArray *)input
{
	NSMutableSet		*set = [[NSMutableSet allocWithZone:[self zone]] init];
	NSMutableArray		*result;
	
	[set addObjectsFromArray:input];
	result = [[set allObjects] mutableCopyWithZone:[self zone]];
	[set release];
	
	return [result autorelease];
}

- (void)awakeWithPropertyList:(NSDictionary *)properties
{
	NSArray			*attribs;
	int         	x;
	int numAttributes;
	int numClassPropertyNames;
	int numFlattenedRelationships;
	int numPrimaryKeyAttributeNames;
	NSDictionary	*work;

	initialized = YES;

	[EOObserverCenter suppressObserverNotification];
	
	attribs = [properties objectForKey:@"attributes"];
	numAttributes = [attribs count];
	for (x = 0; x < numAttributes; x++) {
		NSDictionary   *attributeProperties = [attribs objectAtIndex:x];
		EOAttribute		*attribute;
		
		attribute = [[EOAttribute allocWithZone:[self zone]] initWithPropertyList:attributeProperties owner:self];
		[self addAttribute:attribute];
		[attribute release];
	}
	
	className = [[properties objectForKey:@"className"] retain];
	if ([className isEqualToString:@"EOGenericRecord"]) {
		className = [@"EOGenericRecord" retain];
	}
	[classPropertyNames removeAllObjects];
	[classPropertyNames addObjectsFromArray:[self _uniqueProperties:[properties objectForKey:@"classProperties"]]];
	// We actually do this, because it helps when determining edits
	// to relationships, since it gives a quick check to see if we
	// need to examine the snapshot or the object for the key values.
	if ([classPropertyNames count]) {
		numClassPropertyNames = [classPropertyNames count];
		for (x = 0; x < numClassPropertyNames; x++) {
			NSString		*key = [classPropertyNames objectAtIndex:x];
			EOAttribute *attribute = [attributeIndex objectForKey:key];
			
			[attribute _setIsClassProperty:YES];
			if (attribute != nil) {
				[classAttributes addObject:key];
			} else {
				[classRelationships addObject:key];
			}
		}
	}
	
	externalName = [[properties objectForKey:@"externalName"] retain];
	externalQuery = [[properties objectForKey:@"externalQuery"] retain];
	if ([properties objectForKey:@"restrictingQualifier"]) {
		[self setRestrictingQualifier: [EOQualifier qualifierWithQualifierFormat:[properties objectForKey:@"restrictingQualifier"]]];
	}
	
	// garry @ dynafocus.com 2005-09-06
	// parentEntity is not the key for the parent Entity using Apple's EOModeler
	id tmpParentEntity = [properties objectForKey: @"parent"];
	if (!tmpParentEntity)
	{
		// this is left here for compatibility with models generated by AJR EOModeler
		tmpParentEntity = [properties objectForKey: @"parentEntity"];
	}
	
	if (tmpParentEntity)
	{
		EOEntity *entity;
		
		entity = [[[self model] modelGroup] entityNamed: tmpParentEntity];
		[entity addSubEntity: self];
	}
	
	[primaryKeyAttributeNames removeAllObjects];
	[primaryKeyAttributeNames addObjectsFromArray:[properties objectForKey:@"primaryKeyAttributes"]];
	primaryKeyIsPrivate = YES;
	primaryKeyIsNumeric = YES; // Assume YES, since it's easier to flip to NO down below.
	[primaryKeyAttributes removeAllObjects];
	if (primaryKeyAttributes != nil) {
		numPrimaryKeyAttributeNames = [primaryKeyAttributeNames count];
		for (x = 0; x < numPrimaryKeyAttributeNames; x++) {
			NSString		*key = [primaryKeyAttributeNames objectAtIndex:x];
			EOAttribute	*attribute = [attributeIndex objectForKey:key];
			
			if (attribute != nil) {
				[primaryKeyAttributes addObject:attribute];
				[attribute _setIsPrimaryKey:YES];
				if ([attribute _isClassProperty]) primaryKeyIsPrivate = NO;
				if (![attribute _isIntegralNumeric]) primaryKeyIsNumeric = NO;
			}
		}
	}
	primaryKeyValues = (id *)NSZoneMalloc([self zone], sizeof(id) * [primaryKeyAttributes count]);
	primaryKeyNames = (NSString **)NSZoneMalloc([self zone], sizeof(NSString *) * [primaryKeyAttributes count]);
	numPrimaryKeyAttributeNames = [primaryKeyAttributeNames count];
	for (x = 0; x < numPrimaryKeyAttributeNames; x++) {
		primaryKeyNames[x] = [primaryKeyAttributeNames objectAtIndex:x];
	}
	
	attribs = [properties objectForKey:@"relationships"];
	if (attribs != nil) {
		NSMutableArray		*flattenedRelationships;
		
		flattenedRelationships = [[NSMutableArray alloc] init];
		
		numAttributes = [attribs count];
		for (x = 0; x < numAttributes; x++) {
			NSDictionary    *relationshipProperties = [attribs objectAtIndex:x];
			
			if ([relationshipProperties objectForKey:@"definition"])   {
				[flattenedRelationships addObject:relationshipProperties];
			} else {
				[self _addRelationshipFromProperties:relationshipProperties];
			}
		}
		
		// Add flattened relationships
		numFlattenedRelationships = [flattenedRelationships count];
		for (x = 0; x < numFlattenedRelationships; x++) {
			[self _addRelationshipFromProperties:[flattenedRelationships objectAtIndex:x]];
		}
		
		[flattenedRelationships release];
	}
	
	attribs = [properties objectForKey:@"attributesUsedForLocking"];
	if (attribs != nil) {
		numAttributes = [attribs count];
		for (x = 0; x < numAttributes; x++) {
			EOAttribute		*attribute = [self attributeNamed:[attribs objectAtIndex:x]];
			if (attribute != nil) {
				[attributesUsedForLocking addObject:attribs];
			}
		}
	}

	// mont_rothstein @ yahoo.com 2004-12-20
	// The section below was causing problems.  Specifically the call to isToMany on the
	// relationship caused initializeDefinition to be called on relationships before the
	// entities they point to are loaded.  Therefore I moved this code to its own method
	// (_initializeClassProperties) that is lazily as necessary.
//	[classProperties removeAllObjects];
//	if ([classPropertyNames count]) {
//		for (x = 0; x < (const int)[classPropertyNames count]; x++) {
//			NSString		*key = [classPropertyNames objectAtIndex:x];
//			id				property = [attributeIndex objectForKey:key];
//			
//			if (property == nil) property = [relationshipIndex objectForKey:key];
//			
//			if (property == nil) {
//				[EOLog logWarningWithFormat:@"Encountered a class property name, but it is neither an attribute or a relationship: %@", key];
//			} else {
//				[classProperties addObject:property];
//				
//				if ([property isKindOfClass:[EORelationship class]]) {
//					if ([property isToMany]) {
//						[classRelationshipsToMany addObject:[property name]];
//					} else {
//						[classRelationshipsToOne addObject:[property name]];
//					}
//				}
//			}
//		}
//	}
	
	// This isn't actually correct, but it's what we're using for the time being. This should basically be any value needed for fetching a snapshot from the database. Thus, below is close, but not necessarily the same thing for some advanced objects.
	[attributesToFetch addObjectsFromArray:attributes];
	
	// Locking attributes
	attribs = [properties objectForKey:@"attributesUsedForLocking"];
	[attributesUsedForLocking removeAllObjects];
	if (attribs) {
		numAttributes = [attribs count];
		for (x = 0; x < numAttributes; x++) {
			NSString	*key = [attribs objectAtIndex:x];
			id			property = [attributeIndex objectForKey:key];
			
			if (property == nil) property = [relationshipIndex objectForKey:key];
			
			if (property == nil) {
				[EOLog logWarningWithFormat:@"Encountered a locking attribute name (%@), but it is neither an attribute or a relationship", key];
			} else {
				[attributesUsedForLocking addObject:property];
			}
		}
	}
	
	// Pick up our stored procedures...
	work = [properties objectForKey:@"storedProcedureNames"];
	[storedProcedures removeAllObjects];
	if ([work count]) {
		NSEnumerator		*enumerator = [work keyEnumerator];
		NSString				*key;
		
		while ((key = [enumerator nextObject]) != nil) {
			NSString		*spName = [work objectForKey:key];
			EOStoredProcedure	*procedure = [model storedProcedureNamed:spName];
			if (procedure) {
				[storedProcedures setObject:procedure forKey:key];
			}
		}
	}
	
	// User info
	work = [properties objectForKey:@"userInfo"];
	if ([work count]) {
		// Tom.Martin @ Riemer.com 2011-09=8-22
		// replace depreciated method call
		//[userInfo takeValuesFromDictionary:work];
		[userInfo setValuesForKeysWithDictionary:work];
	}
	
	// Miscellaneous flags
	cachesObjects = [[properties objectForKey:@"cachesObjects"] hasPrefix:@"Y"];
	readOnly = [[properties objectForKey:@"isReadOnly"] hasPrefix:@"Y"];
	isAbstractEntity = [[properties objectForKey:@"isAbstractEntity"] hasPrefix:@"Y"];

	// mont_rothstein@yahoo.com 2006-04-19
	// We have to use an NSScanner to get to unsigned int out of the NSString
	if ([properties objectForKey: @"maxNumberOfInstancesToBatchFetch"]) 
	{
		long long numFaults;
		NSScanner *numberScanner;
		
		numberScanner = [NSScanner scannerWithString: [properties objectForKey: @"maxNumberOfInstancesToBatchFetch"]];
		[numberScanner scanLongLong: &numFaults];
		batchSize = (unsigned int)numFaults;
	}
	
	[EOObserverCenter enableObserverNotification];
}

// mont_rothstein @ yahoo.com 2004-12-20
// Added this method to delay the initialization of class properties until after awakeFromPropertiesList:,
// which is where this code was.
- (void)_initializeClassProperties
{
	if (!classProperties)
	{
		int x;
		
		classProperties = [[NSMutableArray allocWithZone:[self zone]] init];
		
		if ([classPropertyNames count]) {
			int numClassPropertyNames;
			
			numClassPropertyNames = [classPropertyNames count];
			for (x = 0; x < numClassPropertyNames; x++) {
				NSString		*key = [classPropertyNames objectAtIndex:x];
				id				property = [attributeIndex objectForKey:key];
				
				if (property == nil) property = [relationshipIndex objectForKey:key];
				
				if (property == nil) {
					[EOLog logWarningWithFormat:@"Encountered a class property name, but it is neither an attribute or a relationship: %@", key];
				} else {
					[classProperties addObject:property];
					
					if ([property isKindOfClass:[EORelationship class]]) {
						if ([property isToMany]) {
							[classRelationshipsToMany addObject:[property name]];
						} else {
							[classRelationshipsToOne addObject:[property name]];
						}
					}
				}
			}
		}
	}
}

- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties
{
	NSMutableArray			*array;
	NSMutableDictionary	*dictionary;
	NSEnumerator			*enumerator;
	NSString					*key;
	int						x;
	int numAttributes;
	int numRelationships;
	
	[self _initialize];
	if (name) [properties setObject:name forKey:@"name"];
	if (externalName) [properties setObject:externalName forKey:@"externalName"];
	if (externalQuery) [properties setObject:externalQuery forKey:@"externalQuery"];
	if (restrictingQualifier) [properties setObject:[restrictingQualifier description] forKey:@"restrictingQualifier"];

	// garry@dynafocus.com 2005-09-06
	// parentEntity key should be "parent" for eomodels generated by Apple's EOModeler 
	// added code to handle incorrectly generated AJR models in awakeFromPropertyList
	if (parentEntity) [properties setObject: [parentEntity name] forKey: @"parent"];
	
	if ([userInfo count]) [properties setObject:userInfo forKey:@"userInfo"];
	[properties setObject:primaryKeyAttributeNames forKey:@"primaryKeyAttributes"];
	if ([classPropertyNames count]) [properties setObject:classPropertyNames forKey:@"classProperties"];
	if (className) {
		if ([className isEqualToString:@"EOGenericRecord"]) {
			[properties setObject:@"EOGenericRecord" forKey:@"className"];
		} else {
			[properties setObject:className forKey:@"className"];
		}
	}
	[properties setObject:[attributesUsedForLocking valueForKey:@"name"] forKey:@"attributesUsedForLocking"];
	if (readOnly) [properties setObject:@"Y" forKey:@"isReadOnly"];
	if (cachesObjects) [properties setObject:@"Y" forKey:@"cachesObjects"];
	if (isAbstractEntity) [properties setObject:@"Y" forKey:@"isAbstractEntity"];
	if (batchSize != 0) [properties setObject:[NSNumber numberWithInt:batchSize] forKey:@"maxNumberOfInstancesToBatchFetch"];
	if ([[self fetchSpecificationNames] count] == 0) [properties setObject:[NSDictionary dictionary] forKey:@"fetchSpecificationDictionary"];
	
	array = [[NSMutableArray allocWithZone:[self zone]] init];
	numAttributes = [attributes count];
	for (x = 0; x < numAttributes; x++) {
		EOAttribute		*attribute = [attributes objectAtIndex:x];
		dictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
		[attribute encodeIntoPropertyList:dictionary];
		[array addObject:dictionary];
		[dictionary release];
	}
	[properties setObject:array forKey:@"attributes"];
	[array release];
	
	array = [[NSMutableArray allocWithZone:[self zone]] init];
	numRelationships = [relationships count];
	for (x = 0; x < numRelationships; x++) {
		EORelationship		*relationship = [relationships objectAtIndex:x];
		dictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
		[relationship encodeIntoPropertyList:dictionary];
		[array addObject:dictionary];
		[dictionary release];
	}
	[properties setObject:array forKey:@"relationships"];
	[array release];
	
	dictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
	enumerator = [storedProcedures keyEnumerator];
	while ((key = [enumerator nextObject])) {
		[dictionary setObject:[[storedProcedures objectForKey:key] name] forKey:key];
	}
	if ([dictionary count]) {
		[properties setObject:dictionary forKey:@"storedProcedureNames"];
	}
	[dictionary release];
}

- (void)setName:(NSString *)aName
{
   if (name != aName && ![name isEqualToString:aName]) {
		NSString		*oldName = [name retain];
		
		[self willChange];
		if ([model undoManager]) {
			[[model undoManager] registerUndoWithTarget:self selector:@selector(setName:) object:name];
		}
      [name release];
      name = [aName retain];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:EOEntityDidChangeNameNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldName, @"oldName", name, @"newName", nil]];
		[oldName release];
   }
}

- (NSString *)name
{
   return name;
}

- (NSException *)validateName:(NSString *)aName
{
	NSString		*error;

	error = [EOModel _validateName:aName];
	if (!error && [[self model] entityNamed:aName] != nil) {
		error = @"An entity already exists with name";
	}
	if (!error && [[self model] storedProcedureNamed:aName] != nil) {
		error = @"A stored procedure already exists with name";
	}
	
	if (error) {
		return [[[NSException allocWithZone:[self zone]] initWithName:NSInvalidArgumentException reason:error userInfo:nil] autorelease];
	}
	
	return nil;
}

- (void)beautifyName
{
	[self setName:[NSString nameForExternalName:name separatorString:@"_" initialCaps:YES]];
}

- (void)_changeAttributeName:(NSString *)oldName to:(NSString *)newName
{
   EOAttribute *attribute = [attributeIndex objectForKey:oldName];

   if (attribute != nil) {
      [attributeIndex setObject:attribute forKey:newName];
      [attributeIndex removeObjectForKey:oldName];
   }
}

- (void)addAttribute:(EOAttribute *)attribute
{
   [self _initialize];
	
	if ([attributeIndex objectForKey:[attribute name]] == nil) {
		[self willChange];
		if ([model undoManager]) {
			[[model undoManager] registerUndoWithTarget:self selector:@selector(removeAttribute:) object:attribute];
		}
		[attributes addObject:attribute];
		attributesNeedSorting = YES;
		[attributeIndex setObject:attribute forKey:[attribute name]];
		[attributesToFetch addObject:attribute];
		[attribute _setParent:self];
		[attributeNames release]; attributeNames = nil;
		
		[EOObserverCenter addObserver:self forObject:attribute];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_attributeDidChangeName:) name:EOAttributeDidChangeNameNotification object:attribute];
	}
}

- (EOAttribute *)attributeNamed:(NSString *)aName
{
   [self _initialize];
   return [attributeIndex objectForKey:aName];
}

- (EOAttribute *)anyAttributeNamed:(NSString *)aName
{
   [self _initialize];
   return [attributeIndex objectForKey:aName];
}

- (NSArray *)attributes
{
   [self _initialize];
	if (attributesNeedSorting) {
		[attributes sortUsingSelector:@selector(compare:)];
		attributesNeedSorting = NO;
	}
   return attributes;
}

- (NSArray *)_attributeNames
{
	if (attributeNames == nil) {
		attributeNames = [[attributes valueForKey:@"name"] retain];
	}
	return attributeNames;
}

- (void)removeAttribute:(EOAttribute *)attribute
{
	[self _initialize];
	if ([attributeIndex objectForKey:[attribute name]]) {
		[self willChange];
		if ([model undoManager]) {
			[[model undoManager] registerUndoWithTarget:self selector:@selector(addAttribute:) object:attribute];
		}
		[attribute _setParent:nil];
		[attributes removeObject:attribute];
		[attributesToFetch removeObject:attribute];
		[attributeIndex removeObjectForKey:[attribute name]];
		[attributeNames release]; attributeNames = nil;
		
		[EOObserverCenter removeObserver:self forObject:attribute];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:EOAttributeDidChangeNameNotification object:attribute];
	}
}

- (NSArray *)attributesToFetch
{
	[self _initialize];
	return attributesToFetch;
}

- (void)addRelationship:(EORelationship *)relationship
{
   [self _initialize];
	
	if ([relationshipIndex objectForKey:[relationship name]] == nil) {
		[self willChange];
		if ([model undoManager]) {
			[[model undoManager] registerUndoWithTarget:self selector:@selector(removeRelationship:) object:relationship];
		}
		[relationships addObject:relationship];
		relationshipsNeedSorting = YES;
		[relationshipIndex setObject:relationship forKey:[relationship name]];
		[relationship setEntity:self];
		
		[EOObserverCenter addObserver:self forObject:relationship];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_relationshipDidChangeName:) name:EORelationshipDidChangeNameNotification object:relationship];
	}
}

- (EORelationship *)anyRelationshipNamed:(NSString *)aName
{
   [self _initialize];
   return [relationshipIndex objectForKey:aName];
}

- (NSArray *)relationships
{
   [self _initialize];
	if (relationshipsNeedSorting) {
		relationshipsNeedSorting = NO;
		[relationships sortUsingSelector:@selector(compare:)];
	}

   return relationships;
}

- (EORelationship *)relationshipNamed:(NSString *)aName
{
   [self _initialize];
   return [relationshipIndex objectForKey:aName];
}

- (void)removeRelationship:(EORelationship *)relationship
{
	[self _initialize];
	if ([relationshipIndex objectForKey:[relationship name]] != nil) {
		[self willChange];
		if ([model undoManager]) {
			[[model undoManager] registerUndoWithTarget:self selector:@selector(addRelationship:) object:relationship];
		}
		[relationship setEntity:nil];
		[relationships removeObject:relationship];
		[relationshipIndex removeObjectForKey:[relationship name]];
		
		[EOObserverCenter removeObserver:self forObject:relationship];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:EORelationshipDidChangeNameNotification object:relationship];
	}
}

- (NSArray *)externalModelsReferenced
{
	NSMutableArray	*models = nil;
	NSArray			*array;
	NSArray			*work;
	int				x;
	
	array = [self attributes];
	for (x = [array count] - 1; x >= 0; x--) {
		EOAttribute		*attribute = [array objectAtIndex:x];
		work = [attribute _externalModelsReferenced];
		if ([work count]) {
			if (models == nil) models = [[work mutableCopyWithZone:[self zone]] autorelease];
			[models addObjectsFromArray:work];
		}
	}
	
	array = [self relationships];
	for (x = [array count] - 1; x >= 0; x--) {
		EORelationship		*relationship = [array objectAtIndex:x];
		work = [relationship _externalModelsReferenced];
		if ([work count]) {
			if (models == nil) models = [[work mutableCopyWithZone:[self zone]] autorelease];
			[models addObjectsFromArray:work];
		}
	}
	
	return models;
}

- (NSArray *)_referencesToProperty:(id)property
{
	NSMutableArray	*properties = nil;
	NSArray			*array;
	int				x;
	
	array = [self attributes];
	for (x = [array count] - 1; x >= 0; x--) {
		EOAttribute		*attribute = [array objectAtIndex:x];
		if ([attribute _referencesProperty:property]) {
			if (properties == nil) properties = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];
			[properties addObject:attribute];
		}
	}
	
	array = [self relationships];
	for (x = [array count] - 1; x >= 0; x--) {
		EORelationship		*relationship = [array objectAtIndex:x];
		if ([relationship _referencesProperty:property]) {
			if (properties == nil) properties = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];
			[properties addObject:relationship];
		}
	}
	
	return properties;
}

- (BOOL)referencesProperty:(id)property
{
	NSArray		*array;
	int			x;
	
	array = [self attributes];
	for (x = [array count] - 1; x >= 0; x--) {
		if ([[array objectAtIndex:x] _referencesProperty:property]) return YES;
	}
	
	array = [self relationships];
	for (x = [array count] - 1; x >= 0; x--) {
		if ([[array objectAtIndex:x] _referencesProperty:property]) return YES;
	}
	
	return NO;
}

- (EOGlobalID *)globalIDForRow:(NSDictionary *)row
{
	int			x;
	int numPrimaryKeyAttributes;
	EOGlobalID	*globalID;
	id			primaryKeyValue;
	
	[self _initialize];
	
	numPrimaryKeyAttributes = [primaryKeyAttributes count];
	for (x = 0; x < numPrimaryKeyAttributes; x++) {
		// mont_rothstein @ yahoo.com 2005-01-20
		// For some reason the entity sometimes has NULLs for attribute values when a value 
		// has not been set (i.e. would otherwise be nil).  Added to code to check for this
		// because othewise NSNumber was puking trying to return an unsignedLongLong for
		// a NULL value.
		// aclark @ ghoti.org 2005-12-18
		// globalIDForRow can pass junk data in primaryKeyValues if passed NULL values. This patch enforces nil values being passed in lieu of NSNull objects for further methods to handle it properly.
		// Tom.Martin @ riemer.com 2011-08-16
		// same as above but code was not setting primaryKeyValues[x] to nil on NULL, but leaving it unset.
		primaryKeyValue = [row objectForKey:[primaryKeyAttributeNames objectAtIndex:x]];
		if (primaryKeyValue != [NSNull null]) 
			primaryKeyValues[x] = primaryKeyValue;
		else
			primaryKeyValues[x] = nil;
	}
	
	if ([self _primaryKeyIsNumeric]) {
		globalID = [EONumericKeyGlobalID globalIDWithEntityName:[self name] keys:primaryKeyNames values:primaryKeyValues count:[primaryKeyAttributeNames count]];
	} else {
		globalID = [EOKeyGlobalID globalIDWithEntityName:[self name] keys:primaryKeyNames values:primaryKeyValues count:[primaryKeyAttributeNames count]];
	}
	
	return globalID;
}

- (BOOL)isPrimaryKeyValidInObject:(id)object
{
	NSArray		*keys = [self primaryKeyAttributeNames];
	int			x;
	int numKeys;
	
	numKeys = [keys count];
	for (x = 0; x < numKeys; x++) {
		if ([object valueForKey:[keys objectAtIndex:x]] == nil) return NO;
	}
	
	return YES;
}

- (NSDictionary *)primaryKeyForGlobalID:(EOGlobalID *)globalID
{
	return [self primaryKeyForRow:(NSDictionary *)globalID];
}

- (NSDictionary *)primaryKeyForRow:(NSDictionary *)row
{
	NSArray					*keys = [self primaryKeyAttributeNames];
	int						x;
	int numKeys;
	NSMutableDictionary	*pk = [NSMutableDictionary dictionary];
	
	numKeys = [keys count];
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		id				value;
		
		value = [row valueForKey:key];
		if (value == nil) return nil;
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  
		//[pk takeValue:value forKey:key];
		[pk setValue:value forKey:key];
	}
	
	return pk;
}

- (void)setPrimaryKeyAttributes:(NSArray *)someAttributes
{
	[self _initialize];
	if (primaryKeyAttributes != someAttributes) {
		int			x;
		int numPrimaryKeyAttributes;
		int numPrimaryKeyAttributeNames;
		
		[self willChange];
		if ([model undoManager]) {
			[[model undoManager] registerUndoWithTarget:self selector:@selector(setPrimaryKeyAttributes:) object:primaryKeyAttributes];
		}
		
		numPrimaryKeyAttributes = [primaryKeyAttributes count];
		for (x = 0; x < numPrimaryKeyAttributes; x++) {
			[[primaryKeyAttributes objectAtIndex:x] _setIsPrimaryKey:NO];
		}
		[primaryKeyAttributes release];
		primaryKeyAttributes = [someAttributes mutableCopyWithZone:[self zone]];
		
		// Scan and "prime" the new attributes
		primaryKeyIsPrivate = YES;
		primaryKeyIsNumeric = YES; // Assume YES, since it's easier to flip to NO down below.
		numPrimaryKeyAttributes = [primaryKeyAttributes count];
		for (x = 0; x < numPrimaryKeyAttributes; x++) {
			EOAttribute		*attribute = [primaryKeyAttributes objectAtIndex:x];
			[attribute _setIsPrimaryKey:YES];
			if ([attribute _isClassProperty]) primaryKeyIsPrivate = NO;
			if (![attribute _isIntegralNumeric]) primaryKeyIsNumeric = NO;
		}
		
		[primaryKeyAttributeNames removeAllObjects];
		[primaryKeyAttributeNames addObjectsFromArray:[primaryKeyAttributes valueForKey:@"name"]];
		
		if (primaryKeyValues) NSZoneFree([self zone], primaryKeyValues);
		primaryKeyValues = (id *)NSZoneMalloc([self zone], sizeof(id) * [primaryKeyAttributes count]);
		if (primaryKeyNames) NSZoneFree([self zone], primaryKeyNames);
		primaryKeyNames = (NSString **)NSZoneMalloc([self zone], sizeof(NSString *) * [primaryKeyAttributes count]);
		numPrimaryKeyAttributeNames = [primaryKeyAttributeNames count];
		for (x = 0; x < numPrimaryKeyAttributeNames; x++) {
			primaryKeyNames[x] = [primaryKeyAttributeNames objectAtIndex:x];
		}
		
	}
}

- (NSArray *)primaryKeyAttributes
{
	return primaryKeyAttributes;
}

- (NSArray *)primaryKeyAttributeNames
{
   [self _initialize];
   return primaryKeyAttributeNames;
}

- (NSString *)primaryKeyRootName
{
	[self _initialize];
	if (parentEntity) return [parentEntity primaryKeyRootName];
	return [self externalName];
}

- (BOOL)isValidPrimaryKeyAttribute:(EOAttribute *)attribute
{
	if ([attribute isKindOfClass:[EOAttribute class]] && [attribute entity] == self/* && ![attribute isDerived]*/) {
		return YES;
	}
	
	return NO;
}

- (void)setClassProperties:(NSArray *)properties
{
	int			x;
	int numClassProperties;
	
	/*! @todo use isValidClassProperty: return NO if any properties are not valid class properties.  See docs for more details. */
		
	// mont_rothstein @ yahoo.com 2004-12-20
	// Modified this to call the new _initializeClassProperties method instead of _initialize.
   [self _initializeClassProperties];

	[self willChange];
	if ([model undoManager]) {
		[[model undoManager] registerUndoWithTarget:self selector:@selector(setClassProperties:) object:classProperties];
	}
	
	numClassProperties = [classProperties count];
	for (x = 0; x < numClassProperties; x++) {
		[[classProperties objectAtIndex:x] _setIsClassProperty:NO];
	}
	
	// mont_rothstein @ yahoo.com 2005-09-10
	// The setting of the class properties below, never used when auto-loading a model, faileded to do a number of steps necessary when programatically building a model.  This now builds the classAttrbitues and classRelationships arrays and delays setting the actual classProperties until they are next accessed, which will cause futher setup to occur.
	[classProperties release]; classProperties = nil;
	[classPropertyNames removeAllObjects];
	[classAttributes removeAllObjects];
	[classRelationships removeAllObjects];
	classPropertyNames = [[properties valueForKey:@"name"] retain];;
	numClassProperties = [classPropertyNames count];
	for (x = 0; x < numClassProperties; x++) {
		NSString		*key = [classPropertyNames objectAtIndex:x];
		EOAttribute *attribute = [attributeIndex objectForKey:key];
		
		[attribute _setIsClassProperty:YES];
		if (attribute != nil) [classAttributes addObject:key];
		else [classRelationships addObject:key];
	}
}

- (NSArray *)classProperties
{
	// mont_rothstein @ yahoo.com 2004-12-20
	// added call to _initializeClassProperties because classProperties are now initialized lazily.
   [self _initializeClassProperties];
   return classProperties;
}

- (NSArray *)classPropertyNames
{
	// Only return the public attributes.
	// 2006-10-16 AJR This is a condition that requires delayed initialization
   [self _initialize];
	return classPropertyNames;
}

- (BOOL)isValidClassProperty:(id)property
{
	if ([property isKindOfClass:[EOAttribute class]] && [property entity] == (id)self) return YES;
	if ([property isKindOfClass:[EORelationship class]] && [property entity] == (id)self) return YES;
	
	return NO;
}

- (EOEntityClassDescription *)classDescriptionForInstances
{
	return (EOEntityClassDescription *)[EOEntityClassDescription classDescriptionForEntityName:name];
}

- (void)setClassName:(NSString *)aName
{
   if (aName != className && ![className isEqualToString:aName]) {
		[self willChange];
		if ([model undoManager]) {
			[[model undoManager] registerUndoWithTarget:self selector:@selector(setClassName:) object:className];
		}
      [className release];
      className = [aName retain];
      objectClass = Nil;
   }
}

- (NSString *)className
{
   return className;
}

- (void)setAttributesUsedForLocking:(NSArray *)someAttributes
{
	int			x;
	int numAttributes;
	
	[self willChange];
	numAttributes = [attributesUsedForLocking count];
	for (x = 0; x < numAttributes; x++) {
		[[attributesUsedForLocking objectAtIndex:x] willChange];
	}

	if ([model undoManager]) {
		[[model undoManager] registerUndoWithTarget:self selector:@selector(setAttributesUsedForLocking:) object:attributesUsedForLocking];
	}
	[attributesUsedForLocking release];
	attributesUsedForLocking = [someAttributes mutableCopyWithZone:[self zone]];
}

- (NSArray *)attributesUsedForLocking
{
	[self _initialize];
	return attributesUsedForLocking;
}

- (BOOL)isValidAttributeUsedForLocking:(EOAttribute *)anAttribute
{
	return [anAttribute isKindOfClass:[EOAttribute class]] && [[self attributes] containsObject:anAttribute];
}

- (void)setExternalName:(NSString *)aName
{
   if (externalName != aName && ![externalName isEqualToString:aName]) {
		[self willChange];
		if ([model undoManager]) {
			[[model undoManager] registerUndoWithTarget:self selector:@selector(setExternalName:) object:externalName];
		}
      [externalName release];
      externalName = [aName retain];
   }
}

- (NSString *)externalName
{
   [self _initialize];
   return externalName;
}

- (void)setReadOnly:(BOOL)flag
{
	[self _initialize];
	if (readOnly != flag) {
		[self willChange];
		if ([model undoManager]) {
			[[[model undoManager] prepareWithInvocationTarget:self] setReadOnly:readOnly];
		}
		readOnly = flag;
	}
}

- (BOOL)isReadOnly
{
	[self _initialize];
	return readOnly;
}

- (void)setUserInfo:(NSDictionary *)someInfo
{
	[self _initialize];
	if (userInfo != someInfo) {
		[self willChange];
		if ([model undoManager]) {
			[[model undoManager] registerUndoWithTarget:self selector:@selector(setUserInfo:) object:userInfo];
		}
		[userInfo release];
		userInfo = [someInfo mutableCopyWithZone:[self zone]];
	}
}

- (NSDictionary *)userInfo
{
	[self _initialize];
	return userInfo;
}

- (void)setStoredProcedure:(EOStoredProcedure *)storedProcedure forOperation:(NSString *)operation
{
	[self _initialize];
	[self willChange];
	if ([model undoManager]) {
		[[[model undoManager] prepareWithInvocationTarget:self] setStoredProcedure:[self storedProcedureForOperation:operation] forOperation:operation];
	}
	if (storedProcedure == nil) {
		[storedProcedures removeObjectForKey:operation];
	} else {
		[storedProcedures setObject:storedProcedure forKey:operation];
	}
}

- (EOStoredProcedure *)storedProcedureForOperation:(NSString *)operation
{
	[self _initialize];
	return [storedProcedures objectForKey:operation];
}

- (void)_initializeFetchSpecifications
{
	if (fetchSpecifications == nil) 
    {
		NSDictionary		*properties;
		
		fetchSpecifications = [[NSMutableDictionary allocWithZone:[self zone]] init];
		
		properties = [model _propertiesForFetchSpecificationForEntityNamed:[self name]];

        if ([properties count]) 
        {
			NSEnumerator	*enumerator	= [properties keyEnumerator];
			NSString			*fetchName;
			
			while ((fetchName = [enumerator nextObject])) 
            {
                NSDictionary			*fetchProperties = [properties objectForKey:fetchName];
				EOFetchSpecification	*fetch;
				
				fetch = [[EOFetchSpecification allocWithZone:[self zone]] initWithPropertyList:fetchProperties owner:self];
				if (fetch) {
					[fetchSpecifications setObject:fetch forKey:fetchName];
				}
                [fetch release];
			}
		}
	}
}

- (void)addFetchSpecification:(EOFetchSpecification *)fetch withName:(NSString *)aName
{
	[self _initialize];
	[self _initializeFetchSpecifications];
	[self willChange];
	if ([model undoManager]) {
		[[model undoManager] registerUndoWithTarget:self selector:@selector(removeFetchSpecificationNamed:) object:aName];
	}
	[fetchSpecifications setObject:fetch forKey:aName];
	[fetch setName:aName];
	[fetch _setEntity:self];
}

- (EOFetchSpecification *)fetchSpecificationNamed:(NSString *)aName
{
	[self _initialize];
	[self _initializeFetchSpecifications];
	return [fetchSpecifications objectForKey:aName];
}

- (NSArray *)fetchSpecificationNames
{
	[self _initialize];
	[self _initializeFetchSpecifications];
	return [[fetchSpecifications allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)removeFetchSpecificationNamed:(NSString *)aName
{
	[self _initialize];
	[self _initializeFetchSpecifications];
	[[fetchSpecifications objectForKey:aName] _setEntity:nil];
	[fetchSpecifications removeObjectForKey:aName];
}

- (NSArray *)_toManyRelationshipKeys
{
	// mont_rothstein @ yahoo.com 2004-12-20
	// added call to _initializeClassProperties because classProperties are now initialized lazily.
	[self _initializeClassProperties];
	return classRelationshipsToMany;
}

- (NSArray *)_toOneRelationshipKeys
{
	// mont_rothstein @ yahoo.com 2004-12-20
	// added call to _initializeClassProperties because classProperties are now initialized lazily.
	[self _initializeClassProperties];
	return classRelationshipsToOne;
}

- (void)setExternalQuery:(NSString *)aQuery
{
	[self _initialize];
	if (externalQuery != aQuery && ![externalQuery isEqualToString:aQuery]) {
		[self willChange];
		if ([model undoManager]) {
			[[model undoManager] registerUndoWithTarget:self selector:@selector(setExternalQuery:) object:externalQuery];
		}
		[externalQuery release];
		externalQuery = [aQuery retain];
	}
}

- (NSString *)externalQuery
{
	[self _initialize];
	return externalQuery;
}

- (void)setRestrictingQualifier:(EOQualifier *)qualifier
{
	[self _initialize];
	if (restrictingQualifier != qualifier) {
		[self willChange];
		if ([model undoManager]) {
			[[model undoManager] registerUndoWithTarget:self selector:@selector(setRestrictingQualifier:) object:restrictingQualifier];
		}
		[restrictingQualifier release];
		restrictingQualifier = [qualifier retain];
	}
}

- (EOQualifier *)restrictingQualifier
{
	[self _initialize];
	return restrictingQualifier;
}

- (EOQualifier *)qualifierForPrimaryKey:(NSDictionary *)pk
{
	NSArray			*names = [self primaryKeyAttributeNames];
	NSMutableArray	*parts;
	EOQualifier		*qualifier;
    NSString        *aName;
    EOQualifier		*kvQualifier;
    
	if ([names count] == 1) 
    {
        aName = [names objectAtIndex:0];
		return [EOKeyValueQualifier qualifierWithKey:aName value:[pk valueForKey:aName]];
	}
	
    // Tom.Martin @ Riemer.com 2012-07-10
    // There was a bug where where it was the key,value was always the first kv pair of the 
    // dictionary. 
	parts = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:[names count]];
    for (aName in names)
    {
        kvQualifier = [EOKeyValueQualifier qualifierWithKey:aName value:[pk valueForKey:aName]];
        [parts addObject:kvQualifier];
    }
     	
	qualifier = [EOAndQualifier qualifierWithArray:parts];
	[parts release];
	
	return qualifier;
}

- (BOOL)isQualifierForPrimaryKey:(EOQualifier *)aQualifier
{
	NSArray		*names = [self primaryKeyAttributeNames];
	// Tom.Martin @ Riemer.com 2011-08-30
	// added check for qualifier operation is eqauls
	if ([names count] > 1) 
	{
		if ([aQualifier isKindOfClass:[EOAndQualifier class]]) 
		{
			NSArray		*parts = [(EOAndQualifier *)aQualifier qualifiers];
			int			numParts = [parts count];
			
			if (numParts == [names count]) 
			{
				int				x;
				NSMutableSet	*someNames = [NSMutableSet set];
				
				[someNames addObjectsFromArray:names];
				for (x = 0; x < numParts; x++) {
					EOQualifier	*subqualifier = [parts objectAtIndex:x];
					if ([subqualifier isKindOfClass:[EOKeyValueQualifier class]]) {
						if ([(EOKeyValueQualifier *)subqualifier selector] == EOQualifierEquals) {
							[someNames removeObject:[(EOKeyValueQualifier *)subqualifier key]];
						}
					}
				}
				if ([someNames count] == 0) return YES;
			}
		}
	} 
	else 
	{
		if ([aQualifier isKindOfClass:[EOKeyValueQualifier class]]) {
			if ([(EOKeyValueQualifier *)aQualifier selector] == EOQualifierEquals) {
				return [[(EOKeyValueQualifier *)aQualifier key] isEqualToString:[names objectAtIndex:0]];
			}
		}
	}
	
	return NO;
}

- (void)_setParentEntity:(EOEntity *)aParent
{
	if (parentEntity != aParent) {
		[self willChange];
		parentEntity = aParent;
	}
}

- (EOEntity *)parentEntity
{
	return parentEntity;
}

- (NSArray *)subEntities
{
	return subentities;
}

- (void)addSubEntity:(EOEntity *)subentity
{
	[self willChange];
	if ([[subentity model] undoManager]) {
		[[[subentity model] undoManager] registerUndoWithTarget:self selector:@selector(removeSubEntity:) object:subentity];
	}
	if ([subentity parentEntity] != nil) {
		// Remove the subentity from it's previous parent first.
		[[subentity parentEntity] removeSubEntity:subentity];
	}
	[subentities addObject:subentity];
	[subentity _setParentEntity:self];
}

- (void)removeSubEntity:(EOEntity *)subentity
{
	NSUInteger index;
	
	if ((index = [subentities indexOfObjectIdenticalTo:subentity]) != NSNotFound) {
		[self willChange];
		if ([[subentity model] undoManager]) {
			[[[subentity model] undoManager] registerUndoWithTarget:self selector:@selector(addSubEntity:) object:subentity];
		}
		[subentities removeObjectAtIndex:index];
		[subentity _setParentEntity:nil];
	}
}

- (void)setIsAbstractEntity:(BOOL)flag
{
	if (isAbstractEntity != flag) {
		[self willChange];
		if ([model undoManager]) {
			[[[model undoManager] prepareWithInvocationTarget:self] setIsAbstractEntity:isAbstractEntity];
		}
	}
	isAbstractEntity = flag;
}

- (BOOL)isAbstractEntity
{
	return isAbstractEntity;
}

- (void)setMaxNumberOfInstancesToBatchFetch:(unsigned int)size
{
	if (batchSize != size) {
		[self willChange];
		if ([model undoManager]) {
			[[[model undoManager] prepareWithInvocationTarget:self] setMaxNumberOfInstancesToBatchFetch:batchSize];
		}
		batchSize = size;
	}
}

- (unsigned int)maxNumberOfInstancesToBatchFetch
{
	return batchSize;
}

- (void)setCachesObjects:(BOOL)flag
{
	if (cachesObjects != flag) {
		[self willChange];
		if ([model undoManager]) {
			[[[model undoManager] prepareWithInvocationTarget:self] setCachesObjects:cachesObjects];
		}
	}
	cachesObjects = flag;
}

- (BOOL)cachesObjects
{
	return cachesObjects;
}

- (void)_setObjectClass:(Class)aClass
{
   if (objectClass != aClass) {
      objectClass = aClass;
      [className release];
      className = [NSStringFromClass(objectClass) retain];
   }
}

- (Class)_objectClass
{
   [self _initialize];
   if (objectClass == Nil) {
      objectClass = NSClassFromString(className);
      if (!objectClass) {
         // 2006-10-07 AJR
         // We we're throwing an exception on this one, but let's log a warning instead and
         // just use EOGenericRecord when we can't find the proper class. This would probably
         // cause breakage in a normal program, but it helps when developing, especially early
         // on and the initial system is being set up.
         [EOLog logWarningWithFormat:@"No class \"%@\" loaded, substituting EOGenericRecord.", className];
         objectClass = [EOGenericRecord class];
      }
   }
   return objectClass;
}

- (NSString *)description
{
   [self _initialize];
   return EOFormat(@"[EOEntity:%@]", name);
}

- (void)_setModel:(EOModel *)aModel
{
	model = aModel;
}

- (EOModel *)model
{
   return model;
}

- (NSArray *)_attributesForKeyPath:(NSString *)path
{
	int				x, max = [path length], lastX;
	NSMutableArray	*someAttributes = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];
	EOEntity			*left = self;
	id					object;
	NSString			*aName;
	NSArray				*components;
	
	[self _initialize];

	for (lastX = x = 0; x < max; x++) 
	{
		if ([path characterAtIndex:x] == '.') 
		{
			NSString			*relationshipName = [path substringWithRange:(NSRange){lastX, x - lastX}];
			EORelationship	*relationship = [left relationshipNamed:relationshipName];

			if (relationship == nil) 
			{
				someAttributes = nil;
				return nil;
			}
		 
			// if we encounter a flattened attribute, then expand it
			if ([relationship isFlattened])
			{
				components = [left _attributesForKeyPath:[relationship definition]];
				if (! components) 
				{
					someAttributes = nil;
					return nil;
				}
				[someAttributes addObject:components];
				left = [(EORelationship *)[components lastObject] destinationEntity];
			}
			else 
			{
				left = [relationship destinationEntity];
				[someAttributes addObject:relationship];
			}
			lastX = x + 1;
		}
	}
	aName = [path substringWithRange:(NSRange){lastX, x - lastX}];
	if ((object = [left attributeNamed:aName]) != nil) 
	{
		[someAttributes addObject:object];
	}
	else if ((object = [left relationshipNamed:aName]) != nil) 
	{
		[someAttributes addObject:object];
	}

   return someAttributes;
}

- (NSArray *)_classAttributes
{
   [self _initialize];
   return classAttributes;
}

- (NSArray *)_classRelationships
{
   [self _initialize];
   return classRelationships;
}

- (BOOL)_primaryKeyIsPrivate
{
   return primaryKeyIsPrivate;
}

- (BOOL)_primaryKeyIsNumeric
{
	return primaryKeyIsNumeric;
}

- (void)_removeReferencesToEntity:(EOEntity *)entity
{
	NSArray		*relations = [self relationships];
	int			x;
	int numRelations;
	
	numRelations = [relations count];
	for (x = 0; x < numRelations; x++) {
		EORelationship		*relationship = [relations objectAtIndex:x];
		
		if ([relationship destinationEntity] == entity) {
			[self removeRelationship:relationship];
		}
	}
}

- (int)compare:(id)other
{
	if (![other isKindOfClass:[EOEntity class]]) return NSOrderedAscending;
	return [[self name] caseInsensitiveCompare:[other name]];
}

- (void)objectWillChange:(id)object
{
	// Just forward this to our model. This keeps are model, which listens for our changes, to have to register to listen to changes to all our contained objects, like relationships and attributes.
	//[EOLog logDebugWithFormat:@"change (Entity): %@\n", object];
	[model objectWillChange:object];
}

- (void)_attributeDidChangeName:(NSNotification *)notification
{
	EOAttribute	*attribute = [notification object];
	NSString		*oldName = [[notification userInfo] objectForKey:@"oldName"];
	NSString		*newName = [[notification userInfo] objectForKey:@"newName"];
	
	if (oldName) [attributeIndex removeObjectForKey:oldName];
	if (newName) [attributeIndex setObject:attribute forKey:newName];
	
	// mont_rothstein @ yahoo.com 2005-04-17
	// The was checking for the index != nil, it needs to be NSNotFound.
	if ([[self classProperties] indexOfObjectIdenticalTo:attribute] != NSNotFound) {
		if (oldName) [classPropertyNames removeObject:oldName];
		if (newName) [classPropertyNames addObject:newName];
	}
	
	// mont_rothstein @ yahoo.com 2005-04-17
	// This was checking for nil instead of NSNotFound, which caused all new attributes to get
	// added to the primary keys.
	if ([primaryKeyAttributes indexOfObjectIdenticalTo:attribute] != NSNotFound) {
		if (oldName) [primaryKeyAttributeNames removeObject:oldName];
		if (newName) [primaryKeyAttributeNames addObject:newName];
	}
	// Clear the name cache.
	[attributeNames release]; attributeNames = nil;
	
	attributesNeedSorting = YES;
}

- (void)_relationshipDidChangeName:(NSNotification *)notification
{
	EORelationship	*relationship = [notification object];
	NSString			*oldName = [[notification userInfo] objectForKey:@"oldName"];
	NSString			*newName = [[notification userInfo] objectForKey:@"newName"];
	
	if (oldName) [relationshipIndex removeObjectForKey:oldName];
	if (newName) [relationshipIndex setObject:relationship forKey:newName];
	
	// mont_rothstein @ yahoo.com 2005-04-17
	// The was checking for the index != nil, it needs to be NSNotFound.
	if ([[self classProperties] indexOfObjectIdenticalTo:relationship] != NSNotFound) {
		if (oldName) [classPropertyNames removeObject:oldName];
		if (newName) [classPropertyNames addObject:newName];
	}

	relationshipsNeedSorting = YES;
}

@end
