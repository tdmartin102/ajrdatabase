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

#import "EOSQLQualifier.h"
#import "EOSQLExpression.h"
#import "EODatabase.h"
#import "EOAttribute.h"

static NSCharacterSet	*whitespaceSet = nil;
static NSCharacterSet	*literalStartSet;
static NSCharacterSet	*literalSet;
static NSCharacterSet	*doubleQSet;
static NSCharacterSet	*singleQSet;

@implementation EOSQLQualifier

+ (void)initialize
{
	if (whitespaceSet == nil) {
		whitespaceSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
		literalStartSet = [[NSCharacterSet characterSetWithCharactersInString:
			@"_"
			@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			@"abcdefghijklmnopqrstuvwxyz\"'"] retain];
		literalSet = [[NSCharacterSet characterSetWithCharactersInString:
			@"_"
			@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			@"abcdefghijklmnopqrstuvwxyz"
			@"0123456789.\"'"] retain];
		doubleQSet = [[NSCharacterSet characterSetWithCharactersInString:
			@"\""] retain];
		singleQSet = [[NSCharacterSet characterSetWithCharactersInString:
			@"'"] retain];
	}
}

+ (EOQualifier *)qualifierWithExpression:(NSString *)anExpression
{
   return [[[self alloc] initWithExpression:anExpression] autorelease];
}

- (id)initWithEntity:(EOEntity *)entity qualifierFormat:(NSString *)format varargList:(va_list)args
{
	NSMutableString		*aString;
	NSString			*attribSQLName;
	id					attribEnum;
	EOAttribute			*attrib;
	
	_entity = [entity retain];
	
	// just go ahead and create the expression now I guess.  This does not create binds but...
	expression = [[NSString allocWithZone:[self zone]] initWithFormat:format arguments:args];

	return nil;
}

- (id)initWithEntity:(EOEntity *)entity qualifierFormat:(NSString *)qualifierFormat, ...
{
	id			result;
	va_list	ap;
	
	va_start(ap, qualifierFormat);
	result = [self initWithEntity:entity qualifierFormat:qualifierFormat varargList:ap];
	va_end(ap);
	
	return result;
}

+ (EOQualifier *)qualifierWithQualifierFormat:(NSString *)format, ...
{
	[NSException raise:EODatabaseException format:@"EOSQLQualifier may not be created with 'qualifierWIthQualfierFormat:."];
	return nil;
}

// This is NOT the EOF 4.5 API, but I'm going to leave it here.
- (id)initWithExpression:(NSString *)anExpression
{
   [super init];
   
   expression = [anExpression copy];

   return self;
}

- (void)dealloc
{
	[_entity release];
	[expression release];

	[super dealloc];
}

- (NSString *)sqlString
{
	return expression;
}

- (NSString *)sqlStringForSQLExpression:(EOSQLExpression *)otherExpression
{
	// If this was created using initWithExpression, well then, just return that.
	if (! _entity)
		return expression;
		
	id				attribEnum;
	NSString		*attribSQLName;
	NSMutableString	*sqlString;
	BOOL			done;
	NSString		*token;
	NSCharacterSet	*qSet;
	NSScanner		*scanner;
		
	// scan, skipping all characters until we encounter a-zA-Z"' (literal start character)
	// scan in characters from set a-zA-Z0-9."'  This would be a token of interest
	// IF the token begins with a '"' or a ''' THEN
	//     Scan skiping unil a MATCHING " or ' is incountered	
    // ELSE
	//     Check the token to see if it is an attribute name
	//       if so then replace it.
	// rinse - repeat until end of string
	
	sqlString = [[NSMutableString allocWithZone:[self zone]] initWithCapacity:[expression length] + 10];
	scanner = [[NSScanner allocWithZone:[self zone]] initWithString:expression];
	done = NO;
	while (! done)
	{
		token = nil;
		[scanner scanUpToCharactersFromSet:literalStartSet intoString:&token];
		if ([token length])
			[sqlString appendString:token];
		if ([scanner isAtEnd])
			done = YES;
		else
		{
			token = nil;
			[scanner scanCharactersFromSet:literalSet intoString:&token];
			if ([token length])
			{
				// this should work for escaped quotes as well
				qSet = nil;
				if ([token hasPrefix:@"\""])
					qSet = doubleQSet;
				if ([token hasPrefix:@"'"])
					qSet = singleQSet;
				if (qSet)
				{
					// scan up to a matching qoute
					[scanner scanUpToCharactersFromSet:qSet intoString:&token];
					if ([token length])
						[sqlString appendString:token];
				}
				else
				{
					// this literal does NOT start with a quote
					attribSQLName = [otherExpression sqlStringForAttributeNamed:token];
					if (attribSQLName)
						[sqlString appendString:attribSQLName];
					else
						[sqlString appendString:token];
				}
				if ([scanner isAtEnd])
					done = YES;
			}
		}
	}
	[scanner release];

	return [sqlString autorelease];
}

- (NSString *)sqlJoinForSQLExpression:(EOSQLExpression *)otherExpression
{
	return nil;
}

@end

