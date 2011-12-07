//
//  EODatabaseDataSource.m
//  EOAccess
//
//  Created by Alex Raftis on 6/27/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "EODatabaseDataSource.h"

#import "EODatabaseContext.h"
#import "EOEditingContext-EOAccess.h"
#import "EOEntity.h"
#import "EOModelGroup.h"

@implementation EODatabaseDataSource

/*!
 * This is generally a private init method, used when creating a data source
 * in a nib file. You would not normally use it during day to day operations
 * outside of interface builder.
 */
- (id)init
{
	if (self = [super init])
	{
		editingContext = [[EOEditingContext allocWithZone:[self zone]] init];
		fetchSpecification = [[EOFetchSpecification allocWithZone:[self zone]] init];
		fetchEnabled = YES;
	}
	
	return self;
}

- (id)initWithEditingContext:(EOEditingContext *)anEditingContext entityName:(NSString *)anEntityName
{
	return [self initWithEditingContext:anEditingContext entityName:anEntityName fetchSpecificationName:nil];
}

- (id)initWithEditingContext:(EOEditingContext *)anEditingContext entityName:(NSString *)anEntityName fetchSpecificationName:(NSString *)aFetchSpecificationName
{
	if ((self = [super init]) == nil)
		return nil;
		
	editingContext = [anEditingContext retain];
	if (editingContext == nil) {
		editingContext = [[EOEditingContext allocWithZone:[self zone]] init];
	}
	fetchSpecification = [[EOFetchSpecification allocWithZone:[self zone]] init];
	[fetchSpecification setEntityName:anEntityName];
	fetchSpecificationName = [aFetchSpecificationName retain];
	fetchEnabled = YES;
	
	if (editingContext != nil) {
		if ([self entity] == nil) {
			[NSException raise:NSInternalInconsistencyException format:@"Unable to find a model containing entity '%@'. Unable to create EODatabaseDataSource.", [fetchSpecification entityName]];
		}
		if (aFetchSpecificationName != nil) {
			[self setFetchSpecificationByName:aFetchSpecificationName];
		}
	}
	
	return self;
}

- (EOFetchSpecification *)fetchSpecification
{
	return fetchSpecification;
}

- (EOFetchSpecification *)fetchSpecificationForFetch
{
	EOQualifier		*leftQualifier = nil;
	EOQualifier		*rightQualifier = nil;
	
	if (fetchSpecification == nil) return nil;
	
	if (auxiliaryQualifier != nil) {
		if (qualifierBindings != nil) {
			leftQualifier = [auxiliaryQualifier qualifierWithBindings:qualifierBindings requiresAllVariables:[fetchSpecification requiresAllQualifierBindingVariables]];
		} else {
			leftQualifier = auxiliaryQualifier;
		}
	}
	
	if ([fetchSpecification qualifier] != nil) {
		if (qualifierBindings != nil) {
			rightQualifier = [[fetchSpecification qualifier] qualifierWithBindings:qualifierBindings requiresAllVariables:[fetchSpecification requiresAllQualifierBindingVariables]];
		} else {
			rightQualifier = [fetchSpecification qualifier];
		}
	}

	if (leftQualifier != nil || rightQualifier != nil) {
		EOQualifier				*newQualifier = nil;
		EOFetchSpecification	*newFetch;
		
		if (leftQualifier == nil && rightQualifier != nil) {
			newQualifier = rightQualifier;
		} else if (leftQualifier != nil && rightQualifier == nil) {
			newQualifier = leftQualifier;
		} else {
			newQualifier = [EOAndQualifier qualifierFor:leftQualifier and:rightQualifier];
		}
		
		newFetch = [fetchSpecification copyWithZone:[self zone]];
		[newFetch setQualifier:newQualifier];
		
		return newFetch;
	}
	
	return fetchSpecification;
}

- (EOQualifier *)auxiliaryQualifier
{
	return auxiliaryQualifier;
}

- (void)setAuxiliaryQualifier:(EOQualifier *)aQualifier
{
	if (auxiliaryQualifier != aQualifier) {
		[auxiliaryQualifier release];
		auxiliaryQualifier = [aQualifier retain];
	}
}

- (void)setFetchSpecification:(EOFetchSpecification *)aFetchSpecification
{
	if (fetchSpecification != aFetchSpecification) {
		[fetchSpecificationName release];
		fetchSpecificationName = nil;
		[fetchSpecification release];
		fetchSpecification = [aFetchSpecification retain];
	}
}

- (void)setFetchSpecificationByName:(NSString *)aName
{
	if (fetchSpecificationName != aName) {
		[fetchSpecificationName release];
		fetchSpecificationName = [aName retain];
		[fetchSpecification release];
		fetchSpecification = [[[self entity] fetchSpecificationNamed:fetchSpecificationName] retain];
		[entity release]; entity = nil;
	}
}

- (NSString *)fetchSpecificationName
{
	return fetchSpecificationName;
}

- (EOEntity *)entity
{
	if (entity == nil) {
		entity = [[editingContext entityNamed:[fetchSpecification entityName]] retain];
	}
	return entity;
}

- (EODatabaseContext *)databaseContext
{
	return [[self editingContext] databaseContextForModelNamed:[[entity model] name]];
}

- (void)setFetchEnabled:(BOOL)flag
{
	fetchEnabled = flag;
}

- (BOOL)isFetchEnabled
{
	return fetchEnabled;
}

- (NSArray *)qualifierBindingKeys
{
	return [[self qualifierBindings] allKeys];
}

- (NSDictionary *)qualifierBindings
{
	return qualifierBindings;
}

- (void)setQualifierBindings:(NSDictionary *)someBindings
{
	if (qualifierBindings != someBindings) {
		[qualifierBindings release];
		qualifierBindings = [someBindings retain];
	}
}

- (EOClassDescription *)classDescriptionForObjects
{
	return (EOClassDescription *)[entity classDescriptionForInstances];
}

- (NSArray *)fetchObjects
{
	if (!fetchEnabled) {
		return [NSArray array];
	}
	
	return [[self editingContext] objectsWithFetchSpecification:[self fetchSpecificationForFetch]];
}

- (void)deleteObject:(id)object
{
	[[self editingContext] deleteObject:object];
}

- (void)insertObject:(id)object
{
	// This is actually inserted, for us, by createObject, so we'll do nothing here.
}

- (EOEditingContext *)editingContext
{
	if (editingContext == nil) {
		// Assume no editing context was provided and create a default one.
		editingContext = [[EOEditingContext allocWithZone:[self zone]] init];
	}
	return editingContext;
}

- (id)initWithCoder:(NSCoder *)coder
{
	[self init];
	
	if ([coder allowsKeyedCoding]) {
		editingContext = [[coder decodeObjectForKey:@"editingContext"] retain];
		fetchSpecificationName = [[coder decodeObjectForKey:@"fetchSpecificationName"] retain];
		fetchSpecification = [[coder decodeObjectForKey:@"fetchSpecification"] retain];
		qualifierBindings = [[coder decodeObjectForKey:@"qualifierBindings"] retain];
		auxiliaryQualifier = [[coder decodeObjectForKey:@"auxiliaryQualifier"] retain];
		fetchEnabled = [coder decodeBoolForKey:@"fetchEnabled"];
	} else {
		BOOL tempBool;
		
		editingContext = [[coder decodeObject] retain];
		fetchSpecificationName = [[coder decodeObject] retain];
		fetchSpecification = [[coder decodeObject] retain];
		qualifierBindings = [[coder decodeObject] retain];
		auxiliaryQualifier = [[coder decodeObject] retain];
		[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; fetchEnabled = tempBool;
	}
	
	return self;	
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if ([coder allowsKeyedCoding]) {
		[coder encodeObject:editingContext forKey:@"editingContext"];
		[coder encodeObject:fetchSpecificationName forKey:@"fetchSpecificationName"];
		[coder encodeObject:fetchSpecification forKey:@"fetchSpecification"];
		[coder encodeObject:qualifierBindings forKey:@"qualifierBindings"];
		[coder encodeObject:auxiliaryQualifier forKey:@"auxiliaryQualifier"];
		[coder encodeBool:fetchEnabled forKey:@"fetchEnabled"];
	} else {
		BOOL tempBool;
		
		[coder encodeObject:editingContext];
		[coder encodeObject:fetchSpecificationName];
		[coder encodeObject:fetchSpecification];
		[coder encodeObject:qualifierBindings];
		[coder encodeObject:auxiliaryQualifier];
		tempBool = fetchEnabled; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
	}
}

#pragma mark <EOKeyValueArchiving>

/*
 dataSource = {
     class = EODatabaseDataSource; 
     editingContext = session.defaultEditingContext; 
     fetchSpecification = {
         class = EOFetchSpecification; 
         entityName = PPURDiscount; 
         fetchLimit = 0; 
         isDeep = YES; 
     }; 
 }; 
 dataSource = {
     class = EODatabaseDataSource; 
     editingContext = editingContext; 
     fetchSpecification = {
         class = EOFetchSpecification; 
         entityName = PPURInfoRequest; 
         fetchLimit = 0; 
         isDeep = YES; 
     }; 
     fetchSpecificationName = infoRequestsByEmail; 
 }; 
 */
- (id)initWithKeyValueUnarchiver:(EOKeyValueUnarchiver *)unarchiver
{
    if((self = [super init]) != nil){
        fetchSpecification = [[unarchiver decodeObjectForKey:@"fetchSpecification"]  retain];
        fetchSpecificationName = [[unarchiver decodeObjectForKey:@"fetchSpecificationName"]  retain];
        editingContext = [unarchiver decodeObjectReferenceForKey:@"editingContext"];
        fetchEnabled = YES;
    }
    return self;
}

- (void)encodeWithKeyValueArchiver:(EOKeyValueArchiver *)archiver
{
    [archiver encodeObject:[self fetchSpecification] forKey:@"fetchSpecification"];
    [archiver encodeObject:[self fetchSpecificationName] forKey:@"fetchSpecificationName"];
    [archiver encodeReferenceToObject:[self editingContext] forKey:@"editingContext"];
}

@end
