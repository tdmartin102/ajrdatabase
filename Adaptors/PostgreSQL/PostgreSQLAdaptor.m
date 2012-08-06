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

#import "PostgreSQLAdaptor.h"

#import "PostgreSQLContext.h"
#import "PostgreSQLExpression.h"
#import "PostgreSQLSchemaGeneration.h"

#import <libpq-fe.h>

@implementation PostgreSQLAdaptor

static NSMutableDictionary 	*dataTypes = nil;

+ (void)initialize
{
   if (dataTypes == nil) {
      NSBundle		*bundle = [NSBundle bundleForClass:[self class]];
      NSString		*path;
		
      path = [bundle pathForResource:@"PSQLDataTypes" ofType:@"plist"];
		
      if (path) {
         dataTypes = [[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL] propertyList] retain];
         if (!dataTypes) {
            [NSException raise:NSInternalInconsistencyException format:@"Unable to load PSQL data types."];
         }
      } else {
         [NSException raise:NSInternalInconsistencyException format:@"Unable to find PSQL data types."];
      }
   }
}

+ (void)load { }

+ (NSString *)adaptorName
{
   return @"PostgreSQL";
}

+ (NSArray *)externalTypesWithModel:(EOModel *)model
{
	NSMutableSet		*types = [NSMutableSet set];
	NSEnumerator		*enumerator = [dataTypes objectEnumerator];
	NSDictionary		*entry;
	
	while ((entry = [enumerator nextObject]) != nil) {
		NSString		*external = [entry objectForKey:@"externalType"];
		if (![external hasPrefix:@"_"]) [types addObject:[entry objectForKey:@"externalType"]];
	}
	
	return [[types allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

+ (NSDictionary *)dataTypes
{
	return dataTypes;
}

- (EOAdaptorContext *)createAdaptorContext
{
   EOAdaptorContext		*context;
	
	context = [[PostgreSQLContext allocWithZone:[self zone]] initWithAdaptor:self];
	[adaptorContexts addObject:context];
	// Tom.Martin @ riemer.com 2011-12-7
	// changed from release to autorelease.  This needs to be an autorelease 
	// because adaptorContext is weak
	[context autorelease];
	
	return context;
}

- (Class)defaultExpressionClass
{
   return [PostgreSQLExpression class];
}

+ (Class)connectionPaneClass
{
	return NSClassFromString(@"PostgreSQLConnectionPane");
}

- (EOSchemaGeneration *)synchronizationFactory
{
	return [[[PostgreSQLSchemaGeneration allocWithZone:[self zone]] init] autorelease];
}

@end
