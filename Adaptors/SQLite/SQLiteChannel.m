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

#import "SQLiteChannel.h"

#import "NSString-SQLite.h"

#import <fcntl.h>
#import <sqlite.h>

@implementation SQLiteChannel

- (id)initWithAdaptorContext:(EOAdaptorContext *)aContext
{
   [super initWithAdaptorContext:aContext];

	if (!strcmp(sqlite_encoding, "UTF-8")) {
		databaseEncoding = NSUTF8StringEncoding;
	} else {
		databaseEncoding = NSISOLatin1StringEncoding;
	}

   return self;
}

- (sqlite *)connection
{
   return connection;
}

- (void)dealloc
{
   if ([self isFetchInProgress]) {
      [self cancelFetch];
   }
   if ([self isOpen]) {
      [self closeChannel];
   }
   if (connection) sqlite_close(connection); connection = NULL;

   [super dealloc];
}

- (NSString *)_replace:(NSString *)variableName with:(NSString *)replacement in:(NSString *)string
{
	string = [string _sqliteStringByReplacingSubstring:EOFormat(@"$%@", variableName) withString:replacement replaceAll:YES];
	return [string _sqliteStringByReplacingSubstring:EOFormat(@"$(%@)", variableName) withString:replacement replaceAll:YES];
}

- (NSString *)databasePath
{
   NSDictionary		*info = [[[self adaptorContext] adaptor] connectionDictionary];
	NSString				*databasePath;
	
	if ([info objectForKey:@"path"]) {
		databasePath = [info objectForKey:@"path"];
	} else {
		NSString				*url = [info objectForKey:@"URL"];
		NSArray				*urlParts;
		
		url = [info objectForKey:@"URL"];
		urlParts = [url componentsSeparatedByString:@":"];
		databasePath = [[urlParts lastObject] substringFromIndex:2];
	}
	
	databasePath = [self _replace:@"appResource" with:[[NSBundle mainBundle] resourcePath] in:databasePath];
	databasePath = [self _replace:@"appSupport" with:[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] in:databasePath];
	databasePath = [self _replace:@"globalSupport" with:@"/Library/Application Support" in:databasePath];
	databasePath = [self _replace:@"appName" with:[[NSProcessInfo processInfo] processName] in:databasePath];
		
	return databasePath;
}

- (void)openChannel
{
   NSString				*databasePath = [self databasePath];
	char					*error;

	[EOLog logDebugWithFormat:@"SQLite: Opening %@\n", databasePath];
	
   if (connected) {
      [NSException raise:EODatabaseException format:@"EOAdaptorChannel is already open"];
   }

   connection = sqlite_open([[NSFileManager defaultManager] fileSystemRepresentationWithPath:databasePath], O_RDWR, &error);
   if (connection == NULL) {
		NSString		*message = EOFormat(@"Connection to database '%@' failed: %s\n", databasePath, error);
		sqlite_freemem(error);
      [NSException raise:EODatabaseException format:@"%@", message];
   }

   [EOLog logWithFormat:@"Connected to database %@\n", databasePath];

   connected = YES;
}

- (void)closeChannel
{
   if (!connected) {
      [NSException raise:EODatabaseException format:@"The database connection has already been closed."];
   }

   sqlite_close(connection); connection = NULL;
   [EOLog logWithFormat:@"Disconnected from database.\n"];

   connected = NO;
}

- (BOOL)isFetchInProgress
{
   return fetchAttributes != nil;
}

- (const char *)makeCommand:(NSString *)command
{
   NSData		*data = [command dataUsingEncoding:databaseEncoding allowLossyConversion:YES];
   char			*buffer;

   buffer = [EOAutoreleasedMemory autoreleasedMemoryWithCapacity:[data length] + 1];
   memcpy(buffer, [data bytes], [data length]);
   buffer[[data length]] = '\0';
   return buffer;
}

- (void)evaluateExpression:(EOSQLExpression *)expression
{
	char			*error;
	int			resultCode;
	
   if ([self isDebugEnabled]) [EOLog logWithFormat:@"SQL (%p): %@\n", self, [expression statement]];

   resultCode = sqlite_compile(connection, 
										 [self makeCommand:[expression statement]],
										 NULL,			// always one expression, so we don't care about extra
										 &resultSet,
										 &error);
   if (error) {
      NSString		*message = EOFormat(@"Unable to execute SQL: %@: %s\n", [expression statement], error);
		sqlite_freemem(error);
      [EOLog logErrorWithFormat:@"SQL Error: %@\n", message];
      [NSException raise:EODatabaseException format:@"%@", message];
   }

	resultCode = sqlite_step(resultSet, &columnCount, &values, &columnNames);
   if (resultCode == SQLITE_ROW) {
		// We're actually getting data...
      int				x;
      EOAttribute		*tempAttribute;

      fetchAttributes = [[NSMutableArray allocWithZone:[self zone]] init];

      for (x = 0; x < columnCount; x++) {
//         NSDictionary		*dataType;
         
         tempAttribute = [[EOAttribute alloc] init];
         [tempAttribute setName:[NSString stringWithCString:columnNames[x]]];
         [tempAttribute setColumnName:[tempAttribute name]];

         // Look up the datatype and map it appropriately, but if we don't recognize the database, we can still treat as a string.
			// Not sure how this is handled yet...
//         dataType = [dataTypes objectForKey:EOFormat(@"%d", PQftype(resultSet, x))];
//         if (dataType) {
//            [tempAttribute setValueClassName:[dataType objectForKey:@"valueClassName"]];
//            [tempAttribute setExternalType:[dataType objectForKey:@"externalType"]];
//            [tempAttribute setValueType:[dataType objectForKey:@"valueType"]];
//         } else {
            [EOLog logWarningWithFormat:@"Unknown type for %@: %s\n", [tempAttribute name], columnNames[x]];
            [tempAttribute setValueClassName:@"NSString"];
            [tempAttribute setExternalType:@"unknown"];
//         }

         [(NSMutableArray *)fetchAttributes addObject:tempAttribute];
         [tempAttribute release];
      }
   } else {
		sqlite_finalize(resultSet, NULL);
	}
}

- (void)selectAttributes:(NSArray *)attributes fetchSpecification:(EOFetchSpecification *)fetch lock:(BOOL)lock entity:(EOEntity *)entity
{
   EOSQLExpression	*expression;
	int					resultCode;
	char					*error;

   if ([self isFetchInProgress]) {
      [NSException raise:EODatabaseException format:@"Attempt to select objects while a fetch was already in progress."];
   }

   fetchEntity = [entity retain];

   if ([attributes count] == 0) {
      attributes = [fetchEntity attributes];
   }
   // Make sure this won't change on us. Otherwise we'd get some really strange errors.
   fetchAttributes = [attributes mutableCopyWithZone:[self zone]];
   rowsFetched = 0;

   // mont_rothstein @ yahoo.com 2005-09-22
   // When prepareSelectExpressionWithAttributes:... raised an exception (for example when a qualifier referenced items not in the model, the app basically locked up because the fetch was left open.  Modified to catch exception and cancel fetch.
   NS_DURING
   {
	   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:fetchEntity];
   // mont_rothstein @ yahoo.com 2005-06-23
   // Modified to pass in lock parameter
   [expression setUseAliases:YES];
   [expression prepareSelectExpressionWithAttributes:fetchAttributes 
												lock:[fetch locksObjects]
								  fetchSpecification:fetch];
   }
   NS_HANDLER
   {
	   [self cancelFetch];
	   [localException raise];
   }
   NS_ENDHANDLER
      
   if ([self isDebugEnabled]) [EOLog logWithFormat:@"SQL (%p): %@\n", self, [expression statement]];

   resultCode = sqlite_compile(connection, 
										 [self makeCommand:[expression statement]],
										 NULL,			// always one expression, so we don't care about extra
										 &resultSet,
										 &error);
   if (resultCode != SQLITE_OK) {
		NSString		*message = EOFormat(@"Unable to execute SQL: %@: %s\n", [expression statement], error);
		sqlite_freemem(error);
		// mont_rothstein @ yahoo.com 2005-09-05
		// Changed this to call cancelFetch because more needs to be done than just PQClear().  This had been causing failed selects to basically lock an application up because no further fetches could be performed.
//		if (resultSet) sqlite_finalize(resultSet, NULL);
		[self cancelFetch];
      [NSException raise:EODatabaseException format:@"%@", message];
   }

   [expression release]; // We're now done with the expression.
}

- (id)valueForResultAtIndex:(unsigned int)index
{
   EOAttribute	*attribute = [fetchAttributes objectAtIndex:index];
   NSString		*valueClassName = [attribute valueClassName];
   const char	*value;

   if (values[index] == NULL) return nil;

   value = values[index];
   valueClassName = [attribute valueClassName];

   if ([[attribute name] isEqualToString:@"grolist"]) {
      [EOLog logDebugWithFormat:@"%@: %s\n", attribute, value];
   }

   if ([valueClassName isEqualToString:@"NSString"]) {
      NSData		*data = [[NSData alloc] initWithBytesNoCopy:(char *)value length:strlen(value) freeWhenDone:NO];
      NSString		*string;

      string = [[[NSString alloc] initWithData:data encoding:databaseEncoding] autorelease];
      [data release];
      return string;
   } else if ([valueClassName isEqualToString:@"NSDecimalNumber"]) {
      return [NSDecimalNumber decimalNumberWithString:[NSString stringWithCString:value]];
   } else if ([valueClassName isEqualToString:@"NSNumber"]) {
      NSString	*type = [attribute valueType];

      if (value[0] == 't' || value[1] == 'f') {
         return [NSNumber numberWithBool:value[0] == 't'];
      }

      if ([type length]) {
         unichar				valueType = [type characterAtIndex:0];
         switch (valueType) {
            case 's':
               return [NSNumber numberWithShort:strtol(value, NULL, 10)];
            case 'S':
               return [NSNumber numberWithUnsignedShort:strtoul(value, NULL, 10)];
            case 'i':
               return [NSNumber numberWithInt:strtol(value, NULL, 10)];
            case 'I':
               return [NSNumber numberWithUnsignedInt:strtol(value, NULL, 10)];
            case 'l':
               return [NSNumber numberWithLong:strtol(value, NULL, 10)];
            case 'L':
               return [NSNumber numberWithUnsignedLong:strtol(value, NULL, 10)];
            case 'q':
               return [NSNumber numberWithLongLong:strtoll(value, NULL, 10)];
            case 'Q':
               return [NSNumber numberWithUnsignedLongLong:strtoull(value, NULL, 10)];
            case 'f':
               return [NSNumber numberWithFloat:strtod(value, NULL)];
            case 'd':
               return [NSNumber numberWithDouble:strtod(value, NULL)];
            case 'c':
               return [NSNumber numberWithChar:strtol(value, NULL, 10)];
         }
         [EOLog logWarningWithFormat:@"Unknown valueType '%c', which may result in incorrect database values\n", valueType];
      } else {
         [EOLog logWarningWithFormat:@"Numeric attribute %@ in entity %@ is missing it's valueType which may result in incorrect database values\n", [attribute name], [[attribute entity] name]];
      }

      return [NSNumber numberWithInt:atoi(value)];
   } else if ([valueClassName isEqualToString:@"NSCalendarDate"]) {
      char				buffer[100];
		int				length = strlen(value);
      strncpy(buffer, value, 19);
      buffer[19] = '\0';
      strcat(buffer, " ");
      strcat(buffer, value + length - 3);
      buffer[23] = '0';
      buffer[24] = '0';
      buffer[25] = '\0';
      return [NSCalendarDate dateWithString:[NSString stringWithCString:buffer]];
   } else if ([valueClassName isEqualToString:@"NSArray"]) {
      NSString	*type = [attribute valueType];
      if ([type length]) {
         NSMutableArray		*p2 = [NSMutableArray array];
         unichar				valueType;
         NSNumber				*number;
			const char			*where;

         valueType = [type characterAtIndex:0];

			where = value;
         do {
            while (*where && !isdigit(*where)) where++;
            switch (valueType) {
               case 's':
                  number = [NSNumber numberWithShort:strtol(value, NULL, 10)]; break;
               case 'S':
                  number = [NSNumber numberWithUnsignedShort:strtoul(value, NULL, 10)]; break;
               case 'i':
                  number = [NSNumber numberWithInt:strtol(value, NULL, 10)]; break;
               case 'I':
                  number = [NSNumber numberWithUnsignedInt:strtol(value, NULL, 10)]; break;
               case 'l':
                  number = [NSNumber numberWithLong:strtol(value, NULL, 10)]; break;
               case 'L':
                  number = [NSNumber numberWithUnsignedLong:strtol(value, NULL, 10)]; break;
               case 'q':
                  number = [NSNumber numberWithLongLong:strtoll(value, NULL, 10)]; break;
               case 'Q':
                  number = [NSNumber numberWithUnsignedLongLong:strtoull(value, NULL, 10)]; break;
               case 'f':
                  number = [NSNumber numberWithFloat:strtod(value, NULL)]; break;
               case 'd':
                  number = [NSNumber numberWithDouble:strtod(value, NULL)]; break;
               case 'c':
                  number = [NSNumber numberWithChar:strtol(value, NULL, 10)]; break;
               default:
                  [EOLog logWarningWithFormat:@"Unknown valueType '%c', which may result in incorrect database values\n", valueType];
                  where = NULL;
                  break;
            }
            [p2 addObject:number];
         } while (where && *where != '\0');
         //[EOLog logDebugWithFormat:@"Returning: %@\n", p2];
         return p2;
      } else {
         [EOLog logWarningWithFormat:@"Numeric vector attribute %@ is missing it's valueType which may result in incorrect database values\n", [attribute name]];
         return [NSArray array];
      }
   } else if ([valueClassName isEqualToString:@"NSData"]) {
#warning This probably isnt right for the NSData type on SQLite.
      return [NSData dataWithBytes:value length:strlen(value)];
   } else {
      // This should be handling custom types.
   }

   return nil;
}

- (NSMutableDictionary *)fetchRowWithZone:(NSZone *)zone
{
	int		resultCode;
	int		attempts = 0;
	
	do {
		resultCode = sqlite_step(resultSet, &columnCount, &values, &columnNames);
		
		if (resultCode == SQLITE_ROW) {
			NSMutableDictionary	*result = [[[NSMutableDictionary allocWithZone:[self zone]] init] autorelease];
			int        				x;
			int numFetchAttributes;
			
			numFetchAttributes = [fetchAttributes count];
			for (x = 0; x < numFetchAttributes; x++) {
				[result takeValue:[self valueForResultAtIndex:x] forKey:[[fetchAttributes objectAtIndex:x] name]];
			}
			
			rowsFetched++;
			
			return result;
		} else if (resultCode == SQLITE_DONE) {
			[self cancelFetch];
			return nil;
		} else if (resultCode == SQLITE_ERROR) {
			[self cancelFetch];
			[NSException raise:EODatabaseException format:@"An error occured while fetching rows."];
			return nil;
		} else if (resultCode == SQLITE_MISUSE) {
			[self cancelFetch];
			return nil;
		} else if (resultCode == SQLITE_BUSY) {
			attempts++;
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		} else {
			[EOLog logWarningWithFormat:@"Unknown result code from SQLLite: %d. Cancelling fetch.", resultCode];
			[self cancelFetch];
			return nil;
		}
	} while (attempts <= 5);

   return nil;
}

- (void)cancelFetch
{
   if ([self isDebugEnabled]) [EOLog logWithFormat:@"SQL (%p): %d row%@ processed\n", self, rowsFetched, rowsFetched == 1 ? @"" : @"s"];
   rowsFetched = 0;

   sqlite_finalize(resultSet, NULL); resultSet = NULL;

   [fetchEntity release]; fetchEntity = nil;
   [fetchAttributes release]; fetchAttributes = nil;
}

- (void)executeSQL:(NSString *)sql
{
	int		resultCode;
	char		*error;
	
   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %@\n", self, sql];

   resultCode = sqlite_exec(connection, [self makeCommand:sql], NULL, NULL, &error);
	if (resultCode != SQLITE_OK) {
      NSString		*errorMessage;

		errorMessage = EOFormat(@"Unable to execute SQL: %@: %s\n", sql, error);
		sqlite_freemem(error);
      [NSException raise:EODatabaseException format:@"%@", errorMessage];
   }
   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %s row(s) effected\n", self, sqlite_changes(connection)];
}

- (void)execute:(EOSQLExpression *)expression
{
	NS_DURING
		[self executeSQL:[expression statement]];
	NS_HANDLER
		[expression release];
		[localException raise];
	NS_ENDHANDLER
	[expression release];
}

- (void)updateValues:(NSDictionary *)row inRowDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   EOSQLExpression     *expression;

   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression setUseAliases:NO];
   [expression prepareUpdateExpressionWithRow:row qualifier:qualifier];
   [self execute:expression]; // release handled by above!
}

- (unsigned int)updateValues:(NSDictionary *)row inRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   EOSQLExpression     *expression;
	
   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression setUseAliases:NO];
   [expression prepareUpdateExpressionWithRow:row qualifier:qualifier];
   [self execute:expression]; // release handled by above!
   #warning not returning rows affected.
   return 1;
}

- (void)insertRow:(NSDictionary *)row forEntity:(EOEntity *)entity;
{
   EOSQLExpression     *expression;

   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression setUseAliases:NO];
   [expression prepareInsertExpressionWithRow:row];
   [self execute:expression]; // release handled by above!
}

- (void)deleteRowDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   [self deleteRowsDescribedByQualifier:qualifier entity:entity];
}

- (void)deleteRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   EOSQLExpression     *expression;

   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression setUseAliases:NO];
   [expression prepareDeleteExpressionWithQualifier:qualifier];
   [self execute:expression]; // release handled by above!
}

// This method can only be called when the database connection is already open
- (void)_createPKTable
{
   [self executeSQL:@"CREATE TABLE EO_pk_table (pk longlong, name CHAR(40))"];
}

- (NSArray *)primaryKeysForNewRowsWithEntity:(EOEntity *)entity count:(int)count
{
   unsigned long long	value;
	int						resultCode;
	char						*error;
	NSMutableArray			*keys;
	int						x;
	NSString					*name;
   
   resultCode = sqlite_compile(connection, 
										 [EOFormat(@"SELECT pk FROM EO_pk_table WHERE name = \"%@\"", [entity name]) cString],
										 NULL,			// always one expression, so we don't care about extra
										 &resultSet,
										 &error);
   if (resultCode != SQLITE_OK) {
		NSString	*errorMessage;
      if ([[NSString stringWithCString:error] rangeOfString:@"table 'EO_pk_table' does not exist."].location != NSNotFound) {
         [self _createPKTable];
         return [self primaryKeysForNewRowsWithEntity:entity count:count];
      }
		errorMessage = EOFormat(@"Unable to fetch next primary key value for entity \"%@\": %s", [entity name], error);
		sqlite_freemem(error);
      [NSException raise:EODatabaseException format:@"%@", errorMessage];
   }
	
	resultCode = sqlite_step(resultSet, &columnCount, &values, &columnNames);
   if (resultCode == SQLITE_DONE) {
		value = 0;
      [self cancelFetch];
      [self executeSQL:EOFormat(@"INSERT INTO EO_pk_table (name, pk) VALUES (\"%@\", %qu)", [entity name], value + count)];
   } else {
		value = strtoull(values[0], NULL, 10);
      [self cancelFetch];
      [self executeSQL:EOFormat(@"UPDATE EO_pk_table SET pk = %qu WHERE name = \"%@\"", value + count, [entity name])];
   }
	
	keys = [NSMutableArray array];
	name = [[entity primaryKeyAttributeNames] objectAtIndex:0];
   for (x = 0; x < count; x++) {
		[keys addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithLongLong:value + x + 1] forKey:name]];
	}
	
   return keys;
}

- (void)setAttributesToFetch:(NSArray *)someAttributes
{
	if (fetchAttributes != someAttributes) {
		[fetchAttributes release];
		fetchAttributes = [someAttributes retain];
	}
}

- (NSArray *)attributesToFetch
{
   return fetchAttributes;
}

- (void)executeStoredProcedure:(EOStoredProcedure *)storedProcedure withValues:(NSDictionary *)values
{
   [NSException raise:EODatabaseException format:@"SQLite does not support stored procedures."];
}

- (NSArray *)describeTableNames
{
	NSMutableArray		*tableNames = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];
	NSDictionary		*row;
	EOSQLExpression	*expression;
	
	expression = [[[[[self adaptorContext] adaptor] expressionClass] alloc] init];
	[expression setStatement:@"SELECT sql FROM (SELECT * FROM sqlite_master UNION ALL SELECT * FROM sqlite_temp_master) WHERE type != 'meta' AND sql NOTNULL"];
	
	NS_DURING
		[self evaluateExpression:expression];
	NS_HANDLER
		[expression release];
		[localException raise];
	NS_ENDHANDLER
	[expression release];
	
	while ((row = [self fetchRowWithZone:NULL]) != nil) {
		NSString		*sql = [row objectForKey:@"sql"];
		
		if ([sql compare:@"CREATE TABLE" options:NSCaseInsensitiveSearch range:(NSRange){0, 12}] == NSOrderedSame) {
			NSString		*table = [[sql componentsSeparatedByString:@" "] objectAtIndex:2];
			if ((![table caseInsensitiveCompare:@"eo_pk_table"] || [table caseInsensitiveCompare:@"EO_pk_table"])) {
				[tableNames addObject:table];
			}
		}
	}
	
	return tableNames;
}

- (EOEntity *)_createEntityNamed:(NSString *)name fromSQL:(NSString *)sql
{
	EOEntity			*entity;
	NSScanner		*scanner;
	BOOL				done;
	NSCharacterSet	*typeTerminal, *subtypeTerminal;
	
	typeTerminal = [NSCharacterSet characterSetWithCharactersInString:@"(,)"];
	subtypeTerminal = [NSCharacterSet characterSetWithCharactersInString:@",)"];
	
	scanner = [[NSScanner allocWithZone:[self zone]] initWithString:sql];
	
	entity = [[EOEntity allocWithZone:[self zone]] init];
	[entity setName:name];
	[entity beautifyName];
	[entity setExternalName:name];
	[entity setClassName:@"EOGenericRecord"];
	
	// First, discard all the initial information
	[scanner scanUpToString:@"(" intoString:NULL];
	[scanner scanString:@"(" intoString:NULL];
	
	// Now process fields
	done = NO;
	do {
		NSString			*name, *type, *scale, *precision, *width;
		unichar			character;
		EOAttribute		*attribute;
		BOOL				allowsNull;
		NSRange			range;
		
		name = nil; type = nil; scale = nil; precision = nil; width = nil;
		allowsNull = YES;

		// First, scan off any whitespace
		[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
		// Scan the field name.
		[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&name];
		// Skip any whitespace
		[scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
		// Now we scan the type up to either a '(' or a ','.
		[scanner scanUpToCharactersFromSet:typeTerminal intoString:&type];
		// Make sure we didn't miss the end.
		if ([scanner isAtEnd]) break;
		// Let's see what caused our termination.
		character = [sql characterAtIndex:[scanner scanLocation]];
		// And skip the character
		[scanner setScanLocation:[scanner scanLocation] + 1];
		if (character == '(') {
			NSString		*work;
			// Start looking for subtype information
			[scanner scanUpToCharactersFromSet:subtypeTerminal intoString:&width];
			// And again, see what terminated us.
			character = [sql characterAtIndex:[scanner scanLocation]];
			// And skip the character
			[scanner setScanLocation:[scanner scanLocation] + 1];
			if (character == ',') {
				// We have scale and precision
				scale = width;
				width = nil;
				[scanner scanUpToCharactersFromSet:subtypeTerminal intoString:&precision];
				[scanner setScanLocation:[scanner scanLocation] + 1];
			} else if (character == ')') {
				// We just had width
			}
			// And make sure we account for any other type data, like "NOT NULL".
			work = nil;
			[scanner scanUpToCharactersFromSet:typeTerminal intoString:&work];
			if (work) {
				type = EOFormat(@"%@ %@", [type _sqliteTrimmedString], [work _sqliteTrimmedString]);
			}
			character = [sql characterAtIndex:[scanner scanLocation]];
			// And skip the character
			[scanner setScanLocation:[scanner scanLocation] + 1];
			if (character == ')') {
				// We're done.
				done = YES;
			}
		} else if (character == ')') {
			// We're done.
			done = YES;
		} else if (character == ',') {
			// We're done with the current item, but not the full create statement.
		}
		
		// Now, check the type for nullability.
		if ((range = [type rangeOfString:@"NOT NULL" options:NSCaseInsensitiveSearch]).location != NSNotFound) {
			allowsNull = NO;
			type = [[type mutableCopy] autorelease];
			[(NSMutableString *)type deleteCharactersInRange:range];
		}
	
		// Make sure everything is trimmed.
		name = [name _sqliteTrimmedString];
		type = [type _sqliteTrimmedString];
		scale = [scale _sqliteTrimmedString];
		precision = [precision _sqliteTrimmedString];
		width = [width _sqliteTrimmedString];
		
		// We can now create the attribute
		attribute = [[EOAttribute allocWithZone:[self zone]] init];
		[attribute setName:name];
		[attribute beautifyName];
		[attribute setColumnName:name];
		[attribute setAllowsNull:YES];
		if (width) [attribute setWidth:[width intValue]];
		if (scale) [attribute setScale:[scale intValue]];
		if (precision) [attribute setPrecision:[precision intValue]];
		[attribute setExternalType:type];
		if ([type isEqualToString:@"integer"] || [type isEqualToString:@"int"] ||
			 [type isEqualToString:@"int4"]) {
			[attribute setValueType:@"i"];
			[attribute setValueClassName:@"NSNumber"];
		} else if ([type isEqualToString:@"bigint"] || [type isEqualToString:@"int8"]) {
			[attribute setValueType:@"q"];
			[attribute setValueClassName:@"NSNumber"];
		} else if ([type isEqualToString:@"float"]) {
			[attribute setValueType:@"f"];
			[attribute setValueClassName:@"NSNumber"];
		} else if ([type isEqualToString:@"double"]) {
			[attribute setValueType:@"d"];
			[attribute setValueClassName:@"NSNumber"];
		} else if ([type isEqualToString:@"boolean"]) {
			[attribute setValueType:@"c"];
			[attribute setValueClassName:@"NSNumber"];
		} else if ([type isEqualToString:@"numeric"]) {
			[attribute setValueClassName:@"NSBigDecimal"];
		} else if ([type isEqualToString:@"varchar"]) {
			[attribute setValueClassName:@"NSString"];
		} else if ([type isEqualToString:@"date"]) {
			[attribute setValueClassName:@"NSCalendarDate"];
		} else if ([type isEqualToString:@"datetime"]) {
			[attribute setValueClassName:@"NSCalendarDate"];
		}
		[entity addAttribute:attribute];
		[attribute release];
	} while (!done);
	
	[entity setClassProperties:[entity attributes]];
	[entity setAttributesUsedForLocking:[entity attributes]];
	
	return [entity autorelease];
}

- (EOModel *)describeModelWithTableNames:(NSArray *)tableNames
{
	EOModel				*model;
	NSDictionary		*row;
	EOSQLExpression	*expression;
	
	
	model = [[EOModel allocWithZone:[self zone]] init];
	[model setName:[[[self databasePath] lastPathComponent] stringByDeletingPathExtension]];
	[model setAdaptorName:[[[self adaptorContext] adaptor] name]];
	[model setConnectionDictionary:[[[self adaptorContext] adaptor] connectionDictionary]];
	
	expression = [[[[[self adaptorContext] adaptor] expressionClass] alloc] init];
	[expression setStatement:@"SELECT sql FROM (SELECT * FROM sqlite_master UNION ALL SELECT * FROM sqlite_temp_master) WHERE type != 'meta' AND sql NOTNULL"];
	
	NS_DURING
		[self evaluateExpression:expression];
	NS_HANDLER
		[expression release];
		[localException raise];
	NS_ENDHANDLER
	[expression release];
	
	while ((row = [self fetchRowWithZone:NULL]) != nil) {
		NSString		*sql = [row objectForKey:@"sql"];
		
		if ([sql compare:@"CREATE TABLE" options:NSCaseInsensitiveSearch range:(NSRange){0, 12}] == NSOrderedSame) {
			NSString		*table = [[sql componentsSeparatedByString:@" "] objectAtIndex:2];
			if ([tableNames containsObject:table]) {
				[model addEntity:[self _createEntityNamed:table fromSQL:sql]];
			}
		}
	}
	
	return [model autorelease];
}

@end
