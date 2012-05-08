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

#import "EOModelP.h"

#import "EOAdaptor.h"
#import "EOEntityClassDescription.h"
#import "EOFetchSpecification-Model.h"
#import "EODatabase.h"
#import "EOEntityP.h"
#import "EOModelGroupP.h"
#import "EOStoredProcedure.h"

#import <EOControl/EOControl.h>

NSString *EOModelDidChangeNameNotification = @"EOModelDidChangeNameNotification";
NSString *EOModelDidChangePathNotification = @"EOModelDidChangeNameNotification";
NSString *EOModelDidAddEntityNotification = @"EOModelDidAddEntityNotification";
NSString *EOModelDidRemoveEntityNotification = @"EOModelDidRemoveEntityNotification";
NSString *EOEntityLoadedNotification = @"EOEntityLoadedNotification";

@implementation EOModel

static NSCharacterSet		*validNameFirstSet = nil;
static NSCharacterSet		*validNameSet = nil;

+ (void)initialize
{
	if (validNameSet == nil) {
		validNameSet = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#_$"] retain];
		validNameFirstSet = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#_"] retain];
	}
}

+ (NSString *)_validateName:(NSString *)aName
{
	if (aName == nil || [aName length] == 0) {
		return @"A name must have length.";
	}
	if (![validNameFirstSet characterIsMember:[aName characterAtIndex:0]]) {
		return @"Invalid starting character, must be [A-Za-z0-9@#_]";
	}
	if ([aName rangeOfCharacterFromSet:[validNameSet invertedSet]].location != NSNotFound) {
		return @"Invalid character in name, must be [A-Za-z0-9@#_$]";
	}
	
	return nil;
}

+ (EOModel *)modelWithPath:(NSString *)aPath;
{
   return [[[[self class] alloc] initWithContentsOfFile:aPath] autorelease];
}

+ (EOModel *)modelWithURL:(NSURL *)aURL
{
   return [[[[self class] alloc] initWithContentsOfURL:aURL] autorelease];
}

- (id)init
{
	if (self = [super init])
    {
        index = [[NSMutableDictionary allocWithZone:[self zone]] init];
        connectionProperties = [[NSMutableDictionary allocWithZone:[self zone]] init];
        entityCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
        entityCacheByClass = [[NSMutableDictionary allocWithZone:[self zone]] init];
        storedProcedures = [[NSMutableArray allocWithZone:[self zone]] init];
        storedProcedureCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
        name = @"Untitled";
        
        [[EOModelGroup defaultModelGroup] addModel:self];
    }
	
	return self;
}

- (id)initWithContentsOfFile:(NSString *)aPath
{
   return [self initWithContentsOfURL:[NSURL fileURLWithPath:aPath]];
}

- (id)initWithContentsOfURL:(NSURL *)aPath
{
   [self _setURL:aPath];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(classDescriptionNeededForClass:) name:NSClassDescriptionNeededForClassNotification object:nil];

   return self;
}

- (id)initWithTableOfContentsPropertyList:(NSDictionary *)tableOfContents path:(NSString *)aPath
{
	[self _setPath:[NSURL fileURLWithPath:aPath]];
	index = [tableOfContents mutableCopy];
	[self _setupEntities];

	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[indexPath release];
	[index release];
	[connectionProperties release];
	[adaptor release];
	[entityCache release];
	[entityCacheByClass release];
	[modelGroup release];
    [name release];

	[super dealloc];
}

- (void)classDescriptionNeededForClass:(NSNotification *)notification
{
	NSString		*entityName = [[notification userInfo] objectForKey:@"entityName"];
	EOEntity		*entity;
	
	// mont_rothstein @ yahoo.com 2004-12-05
	// This was assuming that we had an entity name, which we may not.  Modified to use
	// the class if the entity name is not available.
	if (entityName) entity = [self entityNamed:entityName];
	else entity = [self _entityForClass: [[notification object] class]];
	
	if (entity) {
		EOEntityClassDescription	*description;
		
		description = [[EOEntityClassDescription allocWithZone:[self zone]] initWithEntity:entity];
		[EOEntityClassDescription registerClassDescription:description forClass:[entity _objectClass]];
        [description release];
	}
}

- (void)_setPath:(NSURL *)aPath
{
   if (aPath != path) {
		NSURL		*oldPath = [path retain];
		
      [path release];
      path = [aPath retain];
      [name release];
      name = [[[[path path] lastPathComponent] stringByDeletingPathExtension] retain];
      [indexPath release];
      indexPath = [[NSURL alloc] initWithString:@"index.eomodeld" relativeToURL:path];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:EOModelDidChangePathNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, @"newPath", oldPath, @"oldPath", nil]];
		[oldPath release];
   }
}

- (void)_setURL:(NSURL *)aPath
{
	[self _setPath:aPath];

	[index release];
	index = [[NSMutableDictionary allocWithZone:[self zone]] initWithContentsOfURL:indexPath];
	
	[self _setupEntities];
}

- (NSString *)path
{
	if (path == nil) {
		return [[self name] stringByAppendingPathExtension:@"eomodeld"];
	}
   return [path path];
}

- (void)beautifyNames
{
	NSEnumerator	*enumerator = [entityCache objectEnumerator];
	EOEntity			*entity;
	
	while ((entity = [enumerator nextObject]) != nil) {
		[entity beautifyName];
        [[entity attributes] makeObjectsPerformSelector:@selector(beautifyName)];
        [[entity relationships] makeObjectsPerformSelector:@selector(beautifyName)];
	}
    [[self storedProcedures] makeObjectsPerformSelector:@selector(beautifyName)];
}

- (void)setName:(NSString *)aName
{
	if (name != aName) {
		NSString		*oldName = [name retain];
		
		[name release];
		name = [aName retain];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:EOModelDidChangeNameNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldName, @"oldName", name, @"newName", nil]];
		[oldName release];
	}
}

- (NSString *)name
{
   return name;
}

- (NSArray *)referencesToProperty:(id)property
{
	NSMutableArray		*properties = nil;
	NSArray				*work = nil;
	NSEnumerator		*enumerator;
	EOEntity				*entity;
	
	enumerator = [entityCache objectEnumerator];
	while ((entity = [enumerator nextObject]) != nil) {
		work = [entity _referencesToProperty:property];
		if ([work count]) {
			if (properties == nil) {
				properties = [work mutableCopyWithZone:[self zone]];
			} else {
				[properties addObjectsFromArray:work];
			}
		}
	}
			 
	return [properties autorelease];
}

- (NSArray *)externalModelsReferenced
{
	NSEnumerator		*enumerator;
	NSMutableArray		*models = nil;
	EOEntity				*entity;
	EOModel				*model;
	
	enumerator = [entityCache objectEnumerator];
	while ((entity = [enumerator nextObject]) != nil) {
		model = [entity model];
		if (model != self) {
			if (models == nil) 
                models = [[NSMutableArray allocWithZone:[self zone]] init];
			[models addObject:model];
		}
	}
	
	return [models autorelease];
}

- (EOEntity *)entityForObject:(id)object
{
	return [self entityNamed:[object entityName]];
}

- (void)loadAllModelObjects
{
	NSEnumerator	*enumerator = [entityCache objectEnumerator];
	EOEntity			*entity;
	
	while ((entity = [enumerator nextObject])) {
		[entity _initialize];
	}
}

- (EOAdaptor *)_adaptor
{
	if (adaptor == nil) {
		NSString			*adaptorName = [self adaptorName];
		
		// Special case, since we don't have jdbc, but we use Apple's EOModeler, which predominantly uses jdbc.
		if (adaptorName != nil && [adaptorName caseInsensitiveCompare:@"jdbc"] == NSOrderedSame) { // We need to test for nil, else second condition is true in case adaptorName is nil
			NSString		*url = [[self connectionDictionary] objectForKey:@"URL"];
			NSArray		*urlParts = [url componentsSeparatedByString:@":"];
			
			adaptorName = [urlParts objectAtIndex:1];
			[self setAdaptorName:adaptorName];
			[(NSMutableDictionary *)[self connectionDictionary] setObject:[[urlParts subarrayWithRange:(NSRange){1, [urlParts count] - 1}] componentsJoinedByString:@":"] forKey:@"URL"];
		}
		
		adaptor = [[EOAdaptor adaptorWithName:adaptorName] retain];
		[adaptor setConnectionDictionary:[self connectionDictionary]];
	}
	
   return adaptor;
}

- (void)setAdaptorName:(NSString *)aName
{
	if ([self adaptorName] != aName && ![[self adaptorName] isEqualToString:aName]) {
		// Release the adaptor if we have it. Setting it to null will cause it to be re-created when necessary.
		[self willChange];
		if (undoManager) {
			[[undoManager prepareWithInvocationTarget:self] setAdaptorName:[self adaptorName]];
		}
		[adaptor release]; adaptor = nil;
		if (aName == nil) {
			[index removeObjectForKey:@"adaptorName"];
		} else {
			[index setObject:aName forKey:@"adaptorName"];
		}
	}
}

- (NSString *)adaptorName
{
   return [index objectForKey:@"adaptorName"];
}

- (void)setConnectionDictionary:(NSDictionary *)aDictionary
{
	if (connectionProperties != aDictionary && ![connectionProperties isEqualToDictionary:aDictionary]) {
		[self willChange];
		if (undoManager) {
			[[undoManager prepareWithInvocationTarget:self] setConnectionDictionary:connectionProperties];
		}
		[connectionProperties release];
		connectionProperties = [aDictionary mutableCopyWithZone:[self zone]];
		
		[index setObject:connectionProperties forKey:@"connectionDictionary"];
		
		if (adaptor) {
			[adaptor setConnectionDictionary:connectionProperties];
		}
	}
}

- (NSDictionary *)connectionDictionary
{
   if (connectionProperties == nil) {
      connectionProperties = [[index objectForKey:@"connectionDictionary"] mutableCopyWithZone:[self zone]];
   }

   return connectionProperties;
}

- (void)setUserInfo:(NSDictionary *)someInfo
{
	[userInfo release];
	userInfo = [someInfo mutableCopyWithZone:[self zone]];
}

- (NSDictionary *)userInfo
{
	return userInfo;
}

- (void)_setupEntities
{
	NSArray				*entities = [index objectForKey:@"entities"];
	NSArray				*procedures = [index objectForKey:@"storedProcedures"];
	int					x;
	int					numEntities;
	int					numProcedures;
	NSDictionary		*aPlist;
	EOStoredProcedure	*procedure;
	EOEntity			*entity;
	
	[self setUserInfo: [index objectForKey:@"userInfo"]];
	[entityCache release];
	entityCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
	[entityCacheByClass release];
	entityCacheByClass = [[NSMutableDictionary allocWithZone:[self zone]] init];
	numEntities = [entities count];
	// Tom Martin 5/12/11
	// removed call to [self addEntity] as the initWithPropertyList:owner: now calls that method
	for (x = 0; x < numEntities; x++) {
		entity =  [[EOEntity allocWithZone:[self zone]] initWithPropertyList:[entities objectAtIndex:x] owner:self];
		[entity release];
	}
	
	[storedProcedures release];
	storedProcedures = [[NSMutableArray allocWithZone:[self zone]] init];
	[storedProcedureCache release];
	storedProcedureCache = [[NSMutableDictionary allocWithZone:[self zone]] init];
	numProcedures = [procedures count];
	for (x = 0; x < numProcedures; x++) {
		aPlist = [NSDictionary dictionaryWithObject:[procedures objectAtIndex:x] forKey:@"name"];
		procedure = [[EOStoredProcedure allocWithZone:[self zone]] initWithPropertyList:aPlist owner:self];
		[self addStoredProcedure:procedure];
		[procedure release];
	}
}

- (void)_revert
{
	int		x;
	int numKeys;
	NSArray	*keys;

	[self willChange];
	
	[EOObserverCenter suppressObserverNotification];
	
	keys = [[entityCache allKeys] copy];
	numKeys = [keys count];
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		[self removeEntity:[self entityNamed:key]];
	}
    [keys release];
	
	keys = [[storedProcedureCache allKeys] copy];
	numKeys = [keys count];
	for (x = 0; x < numKeys; x++) {
		NSString		*key = [keys objectAtIndex:x];
		[self removeStoredProcedure:[self storedProcedureNamed:key]];
	}
    [keys release];
	
	[self _setupEntities];
    
	
	[undoManager removeAllActions];
	
	[EOObserverCenter enableObserverNotification];
}

- (void)addEntity:(EOEntity *)entity
{
	NSString		*className;

	if(entity == nil)
        [NSException raise:NSInvalidArgumentException format:@"%s: entity may not be nil", __PRETTY_FUNCTION__];
    
	if ([entityCache objectForKey:[entity name]] == nil) {
        if([entity model] != nil)
            [NSException raise:NSInvalidArgumentException format:@"Entity named '%@' is already registered in model '%@'", [entity name], [[entity model] name]];

		[self willChange];
		if (undoManager) {
			[[undoManager prepareWithInvocationTarget:self] removeEntity:entity];
		}
		
		[entityCache setObject:entity forKey:[entity name]];
		[entity _setModel:self];
		
		className = [entity className];
		if (![className isEqualToString:@"EOGenericRecord"]) {
			[entityCacheByClass setObject:entity forKey:className];
		}
		
		[EOObserverCenter addObserver:self forObject:entity];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_entityDidChangeName:) name:EOEntityDidChangeNameNotification object:entity];
		[[NSNotificationCenter defaultCenter] postNotificationName:EOModelDidAddEntityNotification object:self userInfo:[NSDictionary dictionaryWithObject:entity forKey:@"entity"]];
		[[NSNotificationCenter defaultCenter] postNotificationName:EOEntityLoadedNotification object:entity];
	}
    else
        [NSException raise:NSInvalidArgumentException format:@"Model already has an entity named '%@'", [entity name]];
}

- (void)removeEntity:(EOEntity *)entity
{
	NSString		*className;
	
	if ([entityCache objectForKey:[entity name]]) {
		[self willChange];
		if (undoManager) {
			[[undoManager prepareWithInvocationTarget:self] addEntity:entity];
		}
		
		className = [entity className];
		if (![className isEqualToString:@"EOGenericRecord"]) {
			[entityCacheByClass removeObjectForKey:className];
		}
		
		[entity retain]; // Make sure the entity doesn't get freed until we're done with it.
		[entityCache removeObjectForKey:[entity name]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:EOEntityDidChangeNameNotification object:entity];
		[EOObserverCenter removeObserver:self forObject:entity];
		[[NSNotificationCenter defaultCenter] postNotificationName:EOModelDidRemoveEntityNotification object:self userInfo:[NSDictionary dictionaryWithObject:entity forKey:@"entity"]];
		[entity release];
	} else {
		[NSException raise:NSInvalidArgumentException format:@"Attempt to remove entity %@ from a model that does not own the entity.", [entity name]];
	}
}

- (void)removeEntityAndReferences:(EOEntity *)entity
{
	NSArray		*models = [modelGroup models];
	int			x;
	int numModels;
	
	numModels = [models count];
	for (x = 0; x < numModels; x++) {
		EOModel		*model = [models objectAtIndex:x];
		NSArray		*entities = [model entities];
		int			y;
		
		for (y = [entities count] - 1; y >= 0; y--) {
			EOEntity		*entity = [entities objectAtIndex:y];
			
			[entity _removeReferencesToEntity:entity];
		}
	}
	
	[self removeEntity:entity];
}

- (NSArray *)entityNames
{
	return [[entityCache allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (EOEntity *)entityNamed:(NSString *)aName
{
   return [entityCache objectForKey:aName];
}

- (EOEntity *)_entityForClass:(Class)targetClass
{
   return [entityCacheByClass objectForKey:NSStringFromClass(targetClass)];
}

- (NSURL *)_urlForEntityNamed:(NSString *)aName
{
	return [NSURL URLWithString:[aName stringByAppendingPathExtension:@"plist"] relativeToURL:path];
}

- (NSURL *)_urlForFetchSpecificationForEntityNamed:(NSString *)aName
{
	return [NSURL URLWithString:[aName stringByAppendingPathExtension:@"fspec"] relativeToURL:path];
}

- (NSURL *)_urlForStoredProcedureNamed:(NSString *)aName
{
	return [NSURL URLWithString:[aName stringByAppendingPathExtension:@"storedProcedure"] relativeToURL:path];
}

- (NSMutableDictionary *)_propertiesForURL:(NSURL *)aURL
{
   NSMutableDictionary     *properties = nil;
	NSString				*contents;
	NSStringEncoding        encoding;
	if (![[NSFileManager defaultManager] fileExistsAtPath:[aURL path]]) {
		return nil;
	}
	contents = [[NSString allocWithZone:[self zone]] initWithContentsOfURL:aURL
                usedEncoding:&encoding error:NULL];
	if (!contents) {
		[NSException raise:NSInvalidArgumentException format:@"Unable to read contents of url: %@: %s", aURL, strerror(errno)];
	}
	
	NS_DURING
		properties = [contents propertyList];
	NS_HANDLER
		[contents release];
		[localException raise];
	NS_ENDHANDLER
	
   return properties;
}

- (NSMutableDictionary *)_propertiesForEntityNamed:(NSString *)aName
{
   return [self _propertiesForURL:[self _urlForEntityNamed:aName]];
}

- (NSMutableDictionary *)_propertiesForStoredProcedureNamed:(NSString *)aName
{
   return [self _propertiesForURL:[self _urlForStoredProcedureNamed:aName]];
}

- (NSMutableDictionary *)_propertiesForFetchSpecificationForEntityNamed:(NSString *)aName;
{
   return [self _propertiesForURL:[self _urlForFetchSpecificationForEntityNamed:aName]];
}

- (NSArray *)entities
{
   return [[entityCache allValues] sortedArrayUsingSelector:@selector(compare:)];
}

/*!
* Sets our model group. This is package scoped, because it will be called
 * by the EOModelGroup when it's call to addModel is made. Once set by the
 * model group, this value should not be changed.
 *
 * @param modelGroup Our model group.
 */
- (void)setModelGroup:(EOModelGroup *)aModelGroup
{
   // Not retained
   modelGroup = aModelGroup;
}

/*!
* Returns our model group, which was set then EOModelGroup.addModel() was
 * called.
 *
 * @return Our model group.
 */
- (EOModelGroup *)modelGroup
{
	if (recursionCheck) return modelGroup;
	
	// We're part of no model group, so we should add to the default group.
	if (modelGroup == nil) {
		recursionCheck = YES;
		[[EOModelGroup defaultModelGroup] addModel:self];
		recursionCheck = NO;
	}
   return modelGroup;
}

- (NSString *)description
{
   NSMutableString		*string = [NSMutableString string];
   int						x;
   int numEntities;
   NSArray					*entities;

   [string appendFormat:@"[EOModel: name=\"%@\", entitites=", [self name]];
   entities = [[entityCache allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
   numEntities = [entities count];
   for (x = 0; x < numEntities; x++) {
      if (x > 0) [string appendString:@","];
      [string appendFormat:@"\"%@\"", [entities objectAtIndex:x]];
   }
   [string appendString:@"]"];

   return string;
}

- (void)setDatabaseEncoding:(NSStringEncoding)anEncoding
{
   NSString		*value;
   
   databaseEncoding = anEncoding;
   switch (databaseEncoding) {
      case NSASCIIStringEncoding:
         value = @"NSASCIIStringEncoding";
         break;
      case NSNEXTSTEPStringEncoding:
         value = @"NSNEXTSTEPStringEncoding";
         break;
      case NSJapaneseEUCStringEncoding:
         value = @"NSJapaneseEUCStringEncoding";
         break;
      case NSUTF8StringEncoding:
         value = @"NSUTF8StringEncoding";
         break;
      case NSISOLatin1StringEncoding:
         value = @"NSISOLatin1StringEncoding";
         break;
      case NSSymbolStringEncoding:
         value = @"NSSymbolStringEncoding";
         break;
      case NSNonLossyASCIIStringEncoding:
         value = @"NSNonLossyASCIIStringEncoding";
         break;
      case NSShiftJISStringEncoding:
         value = @"NSShiftJISStringEncoding";
         break;
      case NSISOLatin2StringEncoding:
         value = @"NSISOLatin2StringEncoding";
         break;
      case NSUnicodeStringEncoding:
         value = @"NSUnicodeStringEncoding";
         break;
      case NSWindowsCP1251StringEncoding:
         value = @"NSWindowsCP1251StringEncoding";
         break;
      case NSWindowsCP1252StringEncoding:
         value = @"NSWindowsCP1252StringEncoding";
         break;
      case NSWindowsCP1253StringEncoding:
         value = @"NSWindowsCP1253StringEncoding";
         break;
      case NSWindowsCP1254StringEncoding:
         value = @"NSWindowsCP1254StringEncoding";
         break;
      case NSWindowsCP1250StringEncoding:
         value = @"NSWindowsCP1250StringEncoding";
         break;
      case NSISO2022JPStringEncoding:
         value = @"NSISO2022JPStringEncoding";
         break;
      case NSMacOSRomanStringEncoding:
         value = @"NSMacOSRomanStringEncoding";
         break;
      default:
         value = EOFormat(@"%d", databaseEncoding);
   }

	// tom.martin @ riemer.com - 2011-09-16
	// replace depreciated method.  
	//[[self connectionDictionary] takeValue:value forKey:@"encoding"];
	[[self connectionDictionary] setValue:value forKey:@"encoding"];
}

- (NSStringEncoding)databaseEncoding
{
   if (databaseEncoding == 0) {
      NSString		*value = [[self connectionDictionary] objectForKey:@"encoding"];
      if (value != nil) {
         if ([value isEqualToString:@"NSASCIIStringEncoding"]) {
            databaseEncoding = NSASCIIStringEncoding;
         } else if ([value isEqualToString:@"NSNEXTSTEPStringEncoding"]) {
            databaseEncoding = NSNEXTSTEPStringEncoding;
         } else if ([value isEqualToString:@"NSJapaneseEUCStringEncoding"]) {
            databaseEncoding = NSJapaneseEUCStringEncoding;
         } else if ([value isEqualToString:@"NSUTF8StringEncoding"]) {
            databaseEncoding = NSUTF8StringEncoding;
         } else if ([value isEqualToString:@"NSISOLatin1StringEncoding"]) {
            databaseEncoding = NSISOLatin1StringEncoding;
         } else if ([value isEqualToString:@"NSSymbolStringEncoding"]) {
            databaseEncoding = NSSymbolStringEncoding;
         } else if ([value isEqualToString:@"NSNonLossyASCIIStringEncoding"]) {
            databaseEncoding = NSNonLossyASCIIStringEncoding;
         } else if ([value isEqualToString:@"NSShiftJISStringEncoding"]) {
            databaseEncoding = NSShiftJISStringEncoding;
         } else if ([value isEqualToString:@"NSISOLatin2StringEncoding"]) {
            databaseEncoding = NSISOLatin2StringEncoding;
         } else if ([value isEqualToString:@"NSUnicodeStringEncoding"]) {
            databaseEncoding = NSUnicodeStringEncoding;
         } else if ([value isEqualToString:@"NSWindowsCP1251StringEncoding"]) {
            databaseEncoding = NSWindowsCP1251StringEncoding;
         } else if ([value isEqualToString:@"NSWindowsCP1252StringEncoding"]) {
            databaseEncoding = NSWindowsCP1252StringEncoding;
         } else if ([value isEqualToString:@"NSWindowsCP1253StringEncoding"]) {
            databaseEncoding = NSWindowsCP1253StringEncoding;
         } else if ([value isEqualToString:@"NSWindowsCP1254StringEncoding"]) {
            databaseEncoding = NSWindowsCP1254StringEncoding;
         } else if ([value isEqualToString:@"NSWindowsCP1250StringEncoding"]) {
            databaseEncoding = NSWindowsCP1250StringEncoding;
         } else if ([value isEqualToString:@"NSISO2022JPStringEncoding"]) {
            databaseEncoding = NSISO2022JPStringEncoding;
         } else if ([value isEqualToString:@"NSMacOSRomanStringEncoding"]) {
            databaseEncoding = NSMacOSRomanStringEncoding;
         } else {
            databaseEncoding = [value intValue];
         }
      } else {
         databaseEncoding = NSISOLatin1StringEncoding;
      }
   }
   return databaseEncoding;
}

- (void)encodeTableOfContentsIntoPropertyList:(NSMutableDictionary *)propertyList
{
	// Tom.Martin @ Riemer.com 2011-09=8-22
	// replace depreciated method call
	//[propertyList takeValuesFromDictionary:index];
	[propertyList setValuesForKeysWithDictionary:index];
}

// aclark @ ghoti.org 2005-06-11
// added code to preserve version control directories
- (void)writeToFile:(NSString *)aPath
{
	BOOL					isDirectory;
	NSArray				*keys;
	NSMutableArray		*entityIndex;
	NSMutableArray		*storedProcedureIndex;
	int					x;
	int numKeys;
	// william @ swats.org 2005-07-23
	// backupPath was sometimes being used uninitilized
	NSString            *backupPath = nil;
	NSArray             *versionControlPaths;

	// array of version control paths to preserve between file saves
	versionControlPaths = [NSArray arrayWithObjects:@"CVS", @".svn", nil];

	if ([[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&isDirectory]) {
		if (!isDirectory) {
			[NSException raise:NSInvalidArgumentException format:@"Attempt to save a model to a location which already exists, but is not a directory"];
		}
		
		backupPath = [NSString stringWithFormat:@"%@~.%@", 
			[aPath stringByDeletingPathExtension], [aPath pathExtension]];
	#if MAC_OS_X_VERSION_MAX_ALLOWED > 1040
		[[NSFileManager defaultManager] removeItemAtPath:backupPath error:NULL];
		if (![[NSFileManager defaultManager] moveItemAtPath:aPath toPath:backupPath error:NULL]) 
		{
			[NSException raise:NSInvalidArgumentException format:@"Unable to create directory: %@: %s", aPath, strerror(errno)];
		}
	}

	[[NSFileManager defaultManager] createDirectoryAtPath:aPath withIntermediateDirectories:YES attributes:nil error:NULL];
	#else
		[[NSFileManager defaultManager] removeFileAtPath:backupPath handler:nil];		
		if (![[NSFileManager defaultManager] movePath:aPath toPath:backupPath handler:nil]) 
		{
			[NSException raise:NSInvalidArgumentException format:@"Unable to create directory: %@: %s", aPath, strerror(errno)];
		}
	}
	[[NSFileManager defaultManager] createDirectoryAtPath:aPath attributes:nil];
	#endif

	if (backupPath) 
	{
		NSEnumerator        *pathsEnumerator;
		NSString            *vcItem;
		
		pathsEnumerator = [versionControlPaths objectEnumerator];
		
		while (vcItem = [pathsEnumerator nextObject]) 
		{
			NSString *vcBackupPath = [backupPath stringByAppendingPathComponent:vcItem];
			NSString *vcNewPath = [aPath stringByAppendingPathComponent:vcItem];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath: vcBackupPath 
													 isDirectory: &isDirectory]) 
			{
				if (isDirectory) 
				{
					// tom.martin @ riemer.com - 2011-09-16
					// replace depreciated method.  
					#if MAC_OS_X_VERSION_MAX_ALLOWED > 1040
					[[NSFileManager defaultManager] copyItemAtPath: vcBackupPath 
													toPath: vcNewPath 
													error:NULL];
					#else
					[[NSFileManager defaultManager] copyPath: vcBackupPath 
													toPath: vcNewPath 
													handler:nil];
					#endif
				}
			}
		}
	}
	   
   entityIndex = [[NSMutableArray allocWithZone:[self zone]] init];
   keys = [[entityCache allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
   numKeys = [keys count];
   for (x = 0; x < numKeys; x++) {
	   EOEntity		*entity = [self entityNamed:[keys objectAtIndex:x]];
	   NSString		*outputPath = [[aPath stringByAppendingPathComponent:[entity name]] stringByAppendingPathExtension:@"plist"];
	   NSMutableDictionary	*dictionary;
	   NSArray					*fetches;
	   
	   dictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
	   NS_DURING
		   [entity encodeIntoPropertyList:dictionary];
		   // tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  
		   [[dictionary description] writeToFile:outputPath atomically:NO encoding:NSUTF8StringEncoding error:NULL];
		   [entityIndex addObject:[NSDictionary dictionaryWithObjectsAndKeys:[entity name], @"name", [[entity className] isEqualToString:@"EOGenericRecord"] ? @"EOGenericRecord" : [entity className], @"className", nil]];
	   NS_HANDLER
		   [dictionary release];
		   [entityIndex release];
		   [localException raise];
	   NS_ENDHANDLER
	   [dictionary release];
	   
	   fetches = [entity fetchSpecificationNames];
	   if ([fetches count]) {
		   NSMutableDictionary	*encodedFetches;
		   int						x;
		   int numFetches;
		   
		   encodedFetches = [[NSMutableDictionary allocWithZone:[self zone]] init];
		   NS_DURING
			   numFetches = [fetches count];
			   for (x = 0; x < numFetches; x++) {
				   NSString					*fetchName = [fetches objectAtIndex:x];
				   EOFetchSpecification	*fetch = [entity fetchSpecificationNamed:fetchName];
				   dictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
				   [fetch encodeIntoPropertyList:dictionary];
				   [encodedFetches setObject:dictionary forKey:fetchName];
				   [dictionary release];
			   }
			   
			   outputPath = [[aPath stringByAppendingPathComponent:[entity name]] stringByAppendingPathExtension:@"fspec"];
			   // tom.martin @ riemer.com - 2011-09-16
				// replace depreciated method.  
			   [[encodedFetches description] writeToFile:outputPath atomically:NO encoding:NSUTF8StringEncoding error:NULL];
		   NS_HANDLER
			   [encodedFetches release];
			   [entityIndex release];
			   [localException raise];
		   NS_ENDHANDLER
		   [encodedFetches release];
	   }
   }
   
   [index setObject:entityIndex forKey:@"entities"];
   [entityIndex release];
   
   storedProcedureIndex = [[NSMutableArray allocWithZone:[self zone]] init];
   keys = [[storedProcedureCache allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
   numKeys = [keys count];
   for (x = 0; x < numKeys; x++) {
	   EOStoredProcedure		*storedProcedure = [self storedProcedureNamed:[keys objectAtIndex:x]];
	   NSString					*outputPath = [[aPath stringByAppendingPathComponent:[storedProcedure name]] stringByAppendingPathExtension:@"storedProcedure"];
	   NSMutableDictionary	*dictionary;
	   
	   dictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
	   NS_DURING
		   [storedProcedure encodeIntoPropertyList:dictionary];
		   // tom.martin @ riemer.com - 2011-09-16
			// replace depreciated method.  
		   [[dictionary description] writeToFile:outputPath atomically:NO encoding:NSUTF8StringEncoding error:NULL];
		   [storedProcedureIndex addObject:[storedProcedure name]];
	   NS_HANDLER
		   [dictionary release];
		   [storedProcedureIndex release];
		   [localException raise];
	   NS_ENDHANDLER
	   [dictionary release];
   }
   
   [index setObject:storedProcedureIndex forKey:@"storedProcedures"];
   [storedProcedureIndex release];
   
   [index setObject:connectionProperties forKey:@"connectionDictionary"];
   if ([self _adaptor]) {
	   [index setObject:[adaptor name] forKey:@"adaptorName"];
   } else {
	   [index setObject:@"None" forKey:@"adaptorName"];
   }
   
   [index setObject:@"2.1" forKey:@"EOModelVersion"];
   
   if (![[index description] writeToFile:[[aPath stringByAppendingPathComponent:@"index"]
		// tom.martin @ riemer.com - 2011-09-16
		// replace depreciated method.   
		stringByAppendingPathExtension:@"eomodeld"] atomically:NO encoding:NSUTF8StringEncoding error:NULL]) {
	   [NSException raise:NSInvalidArgumentException format:@"Unable to write to file: %@: %s", [aPath stringByAppendingPathExtension:@"eomodeld"], strerror(errno)];
   }
   
   [EOObserverCenter suppressObserverNotification];
   [self _setPath:[NSURL fileURLWithPath:aPath]];
   [self setName:[[aPath lastPathComponent] stringByDeletingPathExtension]];
   [EOObserverCenter enableObserverNotification];
}

- (void)addStoredProcedure:(EOStoredProcedure *)procedure
{
	if(procedure == nil)
        [NSException raise:NSInvalidArgumentException format:@"%s: procedure may not be nil", __PRETTY_FUNCTION__];
    
	if ([storedProcedures indexOfObjectIdenticalTo:procedure] == NSNotFound) {
        if([procedure model] != nil)
            [NSException raise:NSInvalidArgumentException format:@"Stored procedure named '%@' is already registered in model '%@'", [procedure name], [[procedure model] name]];
        
		[self willChange];
		if (undoManager) {
			[[undoManager prepareWithInvocationTarget:self] removeStoredProcedure:procedure];
		}
		[storedProcedures addObject:procedure];
		[storedProcedureCache setObject:procedure forKey:[procedure name]];
		[storedProcedures sortUsingSelector:@selector(compare:)];
		
		[EOObserverCenter addObserver:self forObject:procedure];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_storedProcedureDidChangeName:) name:EOStoredProcedureDidChangeNameNotification object:procedure];
	}
    else
        [NSException raise:NSInvalidArgumentException format:@"Model already contains stored procedure named '%@'.", [procedure name]];
}

- (void)removeStoredProcedure:(EOStoredProcedure *)procedure
{
	if ([storedProcedures indexOfObjectIdenticalTo:procedure] != NSNotFound) {
		[self willChange];
		if (undoManager) {
			[[undoManager prepareWithInvocationTarget:self] addStoredProcedure:procedure];
		}
		[storedProcedures removeObject:procedure];
		[storedProcedureCache removeObjectForKey:[procedure name]];

		[EOObserverCenter removeObserver:self forObject:procedure];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:EOStoredProcedureDidChangeNameNotification object:procedure];
	}
}

- (NSArray *)storedProcedureNames
{
	return [[storedProcedureCache allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

- (EOStoredProcedure *)storedProcedureNamed:(NSString *)aName
{
	return [storedProcedureCache objectForKey:aName];
}

- (NSArray *)storedProcedures
{
	return storedProcedures;
}

- (void)setUndoManager:(NSUndoManager *)anUndoManager
{
	if (undoManager != anUndoManager) {
		[undoManager release];
		undoManager = [anUndoManager retain];
	}
}

- (NSUndoManager *)undoManager
{
	return undoManager;
}

- (void)objectWillChange:(id)object
{
	// We just forward our observers. This will basically forward messages from our entities and stored procedures.
	//[EOLog logDebugWithFormat:@"change (Model): %@\n", object];
	[[EOObserverCenter observersForObject:self] makeObjectsPerformSelector:@selector(objectWillChange:) withObject:object];
}

- (void)_entityDidChangeName:(NSNotification *)notification
{
	NSString		*oldName = [[notification userInfo] objectForKey:@"oldName"];
	NSString		*newName = [[notification userInfo] objectForKey:@"newName"];
	
	if (oldName) [entityCache removeObjectForKey:oldName];
	if (newName) [entityCache setObject:[notification object] forKey:newName];
}

- (void)_storedProcedureDidChangeName:(NSNotification *)notification
{
	NSString		*oldName = [[notification userInfo] objectForKey:@"oldName"];
	NSString		*newName = [[notification userInfo] objectForKey:@"newName"];
	
	if (oldName) [storedProcedureCache removeObjectForKey:oldName];
	if (newName) [storedProcedureCache setObject:[notification object] forKey:newName];
}

@end
