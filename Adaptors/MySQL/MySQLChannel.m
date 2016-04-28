//
//  MySQLChannel.m
//  Adaptors
//
//  Created by Tom Martin on 9/12/15.
//
//

#import "MySQLChannel.h"
#import "MySQLAdaptor.h"
#import "MySQLBindInfo.h"

@implementation MySQLChannel

- (int)rowsAffected { return rowsAffected; }

//=========================================================================================
//            Private Methods
//=========================================================================================

//---(Private)--- Return the Oracle Adaptor -------------------------
- (MySQLAdaptor *)mysqlAdaptor
{
    return (MySQLAdaptor *)[adaptorContext adaptor];
}

- (NSString *)checkStatus
{
    NSString *result = nil;
    const char *str;
    if(! mysql_stmt_errno(stmt))
    {
        str = mysql_stmt_error(stmt);
        result = [NSString stringWithUTF8String:str];
        NSException *ouch;
        ouch = [[NSException alloc] initWithName:@"EOGeneralAdaptorException" reason:result userInfo:nil];
        [ouch raise];
    }
    
    return result;
}

- (NSString *)fieldTypeNameForTypeValue:(int)value isBinary:(BOOL)isBinary
{
    /*
     For Reference these are ALL the types in the enum
     I only deal with the types that are returned by the fun
     mysql_fetch_field which is apparently a subset of the complete set.
     
     I think it does some kind of conversion. For instance there is a BOOL
     type, and BOOL is equivilent to TINYINT(1), so more than likely thats 
     what it returns.
     
     NOTE:  VERY VERY IMPORTANT
     THE VARCHAR, CHAR and TEXT type width indicates CHARACTERS not BYTES.  So any
     allocated buffers need to be large enough to store UTF-8 bytes. UTF-8 can take
     up to 4 octets or 4 bytes to describe a character so a COMPLETELY safe buffer
     would be 4 * width.  Just sayin.  That said that is probably over-allocation.
     
     If there is a way to determine byte length BEFORE allocation, that may be the
     way to go, even if it means doing two passes.
     
     And just in case you are wondering UTF-16 is ALSO Multibyte.  There are characters
     that require two bytes in UTF-16 to describe a character, so UTF-16 is NOT mono byte.
     UTF-16 also has endian issues, and typically uses a lot more storage that actually
     needed to represent a string, so while we COULD use UTF-16 for our adaptor
     encodeing it does not really give us any huge advantage because we STILL can not 
     consider it to be mono byte where one unichar equals one character
     
     The following is a listing of all the datatypes
     
     MYSQL_TYPE_DECIMAL,        0
     MYSQL_TYPE_TINY,           1
     MYSQL_TYPE_SHORT,          2
     MYSQL_TYPE_LONG,           3
     MYSQL_TYPE_FLOAT,          4
     MYSQL_TYPE_DOUBLE,         5
     MYSQL_TYPE_NULL,           6
     MYSQL_TYPE_TIMESTAMP,      7
     MYSQL_TYPE_LONGLONG,       8
     MYSQL_TYPE_INT24,          9
     MYSQL_TYPE_DATE,           10
     MYSQL_TYPE_TIME,           11
     MYSQL_TYPE_DATETIME,       12
     MYSQL_TYPE_YEAR,           13
     MYSQL_TYPE_NEWDATE,        14
     MYSQL_TYPE_VARCHAR,        15
     MYSQL_TYPE_BIT,            16
     MYSQL_TYPE_TIMESTAMP2,     17
     MYSQL_TYPE_DATETIME2,      18
     MYSQL_TYPE_TIME2,          19
     MYSQL_TYPE_NEWDECIMAL=246, 246
     MYSQL_TYPE_ENUM=247,       247
     MYSQL_TYPE_SET=248,        248
     MYSQL_TYPE_TINY_BLOB=249,  249
     MYSQL_TYPE_MEDIUM_BLOB=250,250
     MYSQL_TYPE_LONG_BLOB=251,  251
     MYSQL_TYPE_BLOB=252,       252
     MYSQL_TYPE_VAR_STRING=253, 253
     MYSQL_TYPE_STRING=254,     254
     MYSQL_TYPE_GEOMETRY=255    255
    */
    
    NSString *result = nil;
    switch (value)
    {
        case MYSQL_TYPE_TINY:
            result = @"TINYINT";
            break;
        case MYSQL_TYPE_SHORT:
            result = @"SMALLINT";
            break;
        case MYSQL_TYPE_LONG:
            result = @"INTEGER";
            break;
        case MYSQL_TYPE_INT24:
            result = @"MEDIUMINT";
            break;
        case MYSQL_TYPE_LONGLONG:
            result = @"BIGINT";
            break;
        case MYSQL_TYPE_DECIMAL:
            result = @"DECIMAL";
            break;
        case MYSQL_TYPE_NEWDECIMAL:
            result = @"DECIMAL";
            break;
        case MYSQL_TYPE_FLOAT:
            result = @"FLOAT";
            break;
        case MYSQL_TYPE_DOUBLE:
            result = @"DOUBLE";
            break;
        case MYSQL_TYPE_BIT:
            result = @"BIT";
            break;
        case MYSQL_TYPE_TIMESTAMP:
            result = @"TIMESTAMP";
            break;
        case MYSQL_TYPE_DATE:
            result = @"DATE";
            break;
        case MYSQL_TYPE_TIME:
            result = @"TIME";
            break;
        case MYSQL_TYPE_DATETIME:
            result = @"DATETIME";
            break;
        case MYSQL_TYPE_YEAR:
            result = @"YEAR";
            break;
        case MYSQL_TYPE_STRING:
            result = isBinary ? @"BINARY" : @"CHAR";
            break;
        case MYSQL_TYPE_VAR_STRING:
            result = isBinary ? @"VARBINARY" : @"VARCHAR";
            break;
        case MYSQL_TYPE_BLOB:
            result = isBinary ? @"BLOB" : @"TEXT";
            break;
        case MYSQL_TYPE_SET:
            result = @"SET";
            break;
        case MYSQL_TYPE_ENUM:
            result = @"ENUM";
            break;
        case MYSQL_TYPE_NULL:
            result = @"NULL";
            break;
    }
    return result;
}

//---(Private)---- describe bindings for debug logging --------
- (NSString *)bindingsDescription:(NSArray *)b
{
    NSDictionary		*binding;
    id					enumArray = [b objectEnumerator];
    NSMutableString		*result;
    id					v;
    NSString			*str;
    
    result = [@"{" mutableCopy];
    while ((binding = [enumArray nextObject]) != nil)
    {
        [result appendString:(NSString *)[binding objectForKey:EOBindVariableNameKey]];
        [result appendString:@" = "];
        v = [binding objectForKey:EOBindVariableValueKey];
        if ([v isKindOfClass:[NSNumber class]])
            [result appendString:[v description]];
        else
        {
            [result appendString:@"'"];
            // output no more than the first 200 characaters
            str = [v description];
            if ([str length] > 200)
                str = [str substringToIndex:199];
            [result appendString:str];
            [result appendString:@"'"];
        }
        [result appendString:@"; "];
    }
    [result appendString:@"}"];
    
    return [result autorelease];
}

//---(Private)---- create MySQL binds using the expression bind dictionaries
- (void)createBindsForExpression:(EOSQLExpression *)expression
{
    id					bindEnum;
    NSMutableDictionary	*bindDict;
    MySQLBindInfo		*mysqlBindInfo;
    
    if (bindCache)
        [bindCache release];
    bindCache = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:
                 [[expression bindVariableDictionaries] count] + 1];
    
    bindEnum = [[expression bindVariableDictionaries] objectEnumerator];
    while ((bindDict = [bindEnum nextObject]) != nil)
    {
        // associated with every bind is a bindHandle and a lot of info about
        // how to do a bind.  We will wrap all that in an object
        mysqlBindInfo = [[MySQLBindInfo alloc] initWithBindDictionary:bindDict];
        [bindCache addObject:mysqlBindInfo];
        [mysqlBindInfo release];
        [mysqlBindInfo createBindForChannel:self];
    }
}

//=========================================================================================
//            Public (API) Methods
//=========================================================================================

- (id)initWithAdaptorContext:(EOAdaptorContext *)aContext
{
    if (self = [super initWithAdaptorContext:aContext])
    {
     }
    
    return self;
}

- (void)dealloc
{
    if ([self isFetchInProgress]) {
        [self cancelFetch];
    }
    if ([self isOpen]) {
        [self closeChannel];
    }
    
    if (mysql)
        mysql_close(mysql);
    
    [super dealloc];
}

- (void)openChannel
{
    BOOL                okay;
    NSDictionary		*info;
    NSString			*username;
    NSString			*password;
    NSString			*hostname;
    NSString            *databaseName;
    NSString            *protocol;
    int                 mysql_protocol;
    unsigned int		port;
    
    if (connected) {
        [NSException raise:EODatabaseException format:@"EOAdaptorChannel is already open"];
    }
    
    // The connection dictionary is username, password, databaseName, hostname, port protocol.  I am NOT doing URL
    // because it is not typical for mysql, and I see no reason to do it.
    info = [[[self adaptorContext] adaptor] connectionDictionary];
    username = [info objectForKey:@"userName"];
    password = [info objectForKey:@"password"];
    databaseName = [info objectForKey:@"databaseName"];
    hostname = [info objectForKey:@"hostName"];
    protocol = [info objectForKey:@"protocol"];
    // a port of zero is fine.  THat means it will use the default port of 3306.
    port = [[info objectForKey:@"port"] intValue];
    
    if (![hostname length]) hostname = @"localhost";
    if (![username length]) username = NSUserName();
    if (![databaseName length]) databaseName = NSUserName();
    // make sure protocol is set to either TCP or SOCKET
    if (! [protocol length])
    {
        if ([hostname isEqualToString:@"localhost"])
            mysql_protocol = MYSQL_PROTOCOL_SOCKET;
        else
            mysql_protocol = MYSQL_PROTOCOL_TCP;

    }
    else
    {
        if ([protocol isEqualToString:@"SOCKET"])
            mysql_protocol = MYSQL_PROTOCOL_SOCKET;
        else
            mysql_protocol = MYSQL_PROTOCOL_TCP;
    }
    
    if (connected)
        [NSException raise:EODatabaseException format:@"EOAdaptorChannel is already open"];
    
    if ([self isDebugEnabled])
    {
        [EOLog logDebugWithFormat:@"%@ attempting to connect with dictionary:{password = <password deleted for log>; protocol = %@; hostName = %@; port = %d; databaseName = %@; userName = %@;}",
         [self description], protocol, hostname, port, databaseName, username];
    }
    
    // this next step could certainly fail.
    okay = YES;
    NS_DURING
    // I think this should be in the channel, so that we can have one structure per channel.
    // Having multiple channels per mysql is probably okay, having multiple channels in multiple
    // threads sharing the same mysql structure, I'm thinking that is NOT okay.
    mysql = mysql_init(NULL);

    // Autocommit should be disabled so that transactions need to be explicitly commited.
    // a new one always begins after the last is commited.
    mysql_options(mysql,MYSQL_INIT_COMMAND,"SET autocommit=0");
    mysql_options(mysql, MYSQL_OPT_PROTOCOL, &mysql_protocol);
    // we will set the character set to UTF8, we MIGHT want to use UTF16, I'm not certain, it may be faster
    // plus I don't understand yet the relationship betwen the DATABASE character set and the
    // connection character set.
    mysql_options(mysql, MYSQL_SET_CHARSET_NAME, "utf8");
    if (! mysql_real_connect(mysql, [hostname UTF8String], [username UTF8String], [password UTF8String],
                             [databaseName UTF8String] , port, NULL, 0))
        okay = NO;
    NS_HANDLER
    okay = NO;
    if ([self isDebugEnabled])
    {
        [EOLog logDebugWithFormat:@"%@ Failed to connect to MySQL database %@ With status: %s\n",
         [self description], mysql_error(mysql)];
    }
    [localException raise];
    NS_ENDHANDLER
    if (okay == NO)
    {
        if ([self isDebugEnabled])
        {
            [EOLog logDebugWithFormat:@"%@ Failed to connect to MySQL database %@ With status: %s\n",
             [self description], databaseName, mysql_error(mysql)];
        }
        [NSException raise:@"EOGeneralAdaptorException"
                    format:@"%@ Failed to connect to MySQL database %@.\n",
         [self description], databaseName];
    }

    connected = YES;
    
    if ([self isDebugEnabled])
    {
        [EOLog logDebugWithFormat:@"%@ Connected to MySQL database %@\n",
         [self description], databaseName];
    }
}

- (void)closeChannel
{
    if (!connected)
        [NSException raise:EODatabaseException format:@"The database connection has already been closed."];
    
    // shutdown the session
    // I do not think the mysql structure can be re-used if the channel is closed as
    // the connection handle in the structure is freed.
    if (mysql)
    {
        mysql_close(mysql);
        mysql = NULL;
    }

    connected = NO;
    
    if ([self isDebugEnabled]) 
        [EOLog logDebugWithFormat:@"%@ Disconnected from database.\n", 
         [self description]];
}

- (BOOL)isFetchInProgress { return fetchInProgress; }

- (MYSQL *)mysql { return mysql; }

- (NSArray *)describeResults
{
    MYSQL_FIELD         *field;
    BOOL                isBinary;
    BOOL                isUnsigned;
    BOOL                isBlob;
    NSString            *fieldType;
    MYSQL_RES           *fetchResult;
    int                 fieldCount;
    int                 index;
    int					counter;
    EOAttribute			*tempAttribute;
    NSDictionary		*dataTypes;
    NSDictionary		*dataTypeDict;
    NSMutableArray		*rawAttributes;
    NSAutoreleasePool	*pool;
    
    if (! [self isFetchInProgress])
        [NSException raise:EODatabaseException format:@"describeResults called while a fetch was not in progress."];
    
    // regardless of whether of not the fetch attributes have been set
    // we will return what the DATABASE sees ad the restultig attributes
    // in other words we do NOT return fetchAttributes which may be set
    // by setAttributesToFetch, but rather what the AVAILABLE in the resulting
    // fetch.
    
    // We MIGHT already know this if evaluateExpression was called
    if (evaluateAttributes)
        return evaluateAttributes;
    
    rawAttributes = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:30];
    dataTypes = [MySQLAdaptor dataTypes];

    // get the parameters returned.
    counter = 0;
    // get the fetch results from the prepared statement
    // we used prepared statments because ONLY fetches from preparied statements
    // can be cancled.  Also, only prepared statments do binds.
    fetchResult = mysql_stmt_result_metadata(stmt);
    fieldCount = mysql_num_fields(fetchResult);
    field = mysql_fetch_fields(fetchResult);
    for (index = 0; index < fieldCount; ++index)
    {
        pool = [[NSAutoreleasePool alloc] init];
        
        // Build and store the column attribute
        tempAttribute = [[EOAttribute alloc] init];
        
        [tempAttribute setName:[NSString stringWithFormat:@"Attribute%d", counter - 1]];
        [tempAttribute setColumnName:[NSString stringWithUTF8String:field->name]];
        [tempAttribute setAllowsNull:(field->flags & NOT_NULL_FLAG) ? NO : YES];
        isBinary = (field->flags & BINARY_FLAG) ? YES : NO;
        isUnsigned = (field->flags & UNSIGNED_FLAG) ? YES : NO;
        isBlob = (field->flags & BLOB_FLAG) ? YES : NO;
        fieldType = [self fieldTypeNameForTypeValue:field->type isBinary:isBinary];
        
        // NEED WIDTH!!!!
        // Look up the datatype and map it appropriately, but if we don't recognize the data type,
        // we can still treat as a string.
        if (fieldType)
            dataTypeDict = [dataTypes objectForKey:fieldType];
        else
            dataTypeDict = nil;
        if (dataTypeDict)
        {
            if ([dataTypeDict objectForKey:@"useWidth"])
            {
                [tempAttribute setWidth:(int)field->length];
            }
            [tempAttribute setValueClassName:[dataTypeDict objectForKey:@"valueClassName"]];
            [tempAttribute setExternalType:fieldType];
            [tempAttribute setValueType:[dataTypeDict objectForKey:@"valueType"]];
            if (field->type == MYSQL_TYPE_DECIMAL)
            {
                // There does not seem to be any way to get precision and scale for
                // the DECIMAL type.  But MAYBE, just MAYBE precision is length
                // and scale is 'decimals' ??
                if (field->length)
                {
                    [tempAttribute setPrecision:(int)field->length];
                    if (field->decimals)
                        [tempAttribute setScale:(int)field->decimals];
                }
            }
        }
        else 
        {
            [EOLog logWarningWithFormat:@"Unknown data type for %@: %d  We treat it like a string with no width\n", [tempAttribute name], field->type];
            [tempAttribute setValueClassName:@"NSString"];
            [tempAttribute setExternalType:@"VARCHAR"];
            [tempAttribute setValueType:@"s"];
        }
        
        if (tempAttribute)
        {
            [rawAttributes addObject:tempAttribute];
            [tempAttribute release];
        }
        
        // get the next param
        ++counter;
        ++field;
        [pool release];
    }
    
    return [rawAttributes autorelease];
}

- (void)evaluateExpression:(EOSQLExpression *)expression
{
    NSUInteger	rowCount;
    NSString	*sqlString;
    NSUInteger	len;
    NSUInteger	iterations;
    const char   *statement;
    
    if (!connected)
        [NSException raise:EODatabaseException format:@"The database is not connected durring an evaluateExpression:."];
    
    if ([self isFetchInProgress])
        [NSException raise:EODatabaseException format:@"fetch in progress when evaluateExpression: called."];
    
    sqlString = [[expression statement] retain];
    if ([self isDebugEnabled])
    {
        if ([[expression bindVariableDictionaries] count] > 0)
            [EOLog logDebugWithFormat:@"%@ evaluateExpression: %@ With bindings:%@", [self description], sqlString,
             [self bindingsDescription:[expression bindVariableDictionaries]]];
        else
            [EOLog logDebugWithFormat:@"%@ evaluateExpression: %@", [self description], sqlString];
    }
    
    // Check with our delegate
    if (_delegateRespondsTo.shouldEvaluateExpression)
    {
        if (![delegate adaptorChannel:self shouldEvaluateExpression:expression])
        {
            if ([self isDebugEnabled])
                [EOLog logDebugWithFormat:@"AdaptorChannel delegate responded 'NO' to shouldEvaluateExpression"];
            return;
        }
    }
    
    if (stmt)
    {
        if (mysql_stmt_close(stmt))
            [self checkStatus];
        stmt = NULL;
    }
    stmt = mysql_stmt_init(mysql);
    if (!stmt)
        [NSException raise:EODatabaseException format:@"Out of memory creating MySQL statement"];

    // if we are not in a transaction, then we need to create one and then END the transaction
    // once we are done with the statement or the fetch.
    if (! [adaptorContext hasOpenTransaction])
    {
        localTransaction = YES;
        [adaptorContext beginTransaction]; // which actually does nothing, but still ..
    }
    else
        localTransaction = NO;
    
    // If we have binds, then do that now as this has to be done BEFORE
    // the prepare.
    if ([[expression bindVariableDictionaries] count] > 0)
        [self createBindsForExpression:expression];  // okay to raise - will call cancel fetch

    // prepare the SQL statement
    // convert the NSString into UTF8.
    statement = [sqlString UTF8String];
    len = strlen(statement);
    
    if (mysql_stmt_prepare(stmt, statement, len))
    {
        [NSException raise:EODatabaseException format:@"mysql_stmt_prepare() failed. %s",
         mysql_stmt_error(stmt)];
    }
    [self checkStatus]; // okay to raise
    
    
    // find out what kind of statement this is.
    OCIAttrGet(stmthp, OCI_HTYPE_STMT, (dvoid *)&commandType, NULL, OCI_ATTR_STMT_TYPE, errhp);
    iterations = 1;
    if (commandType == OCI_STMT_SELECT)
    {
        // we are doing a fetch
        fetchInProgress = YES;
        iterations = 0;
    }
    
    // execute the SQL
    status = OCIStmtExecute([(OracleContext *)adaptorContext serviceContexthp], stmthp, errhp, iterations, 0,
                            (OCISnapshot *)0, (OCISnapshot *)0, OCI_DEFAULT);
    
    NS_DURING
    [self checkStatus];
    NS_HANDLER
    [self cancelFetch];
    [localException raise];
    NS_ENDHANDLER
    
    if (! fetchInProgress)
    {
        // mont_rothstein @ yahoo.com 2005-06-26
        // Set number of rows affected by the expression so that it can be used to determine if the expression
        // evaluated successfully.
        // Tom.Martin @ Riemer.com 2010-01-21
        // This should work for update, delete, but probably not for select ...
        // For that I am thinking that I will need to update it it with every call to fetch as it will
        // return whatever is in the buffer.
        status = OCIAttrGet((dvoid *)stmthp, (ub4)OCI_HTYPE_STMT,
                            (dvoid *)&rowCount, (ub4 *)0, (ub4)OCI_ATTR_ROW_COUNT, errhp);
        rowsAffected = rowCount;
        if ([self isDebugEnabled])
            [EOLog logDebugWithFormat:@"%@ %d rows processed", [self description], rowsAffected];
        
        // this is not a fetch.  if a local transaction is in progress, then end it
        if (localTransaction)
        {
            [adaptorContext commitTransaction];
            localTransaction = NO;
        }
    }
    else
    {
        rowsAffected = 0;
        // If we are doing a select then we need attributes
        // get our attributes so that we can support someone setting attributesToFetch other than
        // the attributes ACTUALLY fetched
        // This HAS to be a non mutable array so that it we can check to see if 
        // fetchAttributes == evaluateAttributes
        // if fetchAttributes is already set, then these are the attributes
        if (! evaluateAttributes)
            evaluateAttributes = [[NSArray allocWithZone:[self zone]] initWithArray:[self describeResults]];
    }
    
    // Notify our delegate
    if (_delegateRespondsTo.didEvaluateExpression)
        [delegate adaptorChannel:self didEvaluateExpression:expression];
}

@end
