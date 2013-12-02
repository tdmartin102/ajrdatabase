//
//  EODisplayGroup.m
//  EOInterface
//
//  Created by Alex Raftis on 5/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "EODisplayGroup.h"

#import <EOAccess/EOAccess.h>
#import <EOControl/EOControl.h>
#import "EOAssociation.h"

int EODefaultFetchLimit = 0;

@implementation EODisplayGroup

+ (void)initialize
{
	[EODisplayGroup setVersion:3];
}

////////////////////////
// Creating instances //
////////////////////////

- (id)init
{
	if ((self = [super init]))
    {
        fetchLimit = EODefaultFetchLimit;
        localKeys = [[NSMutableArray allocWithZone:[self zone]] init];
        insertedObjectDefaultValues = [[NSDictionary allocWithZone:[self zone]] init];
	}
	return self;
}

- (void)dealloc
{
	[qualifier release];
	[localKeys release];
	[dataSource release];
	[defaultStringMatchFormat release];
	[defaultStringMatchOperator release];
	[queryBindingValues release];
	[queryOperatorValues release];
	[insertedObjectDefaultValues release];
	
	[super dealloc];
}

//////////////////////////
// Configuring behavior //
//////////////////////////

- (void)setDefaultStringMatchFormat:(NSString *)matchFormat
{
	if (matchFormat != defaultStringMatchFormat) {
		[defaultStringMatchFormat release];
		defaultStringMatchFormat = [matchFormat retain];
	}
}

- (NSString *)defaultStringMatchFormat
{
	return defaultStringMatchFormat;
}

- (void)setDefaultStringMatchOperator:(NSString *)matchOperator
{
	if (defaultStringMatchOperator != matchOperator) {
		[defaultStringMatchOperator release];
		defaultStringMatchOperator = [matchOperator retain];
	}
}

- (NSString *)defaultStringMatchOperator
{
	return defaultStringMatchOperator;
}

- (void)setFetchesOnLoad:(BOOL)flag
{
	fetchesOnLoad = flag;
}

- (BOOL)fetchesOnLoad
{
	return fetchesOnLoad;
}

- (void)setQueryBindingValues:(NSDictionary *)values
{
	[queryBindingValues release];
	queryBindingValues = [[NSDictionary allocWithZone:[self zone]] initWithDictionary:values];
}

- (NSDictionary *)queryBindingValues
{
	return queryBindingValues;
}

- (void)setQueryOperatorValues:(NSDictionary *)values
{
	[queryOperatorValues	release];
	queryOperatorValues = [[NSDictionary allocWithZone:[self zone]] initWithDictionary:values];
}

- (NSDictionary *)queryOperatorValues
{
	return queryOperatorValues;
}

- (void)setSelectsFirstObjectAfterFetch:(BOOL)flag
{
	selectsFirstObjectAfterFetch = flag;
}

- (BOOL)selectsFirstObjectAfterFetch
{
	return selectsFirstObjectAfterFetch;
}

- (void)setUsesOptimisticRefresh:(BOOL)flag
{
	usesOptimisticRefresh = flag;
}

- (BOOL)usesOptimisticRefresh
{
	return usesOptimisticRefresh;
}

- (void)setValidatesChangesImmediately:(BOOL)flag
{
	validatesChangesImmediately = flag;
}

- (BOOL)validatesChangesImmediately
{
	return validatesChangesImmediately;
}

- (int)fetchLimit
{
	return fetchLimit;
}

- (void)setFetchLimit:(int)aFetchLimit
{
	fetchLimit = aFetchLimit;
}

/////////////////////////////
// Setting the data source //
/////////////////////////////

- (void)setDataSource:(EODataSource *)aDataSource
{
	EOFetchSpecification	*fetch;
	
	if ([aDataSource isKindOfClass:[EOEditingContext class]]) {
		[dataSource release];
		dataSource = [[EODatabaseDataSource allocWithZone:[self zone]] initWithEditingContext:(EOEditingContext *)aDataSource 
																											entityName:[self entityName]
																							fetchSpecificationName:nil];
	} else {
		[dataSource release];
		dataSource = [aDataSource retain];
	}
	
	// Make sure this is setup correctly
	fetch = [(EODatabaseDataSource *)dataSource fetchSpecification];
	if ([fetch entityName] == nil) {
		[fetch setEntityName:[self entityName]];
		if (fetchLimit > 0) [fetch setFetchLimit:fetchLimit];
	}
}

- (EODataSource *)dataSource;
{
	return dataSource;
}

/////////////////////////////////////////////
// Setting the qualifier and sort ordering //
/////////////////////////////////////////////

- (void)setQualifier:(EOQualifier *)aQualifier
{
	if (qualifier != aQualifier) {
		[qualifier release];
		qualifier = [aQualifier retain];
		[[(EODatabaseDataSource *)[self dataSource] fetchSpecification] setQualifier:qualifier];
	}
}

- (EOQualifier *)qualifier
{
	return qualifier;
}

- (void)setSortOrderings:(NSArray *)orderings
{
	// A bit inefficient, but we need to translate these from EOSortOrderings to
	// NSSortDescriptors.
	int				x, max;
	NSMutableArray	*temp;
	
	temp = [[NSMutableArray allocWithZone:[self zone]] init];
	for (x = 0, max = [orderings count]; x < max; x++) {
		[temp addObject:[[orderings objectAtIndex:x] sortDescriptor]];
	}	
	[super setSortDescriptors:temp];
	[temp release];
}

- (NSArray *)sortOrderings
{
	NSArray			*sortDescriptors = [super sortDescriptors];
	int				x, max;
	NSMutableArray	*temp = [[NSMutableArray allocWithZone:[self zone]] init];
	
	for (x = 0, max = [sortDescriptors count]; x < max; x++) {
		NSSortDescriptor		*descriptor = [sortDescriptors objectAtIndex:x];
		EOSortOrdering			*sortOrdering = [[EOSortOrdering allocWithZone:[self zone]] initWithSortDescriptor:descriptor];
		[temp addObject:sortOrdering];
		[sortOrdering release];
	}
	
	return [temp autorelease];
}

//////////////////////
// Managing queries //
//////////////////////

- (EOQualifier *)qualifierFromQueryValues
{
	return nil;
}

- (void)setEqualToQueryValues:(NSDictionary *)values
{
}

- (NSDictionary *)equalToQueryValues
{
	return nil;
}

- (void)setGreaterThanQueryValues:(NSDictionary *)values
{
}

- (NSDictionary *)greaterThanQueryValues
{
	return nil;
}

- (void)setLessThanQueryValues:(NSDictionary *)values
{
}

- (NSDictionary *)lessThanQueryValues
{
	return nil;
}

- (void)qualifyDisplayGroup
{
}

- (void)qualifyDisplayGroup:(id)sender
{
}

- (void)qualifyDataSource
{
}

- (void)qualifyDataSource:(id)sender
{
}

- (void)enterQueryMode:(id)sender
{
}

- (BOOL)inQueryMode
{
	return NO;
}

- (void)setInQueryMode:(BOOL)flag
{
}

- (BOOL)enabledToSetSelectedObjectValueForKey:(NSString *)key
{
	return NO;
}

///////////////////////////////////////////
// Fetching objects from the data source //
///////////////////////////////////////////

- (void)fetch
{
	[self prepareContent];
}

- (void)fetch:(id)sender
{
	[self fetch];
}

/////////////////////////
// Getting the objects //
/////////////////////////

- (NSArray *)allObjects
{
	return [self content];
}

- (NSArray *)displayedObjects
{
	return [self arrangedObjects];
}

////////////////////////////////
// Updating display of values //
////////////////////////////////

- (void)redisplay
{
	[self rearrangeObjects];
}

- (void)updateDisplayedObjects
{
	[self rearrangeObjects];
}

/////////////////////////
// Setting the objects //
/////////////////////////

- (void)setObjectArray:(NSArray *)objects
{
	[self setContent:objects];
}

////////////////////////////
// Changing the selection //
////////////////////////////

- (BOOL)setSelectionIndexes:(NSIndexSet *)someIndexes;
{
   if ([someIndexes isKindOfClass:[NSArray class]]) {
      NSMutableIndexSet		*indexes = [[NSMutableIndexSet allocWithZone:[self zone]] init];
      int						x, max;
      BOOL						result;
      
      [EOLog log:EOLogWarning withFormat:@"You called -[EODisplayGroup setSelectionIndexes:] with an NSArray, not an NSIndexSet. We've mapped this to the correct type for you, but you should update your code to pass in an NSIndexSet."];
      
      for (x = 0, max = [someIndexes count]; x < max; x++) {
         [indexes addIndex:[[(NSArray *)someIndexes objectAtIndex:x] intValue]];
      }
      
      result = [super setSelectionIndexes:indexes];
      [indexes release];
      
      return result;
   }
   
   return [super setSelectionIndexes:someIndexes];
}

- (BOOL)selectObjectsIdenticalTo:(NSArray *)someObjects
{
	return [super setSelectedObjects:someObjects];
}

- (BOOL)selectObjectsIdenticalTo:(NSArray *)someObjects selectFirstOnNoMatch:(BOOL)flag
{
	return [super setSelectedObjects:someObjects];
}

- (BOOL)selectObject:(id)anObject
{
	return [super setSelectedObjects:[NSArray arrayWithObject:anObject]];
}

- (BOOL)clearSelection
{
	return [super setSelectedObjects:[NSArray array]];
}

- (BOOL)selectNext
{
	if ([self canSelectNext]) {
		[super selectNext:self];
		return YES;
	}
	return NO;
}

- (void)selectNext:(id)sender
{
	[self selectNext:sender];
}

- (BOOL)selectPrevious
{
	if ([self canSelectPrevious]) {
		[super selectPrevious:self];
		return YES;
	}
	return NO;
}

- (void)selectPrevious:(id)sender
{
	[super selectPrevious:sender];
}

/////////////////////////////
// Examining the selection //
/////////////////////////////

- (id)selectionIndexes
{
	[EOLog log:EOLogWarning withFormat:@"You're calling -[EODisplayGroup selectionIndexes], but you may not be getting back the information you expect. This method now returns an NSIndexSet rather than an array of index values."];
	return [super selectionIndexes];
}

- (id)selectedObject
{
	NSArray		*selected = [super selectedObjects];
	if ([selected count] >= 1) {
		return [selected objectAtIndex:0];
	}
	return nil;
}

- (NSArray *)selectedObjects
{
	return [super selectedObjects];
}

////////////////////////////////////
// Inserting and deleting objects //
////////////////////////////////////

- (void)removeObject:(id)anObject
{
	if ([[self delegate] respondsToSelector:@selector(displayGroup:shouldDeleteObject:)]) {
		if (![[self delegate] displayGroup:self shouldDeleteObject:anObject]) {
			return;
		}
	}
	
	[[self dataSource] deleteObject:anObject];
	
	if ([[self delegate] respondsToSelector:@selector(displayGroup:didDeleteObject:)]) {
		[[self delegate] displayGroup:self didDeleteObject:anObject];
	}
}

- (void)delete:(id)sender
{
	[self remove:sender];
}

- (BOOL)deleteObjectAtIndex:(unsigned int)index
{
	[self removeObjectAtArrangedObjectIndex:index];
	return YES;
}

- (BOOL)deleteSelection
{
	return [self removeSelectedObjects:[self selectedObjects]];
}

- (void)insert:(id)sender
{
	[self insertObjectAtIndex:[self selectionIndex]];
}

- (id)insertObjectAtIndex:(unsigned int)anIndex
{
	id		newObject = [[self dataSource] createObject];
	
	if ([[self delegate] respondsToSelector:@selector(displayGroup:shouldInsertObject:atIndex:)]) {
		if (![[self delegate] displayGroup:self shouldInsertObject:newObject atIndex:anIndex]) {
			return nil;
		}
	}

	[[self dataSource] insertObject:newObject];
	if (insertedObjectDefaultValues != nil) {
		[newObject takeValuesFromDictionary:insertedObjectDefaultValues];
	}
	
	[super insertObject:newObject atArrangedObjectIndex:anIndex];
	
	if ([[self delegate] respondsToSelector:@selector(displayGroup:didInsertObject:)]) {
		[[self delegate] displayGroup:self didInsertObject:newObject];
	}
	
	return newObject;
}

- (void)insertObject:(id)anObject atIndex:(unsigned int)index
{
	[super insertObject:anObject atArrangedObjectIndex:index];
}

- (void)setInsertedObjectDefaultValues:(NSDictionary *)defaultValues
{
	[insertedObjectDefaultValues release];
	insertedObjectDefaultValues = [[NSDictionary allocWithZone:[self zone]] initWithDictionary:defaultValues];
}

- (NSDictionary *)insertedObjectDefaultValues
{
	return insertedObjectDefaultValues;
}

/////////////////
// Adding keys //
/////////////////

- (void)setLocalKeys:(NSArray *)keys
{
	[localKeys removeAllObjects];
	[localKeys addObjectsFromArray:keys];
}

- (NSArray *)localKeys
{
   if (localKeys == nil) {
      localKeys = [[NSMutableArray alloc] init];
   }
	return localKeys;
}

//////////////////////////////
//	Getting the associations //
//////////////////////////////

- (NSArray *)observingAssociations
{
	[EOLog log:EOLogWarning withFormat:@"-[EODisplayGroup observingAssociations] has no meaning under Mac OS X 10.4"];
	return nil;
}

//////////////////////////
// Setting the delegate //
//////////////////////////

- (void)setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

- (id)delegate
{
	return delegate;
}

///////////////////////////////////////
// Changing values from associations //
///////////////////////////////////////

- (BOOL)setSelectedObjectValue:(id)value forKey:(NSString *)key
{
	NSArray	*objects = [self selectedObjects];
	int		x, max;
	
	for (x = 0, max = [objects count]; x < max; x++) {
		id			object = [objects objectAtIndex:x];
		[self setValue:value forObject:object key:key];
	}
	
	return YES;
}

- (id)selectedObjectValueForKey:(NSString *)key
{
	NSArray	*objects = [self selectedObjects];
	
	if ([objects count] == 1) {
		return [self valueForObject:[objects objectAtIndex:0] key:key];
	}
	
	return nil;
}

- (BOOL)setValue:(id)value forObject:(id)anObject key:(NSString *)key
{
	[anObject takeValue:value forKey:key];
	return YES;
}

- (id)valueForObject:(id)anObject key:(NSString *)key
{
	return [anObject valueForKey:key];
}

- (BOOL)setValue:(id)value forObjectAtIndex:(unsigned int)index key:(NSString *)key
{
	return [self setValue:value forObject:[[self arrangedObjects] objectAtIndex:index] key:key];
}

- (id)valueForObjectAtIndex:(unsigned int)index key:(NSString *)key
{
	return [self valueForObject:[[self arrangedObjects] objectAtIndex:index] key:key];
}

/////////////////////////////
// Editing by associations //
/////////////////////////////

- (void)associationDidBeginEditing:(EOAssociation *)anAssociation
{
	[EOLog log:EOLogWarning withFormat:@"-[%C %S] has no meaning under Mac OS X 10.4", self, _cmd];
}

- (BOOL)association:(EOAssociation *)anAssociation failedToValidateValue:(NSString *)value forKey:(NSString *)key object:(id)anObject errorDescription:(NSString *)errorDescription;
{
	[EOLog log:EOLogWarning withFormat:@"-[%C %S] has no meaning under Mac OS X 10.4", self, _cmd];
	return NO;
}

- (void)associationDidEndEditing:(EOAssociation *)anAssociation
{
	[EOLog log:EOLogWarning withFormat:@"-[%C %S] has no meaning under Mac OS X 10.4", self, _cmd];
}

- (EOAssociation *)editingAssociation
{
	return (EOAssociation *)_editor;
}

- (BOOL)endEditing
{
	return [self commitEditing];
}

///////////////////////////////////////
// Querying changes for associations //
///////////////////////////////////////

- (BOOL)contentsChanged
{
	[EOLog log:EOLogWarning withFormat:@"-[%C %S] has no meaning under Mac OS X 10.4", self, _cmd];
	return NO;
}

- (BOOL)selectionChanged
{
	[EOLog log:EOLogWarning withFormat:@"-[%C %S] has no meaning under Mac OS X 10.4", self, _cmd];
	return NO;
}

- (int)updatedObjectIndex
{
	[EOLog log:EOLogWarning withFormat:@"-[%C %S] has no meaning under Mac OS X 10.4", self, _cmd];
	return -1;
}

///////////////////////////////////////////
// Interacting with the EOEditingContext //
///////////////////////////////////////////

- (BOOL)editorHasChangesForEditingContext:(EOEditingContext *)anEditingContext
{
	[EOLog log:EOLogWarning withFormat:@"-[%C %S] has no meaning under Mac OS X 10.4", self, _cmd];
	return NO;
}

- (void)editingContextWillSaveChanges:(EOEditingContext *)anEditingContext
{
	[EOLog log:EOLogWarning withFormat:@"-[%C %S] has no meaning under Mac OS X 10.4", self, _cmd];
}

- (void)editingContext:(EOEditingContext *)anEditingContext presentErrorMessage:(NSString *)errorMessage
{
	[EOLog log:EOLogWarning withFormat:@"-[%C %S] has no meaning under Mac OS X 10.4", self, _cmd];
}

































/////////////////////////////////////////////////////////////
// Methods for mapping NSArrayController to EODisplayGroup //
/////////////////////////////////////////////////////////////
- (BOOL)canAdd
{
	return YES;
}

- (BOOL)canRemove
{
	return YES;
}

- (void)objectDidBeginEditing:(id)anEditor
{
	[super objectDidBeginEditing:anEditor];
	_editor = anEditor;
}

- (void)objectDidEndEditing:(id)anEditor
{
	_editor = nil;
	[super objectDidEndEditing:anEditor];
}

- (void)setEntityName:(NSString *)aName
{
	[super setEntityName:aName];
	[[(EODatabaseDataSource *)[self dataSource] fetchSpecification] setEntityName:aName];
}

- (void)setEditingContext:(EOEditingContext *)anEditingContext
{
	[self setDataSource:(EODataSource *)anEditingContext];
}

- (void)prepareContent
{
	EODataSource	*localDataSource = [self dataSource];

	if (delegate != nil && 
		 [delegate respondsToSelector:@selector(displayGroupShouldFetch:)] && 
		 ![delegate displayGroupShouldFetch:self]) {
		// Delegate told us no to fetch
		return;
	}
	
	if (localDataSource == nil) {
		[EOLog logDebugWithFormat:@"EODisplayGroup: %@", [self entityName]];
		[super prepareContent];
	} else {
		NSArray			*objects;
		
		[EOLog logDebugWithFormat:@"EODisplayGroup: dataSource: %@ (%@)", localDataSource, [self entityName]];
		objects = [localDataSource fetchObjects];
		[EOLog logDebugWithFormat:@"EODisplayGroup: fetched %d object%@", [objects count], [objects count] == 1 ? @"" : @"s"];
		if ([objects count] > 0) {
			[EOLog logDebugWithFormat:@"EODisplayGroup: first object: %@", [[objects objectAtIndex:0] eoDescription]];
		}
		[self setContent:objects];
	}
	
	if (delegate != nil &&
		 [delegate respondsToSelector:@selector(displayGroup:didFetchObjects:)]) {
		[delegate displayGroup:self didFetchObjects:[self arrangedObjects]];
	}
}

///////////////////////////////////////
// Methods used by Interface Builder //
///////////////////////////////////////

- (NSString *)inspectorClassName
{
   return @"EODisplayGroupInspector";
}

- (id)initWithCoder:(NSCoder *)coder
{
    int      version = [coder versionForClassName:NSStringFromClass([self class])];
		
	if ((self = [super initWithCoder:coder]))
    {
        if ([coder allowsKeyedCoding]) {
            qualifier = [[coder decodeObjectForKey:@"qualifier"] retain];
            fetchLimit = [coder decodeIntForKey:@"fetchLimit"];
            localKeys = [[coder decodeObjectForKey:@"localKeys"] retain];
            dataSource = [[coder decodeObjectForKey:@"dataSource"] retain];
            if (version >= 2) {
                // Remember, delegates aren't retained.
                delegate = [coder decodeObjectForKey:@"delegate"];
            }
            if (version >= 3) {
                defaultStringMatchFormat = [[coder decodeObjectForKey:@"defaultStringMatchFormat"] retain];
                defaultStringMatchOperator = [[coder decodeObjectForKey:@"defaultStringMatchOperator"] retain];
                queryBindingValues = [[coder decodeObjectForKey:@"queryBindingValues"] retain];
                queryOperatorValues = [[coder decodeObjectForKey:@"queryOperatorValues"] retain];
                insertedObjectDefaultValues = [[coder decodeObjectForKey:@"insertedObjectDefaultValues"] retain];
                fetchesOnLoad = [coder decodeBoolForKey:@"fetchesOnLoad"];
                selectsFirstObjectAfterFetch = [coder decodeBoolForKey:@"selectsFirstObjectAfterFetch"];
                usesOptimisticRefresh = [coder decodeBoolForKey:@"usesOptimisticRefresh"];
                validatesChangesImmediately = [coder decodeBoolForKey:@"validatesChangesImmediately"];
            }
        } else {
            qualifier = [[coder decodeObject] retain];
            [coder decodeValueOfObjCType:@encode(int) at:&fetchLimit];
            localKeys = [[coder decodeObject] retain];
            dataSource = [[coder decodeObject] retain];
            if (version >= 2) {
                // Remember, delegates aren't retained.
                delegate = [coder decodeObject];
            }
            if (version >= 3) {
                BOOL tempBool;
                
                defaultStringMatchFormat = [[coder decodeObject] retain];
                defaultStringMatchOperator = [[coder decodeObject] retain];
                queryBindingValues = [[coder decodeObject] retain];
                queryOperatorValues = [[coder decodeObject] retain];
                insertedObjectDefaultValues = [[coder decodeObject] retain];
                [coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; fetchesOnLoad = tempBool;
                [coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; selectsFirstObjectAfterFetch = tempBool;
                [coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; usesOptimisticRefresh = tempBool;
                [coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool]; validatesChangesImmediately = tempBool;
            }
        }
    }
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	
	if ([coder allowsKeyedCoding]) {
		[coder encodeObject:qualifier forKey:@"qualifier"];
		[coder encodeInt:fetchLimit forKey:@"fetchLimit"];
		[coder encodeObject:localKeys forKey:@"localKeys"];
		[coder encodeObject:dataSource forKey:@"dataSource"];
		[coder encodeObject:delegate forKey:@"delegate"];
		[coder encodeObject:defaultStringMatchFormat forKey:@"defaultStringMatchFormat"];
		[coder encodeObject:defaultStringMatchOperator forKey:@"defaultStringMatchOperator"];
		[coder encodeObject:queryBindingValues forKey:@"queryBindingValues"];
		[coder encodeObject:queryOperatorValues forKey:@"queryOperatorValues"];
		[coder encodeObject:insertedObjectDefaultValues forKey:@"insertedObjectDefaultValues"];
		[coder encodeBool:fetchesOnLoad forKey:@"fetchesOnLoad"];
		[coder encodeBool:selectsFirstObjectAfterFetch forKey:@"selectsFirstObjectAfterFetch"];
		[coder encodeBool:usesOptimisticRefresh forKey:@"usesOptimisticRefresh"];
		[coder encodeBool:validatesChangesImmediately forKey:@"validatesChangesImmediately"];
	} else {
		BOOL tempBool;
		
		[coder encodeObject:qualifier];
		[coder encodeValueOfObjCType:@encode(int) at:&fetchLimit];
		[coder encodeObject:localKeys];
		[coder encodeObject:dataSource];
		[coder encodeObject:delegate];
		[coder encodeObject:defaultStringMatchFormat];
		[coder encodeObject:defaultStringMatchOperator];
		[coder encodeObject:queryBindingValues];
		[coder encodeObject:queryOperatorValues];
		[coder encodeObject:insertedObjectDefaultValues];
		tempBool = fetchesOnLoad; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = selectsFirstObjectAfterFetch; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = usesOptimisticRefresh; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = validatesChangesImmediately; [coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
	}
}

@end
