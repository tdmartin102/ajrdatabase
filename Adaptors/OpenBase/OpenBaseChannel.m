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

#import "OpenBaseChannel.h"

#import "OpenBaseContext.h"

#import <OpenBaseAPI/OpenBase.h>

#define qabs(a) ((a) < 0 ? -(a) : (a))

@implementation OpenBaseChannel

- (NSDate *)dateWithString:(NSString *)dateString
{
    struct tm  sometime;
    time_t aTime;
    
    // The time struct MUST be cleared as strptime ONLY sets whatever is in the
    // format.  Seems wrong to me, but there you go.
    memset(&sometime, 0, sizeof(struct tm));
    strptime([dateString UTF8String], "%Y-%m-%d %H:%M:%S %z", &sometime);
    aTime = mktime(&sometime);
    return [NSDate dateWithTimeIntervalSince1970: aTime];
}

- (OpenBase *)connection
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
   [connection release]; connection = nil;

   [super dealloc];
}

- (void)openChannel
{
   EOAdaptor   *adaptor;

   if (connected) {
      [NSException raise:EODatabaseException format:@"EOAdaptorChannel is already open"];
   }

   adaptor = [adaptorContext adaptor];

   if (connection == nil) {
      connection = [[OpenBase alloc] init];
   }

   NS_DURING
      int				returnCode;
      NSDictionary	*info = [[[self adaptorContext] adaptor] connectionDictionary];
      NSString			*url = [info objectForKey:@"URL"];
      NSString			*username = [info objectForKey:@"username"];
      NSString			*password = [info objectForKey:@"password"];
      NSString			*hostname, *databaseName;
      NSArray			*urlParts = [url componentsSeparatedByString:@":"];

      urlParts = [[urlParts lastObject] componentsSeparatedByString:@"/"];
      hostname = [urlParts objectAtIndex:2];
      databaseName = [urlParts objectAtIndex:3];

      // Deal with this once we actually try to connect.
      if (![connection connectToDatabase:databaseName ? [databaseName cString] : ""
                                  onHost:hostname ? [hostname cString] : ""
                                   login:username ? [username cString] : ""
                                password:password ? [password cString] : ""
                                  return:&returnCode]) {
         [EOLog logDebugWithFormat:@"failed to connect: %d\n", returnCode];
         [NSException raise:EODatabaseException format:@"Unable to connect to database, error %d", returnCode];
      }

      databaseEncoding = [connection databaseEncoding];

      [EOLog logWithFormat:@"Connected to database %@ (%s)\n", databaseName, [connection databaseEncodingName]];
   NS_HANDLER
      connected = NO;
      [localException raise];
   NS_ENDHANDLER

   connected = YES;
}

- (void)closeChannel
{
   if (!connected) {
      [NSException raise:EODatabaseException format:@"The database connection has already been closed."];
   }

   NS_DURING
      [connection release]; connection = nil;
      [EOLog logWithFormat:@"Disconnected from database.\n"];
   NS_HANDLER
      [NSException raise:EODatabaseException format:@"Unable to close connection: %@",  localException];
   NS_ENDHANDLER

   connected = NO;
}

- (BOOL)isFetchInProgress
{
   return fetchAttributes != nil;
}

- (void)makeCommand:(NSString *)command
{
   NSData		*data = [command dataUsingEncoding:databaseEncoding allowLossyConversion:YES];
   char			*buffer;

   buffer = NSZoneMalloc([self zone], sizeof(char) * ([data length] + 1));
   memcpy(buffer, [data bytes], [data length]);
   buffer[[data length]] = '\0';
   [connection makeCommand:buffer];
   NSZoneFree([self zone], buffer);
}

- (void)evaluateExpression:(EOSQLExpression *)expression
{
   [self makeCommand:[expression statement]];
   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %@\n", self, [expression statement]];

   if (![connection executeCommand]) {
      NSString		*error = EOFormat(@"Unable to execute SQL: %@: %s\n", [expression statement], [connection serverMessage]);
      [EOLog logErrorWithFormat:@"SQL Error: %@\n", error];
      [NSException raise:EODatabaseException format:@"%@", error];
   }

   if ([connection resultReturned]) {
      int				x, max = [connection resultColumnCount];
      EOAttribute		*tempAttribute;
   
      fetchAttributes = [[NSMutableArray allocWithZone:[self zone]] init];
      resultSet = (OBResult *)NSZoneMalloc([self zone], sizeof(OBResult) * max);

      for (x = 0; x < max; x++) {
         tempAttribute = [[EOAttribute alloc] init];
         [tempAttribute setName:[NSString stringWithCString:[connection resultColumnName:x]]];
         [tempAttribute setColumnName:[tempAttribute name]];

         resultSet[x].type = [connection resultColumnType:x];
         switch (resultSet[x].type) {
            case 1:		// char
               resultSet[x].result.stringResult = (char *)NSZoneMalloc([self zone], sizeof(char) * 2048);
               [connection bindString:resultSet[x].result.stringResult];
               [tempAttribute setValueClassName:@"NSString"];
               [tempAttribute setExternalType:@"char"];
               break;
            case 2:		// int
               [connection bindInt:&(resultSet[x].result.intResult)];
               [tempAttribute setValueClassName:@"NSNumber"];
               [tempAttribute setExternalType:@"int"];
               break;
            case 3:		// float
               [connection bindDouble:&(resultSet[x].result.doubleResult)];
               [tempAttribute setValueClassName:@"NSNumber"];
               [tempAttribute setExternalType:@"double"];
               break;
            case 4:		// long
               [connection bindLong:&(resultSet[x].result.longResult)];
               [tempAttribute setValueClassName:@"NSNumber"];
               [tempAttribute setExternalType:@"long"];
               break;
            case 5:		// money
               [connection bindLongLong:&(resultSet[x].result.longLongResult)];
               [tempAttribute setValueClassName:@"NSDecimalNumber"];
               [tempAttribute setExternalType:@"longlong"];
               break;
            case 6:		// date
               [connection bindDouble:&(resultSet[x].result.doubleResult)];
               [tempAttribute setValueClassName:@"NSDate"];
               [tempAttribute setExternalType:@"date"];
               break;
            case 7:		// time
               break;
            case 8:		// object
               break;
            case 9:		// datetime
               [connection bindDouble:&(resultSet[x].result.doubleResult)];
               [tempAttribute setValueClassName:@"NSDate"];
               [tempAttribute setExternalType:@"datetime"];
               break;
            case 10:		// longlong
               [connection bindLongLong:&(resultSet[x].result.longLongResult)];
               [tempAttribute setValueClassName:@"NSNumber"];
               [tempAttribute setExternalType:@"longlong"];
               break;
            case 11:		// boolean
               [connection bindBoolean:&(resultSet[x].result.booleanResult)];
               [tempAttribute setValueClassName:@"NSNumber"];
               [tempAttribute setExternalType:@"boolean"];
               break;
         }

         [(NSMutableArray *)fetchAttributes addObject:tempAttribute];
         [tempAttribute release];
      }
   }
}

- (void)selectAttributes:(NSArray *)attributes fetchSpecification:(EOFetchSpecification *)fetch lock:(BOOL)lock entity:(EOEntity *)entity
{
   EOSQLExpression	*expression;
   int					x;
   int numFetchAttributes;

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
   
   [self makeCommand:[expression statement]];
   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %@\n", self, [expression statement]];
   
   if (![connection executeCommand]) {
	   // mont_rothstein @ yahoo.com 2005-09-05
	   // Added call to cancelFetch because this had been causing failed selects to basically lock an application up because no further fetches could be performed.
	   [self cancelFetch];
	   [[expression retain] autorelease];
      [NSException raise:EODatabaseException format:@"Unable to execute SQL: %@: %s\n", [expression statement], [connection serverMessage]];
   }

   [expression release]; // We're now done with the expression.

   resultSet = (OBResult *)NSZoneMalloc([self zone], sizeof(OBResult) * [fetchAttributes count]);
   numFetchAttributes = [fetchAttributes count];
   for (x = 0; x < numFetchAttributes; x++) {
      EOAttribute		*attribute; 

      resultSet[x].type = [connection resultColumnType:x];
      switch (resultSet[x].type) {
         case 1:		// char
            attribute = [fetchAttributes objectAtIndex:x];
            resultSet[x].result.stringResult = (char *)NSZoneMalloc([self zone], sizeof(char) * 2048 /*([attribute width] + 1)*/);
            [connection bindString:resultSet[x].result.stringResult];
            break;
         case 2:		// int
            [connection bindInt:&(resultSet[x].result.intResult)];
            break;
         case 3:		// float
            [connection bindDouble:&(resultSet[x].result.doubleResult)];
            break;
         case 4:		// long
            [connection bindLong:&(resultSet[x].result.longResult)];
            break;
         case 5:		// money
            [connection bindLongLong:&(resultSet[x].result.longLongResult)];
            break;
         case 6:		// date
            [connection bindDouble:&(resultSet[x].result.doubleResult)];
            break;
         case 7:		// time
            break;
         case 8:		// object
            break;
         case 9:		// datetime
            [connection bindDouble:&(resultSet[x].result.doubleResult)];
            break;
         case 10:		// longlong
            [connection bindLongLong:&(resultSet[x].result.longLongResult)];
            break;
         case 11:		// longlong
            [connection bindBoolean:&(resultSet[x].result.booleanResult)];
            break;
      }
   }
}

- (id)valueForInt:(int)integer attribute:(EOAttribute *)attribute
{
   NSString		*valueClassName = [attribute valueClassName];

   if ([valueClassName isEqualToString:@"NSString"]) {
      return [NSString stringWithFormat:@"%d", integer];
   } else if ([valueClassName isEqualToString:@"NSDecimalNumber"]) {
      return [NSDecimalNumber decimalNumberWithMantissa:abs(integer) exponent:0 isNegative:integer < 0];
   } else if ([valueClassName isEqualToString:@"NSNumber"]) {
      return [NSNumber numberWithInt:integer];
   } else if ([valueClassName isEqualToString:@"NSDate"]) {
      return [NSDate dateWithTimeIntervalSince1970:integer];
   } else if ([valueClassName isEqualToString:@"NSData"]) {
      return [NSData dataWithBytes:&integer length:4];
   } else {
   }

   return nil;
}

- (id)valueForDouble:(double)aDouble attribute:(EOAttribute *)attribute
{
   NSString		*valueClassName = [attribute valueClassName];

   if ([valueClassName isEqualToString:@"NSString"]) {
      return [NSString stringWithFormat:@"%lf", aDouble];
   } else if ([valueClassName isEqualToString:@"NSDecimalNumber"]) {
      return [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%lf", aDouble]];
   } else if ([valueClassName isEqualToString:@"NSNumber"]) {
      return [NSNumber numberWithDouble:aDouble];
   } else if ([valueClassName isEqualToString:@"NSDate"]) {
      return [NSDate dateWithTimeIntervalSinceReferenceDate:aDouble];
   } else if ([valueClassName isEqualToString:@"NSData"]) {
      return [NSData dataWithBytes:&aDouble length:sizeof(double)];
   } else {
   }

   return nil;
}

- (id)valueForLong:(long)aLong attribute:(EOAttribute *)attribute
{
   NSString		*valueClassName = [attribute valueClassName];

   if ([valueClassName isEqualToString:@"NSString"]) {
      return [NSString stringWithFormat:@"%l", aLong];
   } else if ([valueClassName isEqualToString:@"NSDecimalNumber"]) {
      return [NSDecimalNumber decimalNumberWithMantissa:labs(aLong) exponent:0 isNegative:aLong < 0];
   } else if ([valueClassName isEqualToString:@"NSNumber"]) {
      return [NSNumber numberWithLong:aLong];
   } else if ([valueClassName isEqualToString:@"NSDate"]) {
      return [NSDate dateWithTimeIntervalSince1970:aLong];
   } else if ([valueClassName isEqualToString:@"NSData"]) {
      return [NSData dataWithBytes:&aLong length:sizeof(long)];
   } else {
   }

   return nil;
}

- (id)valueForLongLong:(long)aLong attribute:(EOAttribute *)attribute
{
   NSString		*valueClassName = [attribute valueClassName];

   if ([valueClassName isEqualToString:@"NSString"]) {
      return EOFormat(@"%q", aLong);
   } else if ([valueClassName isEqualToString:@"NSDecimalNumber"]) {
      return [NSDecimalNumber decimalNumberWithMantissa:qabs(aLong) exponent:0 isNegative:aLong < 0];
   } else if ([valueClassName isEqualToString:@"NSNumber"]) {
      return [NSNumber numberWithLongLong:aLong];
   } else if ([valueClassName isEqualToString:@"NSDate"]) {
      return [NSDate dateWithTimeIntervalSince1970:aLong];
   } else if ([valueClassName isEqualToString:@"NSData"]) {
      return [NSData dataWithBytes:&aLong length:sizeof(long long)];
   } else {
   }

   return nil;
}

- (id)valueForChar:(char *)string attribute:(EOAttribute *)attribute
{
   NSString		*valueClassName = [attribute valueClassName];
   NSString		*object;

   if ([valueClassName isEqualToString:@"NSString"]) {
      // This doesn't take into account the database encoding as yet.
      BYTES_TO_STRING(object, string, databaseEncoding);
      return object;
   } else if ([valueClassName isEqualToString:@"NSDecimalNumber"]) {
      return [NSDecimalNumber decimalNumberWithString:[NSString stringWithCString:string]];
   } else if ([valueClassName isEqualToString:@"NSNumber"]) {
      return [NSNumber numberWithInt:atoi(string)];
   } else if ([valueClassName isEqualToString:@"NSDate"]) {
      return [self dateWithString:[NSString stringWithCString:string]];
   } else if ([valueClassName isEqualToString:@"NSData"]) {
      return [NSData dataWithBytes:string length:[attribute width]];
   } else {
   }

   return nil;
}

- (id)valueForBoolean:(BOOL)boolean attribute:(EOAttribute *)attribute
{
   NSString		*valueClassName = [attribute valueClassName];

   if ([valueClassName isEqualToString:@"NSString"]) {
      // This doesn't take into account the database encoding as yet.
      return boolean ? @"YES" : @"NO";
   } else if ([valueClassName isEqualToString:@"NSDecimalNumber"]) {
      return nil;
   } else if ([valueClassName isEqualToString:@"NSNumber"]) {
      return [NSNumber numberWithBool:boolean];
   } else if ([valueClassName isEqualToString:@"NSDate"]) {
      return nil;
   } else if ([valueClassName isEqualToString:@"NSData"]) {
      return [NSData dataWithBytes:&boolean length:sizeof(BOOL)];
   } else {
   }

   return nil;
}

- (id)valueForDate:(double)aDouble attribute:(EOAttribute *)attribute
{
   NSString		*valueClassName = [attribute valueClassName];

   if ([valueClassName isEqualToString:@"NSString"]) {
   } else if ([valueClassName isEqualToString:@"NSDecimalNumber"]) {
   } else if ([valueClassName isEqualToString:@"NSNumber"]) {
   } else if ([valueClassName isEqualToString:@"NSDate"]) {
      return [NSDate dateWithTimeIntervalSinceReferenceDate:aDouble];
   } else if ([valueClassName isEqualToString:@"NSData"]) {
   } else {
   }

   return nil;
}

- (id)valueForResultAtIndex:(unsigned int)index
{
   EOAttribute		*attribute = [fetchAttributes objectAtIndex:index];
   id					value = nil;

   if ([connection isColumnNULL:index]) return nil;

   switch (resultSet[index].type) {
      case 1:		// char
         return [self valueForChar:resultSet[index].result.stringResult attribute:attribute];
      case 2:		// int
         return [self valueForInt:resultSet[index].result.intResult attribute:attribute];
      case 3:		// float
         return [self valueForDouble:resultSet[index].result.doubleResult attribute:attribute];
      case 4:		// long
         return [self valueForLong:resultSet[index].result.longResult attribute:attribute];
      case 5:		// money
         break;
      case 6:		// date
         return [self valueForDate:resultSet[index].result.doubleResult attribute:attribute];
      case 7:		// time
         break;
      case 8:		// object
         break;
      case 9:		// datetime
         return [self valueForDate:resultSet[index].result.doubleResult attribute:attribute];
      case 10:		// longlong
         return [self valueForLongLong:resultSet[index].result.longLongResult attribute:attribute];
      case 11:		// boolean
         return [self valueForBoolean:resultSet[index].result.booleanResult attribute:attribute];
   }

   return value;
}

- (NSMutableDictionary *)fetchRowWithZone:(NSZone *)zone
{
   if ([connection nextRow]) {
      NSMutableDictionary	*result = [[[NSMutableDictionary allocWithZone:[self zone]] init] autorelease];
      int        				x;
	  int numFetchAttributes;

	  numFetchAttributes = [fetchAttributes count];
      for (x = 0; x < numFetchAttributes; x++) {
         [result takeValue:[self valueForResultAtIndex:x] forKey:[[fetchAttributes objectAtIndex:x] name]];
      }

      rowsFetched++;

      return result;
   } else {
      [self cancelFetch];
      return nil;
   }

   return nil;
}

- (void)cancelFetch
{
	int			x;
	int numFetchAttributes;
	
	if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %d row%@ processed\n", self, rowsFetched, rowsFetched == 1 ? @"" : @"s"];
	rowsFetched = 0;
	
	numFetchAttributes = [fetchAttributes count];
	for (x = 0; x < numFetchAttributes; x++) {
		switch (resultSet[x].type) {
			case 1:
				NSZoneFree([self zone], resultSet[x].result.stringResult);
				break;
		}
	}
	NSZoneFree([self zone], resultSet); resultSet = NULL;
	[fetchEntity release]; fetchEntity = nil;
	[fetchAttributes release]; fetchAttributes = nil;
}

- (void)updateValues:(NSDictionary *)row inRowDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   EOSQLExpression     *expression;

   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression prepareUpdateExpressionWithRow:row qualifier:qualifier];
   [expression setUseAliases:NO];

   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %@\n", self, [expression statement]];

   [self makeCommand:[expression statement]];
   if (![connection executeCommand]) {
      [expression autorelease];
      [NSException raise:EODatabaseException format:@"Unable to execute SQL: %@: %s\n", [expression statement], [connection serverMessage]];
   }
   [expression release];
}

- (unsigned int)updateValues:(NSDictionary *)row inRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   EOSQLExpression     *expression;
	
   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression prepareUpdateExpressionWithRow:row qualifier:qualifier];
   [expression setUseAliases:NO];
	
   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %@\n", self, [expression statement]];
	
   [self makeCommand:[expression statement]];
   if (![connection executeCommand]) {
      [expression autorelease];
      [NSException raise:EODatabaseException format:@"Unable to execute SQL: %@: %s\n", [expression statement], [connection serverMessage]];
   }
   [expression release];
   #warning NOT RETURNING NUMBER OF ROWS AFFECTED
   return 1;
}

- (void)insertRow:(NSDictionary *)row forEntity:(EOEntity *)entity;
{
   EOSQLExpression     *expression;

   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression prepareInsertExpressionWithRow:row];
   [expression setUseAliases:NO];

   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %@\n", self, [expression statement]];

   [self makeCommand:[expression statement]];
   if (![connection executeCommand]) {
      [expression autorelease];
      [NSException raise:EODatabaseException format:@"Unable to execute SQL: %@: %s\n", [expression statement], [connection serverMessage]];
   }
   [expression release];
}

- (void)deleteRowDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   [EOLog logWarningWithFormat:@"WARNING: Not implemented: -[%@ %@]\n", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
}

- (void)deleteRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   EOSQLExpression     *expression;

   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression prepareDeleteExpressionWithQualifier:qualifier];
   [expression setUseAliases:NO];

   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %@\n", self, [expression statement]];

   [self makeCommand:[expression statement]];
   if (![connection executeCommand]) {
      [expression autorelease];
      [NSException raise:EODatabaseException format:@"Unable to execute SQL: %@\n", [expression statement]];
   }
   [expression release];
}

// This method can only be called when the database connection is already open
- (void)_createPKTable
{
   [connection makeCommand:"CREATE TABLE EO_pk_table (_timestamp datetime, pk longlong,  _rowid longlong NOT NULL UNIQUE INDEX, name CHAR(40) UNIQUE INDEX, _version long)"];
   if (![connection executeCommand]) {
      [NSException raise:EODatabaseException format:@"Unable to create EO_pk_table: %s\n", [connection serverMessage]];
   }
   [connection makeCommand:"CREATE PRIMARY KEY EO_pk_table(_rowid)"];
   if (![connection executeCommand]) {
      [NSException raise:EODatabaseException format:@"Unable to create EO_pk_table index: %s\n", [connection serverMessage]];
   }
}

- (NSArray *)primaryKeysForNewRowsWithEntity:(EOEntity *)entity count:(int)count
{
   long long				value;
	NSMutableArray			*keys;
	int						x;
	NSString					*name;
   
   [connection makeCommandf:"SELECT pk FROM EO_pk_table WHERE name = \"%s\"", [[entity name] cString]];
   if (![connection executeCommand]) {
      if ([[NSString stringWithCString:[connection serverMessage]] rangeOfString:@"table 'EO_pk_table' does not exist."].location != NSNotFound) {
         [self _createPKTable];
         return [self primaryKeysForNewRowsWithEntity:entity count:count];
      }
      [NSException raise:EODatabaseException format:@"Unable to fetch next primary key value for entity \"%@\": %s", [entity name], [connection serverMessage]];
   }

   [connection bindLongLong:&value];
   if (![connection nextRow]) {
      value = 0;
      [connection makeCommand:[EOFormat(@"INSERT INTO EO_pk_table (name, pk) VALUES (\"%@\", %qu)", [entity name], value + count) cString]];
   } else {
      [connection cancelFetch];
      [connection makeCommand:[EOFormat(@"UPDATE EO_pk_table SET pk = %qu WHERE name = \"%@\"", value + count, [entity name]) cString]];
   }
   
   if (![connection executeCommand]) {
      [NSException raise:EODatabaseException format:@"Unable to update primary key table."];
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

@end
