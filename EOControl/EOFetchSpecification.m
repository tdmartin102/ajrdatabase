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

#import "EOFetchSpecification.h"

#import "EOQualifier.h"
#import "NSClassDescription-EO.h"

@implementation EOFetchSpecification

+ (id)fetchSpecificationWithEntityName:(NSString *)anEntityName qualifier:(EOQualifier *)aQualifier sortOrderings:(NSArray *)someSortOrderings
{
   return [[[self alloc] initWithEntityName:anEntityName qualifier:aQualifier sortOrderings:someSortOrderings usesDistinct:NO isDeep:NO hints:nil] autorelease];
}

+ (EOFetchSpecification *)fetchSpecificationNamed:(NSString *)name entityNamed:(NSString *)aName
{
    return [[NSClassDescription classDescriptionForEntityName:aName] fetchSpecificationNamed:name];
}

// jean_alexis @ users.sourceforge.net 2005-09-08
// Added method implemtation
- (EOFetchSpecification *)fetchSpecificationWithQualifierBindings:(NSDictionary *)bindings
{
	EOQualifier *newQualifier = [[self qualifier] qualifierWithBindings: bindings requiresAllVariables: NO];
	
	return [[[[self class] alloc] initWithEntityName: [self entityName] qualifier: newQualifier sortOrderings: [self sortOrderings] usesDistinct: [self usesDistinct] isDeep: [self isDeep] hints: [self hints]] autorelease];
}

- (id)initWithEntityName:(NSString *)anEntityName qualifier:(EOQualifier *)aQualifier sortOrderings:(NSArray *)someSortOrderings usesDistinct:(BOOL)distinctFlag isDeep:(BOOL)isDeepFlag hints:(NSDictionary *)someHints
{
   if (self = [super init])
   {
       entityName = [anEntityName retain];
       qualifier = [aQualifier retain];
       sortOrderings = [someSortOrderings retain];
       hints = [someHints retain];
       isDeep = isDeepFlag;
       usesDistinct = distinctFlag;
       userInfo = [[NSMutableDictionary alloc] init];
   }

   return self;
}

- (void)dealloc
{
   [entityName release];
   [rootEntityName release];
   [qualifier release];
   [sortOrderings release];
	[hints release];
	[userInfo release];
	
   [super dealloc];
}

- (void)setQualifier:(EOQualifier *)aQualifier
{
   if (qualifier != aQualifier) {
      [qualifier release];
      qualifier = [aQualifier retain];
   }
}

- (EOQualifier *)qualifier
{
   return qualifier;
}

- (void)setIsDeep:(BOOL)flag
{
	isDeep = flag;
}

- (BOOL)isDeep
{
	return isDeep;
}

- (void)setEntityName:(NSString *)aName
{
	if (aName != entityName) {
		[entityName release];
		entityName = [aName retain];
	}
}

- (NSString *)entityName
{
   return entityName;
}

- (void)setSortOrderings:(NSArray *)someSortOrderings
{
   if (sortOrderings != someSortOrderings) {
      [sortOrderings release];
      sortOrderings = [someSortOrderings copyWithZone:[self zone]];
   }
}

- (NSArray *)sortOrderings
{
   return sortOrderings;
}

- (void)_setRootEntityName:(NSString *)aRootEntityName
{
   if (rootEntityName != aRootEntityName) {
      [rootEntityName release];
      rootEntityName = [aRootEntityName retain];
   }
}

- (NSString *)_rootEntityName
{
   if (rootEntityName == nil) return entityName;
   return rootEntityName;
}

- (void)setUsesDistinct:(BOOL)flag
{
   usesDistinct = flag;
}

- (BOOL)usesDistinct
{
   return usesDistinct;
}

- (void)setFetchLimit:(int)aLimit
{
	fetchLimit = aLimit;
}

- (int)fetchLimit
{
	return fetchLimit;
}

- (void)setFetchesRawRows:(BOOL)flag
{
	fetchesRawRows = flag;
}

- (BOOL)fetchesRawRows
{
	return fetchesRawRows;
}

- (void)setPrefetchingRelationshipKeyPaths:(NSArray *)somePaths
{
	if (prefetchingRelationshipKeyPaths != somePaths) {
		[prefetchingRelationshipKeyPaths release];
		prefetchingRelationshipKeyPaths = [somePaths retain];
	}
}

- (NSArray *)prefetchingRelationshipKeyPaths
{
	return prefetchingRelationshipKeyPaths;
}

- (void)setPromptsAfterFetchLimit:(BOOL)flag
{
	promptsAfterFetchLimit = flag;
}

- (BOOL)promptsAfterFetchLimit
{
	return promptsAfterFetchLimit;
}

- (void)setRawRowKeyPaths:(NSArray *)somePaths
{
	if (rawRowKeyPaths != somePaths) {
		[rawRowKeyPaths release];
		rawRowKeyPaths = [somePaths retain];
	}
}

- (NSArray *)rawRowKeyPaths
{
	return rawRowKeyPaths;
}

- (void)setRequiresAllQualifierBindingVariables:(BOOL)flag
{
	requiresAllQualifierBindingVariables = flag; 
}

- (BOOL)requiresAllQualifierBindingVariables
{
	return requiresAllQualifierBindingVariables;
}

- (void)setHints:(NSDictionary *)someHints
{
	if (hints != someHints) {
		[hints release];
		hints = [someHints retain];
	}
}

- (NSDictionary *)hints
{
	return hints;
}

- (void)setRefreshesObjects:(BOOL)flag
{
   refreshObjects = flag;
}
- (void)setRefreshesRefetchedObjects:(BOOL)flag { refreshObjects = YES; }

- (BOOL)refreshesObjects
{
   return refreshObjects;
}
- (BOOL)refreshesRefetchedObjects { return refreshObjects; }

- (void)setLocksObjects:(BOOL)flag
{
	locksObjects = flag;
}

- (BOOL)locksObjects
{
	return locksObjects;
}

- (id)copy
{
	return [self copyWithZone:[self zone]];
}

- (id)copyWithZone:(NSZone *)zone
{
	EOFetchSpecification		*newFetch = [EOFetchSpecification allocWithZone:zone];
	
   newFetch->entityName = [entityName retain];
   newFetch->rootEntityName = [rootEntityName retain];
   newFetch->qualifier = [qualifier retain];
   newFetch->sortOrderings = [[NSArray allocWithZone:zone] initWithArray:sortOrderings];
	newFetch->hints = [[NSDictionary allocWithZone:zone] initWithDictionary:hints];
	newFetch->fetchLimit = fetchLimit;
	newFetch->prefetchingRelationshipKeyPaths = [[NSArray allocWithZone:zone] initWithArray:prefetchingRelationshipKeyPaths];
	newFetch->rawRowKeyPaths = [[NSArray allocWithZone:zone] initWithArray:rawRowKeyPaths];
	newFetch->userInfo = [[NSMutableDictionary allocWithZone:zone] initWithDictionary:userInfo];
   newFetch->usesDistinct = usesDistinct;
   newFetch->refreshObjects = refreshObjects;
	newFetch->locksObjects = locksObjects;
	newFetch->isDeep = isDeep;
	newFetch->fetchesRawRows = fetchesRawRows;
	newFetch->requiresAllQualifierBindingVariables = requiresAllQualifierBindingVariables;
	newFetch->promptsAfterFetchLimit = promptsAfterFetchLimit;
	
	return newFetch;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [self init];
    if (! self)
        return nil;
	
	if ([coder allowsKeyedCoding]) {
		entityName = [[coder decodeObjectForKey:@"entityName"] retain];
		rootEntityName = [[coder decodeObjectForKey:@"rootEntityName"] retain];
		qualifier = [[coder decodeObjectForKey:@"qualifier"] retain];
		sortOrderings = [[coder decodeObjectForKey:@"sortOrderings"] retain];
		hints = [[coder decodeObjectForKey:@"hints"] retain];
		prefetchingRelationshipKeyPaths = [[coder decodeObjectForKey:@"prefetchingRelationshipKeyPaths"] retain];
		rawRowKeyPaths = [[coder decodeObjectForKey:@"rawRowKeyPaths"] retain];
		userInfo = [[coder decodeObjectForKey:@"userInfo"] retain];
		fetchLimit = [coder decodeIntForKey:@"fetchLimit"];
		usesDistinct = [coder decodeBoolForKey:@"usesDistinct"];
		refreshObjects = [coder decodeBoolForKey:@"refreshObjects"];
		locksObjects = [coder decodeBoolForKey:@"locksObjects"];
		isDeep = [coder decodeBoolForKey:@"isDeep"];
		fetchesRawRows = [coder decodeBoolForKey:@"fetchesRawRows"];
		requiresAllQualifierBindingVariables = [coder decodeBoolForKey:@"requiresAllQualifierBindingVariables"];
		promptsAfterFetchLimit = [coder decodeBoolForKey:@"promptsAfterFetchLimit"];
	} else {
		BOOL tempBool;
		
		entityName = [[coder decodeObject] retain];
		rootEntityName = [[coder decodeObject] retain];
		qualifier = [[coder decodeObject] retain];
		sortOrderings = [[coder decodeObject] retain];
		hints = [[coder decodeObject] retain];
		prefetchingRelationshipKeyPaths = [[coder decodeObject] retain];
		rawRowKeyPaths = [[coder decodeObject] retain];
		userInfo = [[coder decodeObject] retain];
		[coder decodeValueOfObjCType:@encode(int) at:&fetchLimit];
		[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; usesDistinct = tempBool;
		[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; refreshObjects = tempBool;
		[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; locksObjects = tempBool;
		[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; isDeep = tempBool;
		[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; fetchesRawRows = tempBool;
		[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; requiresAllQualifierBindingVariables = tempBool;
		[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; promptsAfterFetchLimit = tempBool;
	}
	
	return self;	
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if ([coder allowsKeyedCoding]) {
		[coder encodeObject:entityName forKey:@"entityName"];
		[coder encodeObject:rootEntityName forKey:@"rootEntityName"];
		[coder encodeObject:qualifier forKey:@"qualifier"];
		[coder encodeObject:sortOrderings forKey:@"sortOrderings"];
		[coder encodeObject:hints forKey:@"hints"];
		[coder encodeObject:prefetchingRelationshipKeyPaths forKey:@"prefetchingRelationshipKeyPaths"];
		[coder encodeObject:rawRowKeyPaths forKey:@"rawRowKeyPaths"];
		[coder encodeObject:userInfo forKey:@"userInfo"];
		[coder encodeInt:fetchLimit forKey:@"fetchLimit"];
		[coder encodeBool:usesDistinct forKey:@"usesDistinct"];
		[coder encodeBool:refreshObjects forKey:@"refreshObjects"];
		[coder encodeBool:locksObjects forKey:@"locksObjects"];
		[coder encodeBool:isDeep forKey:@"isDeep"];
		[coder encodeBool:fetchesRawRows forKey:@"fetchesRawRows"];
		[coder encodeBool:requiresAllQualifierBindingVariables forKey:@"requiresAllQualifierBindingVariables"];
		[coder encodeBool:promptsAfterFetchLimit forKey:@"promptsAfterFetchLimit"];
	} else {
		BOOL tempBool;
		
		[coder encodeObject:entityName];
		[coder encodeObject:rootEntityName];
		[coder encodeObject:qualifier];
		[coder encodeObject:sortOrderings];
		[coder encodeObject:hints];
		[coder encodeObject:prefetchingRelationshipKeyPaths];
		[coder encodeObject:rawRowKeyPaths];
		[coder encodeObject:userInfo];
		[coder encodeValueOfObjCType:@encode(int) at:&fetchLimit];
		tempBool = usesDistinct; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = refreshObjects; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = locksObjects; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = isDeep; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = fetchesRawRows; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = requiresAllQualifierBindingVariables; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = promptsAfterFetchLimit; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
	}
}

- (void)setUserInfo:(NSDictionary *)someInfo
{
/*	[self willChange];
	if ([[[self parent] model] undoManager]) {
		[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setUserInfo:userInfo];
	}*/
	[userInfo release];
	userInfo = [someInfo mutableCopyWithZone:[self zone]];
}

- (NSDictionary *)userInfo
{
	return userInfo;
}

#pragma mark <EOKeyValueArchiving>

- (id)initWithKeyValueUnarchiver:(EOKeyValueUnarchiver *)unarchiver
{
    if((self = [super init]) != nil){
        entityName = [[unarchiver decodeObjectForKey:@"entityName"] copy];
        qualifier  = [[unarchiver decodeObjectForKey:@"qualifier"]  retain];
        hints  = [[unarchiver decodeObjectForKey:@"hints"] copy];
        sortOrderings = [[unarchiver decodeObjectForKey:@"sortOrderings"] retain];
        
        fetchLimit = [unarchiver decodeIntForKey:@"fetchLimit"];
        
        usesDistinct = [unarchiver decodeBoolForKey:@"usesDistinct"];
        locksObjects = [unarchiver decodeBoolForKey:@"locksObjects"];
        isDeep = [unarchiver decodeBoolForKey:@"isDeep"];
#warning FIXME: Misses prefetchingRelationshipKeyPaths, rawRowKeyPaths, userInfo, refreshObjects, fetchesRawRows, requiresAllQualifierBindingVariables, promptsAfterFetchLimit
    }
    return self;
}

- (void)encodeWithKeyValueArchiver:(EOKeyValueArchiver *)archiver
{
    [archiver encodeObject:[self entityName] forKey:@"entityName"];
    [archiver encodeObject:[self qualifier] forKey:@"qualifier"];
    [archiver encodeObject:[self hints] forKey:@"hints"];
    [archiver encodeObject:[self sortOrderings] forKey:@"sortOrderings"];
    
    [archiver encodeInt:[self fetchLimit] forKey:@"fetchLimit"];
    
    [archiver encodeBool:[self usesDistinct] forKey:@"usesDistinct"];
    [archiver encodeBool:[self locksObjects] forKey:@"locksObjects"];
    [archiver encodeBool:[self isDeep] forKey:@"isDeep"];
#warning FIXME: Misses prefetchingRelationshipKeyPaths, rawRowKeyPaths, userInfo, refreshObjects, fetchesRawRows, requiresAllQualifierBindingVariables, promptsAfterFetchLimit
}

@end
