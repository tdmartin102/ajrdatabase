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

#import "EOAdaptor.h"

#import "EOAdaptorChannel.h"
#import "EOAdaptorContext.h"
#import "EOAttribute.h"
#import "EODatabase.h"
#import "EODebug.h"
#import "EOLoginPanel.h"
#import "EOModelP.h"
#import "EOSchemaGeneration.h"
#import "EOSQLExpression.h"
#import "EOSQLFormatter.h"

#import <EOControl/EOControl.h>

static NSMutableDictionary	*_eoAdaptors = nil;
static NSMutableArray *_eoAdaptorNames = nil;
static NSMutableDictionary	*_eoConnectionPanes = nil;
static NSMutableDictionary *_eoExpressionClasses = nil;

@implementation EOAdaptor

+ (void)initialize
{
	if (_eoAdaptors == nil) {
		NSMutableArray *files;
		NSMutableArray *searchPaths;
		int				x;
		int max;
		
		_eoAdaptors = [[NSMutableDictionary alloc] init];
		_eoAdaptorNames = [[NSMutableArray alloc] init];
		
		// Also, scan for bundles we might care about...
		searchPaths = [NSMutableArray arrayWithObject:[[NSBundle mainBundle] resourcePath]];
        
        [searchPaths addObjectsFromArray:NSSearchPathForDirectoriesInDomains(NSAllLibrariesDirectory, NSAllDomainsMask, YES)];
        
		files = [[NSMutableArray alloc] init];
		max = [searchPaths count];
		for (x = 0; x < max; x++) {
			[files addObjectsFromArray:[NSBundle pathsForResourcesOfType:@"eoadaptor" inDirectory:[[searchPaths objectAtIndex:x] stringByAppendingPathComponent:@"Database Adaptors"]]];
		}
		
		max = [files count];
		for (x = 0; x < max; x++) {
			NSString *path = [files objectAtIndex:x];
			// aclark78@users.sourceforge.net - 2006/10/15
			// Changed to only use first adaptor found when the adaptor exists in multiple locations.
			NSString *adaptorName = [[path lastPathComponent] stringByDeletingPathExtension];
			NSString  *adaptorKey = [adaptorName lowercaseString];
			
			if (![_eoAdaptors objectForKey:adaptorKey]) {
				[_eoAdaptors setObject:path forKey:adaptorKey];
				[_eoAdaptorNames addObject:adaptorName];
			}
		}
        [files release];
		
		_eoConnectionPanes = [[NSMutableDictionary alloc] init];
	}
}

+ (id)adaptorWithName:(NSString *)adaptorName
{
   Class			adaptorClass = [_eoAdaptors objectForKey:[adaptorName lowercaseString]];
	
   if ([(id)adaptorClass isKindOfClass:[NSString class]]) {
      NSString		*path = (NSString *)adaptorClass;
		NSBundle		*bundle;
		
      if (EORegistrationDebugEnabled) [EOLog logDebugWithFormat:@"Loading %@\n", path];
		bundle = [NSBundle bundleWithPath:path];
      if (![bundle load]) {
         [NSException raise:EODatabaseException format:@"The bundle %@ failed to load properly.", path];
		}
		adaptorClass = [bundle principalClass];
		[_eoAdaptors setObject:adaptorClass forKey:[adaptorName lowercaseString]];
   }
   
   if (adaptorClass == Nil) {
      [NSException raise:EODatabaseException format:@"Unable to create adaptor with name %@.", adaptorName];
   }
	
   return [[(EOAdaptor *)[adaptorClass alloc] initWithName:adaptorName] autorelease];
}

+ (id)adaptorWithModel:(EOModel *)model
{
   return [model _adaptor];
}

- (id)initWithName:(NSString *)aName
{
	if (self = [super init])
	{
		name = [aName retain];
		adaptorContexts = [[NSClassFromString(@"_EOWeakMutableArray") allocWithZone:[self zone]] init];
	}
	return self;
}

- (void)dealloc
{
   [name release];
	[connectionDictionary release];
	[adaptorContexts release];

   [super dealloc];
}

- (NSString *)name
{
	return name;
}

+ (NSArray *)availableAdaptorNames
{
	return [_eoAdaptorNames sortedArrayUsingSelector:@selector(compare:)];
}

- (void)assertConnectionDictionaryIsValid
{
	EOAdaptorContext		*context;
	EOAdaptorChannel		*channel;
	NSException				*exception = nil;
	
	context = [self createAdaptorContext];
	channel = [context createAdaptorChannel];
	NS_DURING
		[channel openChannel];
	NS_HANDLER
		exception = [localException retain];
	NS_ENDHANDLER
	
	if (!exception) {
		[channel closeChannel];
	} else {
		[exception raise];
	}
}

- (NSDictionary *)connectionDictionary
{
	return connectionDictionary;
}

- (void)setConnectionDictionary:(NSDictionary *)aDictionary
{
	[connectionDictionary release];
	connectionDictionary = [aDictionary mutableCopyWithZone:[self zone]];
}

- (NSStringEncoding)databaseEncoding
{
	return NSISOLatin1StringEncoding;
}

- (id)fetchedValueForValue:(id)value attribute:(EOAttribute *)attribute
{
	if (delegateRespondsToFetchedValue) {
		return [delegate adaptor:self fetchedValueForValue:value attribute:attribute];
	}
	
	if ([value isKindOfClass:[NSString class]]) {
		return [self fetchedValueForStringValue:value attribute:attribute];
	}
	if ([value isKindOfClass:[NSNumber class]]) {
		return [self fetchedValueForNumberValue:value attribute:attribute];
	}
	if ([value isKindOfClass:[NSDate class]]) {
		return [self fetchedValueForDateValue:value attribute:attribute];
	}
	if ([value isKindOfClass:[NSData class]]) {
		return [self fetchedValueForDataValue:value attribute:attribute];
	}

	return value;
}

- (NSData *)fetchedValueForDataValue:(NSData *)value attribute:(EOAttribute *)attribute
{
	return value;
}

- (NSDate *)fetchedValueForDateValue:(NSDate *)value attribute:(EOAttribute *)attribute
{
	return value;
}

- (NSNumber *)fetchedValueForNumberValue:(NSNumber *)value attribute:(EOAttribute *)attribute
{
	return value;
}

- (NSString *)fetchedValueForStringValue:(NSString *)string attribute:(EOAttribute *)attribute
{
	int		max = [attribute width];
	
	if (max != 0 && [string length] > max) {
		string = [string substringToIndex:max];
	}
	
	return string;
}

- (BOOL)canServiceModel:(EOModel *)model
{
	return YES;
}

+ (NSString *)internalTypeForExternalType:(NSString *)type model:(EOModel *)model
{
	return nil;
}

+ (NSArray *)externalTypesWithModel:(EOModel *)model
{
	return nil;
}

+ (void)assignExternalInfoForEntireModel:(EOModel *)model
{
}

+ (void)assignExternalInfoForEntity:(EOEntity *)entity
{
}

+ (void)assignExternalInfoForAttribute:(EOAttribute *)attribute
{
}

- (BOOL)isValidQualifierTypeIn:(NSString *)type model:(EOModel *)model
{
	return YES;
}

- (EOAdaptorContext *)createAdaptorContext
{
	[NSException raise:NSInternalInconsistencyException format:@"Subclasses of EOAdaptor must implement %@", NSStringFromSelector(_cmd)];
   return nil;
}

- (NSArray *)contexts
{
	return adaptorContexts;
}

- (BOOL)hasOpenChannels
{
	int			x;
	int numAdaptorContexts;
	
	numAdaptorContexts = [adaptorContexts count];
	for (x = 0; x < numAdaptorContexts; x++) {
		if ([(EOAdaptorContext *)[adaptorContexts objectAtIndex:x] hasOpenChannels]) return YES;
	}
	
	return NO;
}


+ (void)setExpressionClassName:(NSString *)expressionName adaptorClassName:(NSString *)adaptorName
{   
	@synchronized(self) {
		if (_eoExpressionClasses == nil) {
			_eoExpressionClasses = [[NSMutableDictionary alloc] init];
		}
		if ([expressionName length])
			[_eoExpressionClasses setObject:NSClassFromString(expressionName) forKey:adaptorName];
		else {    
			if ([adaptorName length])  [_eoExpressionClasses removeObjectForKey:adaptorName];
		}
	}                                                                                           
}

- (Class)expressionClass
{
 	Class			class = [_eoExpressionClasses objectForKey:[self name]];
	
	if (class == Nil) {
		class = [self defaultExpressionClass];
	}
	
   return class;
}

- (Class)defaultExpressionClass
{
	return [EOSQLExpression class];
}

- (BOOL)runLoginPanelAndValidateConnectionDictionary
{
	NSDictionary		*dictionary = [self runLoginPanel];
	
	// aclark @ ghoti.org 2005-06/11
	// Replaced use of deprecated takeValuseFromDictionary: method
	[[self connectionDictionary] setValuesForKeysWithDictionary:dictionary];
	
	NS_DURING
		[self assertConnectionDictionaryIsValid];
	NS_HANDLER
		return NO;
	NS_ENDHANDLER
	
	return YES;
}

- (NSDictionary *)runLoginPanel
{
	EOLoginPanel	*loginPanel;
	NSDictionary	*connection;
	
	loginPanel = [[self class] sharedLoginPanelInstance];
	
	connection = [loginPanel runPanelForAdaptor:self validate:NO allowsCreation:NO];
	
	return connection;
}

+ (void)_loadInterface
{
	NSBundle			*bundle;
	NSString			*path;
	NSArray			*paths;
	int				x;
	int numPaths;

	bundle = [NSBundle bundleForClass:[self class]];
	paths = [bundle pathsForResourcesOfType:@"interface" inDirectory:nil];
	numPaths = [paths count];
	for (x = 0; x < numPaths; x++) {
		path = [paths objectAtIndex:x];
		bundle = [NSBundle bundleWithPath:path];
		[bundle load];
	}
}

+ (EOLoginPanel *)sharedLoginPanelInstance
{
	[self _loadInterface];
	return nil;
}

+ (Class)connectionPaneClass
{
	return Nil;
}

+ (EOConnectionPane *)sharedConnectionPane
{
	Class					class;
	EOConnectionPane	*pane;
	
	pane = [_eoConnectionPanes objectForKey:NSStringFromClass([self class])];
	if (pane) return pane;
	
	[self _loadInterface];
	
	class = [self connectionPaneClass];
	if (class) {
		pane = [[class alloc] init];
		[_eoConnectionPanes setObject:pane forKey:NSStringFromClass([self class])];
		return [pane autorelease];
	}
	
	return nil;
}

- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)aDelegate
{
	delegate = aDelegate;
	delegateRespondsToFetchedValue = [delegate respondsToSelector:@selector(adaptor:fetchedValueForValue:attribute:)];
}

- (void)createDatabaseWithAdministrativeConnectionDictionary:(NSDictionary *)connectionDictionary
{
	[NSException raise:NSInternalInconsistencyException format:@"Subclasses of EOAdaptor must implement %@", NSStringFromSelector(_cmd)];
}

- (void)dropDatabaseWithAdministrativeConnectionDictionary:(NSDictionary *)connectionDictionary
{
	[NSException raise:NSInternalInconsistencyException format:@"Subclasses of EOAdaptor must implement %@", NSStringFromSelector(_cmd)];
}

- (NSArray *)prototypeAttributes
{
	[NSException raise:NSInternalInconsistencyException format:@"Subclasses of EOAdaptor must implement %@", NSStringFromSelector(_cmd)];
	return nil;
}

- (EOSchemaGeneration *)synchronizationFactory
{
	return [[[EOSchemaGeneration allocWithZone:[self zone]] init] autorelease];
}

@end
