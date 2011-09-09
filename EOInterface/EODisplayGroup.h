//
//  EODisplayGroup.h
//  EOInterface
//
//  Created by Alex Raftis on 5/11/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <EOAccess/EOAccess.h>

#define EOAssociation id

#if !defined(STRICT_EOF)
extern int EODefaultFetchLimit;
#endif

@interface EODisplayGroup : NSArrayController <NSCoding>
{
	EOQualifier				*qualifier;
	int						fetchLimit;
	NSMutableArray			*localKeys;
	EODataSource			*dataSource;
	id							delegate;
	NSString					*defaultStringMatchFormat;
	NSString					*defaultStringMatchOperator;
	NSDictionary			*queryBindingValues;
	NSDictionary			*queryOperatorValues;
	NSDictionary			*insertedObjectDefaultValues;
	id							_editor;
	BOOL						fetchesOnLoad:1;
	BOOL						selectsFirstObjectAfterFetch:1;
	BOOL						usesOptimisticRefresh:1;
	BOOL						validatesChangesImmediately:1;
}

// Creating instances
- (id)init;

// Configuring behavior
- (void)setDefaultStringMatchFormat:(NSString *)matchFormat;
- (NSString *)defaultStringMatchFormat;
- (void)setDefaultStringMatchOperator:(NSString *)matchOperator;
- (NSString *)defaultStringMatchOperator;
- (void)setFetchesOnLoad:(BOOL)flag;
- (BOOL)fetchesOnLoad;
- (void)setQueryBindingValues:(NSDictionary *)values;
- (NSDictionary *)queryBindingValues;
- (void)setQueryOperatorValues:(NSDictionary *)values;
- (NSDictionary *)queryOperatorValues;
- (void)setSelectsFirstObjectAfterFetch:(BOOL)flag;
- (BOOL)selectsFirstObjectAfterFetch;
- (void)setUsesOptimisticRefresh:(BOOL)flag;
- (BOOL)usesOptimisticRefresh;
- (void)setValidatesChangesImmediately:(BOOL)flag;
- (BOOL)validatesChangesImmediately;
#if !defined(STRICT_EOF)
- (int)fetchLimit;
- (void)setFetchLimit:(int)aFetchLimit;
#endif

// Setting the data source
- (void)setDataSource:(EODataSource *)anEditingContext;
- (EODataSource *)dataSource;
	
// Setting the qualifier and sort ordering
- (void)setQualifier:(EOQualifier *)aQualifier;
- (EOQualifier *)qualifier;
- (void)setSortOrderings:(NSArray *)orderings;
- (NSArray *)sortOrderings;

// Managing queries
- (EOQualifier *)qualifierFromQueryValues;
- (void)setEqualToQueryValues:(NSDictionary *)values;
- (NSDictionary *)equalToQueryValues;
- (void)setGreaterThanQueryValues:(NSDictionary *)values;
- (NSDictionary *)greaterThanQueryValues;
- (void)setLessThanQueryValues:(NSDictionary *)values;
- (NSDictionary *)lessThanQueryValues;
- (void)qualifyDisplayGroup;
- (void)qualifyDisplayGroup:(id)sender;
- (void)qualifyDataSource;
- (void)qualifyDataSource:(id)sender;
- (void)enterQueryMode:(id)sender;
- (BOOL)inQueryMode;
- (void)setInQueryMode:(BOOL)flag;
- (BOOL)enabledToSetSelectedObjectValueForKey:(NSString *)key;

// Fetching objects from the data source
- (void)fetch;
- (void)fetch:(id)sender;

// Getting the objects
- (NSArray *)allObjects;
- (NSArray *)displayedObjects;

// Updating display of values
- (void)redisplay;
- (void)updateDisplayedObjects;

// Setting the objects
- (void)setObjectArray:(NSArray *)objects;

// Changing the selection
- (BOOL)setSelectionIndexes:(NSIndexSet *)indexes;
- (BOOL)selectObjectsIdenticalTo:(NSArray *)someObjects;
- (BOOL)selectObjectsIdenticalTo:(NSArray *)objects selectFirstOnNoMatch:(BOOL)flag;
- (BOOL)selectObject:(id)anObject;
- (BOOL)clearSelection;
- (BOOL)selectNext;
- (void)selectNext:(id)sender;
- (BOOL)selectPrevious;
- (void)selectPrevious:(id)sender;

// Examining the selection
- (id)selectionIndexes;
- (id)selectedObject;
- (NSArray *)selectedObjects;

// Inserting and deleting objects
- (void)delete:(id)sender;
- (BOOL)deleteObjectAtIndex:(unsigned int)index;
- (BOOL)deleteSelection;
- (void)insert:(id)sender;
- (NSDictionary *)insertedObjectDefaultValues;
- (id)insertObjectAtIndex:(unsigned int)anIndex;
- (void)insertObject:(id)anObject atIndex:(unsigned int)index;
- (void)setInsertedObjectDefaultValues:(NSDictionary *)defaultValues;

// Adding keys
- (void)setLocalKeys:(NSArray *)keys;
- (NSArray *)localKeys;

//	Getting the associations
- (NSArray *)observingAssociations;

// Setting the delegate
- (void)setDelegate:(id)aDelegate;
- (id)delegate;
	
// Changing values from associations
- (BOOL)setSelectedObjectValue:(id)value forKey:(NSString *)key;
- (id)selectedObjectValueForKey:(NSString *)key;
- (BOOL)setValue:(id)value forObject:(id)anObject key:(NSString *)key;
- (id)valueForObject:(id)anObject key:(NSString *)key;
- (BOOL)setValue:(id)value forObjectAtIndex:(unsigned int)index key:(NSString *)key;
- (id)valueForObjectAtIndex:(unsigned int)index key:(NSString *)key;
	
// Editing by associations
- (void)associationDidBeginEditing:(EOAssociation *)anAssociation;
- (BOOL)association:(EOAssociation *)anAssociation failedToValidateValue:(NSString *)value forKey:(NSString *)key object:(id)anObject errorDescription:(NSString *)errorDescription;
- (void)associationDidEndEditing:(EOAssociation *)anAssociation;
- (EOAssociation *)editingAssociation;
- (BOOL)endEditing;

// Querying changes for associations
- (BOOL)contentsChanged;
- (BOOL)selectionChanged;
- (int)updatedObjectIndex;
	
// Interacting with the EOEditingContext
- (BOOL)editorHasChangesForEditingContext:(EOEditingContext *)anEditingContext;
- (void)editingContextWillSaveChanges:(EOEditingContext *)anEditingContext;
- (void)editingContext:(EOEditingContext *)anEditingContext presentErrorMessage:(NSString *)errorMessage;

@end

@interface NSObject (EODisplayGroup)

// Fetching objects
- (BOOL)displayGroupShouldFetch:(EODisplayGroup *)aDisplayGroup;
- (void)displayGroup:(EODisplayGroup *)aDisplayGroup didFetchObjects:(NSArray *)someObjects;
- (BOOL)displayGroup:(EODisplayGroup *)aDisplayGroup shouldRefetchForInvalidatedAllObjectsNotification:(NSNotification *)aNotification;

// Inserting, updating, and deleting objects
- (BOOL)displayGroup:(EODisplayGroup *)aDisplayGroup shouldInsertObject:(id)anObject atIndex:(unsigned int)anIndex;
- (void)displayGroup:(EODisplayGroup *)aDisplayGroup didInsertObject:(id)anObject;
- (void)displayGroup:(EODisplayGroup *)aDisplayGroup createObjectFailedForDataSource:(EODataSource *)aDataSource;
- (void)displayGroup:(EODisplayGroup *)aDisplayGroup didSetValue:(id)aValue forObject:(id)anObject key:(NSString *)key;
- (BOOL)displayGroup:(EODisplayGroup *)aDisplayGroup shouldDeleteObject:(id)anObject;
- (void)displayGroup:(EODisplayGroup *)aDisplayGroup didDeleteObject:(id)anObject;

// Managing the display
- (BOOL)displayGroup:(EODisplayGroup *)aDisplayGroup shouldDisplayAlertWithTitle:(NSString *)aTitle message:(NSString *)aMessage;
- (BOOL)displayGroup:(EODisplayGroup *)aDisplayGroup shouldRedisplayForChangesInEditingContext:(EOEditingContext *)anEditingContext;
- (NSArray *)displayGroup:(EODisplayGroup *)aDisplayGroup displayArrayForObjects:(NSArray *)objects;

// Managing the selection
- (BOOL)displayGroup:(EODisplayGroup *)aDisplayGroup shouldChangeSelectionToIndexes:(NSArray *)newIndexes;
- (void)displayGroupDidChangeSelection:(EODisplayGroup *)aDisplayGroup;
- (void)displayGroupDidChangeSelectedObjects:(EODisplayGroup *)aDisplayGroup;
	
// Changing the data source
- (void)displayGroupDidChangeDataSource:(EODisplayGroup *)aDisplayGroup;

@end
