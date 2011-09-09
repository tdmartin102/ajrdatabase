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

#import "SQLiteAdaptor.h"

#import "SQLiteContext.h"
#import "SQLiteExpression.h"

@implementation SQLiteAdaptor

static NSArray *_eoExternalTypes = nil;

+ (void)initialize
{
	_eoExternalTypes = [[NSArray alloc] initWithObjects:@"int", @"float", @"double", @"decimal", @"varchar", @"char", @"boolean", @"blob", @"date", @"time", @"datetime", nil];
}

+ (NSString *)adaptorName
{
   return @"SQLite";
}

- (EOAdaptorContext *)createAdaptorContext
{
   EOAdaptorContext		*context;
	
	context = [[SQLiteContext allocWithZone:[self zone]] initWithAdaptor:self];
	[adaptorContexts addObject:context];
	[context release];
	
	return context;
}

- (Class)defaultExpressionClass
{
   return [SQLiteExpression class];
}

+ (NSArray *)externalTypesWithModel:(EOModel *)model
{
	return _eoExternalTypes;
}

+ (Class)connectionPaneClass
{
	return NSClassFromString(@"SQLiteConnectionPane");
}

@end
