
#import "NSClassDescription-EO.h"

#import "EOFormat.h"
#import "NSArray-EO.h"

#import <Foundation/Foundation.h>

@implementation NSClassDescription (EO)

+ (NSClassDescription *)classDescriptionForEntityName:(NSString *)entityName
{
	// mont_rothstein @ yahoo.com 2005-02-17
	// This method originally did nothing, assuming that it would be overridden by
	// an implementation in EOAccess.  Howver, the implmentation of this method in
	// EOAccess is in EOEntityClassDescription, not in a category.  Therefore 
	// it was never called.  This method has been changed to try and access the
	// EOEntityClassDescription class in EOAccess.

	Class otherClass = NSClassFromString(@"EOEntityClassDescription");
	if (otherClass != Nil) {
		return [otherClass classDescriptionForEntityName:entityName];
	}
	
	return nil;
}

- (id)createInstanceWithEditingContext:(EOEditingContext *)anEditingContext globalID:(EOGlobalID *)globalID zone:(NSZone *)zone
{
	/*! NSClassDescription-EO: Should do more. But main work horse in EOAccess will. */
	return nil;
}

- (NSString *)entityName
{
	// Does nothing. Overridden by subclasses.
}

- (void)propagateDeleteForObject:(id)object editingContext:(EOEditingContext *)anEditingContext
{
	// Do nothing, overridden in subclasses (EOAccess).
}

- (NSClassDescription *)classDescriptionForDestinationKey:(NSString *)key
{
	return nil;
}

- (BOOL)ownsDestinationObjectsForRelationshipKey:(NSString *)key
{
	return NO;
}

- (EODeleteRule)deleteRuleForRelationshipKey:(NSString *)key
{
	return EODeleteRuleNullify;
}

- (void)awakeObjectFromFetch:(id)object inEditingContext:(EOEditingContext *)anEditingContext
{
}

- (void)awakeObjectFromInsert:(id)object inEditingContext:(EOEditingContext *)anEditingContext
{
}

- (NSException *)validateObjectForDelete:(id)object
{
	// Implemented in EOAccess
	return nil;
}

- (NSException *)validateObjectForSave:(id)object
{
	return nil;
}

- (NSException *)validateValue:(id *)value forKey:(NSString *)key
{
	// Implemented in EOAccess
	return nil;
}

- (NSFormatter *)defaultFormatterForKey:(NSString *)key
{
	return nil;
}

- (NSFormatter *)defaultFormatterForKeyPath:(NSString *)keyPath
{
	NSArray					*keys = [keyPath componentsSeparatedByString:@"."];
	int						x;
	int numKeys;
	NSClassDescription	*classDescription = self;
	
	numKeys = [keys count] - 1;
	
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		
		classDescription = [classDescription classDescriptionForDestinationKey:key];
		// Something that can't play nice, so no formatter.
		if (classDescription == nil) return nil;
	}
	
	return [classDescription defaultFormatterForKey:[keys lastObject]];
}

- (NSString *)displayNameForKey:(NSString *)key
{
	NSMutableString		*string = [[key capitalizedString] mutableCopy];
	NSCharacterSet			*lowerCase = [NSCharacterSet uppercaseLetterCharacterSet];
	NSCharacterSet			*upperCase = [NSCharacterSet lowercaseLetterCharacterSet];
	int						x;
	int stringLength;
	BOOL						insertSpace = NO;
	
	/*! @todo Make smarter: displayNameForKey: */
	
	stringLength = [string length];
	for (x = 0; x < stringLength; x++) {
		unichar character = [string characterAtIndex:x];
		
		if ([upperCase characterIsMember:character]) {
			if (insertSpace) {
				[string insertString:@"" atIndex:x];
				x++;
			}
			insertSpace = NO;
		}
		if ([lowerCase characterIsMember:character]) {
			insertSpace = YES;
		}
	}
	
	return [string autorelease];
}

- (NSString *)userPresentableDescriptionForObject:(id)object
{
	NSArray				*keys = [self attributeKeys];
	int					x;
	int numKeys;
	NSMutableString	*description;
	
	description = [[NSMutableString alloc] init];
	[description appendString:EOFormat(@"[%C (%p): ", self, self)];
	
	numKeys = [keys count];
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		NSFormatter	*formatter = [self defaultFormatterForKey:key];
		
		if (x != 0) [description appendString:@", "];
		
		[description appendString:key];
		[description appendString:@"="];
		if (formatter) {
			[description appendString:[formatter stringForObjectValue:[object valueForKey:key]]];
		} else {
			[description appendString:[[object valueForKey:key] description]];
		}
	}
	
	return [description autorelease];
}

- (EOFetchSpecification *)fetchSpecificationNamed:(NSString *)name
{
	return nil;
}

// Note that EOF doesn't do this here, but then EOF had tight control over the key/value coding protocol, which we don't, because it's defined by Apple, not us. For this reason, in order to be able to properly create a snapshot for an EO object, we have to do it in the class description, where we can be aware of the object's entity and relationships.
- (NSDictionary *)snapshotForObject:(id)object
{
	NSMutableDictionary	*snapshot = [[NSMutableDictionary allocWithZone:[self zone]] init];
	int						x;
	int numKeys;
	NSArray					*keys;
	id							value;
	
	keys = [self attributeKeys];
	numKeys = [keys count];
	
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behavior is different.
		// It may be acceptable, and then again maybe not. 
		//value = [self storedValueForKey:key];
		value = [self valueForKey:key];
        // tom.martin @ riemer.com - 2012-02-15
        // NSStrings need special handling becuase empty strings should
        // be treated as nulls.  An EONull string read by the database
        // may get changed to an empty string.  If we try to do an update
        // with optimistic locking and the database string is null yet the
        // snapshot is an empty string, then the row will not be updated.
        if ([value isKindOfClass:[NSString class]])
        {
            if ([(NSString *)value length] == 0)
                value = [NSNull null];
        }
		[snapshot setObject:value == nil ? [NSNull null] : value forKey:key];
	}
	
	keys = [self toOneRelationshipKeys];
	numKeys = [keys count];
	
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behavior is different.
		// It may be acceptable, and then again maybe not. 
		//value = [self storedValueForKey:key];
		value = [self valueForKey:key];
		[snapshot setObject:value == nil ? [NSNull null] : value forKey:key];
	}
	
	keys = [self toManyRelationshipKeys];
	numKeys = [keys count];
	
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.  This should be tested, behavior is different.
		// It may be acceptable, and then again maybe not.
		//value = [[self storedValueForKey:key] shallowCopy];
		value = [[self valueForKey:key] shallowCopy];
		[snapshot setObject:value == nil ? [NSNull null] : value forKey:key];
		[value release];
	}
	
	return [snapshot autorelease];
}

@end

@implementation NSClassDescription (EOPrivate)
// mont_rothstein @ yahoo.com 2005-09-29
// Needed to add this method so that it can be overridden in EOAccess, so that the updateFromSnapshot: method in EOEnterpriseObject can be completed.
- (void)completeUpdateForObject:(NSObject *)object fromSnapshot:(NSDictionary *)snapshot;
{
	
}

@end

@implementation EOClassDescription

@end

