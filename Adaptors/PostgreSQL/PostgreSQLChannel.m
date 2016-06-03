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

#import "PostgreSQLChannel.h"

#import "PostgreSQLAdaptor.h"
#import "PostgreSQLContext.h"
#import "PostgreSQLExpression.h"

#import <EOAccess/EOAccess.h>
#import <EOControl/EOControl.h>

#define qabs(a) ((a) < 0 ? -(a) : (a))

@implementation PostgreSQLChannel

- (NSDate *)dateWithString:(NSString *)dateString calendarFormat:(NSString *)fmt
{
    struct tm  sometime;
    time_t aTime;
    const char *formatString = [fmt UTF8String];
    
    // The time struct MUST be cleared as strptime ONLY sets whatever is in the
    // format.  Seems wrong to me, but there you go.
    memset(&sometime, 0, sizeof(struct tm));
    strptime([dateString UTF8String], formatString, &sometime);
    aTime = mktime(&sometime);
    return [NSDate dateWithTimeIntervalSince1970: aTime];
}

- (NSDate *)dateWithString:(NSString *)dateString
{
    return [self dateWithString:(NSString *)dateString calendarFormat:@"%Y-%m-%d %H:%M:%S %z"];
}

- (id)initWithAdaptorContext:(EOAdaptorContext *)aContext
{
   if (self = [super initWithAdaptorContext:aContext])
   {
       databaseEncoding = -1;
       dateFormatter = [[NSDateFormatter alloc] init];
   }

   return self;
}

- (PGconn *)connection
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
   PQfinish(connection); connection = NULL;
    [dateFormatter release];

   [super dealloc];
}

- (NSString *)errorMessage
{
	NSString		*string;
	
	if (resultSet) {
		string = [NSString stringWithUTF8String:PQresultErrorMessage(resultSet)];
	} else {
		string = [NSString stringWithUTF8String:PQerrorMessage(connection)];
	}
	
	while ([string hasSuffix:@"\n"] && [string length]) {
		string = [string substringToIndex:[string length] - 1];
	}
	
	return string;
}

- (NSStringEncoding)_getDatabaseEncoding
{
   NSString				*encodingName;

   resultSet = PQexec(connection, "select getdatabaseencoding()");
   if (!resultSet ||
       (PQresultStatus(resultSet) != PGRES_COMMAND_OK &&
        PQresultStatus(resultSet) != PGRES_TUPLES_OK)) {
      [EOLog logErrorWithFormat:@"SQL Error: Unable to get database encoding: %@",  [self errorMessage]];
      PQclear(resultSet); resultSet = NULL;
      return NSASCIIStringEncoding;
   }

   encodingName = [NSString stringWithUTF8String:PQgetvalue(resultSet, 0, 0)];
   PQclear(resultSet); resultSet = NULL;

   if ([encodingName isEqualToString:@"SQL_ASCII"]) {
      return NSASCIIStringEncoding;
	} else if ([encodingName isEqualToString:@"UNICODE"] || [encodingName isEqualToString:@"UTF8"]) {
		// Because unicode on Postgres is really utf-8, not true 16 bit unicode.
		return NSUTF8StringEncoding;
   } else {
      CFStringEncoding		encoding;

      if (encodingName == nil) return NSASCIIStringEncoding;

      encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName);

      if (encoding == kCFStringEncodingInvalidId) {
         [EOLog logWarningWithFormat:@"Unknown character set \"%@\".\n", encodingName];
         return NSASCIIStringEncoding;
      } else {
         return  CFStringConvertEncodingToNSStringEncoding(encoding);
      }
   }

   return NSASCIIStringEncoding;
}

- (void)openChannel
{
    NSDictionary		*info;
    NSString			*url;
    NSString			*username;
    NSString			*password;
    NSString				*hostname, *databaseName;
	int					port;
    NSArray				*urlParts;
    NSMutableString	*cInfo;
    
    if (connected) {
        [NSException raise:EODatabaseException format:@"EOAdaptorChannel is already open"];
    }
    
    info = [[[self adaptorContext] adaptor] connectionDictionary];
   url = [info objectForKey:@"URL"];
   username = [info objectForKey:@"username"];
   password = [info objectForKey:@"password"];
	databaseName = [info objectForKey:@"databaseName"];
	hostname = [info objectForKey:@"hostname"];
	port = [[info objectForKey:@"port"] intValue];
    if (url)
        urlParts = [url componentsSeparatedByString:@":"];
    else
        urlParts = nil;
	if (![databaseName length] || ![hostname length]) {
		NSRange		range;
		
		urlParts = [url componentsSeparatedByString:@":"];
		urlParts = [[urlParts lastObject] componentsSeparatedByString:@"/"];
		if (!hostname) hostname = [urlParts objectAtIndex:2];
		if (!databaseName) databaseName = [urlParts lastObject];
		
		if ((range = [hostname rangeOfString:@"@"]).location != NSNotFound) {
			if ([username length] == 0) username = [hostname substringToIndex:range.location];
			hostname = [hostname substringFromIndex:range.location + range.length];
		}
	}
		
	if (![hostname length]) hostname = @"localhost";
	if (![username length]) username = NSUserName();
	if (![databaseName length]) databaseName = NSUserName();

   cInfo = [NSMutableString string];
   [cInfo appendFormat:@"host=%@", hostname];
   [cInfo appendFormat:@" dbname='%@'", databaseName];
   if (password) [cInfo appendFormat:@" password='%@'", password];
   if (username) [cInfo appendFormat:@" user='%@'", username];
	if (port != 0) [cInfo appendFormat:@" port=%d", port];

   connection = PQconnectdb([cInfo UTF8String]);
   if (PQstatus(connection) == CONNECTION_BAD) {
		[EOLog logErrorWithFormat:@"%@\n", [self errorMessage]];
      [NSException raise:EODatabaseException format:@"%@", [self errorMessage]];
   }

   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"Connected to database %@\n", databaseName];

   if (databaseEncoding == -1) databaseEncoding = [self _getDatabaseEncoding];
   
   connected = YES;
}

- (void)closeChannel
{
   if (!connected) {
      [NSException raise:EODatabaseException format:@"The database connection has already been closed."];
   }

   PQfinish(connection); connection = NULL;
   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"Disconnected from database.\n"];

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

// mont_rothstein @ yahoo.com 2005-06-26
// Added subclass of private method.  This is used by 
// updateValues:inRowDescribedByQualifier:inEntity: to determine success or failure
- (int)_rowsAffected { return rowsAffected; }

- (void)evaluateExpression:(EOSQLExpression *)expression
{
	if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %@\n", self, [expression statement]];
	
	// mont_rothstein @ yahoo.com 2005-06-26
	// Clear the number of rows affected
	rowsAffected = -1;
	
	resultSet = PQexec(connection, [self makeCommand:[expression statement]]);
	if (!resultSet ||
		(PQresultStatus(resultSet) != PGRES_COMMAND_OK &&
		 PQresultStatus(resultSet) != PGRES_TUPLES_OK)) {
		NSString		*error = EOFormat(@"Unable to execute SQL: %@: %@\n", [expression statement], [self errorMessage]);
		[EOLog logErrorWithFormat:@"SQL Error: %@\n", error];
		if (resultSet) { PQclear(resultSet); resultSet = NULL; }
		[NSException raise:EODatabaseException format:@"%@", error];
	}
	
	if (PQresultStatus(resultSet) != PGRES_EMPTY_QUERY) {
		int				x, max = PQnfields(resultSet);
		
		// mont_rothstein @ yahoo.com 2005-06-26
		// Added check to make sure there were fields returned
		if (max)
		{
			EOAttribute		*tempAttribute;
			NSDictionary	*dataTypes = [PostgreSQLAdaptor dataTypes];
			
			fetchAttributes = [[NSMutableArray allocWithZone:[self zone]] init];
			
			for (x = 0; x < max; x++) {
				NSDictionary		*dataType;
				
				tempAttribute = [[EOAttribute alloc] init];
				[tempAttribute setName:[NSString stringWithUTF8String:PQfname(resultSet, x)]];
				[tempAttribute setColumnName:[tempAttribute name]];
				
				// Look up the datatype and map it appropriately, but if we don't recognize the database, we can still treat as a string.
				dataType = [dataTypes objectForKey:EOFormat(@"%d", PQftype(resultSet, x))];
				if (dataType) {
					[tempAttribute setValueClassName:[dataType objectForKey:@"valueClassName"]];
					[tempAttribute setExternalType:[dataType objectForKey:@"externalType"]];
					[tempAttribute setValueType:[dataType objectForKey:@"valueType"]];
				} else {
					[EOLog logWarningWithFormat:@"Unknown type for %@: %d\n", [tempAttribute name], PQftype(resultSet, x)];
					[tempAttribute setValueClassName:@"NSString"];
					[tempAttribute setExternalType:@"unknown"];
				}
				
				[(NSMutableArray *)fetchAttributes addObject:tempAttribute];
				[tempAttribute release];
			}
			
		}		
	}
	
	// mont_rothstein @ yahoo.com 2005-06-26
	// Set number of rows affected by the expression so that it can be used to determine if the expression
	// evaluated successfully.
	rowsAffected = [[NSString stringWithFormat: @"%s", PQcmdTuples(resultSet)] intValue];
}

- (void)selectAttributes:(NSArray *)attributes fetchSpecification:(EOFetchSpecification *)fetch lock:(BOOL)lock entity:(EOEntity *)entity
{
   EOSQLExpression	*expression;

   if ([self isFetchInProgress]) {
      [NSException raise:EODatabaseException format:@"Attempt to select objects while a fetch was already in progress."];
   }
	
	if (connection == NULL) {
		[NSException raise:EODatabaseException format:@"Attempt to select attributes on an unopened adaptor channel (%p).", self];
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
	   
	   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %@\n", self, [expression statement]];

   resultSet = PQexec(connection, [self makeCommand:[expression statement]]);
   if (!resultSet || PQresultStatus(resultSet) != PGRES_TUPLES_OK) {
      NSString *errorMessage = [self errorMessage];
	   // mont_rothstein @ yahoo.com 2005-09-05
	   // Changed this to call cancelFetch because more needs to be done than just PQClear().  This had been causing failed selects to basically lock an application up because no further fetches could be performed.
	   //      PQclear(resultSet);
	   [self cancelFetch];
      [[expression retain] autorelease];
      [NSException raise:EODatabaseException format:@"Unable to execute SQL: %@: %@\n", [expression statement], errorMessage];
   }

   [expression release]; // We're now done with the expression.
}

- (id)valueForResultAtIndex:(unsigned int)index
{
   EOAttribute	*attribute = [fetchAttributes objectAtIndex:index];
   NSString		*valueClassName;
   char			*string;

   if (PQgetisnull(resultSet, rowsFetched, index)) return nil;

   string = PQgetvalue(resultSet, rowsFetched, index);
   valueClassName = [attribute valueClassName];

   if ([[attribute name] isEqualToString:@"grolist"]) {
      [EOLog logDebugWithFormat:@"%@: %s\n", attribute, string];
   }

   if ([valueClassName isEqualToString:@"NSString"]) {
      NSData		*data = [[NSData alloc] initWithBytesNoCopy:string length:strlen(string) freeWhenDone:NO];
      NSString		*string;

      string = [[[NSString alloc] initWithData:data encoding:databaseEncoding] autorelease];
      [data release];
      return string;
   } else if ([valueClassName isEqualToString:@"NSDecimalNumber"]) {
      return [NSDecimalNumber decimalNumberWithString:[NSString stringWithUTF8String:string]];
   } else if ([valueClassName isEqualToString:@"NSNumber"]) {
      NSString	*type = [attribute valueType];

      if (string[0] == 't' || string[1] == 'f') {
         return [NSNumber numberWithBool:string[0] == 't'];
      }

      if ([type length]) {
         unichar				valueType = [type characterAtIndex:0];
         switch (valueType) {
            case 's':
               return [NSNumber numberWithShort:strtol(string, NULL, 10)];
            case 'S':
               return [NSNumber numberWithUnsignedShort:strtoul(string, NULL, 10)];
            case 'i':
               return [NSNumber numberWithInt:strtol(string, NULL, 10)];
            case 'I':
               return [NSNumber numberWithUnsignedInt:strtol(string, NULL, 10)];
            case 'l':
               return [NSNumber numberWithLong:strtol(string, NULL, 10)];
            case 'L':
               return [NSNumber numberWithUnsignedLong:strtol(string, NULL, 10)];
            case 'q':
               return [NSNumber numberWithLongLong:strtoll(string, NULL, 10)];
            case 'Q':
               return [NSNumber numberWithUnsignedLongLong:strtoull(string, NULL, 10)];
            case 'f':
               return [NSNumber numberWithFloat:strtod(string, NULL)];
            case 'd':
               return [NSNumber numberWithDouble:strtod(string, NULL)];
            case 'c':
               return [NSNumber numberWithChar:strtol(string, NULL, 10)];
         }
         [EOLog logWarningWithFormat:@"Unknown valueType '%c', which may result in incorrect database values\n", valueType];
      } else {
         [EOLog logWarningWithFormat:@"Numeric attribute %@ in entity %@ is missing it's valueType which may result in incorrect database values\n", [attribute name], [[attribute entity] name]];
      }

      return [NSNumber numberWithInt:atoi(string)];
   } else if ([valueClassName isEqualToString:@"NSDate"]) {
      char				buffer[100];
		int				length = strlen(string);
		// mont_rothstein @ yahoo.com 2005-11-15
		// Added conversion to lowercase since all of our comparisons are to lower case values.
		NSString			*externalType = [[attribute externalType] lowercaseString];
		if ([externalType isEqualToString: @"timestamptz"]) {
			strncpy(buffer, string, 19);
			buffer[19] = '\0';
			strcat(buffer, " ");
			strcat(buffer, string + length - 3);          
			buffer[23] = '0';
			buffer[24] = '0';
			buffer[25] = '\0';
			return [self dateWithString:[NSString stringWithUTF8String:buffer]];
		} else if ([externalType isEqualToString: @"timetz"]) {
			strncpy(buffer, string, 8);
			buffer[8] = '\0';
			strcat(buffer, " ");
			strcat(buffer, string + length - 3);          
			buffer[12] = '0';
			buffer[13] = '0';
			buffer[14] = '\0';
			return [self dateWithString:[NSString stringWithUTF8String:buffer] calendarFormat:@"%I:%M:%S %z"];
		} else if ([externalType isEqualToString: @"time"]) {
			strncpy(buffer, string, 8);
			buffer[8] = '\0';
			return [self dateWithString:[NSString stringWithUTF8String:buffer] calendarFormat:@"%I:%M:%S"];
		} else if ([externalType isEqualToString: @"timestamp"]) {
			strncpy(buffer, string, 19);
			buffer[19] = '\0';
			// mont_rothstein @ yahoo.com 2005-01-01
			// This incorrectly had a %z in the format, corrected.
			return [self dateWithString:[NSString stringWithUTF8String:buffer] calendarFormat:@"%Y-%m-%d %I:%M:%S"];
		} else if ([externalType isEqualToString: @"date"]) {
			strncpy(buffer, string, 10);
			buffer[10] = '\0';
			return [self dateWithString:[NSString stringWithUTF8String:buffer] calendarFormat:@"%Y-%m-%d"];
		}
	} else if ([valueClassName isEqualToString:@"NSArray"]) {
      NSString	*type = [attribute valueType];
      if ([type length]) {
         NSMutableArray		*p2 = [NSMutableArray array];
         unichar				valueType;
         NSNumber				*number;
         char					*where;

         valueType = [type characterAtIndex:0];

         where = string;
         do {
            while (*where && !isdigit(*where)) where++;
            switch (valueType) {
               case 's':
                  number = [NSNumber numberWithShort:strtol(where, &where, 10)]; break;
               case 'S':
                  number = [NSNumber numberWithUnsignedShort:strtoul(where, &where, 10)]; break;
               case 'i':
                  number = [NSNumber numberWithInt:strtol(where, &where, 10)]; break;
               case 'I':
                  number = [NSNumber numberWithUnsignedInt:strtol(where, &where, 10)]; break;
               case 'l':
                  number = [NSNumber numberWithLong:strtol(where, &where, 10)]; break;
               case 'L':
                  number = [NSNumber numberWithUnsignedLong:strtol(where, &where, 10)]; break;
               case 'q':
                  number = [NSNumber numberWithLongLong:strtoll(where, &where, 10)]; break;
               case 'Q':
                  number = [NSNumber numberWithUnsignedLongLong:strtoull(where, &where, 10)]; break;
               case 'f':
                  number = [NSNumber numberWithFloat:strtod(where, &where)]; break;
               case 'd':
                  number = [NSNumber numberWithDouble:strtod(where, &where)]; break;
               case 'c':
                  number = [NSNumber numberWithChar:strtol(where, &where, 10)]; break;
               default:
                    [EOLog logWarningWithFormat:@"Unknown valueType '%c', which may result in incorrect database values\n", valueType];
                    where = NULL;
                    // will well assume int
                    number = [NSNumber numberWithInt:strtol(where, &where, 10)];
                    break;
            }
            [p2 addObject:number];
         } while (where && *where != '\0');
         return p2;
      } else {
         [EOLog logWarningWithFormat:@"Numeric vector attribute %@ is missing it's valueType which may result in incorrect database values\n", [attribute name]];
         return [NSArray array];
      }
   } else if ([valueClassName isEqualToString:@"NSData"]) {
      return [NSData dataWithBytes:string length:PQgetlength(resultSet, rowsFetched, index)];
   } else {
      // This should be handling custom types.
   }

   return nil;
}

- (NSMutableDictionary *)fetchRowWithZone:(NSZone *)zone
{
   if (rowsFetched < PQntuples(resultSet)) {
      NSMutableDictionary	*result = [[[NSMutableDictionary allocWithZone:zone] init] autorelease];
      int        				x;
	  int numFetchAttributes;

	  numFetchAttributes = [fetchAttributes count];
      for (x = 0; x < numFetchAttributes; x++) {
         [result setValue:[self valueForResultAtIndex:x] forKey:[[fetchAttributes objectAtIndex:x] name]];
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
   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %d row%@ processed\n", self, rowsFetched, rowsFetched == 1 ? @"" : @"s"];
   rowsFetched = 0;

   PQclear(resultSet); resultSet = NULL;

   [fetchEntity release]; fetchEntity = nil;
   [fetchAttributes release]; fetchAttributes = nil;
}

- (void)executeSQL:(NSString *)expression
{
	// mont_rothstein @ yahoo.com 2005-07-07
	// This method isn't part of the API and should be removed.
	[EOLog log: @"The method executeSQL: in the PostgresSQLChannel has been deprecated because it is not part of the API.  Please replace any uses of it with evaluateExpression:"];
   if ([self isDebugEnabled]) [EOLog logDebugWithFormat:@"SQL (%p): %@\n", self, expression];

   resultSet = PQexec(connection, [self makeCommand:expression]);
   if (!resultSet || PQresultStatus(resultSet) != PGRES_COMMAND_OK) {
      NSString		*errorMessage;

		errorMessage = EOFormat(@"Unable to execute SQL: %@: %@", expression, [self errorMessage]);
      if (resultSet) {
         PQclear(resultSet);
         resultSet = NULL;
      }
      [expression autorelease];
		[EOLog logErrorWithFormat:@"%@", errorMessage];
      [NSException raise:EODatabaseException format:@"%@", errorMessage];
   }
   if ([self isDebugEnabled]) {
		char		*result = PQcmdTuples(resultSet);
		if (result && strlen(result)) [EOLog logDebugWithFormat:@"SQL (%p): %s row(s) effected\n", self, result];
		else [EOLog logDebugWithFormat:@"SQL (%p): SQL executed\n", self];
	}
   PQclear(resultSet);
   resultSet = NULL;
}

// mont_rothstein @ yahoo.com 2005-06-26
// This method was no longer being called, and is not part of the API.
//- (void)execute:(EOSQLExpression *)expression
//{
//   [self executeSQL:[expression statement]];
//   [expression release];
//}

// mont_rothstein @ yahoo.com 2005-06-26
// Commented out method implementation because it is unnecessary.  API calls for the 
// superclass to implement this method
//- (void)updateValues:(NSDictionary *)row inRowDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
//{
//   EOSQLExpression     *expression;
//
//   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
//   [expression setUseAliases:NO];
//   [expression prepareUpdateExpressionWithRow:row qualifier:qualifier];
//   [self execute:expression]; // release handled by above!
//}

- (unsigned int)updateValues:(NSDictionary *)row inRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
	EOSQLExpression     *expression;
	
	expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
	[expression setUseAliases:NO];
	[expression prepareUpdateExpressionWithRow:row qualifier:qualifier];
	
	// mont_rothstein @ yahoo.com 2005-06-26
	// Modified to use evaluateExpression.
	//   [self execute:expression]; // release handled by above!
	NS_DURING
		[self evaluateExpression: expression];
	NS_HANDLER
		[expression autorelease];
		[localException raise];
	NS_ENDHANDLER
	
	// mont_rothstein @ yahoo.com 2005-07-10
	// Added cancelFetch to clean up resources used by evaluateExpression
	// Evaluate starts a whole fetch cycle, so stop it from progressing.
	[self cancelFetch];

	[expression release];
    
    return rowsAffected;
}

- (void)insertRow:(NSDictionary *)row forEntity:(EOEntity *)entity;
{
   EOSQLExpression     *expression;

   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression setUseAliases:NO];
   [expression prepareInsertExpressionWithRow:row];
   
   // mont_rothstein @ yahoo.com 2005-06-26
   // Modified to use evaluateExpression.
   //   [self execute:expression]; // release handled by above!
   NS_DURING
	   [self evaluateExpression: expression];
   NS_HANDLER
	   [expression autorelease];
	   [localException raise];
   NS_ENDHANDLER
   
   // mont_rothstein @ yahoo.com 2005-07-10
   // Added cancelFetch to clean up resources used by evaluateExpression
   // Evaluate starts a whole fetch cycle, so stop it from progressing.
   [self cancelFetch];
   
   [expression release];
}

// mont_rothstein @ yahoo.com 2005-06-26
// Commented out method implementation because it is unnecessary.  API calls for the 
// superclass to implement this method
//- (void)deleteRowDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
//{
//   [self deleteRowsDescribedByQualifier:qualifier entity:entity];
//}

- (unsigned int)deleteRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   EOSQLExpression     *expression;

   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression setUseAliases:NO];
   [expression prepareDeleteExpressionForQualifier:qualifier];
   
   // mont_rothstein @ yahoo.com 2005-06-26
   // Modified to use evaluateExpression.
   //   [self execute:expression]; // release handled by above!
   NS_DURING
	   [self evaluateExpression: expression];
   NS_HANDLER
	   [expression autorelease];
	   [localException raise];
   NS_ENDHANDLER
   
   // mont_rothstein @ yahoo.com 2005-07-10
   // Added cancelFetch to clean up resources used by evaluateExpression
   // Evaluate starts a whole fetch cycle, so stop it from progressing.
   [self cancelFetch];
   
   [expression release];
   
   return rowsAffected;
}

// This method can only be called when the database connection is already open
- (void)_createSequence:(NSString *)name
{
   PGresult				*set;
   char					buffer[1024];

   // Start the sequence at two, since we're just going to assume that when we create the sequence, we can return 1.
   sprintf(buffer, "CREATE SEQUENCE %s_PK MINVALUE 1 START 2", [name UTF8String]);

   set = PQexec(connection, buffer);
   if (!set || PQresultStatus(set) != PGRES_COMMAND_OK) {
      NSString		*errorMessage;
      if (set) {
         errorMessage = EOFormat(@"Unable to create primary key sequence: %@\n", [self errorMessage]);
         PQclear(set);
      } else {
         errorMessage = EOFormat(@"Unable to create primary key sequence for entity %@", name);
      }
      [NSException raise:EODatabaseException format:@"%@", errorMessage];
   }
   PQclear(set);
}

- (NSArray *)primaryKeysForNewRowsWithEntity:(EOEntity *)entity count:(int)count
{
   unsigned long long	value = -1;
   char						buffer[1024];
   NSString					*errorMessage;
	NSMutableArray			*keys;
	int						x;
	NSString					*name;
   
	// mont_rothstein @ yahoo.com 2004-12-2
	// Changed the below sprintf lines to grab the externalName instead of the entity name as is
	// appropriate.
	if (count != 1) {
		// mont_rothstein @ yahoo.com 2005-02-07
		// Somehow the second reference to [entity name] in the line below was still in place.  Changed
		// it to be [entity externalName]
		sprintf(buffer, "SELECT setval('%s_PK', nextval('%s_PK') + %d) - %d", [[entity externalName] UTF8String], [[entity externalName] UTF8String], count, count);
	} else {
		sprintf(buffer, "SELECT nextval('%s_PK')", [[entity externalName] UTF8String]);
	}
   resultSet = PQexec(connection, buffer);
   if (!resultSet || PQresultStatus(resultSet) != PGRES_TUPLES_OK) {
      errorMessage = [self errorMessage];
      if (resultSet) {PQclear(resultSet); resultSet = NULL;}
      if ([errorMessage rangeOfString:@"does not exist"].location != NSNotFound) {
         [self _createSequence:[entity externalName]];

			keys = [NSMutableArray array];
			name = [[entity primaryKeyAttributeNames] objectAtIndex:0];
			for (x = 0; x < count; x++) {
				[keys addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithLongLong:count + x] forKey:name]];
			}
			
			return keys;
      }
   } else if (PQntuples(resultSet) == 1) {
      value = atoll(PQgetvalue(resultSet, 0, 0));
      PQclear(resultSet);
      resultSet = NULL;
   } else {
      errorMessage = [self errorMessage];
      [NSException raise:EODatabaseException format:@"Unable to fetch next primary key value for entity \"%@\": %@", [entity externalName], errorMessage];
   }

	keys = [NSMutableArray array];
	name = [[entity primaryKeyAttributeNames] objectAtIndex:0];
   for (x = 0; x < count; x++) {
		[keys addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithLongLong:value + x] forKey:name]];
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

- (NSArray *)describeTableNames
{
	NSMutableArray		*tableNames = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];
	NSDictionary		*row;
	EOSQLExpression	*expression;
	
	expression = [[[[[self adaptorContext] adaptor] expressionClass] alloc] init];
	[expression setStatement:@"SELECT c.oid AS tableoid, n.nspname AS schemaname, c.relname AS tablename, pg_get_userbyid(c.relowner) AS tableowner, c.relhasindex AS hasindexes, c.relhasrules AS hasrules, (c.reltriggers > 0) AS hastriggers FROM (pg_class c LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace))) WHERE ((c.relkind = 'r'::\"char\") OR (c.relkind = 's'::\"char\"))"];
	
	NS_DURING
		[self evaluateExpression:expression];
	NS_HANDLER
		[expression release];
		[localException raise];
	NS_ENDHANDLER
	[expression release];
	
	while ((row = [self fetchRowWithZone:NULL]) != nil) {
		NSString		*schema = [row objectForKey:@"schemaname"];
		NSString		*table = [row objectForKey:@"tablename"];
		
		if ([schema isEqualToString:@"public"] &&
			 !([table caseInsensitiveCompare:@"EO_pk_table"] == NSOrderedSame ||
				[table caseInsensitiveCompare:@"eo_pk_table"] == NSOrderedSame)) {
			[tableNames addObject:table];
		}
	}
	
	return tableNames;
}

- (EOEntity *)_createEntityForTableNamed:(NSString *)name
{
	NSDictionary		*row;
	EOSQLExpression	*expression;
    EOEntity		*entity;

	expression = [[[[[self adaptorContext] adaptor] expressionClass] alloc] init];
	[expression setStatement:EOFormat(@"SELECT c.oid AS tableoid, n.nspname AS schemaname, c.relname AS tablename, pg_get_userbyid(c.relowner) AS tableowner, c.relhasindex AS hasindexes, c.relhasrules AS hasrules, (c.reltriggers > 0) AS hastriggers FROM (pg_class c LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace))) WHERE ((c.relkind = 'r'::\"char\") OR (c.relkind = 's'::\"char\")) AND (c.relname = '%@' AND n.nspname = 'public')", name)];
	[self evaluateExpression:expression];
	row = [self fetchRowWithZone:NULL];
	[self cancelFetch];
    entity = nil;
	
	if (row) {
		int			oid = [[row objectForKey:@"tableoid"] intValue];
		
		[expression setStatement:EOFormat(@"SELECT attnum, attname, atttypmod, attstattarget, attnotnull, atthasdef, attisdropped, attislocal, pg_catalog.format_type(atttypid,atttypmod) as atttypname from pg_catalog.pg_attribute a where attrelid = '%d'::pg_catalog.oid and attnum > 0::pg_catalog.int2 order by attrelid, attnum;", oid)];
		
		entity = [[EOEntity allocWithZone:[self zone]] init];
		[entity setName:name];
		[entity beautifyName];
		[entity setExternalName:name];
		[entity setClassName:@"EOGenericRecord"];
			
		[self evaluateExpression:expression];
		while ((row = [self fetchRowWithZone:NULL]) != nil) {
			EOAttribute		*attribute = [[EOAttribute allocWithZone:[self zone]] init];
			NSString			*type;
			
			[attribute setName:[row objectForKey:@"attname"]];
			[attribute beautifyName];
			[attribute setColumnName:[row objectForKey:@"attname"]];
			[attribute setAllowsNull:![[row objectForKey:@"attnotnull"] boolValue]];

			type = [row objectForKey:@"atttypname"];
			
			if ([type isEqualToString:@"integer"]) {
				[attribute setExternalType:@"int4"];
				[attribute setValueClassName:@"NSNumber"];
				[attribute setValueType:@"i"];
			} else if ([type isEqualToString:@"bigint"]) {
				[attribute setExternalType:@"int8"];
				[attribute setValueClassName:@"NSNumber"];
				[attribute setValueType:@"i"];
			} else if ([type isEqualToString:@"timestamp with time zone"]) {
				[attribute setExternalType:@"timestamptz"];
				[attribute setValueClassName:@"NSDate"];
			} else if ([type isEqualToString:@"date"]) {
				[attribute setExternalType:@"date"];
				[attribute setValueClassName:@"NSDate"];
			} else if ([type hasPrefix:@"character varying"]) {
				[attribute setExternalType:@"varchar"];
				[attribute setValueClassName:@"NSString"];
                if([type length] > 18) // (stephane@sente.ch) Length might be ommitted
                    [attribute setWidth:[[type substringFromIndex:18] intValue]];
			} else if ([type hasPrefix:@"boolean"]) {
				[attribute setExternalType:@"bool"];
				[attribute setValueClassName:@"NSNumber"];
				[attribute setValueType:@"c"];
			} else if ([type hasPrefix:@"money"]) {
				[attribute setExternalType:@"money"];
				[attribute setValueClassName:@"NSDecimalNumber"];
				[attribute setScale:10];
				[attribute setPrecision:2];
			} else if ([type hasPrefix:@"real"]) {
				[attribute setExternalType:@"float4"];
				[attribute setValueClassName:@"NSNumber"];
				[attribute setValueType:@"f"];
			} else if ([type hasPrefix:@"double precision"]) {
				[attribute setExternalType:@"float8"];
				[attribute setValueClassName:@"NSNumber"];
				[attribute setValueType:@"d"];
			} else if ([type hasPrefix:@"smallint"]) {
				[attribute setExternalType:@"int2"];
				[attribute setValueClassName:@"NSNumber"];
				[attribute setValueType:@"i"];
			} else if ([type hasPrefix:@"text"]) {
				[attribute setExternalType:@"text"];
				[attribute setValueClassName:@"NSString"];
			} else if ([type hasPrefix:@"character"]) {
				[attribute setExternalType:@"char"];
				[attribute setValueClassName:@"NSString"];
				[attribute setWidth:[[type substringFromIndex:10] intValue]];
			} else if ([type hasPrefix:@"numeric"] || [type hasPrefix:@"decimal"]) {
				NSRange	range = [type rangeOfString:@"("];
				int		scale = 0, precision = 0;
				
				if (range.location != NSNotFound) {
					NSArray *parts = [[type substringFromIndex:range.location + range.length] componentsSeparatedByString:@","];
					precision = [[parts objectAtIndex:0] intValue];
					if ([parts count] > 1) {
						scale = [[parts objectAtIndex:1] intValue];
					}
				}
				
				[attribute setExternalType:@"numeric"];
				[attribute setPrecision:precision];
				[attribute setScale:scale];
				if (scale == 0 && precision < 10) {
					[attribute setValueClassName:@"NSNumber"];
					[attribute setValueType:@"i"];
				} else if (scale == 0 && precision < 20) {
					[attribute setValueClassName:@"NSNumber"];
					[attribute setValueType:@"q"];
				} else {
					[attribute setValueClassName:@"NSDecimalNumber"];
				}
			} else {
				[EOLog logWarningWithFormat:@"Unknown type: %@\n", type];
			}
			
			[entity addAttribute:attribute];
			[attribute release];
		}
		
		[entity setClassProperties:[entity attributes]];
		[entity setAttributesUsedForLocking:[entity attributes]];
	}
    [expression release];
	
    if (entity)
    {
        if ([[entity attributes] count] == 0)
        {
            [entity release];
            entity = nil;
        }
    }
	return [entity autorelease];
}

- (EOModel *)describeModelWithTableNames:(NSArray *)tableNames
{
	EOModel		*model;
	int			x;
	int numTableNames;
	NSString		*EOName;
	
	model = [[EOModel allocWithZone:[self zone]] init];
	EOName = [[[[self adaptorContext] adaptor] connectionDictionary] objectForKey:@"databaseName"];
	if (EOName == nil) EOName = NSUserName();
	[model setName:EOName];
	[model setAdaptorName:[[[self adaptorContext] adaptor] name]];
	[model setConnectionDictionary:[[[self adaptorContext] adaptor] connectionDictionary]];
	
	numTableNames = [tableNames count];
	for (x = 0; x < numTableNames; x++) {
		NSString		*tableName = [tableNames objectAtIndex:x];
		EOEntity		*entity;
		
		entity = [self _createEntityForTableNamed:tableName];
		if (entity) {
			[model addEntity:entity];
		}
	}
	
	return [model autorelease];
}

// mont_rothstein @ yahoo.com 2004-12-03
// Store the stored procedure results so they can be grabbed latter via returnValuesForLastStoredProcedureInvocation.
/*! @todo This needs to be made compliant with the WO 4.5 spec.  It currently ignores IN/OUT arguments and OUT arguments.  If there are multiple results it assumes they are a set of single values, and not rows. */
- (void)_storeStoredProcedureResults
{
	int numTuples;
	
	[storedProcedureResults release];
	numTuples = PQntuples(resultSet);
	
	if (rowsFetched < numTuples) {
		storedProcedureResults = [[NSMutableDictionary allocWithZone: [self zone]] init];
		
		if ([fetchAttributes count]) {
			if (numTuples > 1)
			{
				NSMutableArray *results;
				int index;
				id resultValue;
				
				results = [[NSMutableArray alloc] init];
				
				for (index = 0; index < numTuples; index++)
				{
					// mont_rothstein @ yahoo.com 2005-03-24
					// Modified to handle NULL in returned data set
					resultValue = [[self fetchRowWithZone: NULL] 
							objectForKey: [[fetchAttributes objectAtIndex: 0] name]];
					
					if (resultValue) [results addObject: resultValue];
				}
				
				[storedProcedureResults setValue:results forKey: @"returnValue"];
                [results release];
			}
			else
			{
				[storedProcedureResults setValue:[self valueForResultAtIndex:0] forKey: @"returnValue"];
			}
		}
	} else {
		storedProcedureResults = nil;
	}
}


- (void)executeStoredProcedure:(EOStoredProcedure *)storedProcedure withValues:(NSDictionary *)values
{
	EOSQLExpression	*expression;
	
	expression = [[PostgreSQLExpression allocWithZone:[self zone]] init];
	[expression prepareStoredProcedure:storedProcedure withValues:values];
	
	NS_DURING
		[self evaluateExpression:expression];
		// mont_rothsein @ yahoo.com 2004-12-03
		// Added this to store the results so they can be retrieved later.
		[self _storeStoredProcedureResults];
	NS_HANDLER
		[expression release];
		[localException raise];
	NS_ENDHANDLER
	
	// Evaluate starts a whole fetch cycle, so stop it from progressing.
	[self cancelFetch];
	
	[expression release];
}

- (NSArray *)describeResults
{
	return fetchAttributes;
}


// mont_rothstein @ yahoo.com 2004-12-03
// Added for handling stored procedures.
- (NSDictionary *)returnValuesForLastStoredProcedureInvocation
{
	return storedProcedureResults;
}

@end
