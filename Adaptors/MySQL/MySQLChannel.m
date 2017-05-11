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
#import "MySQLDefineInfo.h"

@implementation MySQLChannel

- (unsigned int)rowsAffected { return (unsigned int)rowsAffected; }

//=========================================================================================
//            Private Methods
//=========================================================================================

//---(Private)--- Return the MySQL Adaptor -------------------------
- (MySQLAdaptor *)mysqlAdaptor
{
    return (MySQLAdaptor *)[adaptorContext adaptor];
}

- (NSString *)checkStatus
{
    NSString *result = nil;
    const char *str;
    // we might call checkStatus after a cancel fetch. it is easier just to blow pase the check here than to deal with
    // calling or not calling check status after a cancel.ß
    if (stmt)
    {
        if(mysql_stmt_errno(stmt))
        {
            str = mysql_stmt_error(stmt);
            result = [NSString stringWithUTF8String:str];
            NSException *ouch;
            ouch = [[NSException alloc] initWithName:@"EOGeneralAdaptorException" reason:result userInfo:nil];
            [ouch raise];
        }
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
            result = @"INT";
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

//---(Private)--- find the attribute in the evaluateAttributes by attempting to match the column names
- (unsigned int)indexOfAttribute:(EOAttribute *)attrib
{
    EOAttribute     *anAttrib;
    unsigned int	result, index;
    BOOL            found;
    
    index = 0;
    result = 0;
    found = NO;
    for (anAttrib in evaluateAttributes)
    {
        if ([[anAttrib columnName] caseInsensitiveCompare:[attrib columnName]] == NSOrderedSame)
        {
            result = index;
            found = YES;
            break;
        }
        ++index;
    }
    if (! found)
    {
        // We are going to raise here.  I don't know what else to do.
        [NSException raise:EODatabaseException format:@"fetchRowWithZone: could not find attribute with column name %@ among fetched attributes.",
         [attrib columnName]];
    }
    return result;
}

//---(Private)---- describe bindings for debug logging --------
- (NSString *)bindingsDescription:(NSArray *)b
{
    NSDictionary		*binding;
    NSMutableString		*result;
    id					v;
    NSString			*str;
    
    result = [@"{" mutableCopy];
    for (binding in b)
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
    NSMutableDictionary	*bindDict;
    MySQLBindInfo		*mysqlBindInfo;
    int                 index;
    
    if (bindCache)
        [bindCache release];
    bindCount = (int)[[expression bindVariableDictionaries] count];
    bindCache = [[NSMutableArray alloc] initWithCapacity:bindCount];
    bindArray = calloc(bindCount, sizeof(MYSQL_BIND));
    index = 0;
    for (bindDict in [expression bindVariableDictionaries])
    {
        // associated with every bind is a bindHandle and a lot of info about
        // how to do a bind.  We will wrap all that in an object
        mysqlBindInfo = [[MySQLBindInfo alloc] initWithBindDictionary:bindDict mysqlBind:&(bindArray[index])];
        [bindCache addObject:mysqlBindInfo];
        [mysqlBindInfo release];
        ++index;
    }
    mysql_stmt_bind_param(stmt, bindArray);
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
    // BOOL                isBlob;
    NSString            *fieldType;
    NSString            *valueType;
    MYSQL_RES           *fetchResult;
    int                 fieldCount;
    int                 index;
    int					counter;
    EOAttribute			*tempAttribute;
    NSDictionary		*dataTypes;
    NSDictionary		*dataTypeDict;
    NSMutableArray		*rawAttributes;
    
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
    // can be canceled.  Also, only prepared statments do binds.
    fetchResult = mysql_stmt_result_metadata(stmt);
    fieldCount = mysql_num_fields(fetchResult);
    field = mysql_fetch_fields(fetchResult);
    for (index = 0; index < fieldCount; ++index)
    {
        @autoreleasepool
        {
            // Build and store the column attribute
            tempAttribute = [[EOAttribute alloc] init];
            
            [tempAttribute setName:[NSString stringWithFormat:@"Attribute%d", counter]];
            [tempAttribute setColumnName:[NSString stringWithUTF8String:field->name]];
            [tempAttribute setAllowsNull:(field->flags & NOT_NULL_FLAG) ? NO : YES];
            isBinary = (field->flags & BINARY_FLAG) ? YES : NO;
            isUnsigned = (field->flags & UNSIGNED_FLAG) ? YES : NO;
            // isBlob = (field->flags & BLOB_FLAG) ? YES : NO;
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
                    if (isBinary)
                        [tempAttribute setWidth:(int)field->length];
                    else
                        // MySQL returns the maximum length in bytes. According to the documentation
                        // if the character set is UTF-8 then the maximum length is the number of characters * 3
                        // which is actually wrong since UTF-8 can have a maximum length of 4 bytes, but
                        // we use what MySQL does.
                        [tempAttribute setWidth:(int)(field->length / 3)];
                }
                [tempAttribute setValueClassName:[dataTypeDict objectForKey:@"valueClassName"]];
                [tempAttribute setExternalType:fieldType];
                valueType = [dataTypeDict objectForKey:@"valueType"];
                if (valueType)
                {
                    // convert to uppercase if this is unsigned.  So c->C, i->I, q-Q etc
                    if (isUnsigned)
                        valueType = [valueType uppercaseString];
                    [tempAttribute setValueType:valueType];
                }
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

        }
    }
    
    return [rawAttributes autorelease];
}

- (void)evaluateExpression:(EOSQLExpression *)expression
{
    NSString	*sqlString;
    NSUInteger	len;
    const char   *statement;
    MYSQL_RES   *res;

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
    
    // stmt should not really be set, but if cancel was never called for some reason
    // it COULD be set.  There is no harm in that, we will simply check now
    if (stmt)
    {
        if (mysql_stmt_close(stmt))
            [self checkStatus];
        stmt = NULL;
    }
    
    stmt = mysql_stmt_init(mysql);
    if (!stmt)
        [NSException raise:EODatabaseException format:@"Out of memory creating MySQL statement"];
    
    // In order for the field info max_length to get set we need to tell it to update that.
    // As far as I can tell this is the ONLY way to get the length for a blob or clob otherwise
    // you would need to allocate buffers for the largest possible size which is crazy crazy.
    //
    // aBool = 1;
    // mysql_stmt_attr_set(stmt, STMT_ATTR_UPDATE_MAX_LENGTH, (void*) &aBool);
    //
    // Okay we are NOT going to do it this way.  Apparently this incurres a big performance hit.
    // There is ANOTHER way to get the length.
    //
    // Invoke mysql_stmt_fetch() with a zero-length buffer for the column in question and a
    // pointer in which the real length can be stored. Then use the real length with
    // mysql_stmt_fetch_column().
    /*
     real_length= 0;
     
     bind[0].buffer= 0;
     bind[0].buffer_length= 0;
     bind[0].length= &real_length
     mysql_stmt_bind_result(stmt, bind);
     
     mysql_stmt_fetch(stmt);
     if (real_length > 0)
     {
     data= malloc(real_length);
     bind[0].buffer= data;
     bind[0].buffer_length= real_length;
     mysql_stmt_fetch_column(stmt, bind, 0, 0);
     }
    */
    
    // if we are not in a transaction, then we need to create one and then END the transaction
    // once we are done with the statement or the fetch.
    if (! [adaptorContext hasOpenTransaction])
    {
        localTransaction = YES;
        [adaptorContext beginTransaction]; // which actually does nothing, but still ..
    }
    else
        localTransaction = NO;
    
    
    // okay to raise - will call cancel fetch

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
    [sqlString autorelease];
    
    // If we have binds, then do that now as this has to be done AFTER
    // the prepare.
    if ([[expression bindVariableDictionaries] count] > 0)
    {
        [self createBindsForExpression:expression];
        // now that the bind array is set do the bind.
        mysql_stmt_bind_param(stmt, bindArray);
    }
    
    // execute the SQL
    mysql_stmt_execute(stmt);
    NS_DURING
    [self checkStatus];
    NS_HANDLER
    [self cancelFetch];
    [localException raise];
    NS_ENDHANDLER
    
    /*
    // at this point I think we could release the bindCache.
    [bindCache release];
    bindCache = nil;
    if (bindArray)
    {
        free(bindArray);
        bindArray = NULL;
    }
     */

    // find out what kind of statement this is.
    // it is possible that this will return a valid result
    // BEFORE the statement is executed, but I am not sure.
    res = mysql_stmt_result_metadata(stmt);
    if (res)
    {
        // we are doing a fetch
        fetchInProgress = YES;
        mysql_free_result(res);
        res = NULL;
    }
    
    NS_DURING
    [self checkStatus];
    NS_HANDLER
    [self cancelFetch];
    [localException raise];
    NS_ENDHANDLER
    
    if (! fetchInProgress)
    {
        // This should work for update, delete, but probably not for select ...
        // For that I am thinking that I will need to update it it with every call to fetch as it will
        // return whatever is in the buffer.
        rowsAffected = mysql_stmt_affected_rows(stmt);
         if ([self isDebugEnabled])
            [EOLog logDebugWithFormat:@"%@ %ld rows processed", [self description], (long)rowsAffected];
        
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
    
    // at this point I think we could release the bindCache.
    [bindCache release];
    bindCache = nil;
    if (bindArray)
    {
        free(bindArray);
        bindArray = NULL;
    }
    
    // Notify our delegate
    if (_delegateRespondsTo.didEvaluateExpression)
        [delegate adaptorChannel:self didEvaluateExpression:expression];
}

- (void)selectAttributes:(NSArray *)attributes fetchSpecification:(EOFetchSpecification *)fetch lock:(BOOL)lock entity:(EOEntity *)entity
{
    EOSQLExpression		*expression;
    
    if ([self isFetchInProgress])
        [NSException raise:EODatabaseException format:@"Attempt to select objects while a fetch was already in progress."];
    if (! [self isOpen])
        [NSException raise:EODatabaseException format:@"Attempt to select attributes on an unopened adaptor channel (%p).", self];
    
    fetchEntity = [entity retain];
    
    if ([attributes count] == 0)
        attributes = [fetchEntity attributes];
    // Make sure this won't change on us. Otherwise we'd get some really strange errors.
    fetchAttributes = [attributes mutableCopyWithZone:[self zone]];
    // by setting evaluateAttributes to fetchAttributes we are telling evaluateExpression that it does not
    // NEED to call describe results to describe the result set.  IF then subsequently fetchAttributes
    // is not reset by a call to setAttributesToFetch:, then fethAttributes will equal
    //  evaluateAttributes and finding the attributes by possition is extremely easy.  No lookup need
    // to be performed.
    evaluateAttributes = [fetchAttributes retain];

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
        [self evaluateExpression: expression];
    }
    NS_HANDLER
    {
        [expression release];
        [self cancelFetch];
        [localException raise];
    }
    NS_ENDHANDLER
    
    [expression release]; // We're now done with the expression.   
}

- (NSMutableDictionary *)fetchRowWithZone:(NSZone *)aZone
{
    NSMutableDictionary		*row;
    EOAttribute				*attrib;
    MySQLDefineInfo         *defineInfo;
    BOOL					mustFindPosition;
    unsigned int			attribIndex;
    
    if (! [self isFetchInProgress])
        [NSException raise:EODatabaseException format:@"fetchRowWithZone: called while a fetch was not in progress."];
    
    if (! [fetchAttributes count])
        [NSException raise:EODatabaseException format:@"fetchRowWithZone: called with no fetch attributes set.."];
    
    if (! defineCache)
    {
        // before we do our fetch we need to set up all our defines
        // There are two different situations that must be handled in different ways...
        // if the fetch is a result of evaluateExpression:, then there is no guarantee that there is
        // a one to one relationship between the order and number of attributes and the order and
        // number of attributes returned.  In this case we must try to match the attribute to the
        // COLUMN name and hope that all works out.
        //
        // If the fetch is a result of selectAttributes:fetchSpecification:lock:entity,
        // then there IS a one to one coralation between the attributes array and the
        // attributes that are feteched and we CAN rely upon the index value.
        //
        // The valueForAttribute:atIndex:inZone: blindly gets the value at the index supplied
        // so IF the fetch is a result of evaluateExpression we will attempt to determine
        // the index of the returned attribute before calling the method..  The way we will
        // do this is by comparing the current Attributes to the attributes generated
        // during evaluate (describeResults).  If the current attributes is exactly the
        // same array, then there is no need to translate.  If it is different then we will
        // need to find the index.
        mustFindPosition = NO;
        if (evaluateAttributes)
        {
            // there is a VERY good chance that the fetchAttributes array is
            // the SAME array as that returned by describeResults in which
            // case there is nothing we need to do
            if (evaluateAttributes != fetchAttributes)
                mustFindPosition = YES;  // darn
        }
        // else evaluateExpression: was not called
        
        // we need to create a define for every attribute in fetchAttributes
        defineCache = [[NSMutableArray allocWithZone:aZone] initWithCapacity:[fetchAttributes count]];
        bindArray = calloc([fetchAttributes count], sizeof(MYSQL_BIND));
        attribIndex = 0;
        for (attrib in fetchAttributes)
        {
            @autoreleasepool
            {
                defineInfo = [[MySQLDefineInfo alloc] initWithAttribute:attrib channel:self];
                if (mustFindPosition)
                {
                    attribIndex = [self indexOfAttribute:attrib];  // this can raise if it can not identify the attribute
                    [defineInfo setBindIndex:attribIndex];
                }
                else
                    [defineInfo setBindIndex:attribIndex++];
                [defineCache addObject:defineInfo];
                [defineInfo release];
            }
        }
        // do the bind
        mysql_stmt_bind_result(stmt, bindArray);
        NS_DURING
        [self checkStatus];
        NS_HANDLER
        [self cancelFetch];
        [localException raise];
        NS_ENDHANDLER        
    }
    
    // check the status
    if (mysql_stmt_fetch(stmt) == MYSQL_NO_DATA)
    {
        // we are done
        fetchInProgress = NO;
        // if we are in a local transaction, commit it
        if (localTransaction)
        {
            [adaptorContext commitTransaction];
            localTransaction = NO;
        }
        [self cancelFetch];
    }
    
    NS_DURING
    [self checkStatus];
    NS_HANDLER
    [self cancelFetch];
    [localException raise];
    NS_ENDHANDLER	
    
    if (fetchInProgress)
    {	
        ++rowsAffected;
        row = [[NSMutableDictionary allocWithZone:aZone] initWithCapacity:[fetchAttributes count]];
        for (defineInfo in defineCache)
        {
            @autoreleasepool
            {
                [row setValue:[defineInfo objectValue]
                       forKey:[[defineInfo attribute] name]];
            }
        }
    }
    else
        row = nil;
    
    return [row autorelease];
}

- (void)cancelFetch
{
    // clear attributes if any
    [fetchAttributes release];
    fetchAttributes = nil;
    
    [evaluateAttributes release];
    evaluateAttributes = nil;
    
    // clear our define cache
    [defineCache release];
    defineCache = nil;
    
    [bindCache release];
    bindCache = nil;
    if (bindArray)
    {
        free(bindArray);
        bindArray = NULL;
    }
    
    // if a fetch is in progress cancel it.
    if (fetchInProgress)
    {
        fetchInProgress = NO;
        if ([self isDebugEnabled])
            [EOLog logDebugWithFormat:@"%@ %d rows processed", [self description], rowsAffected];
        
        // free the result set
        mysql_stmt_free_result(stmt);
    }
    
    // if we are in a local transaction roll it back
    // if we are in a transaction but it is not local, then I figure it is the callers
    // responsibility to decide if the transaction needs to be commited, rolled back,
    // or just continue on.
    if (localTransaction)
    {
        [adaptorContext commitTransaction];
        localTransaction = NO;
    }
    
    if (stmt)
    {
        if (mysql_stmt_close(stmt))
            [self checkStatus];
        stmt = NULL;
    }
}

- (unsigned int)updateValues:(NSDictionary *)row inRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
    EOSQLExpression     *expression;
    
    expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
    [expression setUseAliases:NO];
    [expression prepareUpdateExpressionWithRow:row qualifier:qualifier];
    
    NS_DURING
	   [self evaluateExpression: expression];
    NS_HANDLER
	   [expression autorelease];
       [self cancelFetch];
	   [localException raise];
    NS_ENDHANDLER
    
    // Evaluate starts a whole fetch cycle, so stop it from progressing.
    [self cancelFetch];
    
    [expression release];
    
    return (unsigned int)rowsAffected;
}

- (void)insertRow:(NSDictionary *)row forEntity:(EOEntity *)entity;
{
    EOSQLExpression     *expression;
    
    expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
    [expression setUseAliases:NO];
    [expression prepareInsertExpressionWithRow:row];
    
    NS_DURING
	   [self evaluateExpression: expression];
    NS_HANDLER
	   [expression autorelease];
       [self cancelFetch];
	   [localException raise];
    NS_ENDHANDLER
    
    // Evaluate starts a whole fetch cycle, so stop it from progressing.
    [self cancelFetch];
    
    [expression release];
}

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
       [self cancelFetch];
	   [localException raise];
    NS_ENDHANDLER
    
    // mont_rothstein @ yahoo.com 2005-07-10
    // Added cancelFetch to clean up resources used by evaluateExpression
    // Evaluate starts a whole fetch cycle, so stop it from progressing.
    [self cancelFetch];
    
    [expression release];
    
    return (unsigned int)rowsAffected;
}

- (BOOL)createSequenceTable
{
    BOOL result = YES;
    NSString *sqlString = @"CREATE TABLE `ajr_sequence_data` ( \
    `sequence_name` varchar(100) NOT NULL,\
    `sequence_increment` int(11) unsigned NOT NULL DEFAULT 1,\
    `sequence_min_value` int(11) unsigned NOT NULL DEFAULT 1,\
    `sequence_max_value` bigint(20) unsigned NOT NULL DEFAULT 18446744073709551615,\
    `sequence_cur_value` bigint(20) unsigned DEFAULT 1,\
    `sequence_cycle` boolean NOT NULL DEFAULT FALSE,\
    PRIMARY KEY (`sequence_name`)\
    ) ENGINE=InnoDB";
    // evaluate the SQL and fetch the result
    NS_DURING
    [self evaluateExpression:[[[adaptorContext adaptor] expressionClass] expressionForString:sqlString]];
    [self cancelFetch];
    NS_HANDLER
    result = NO;
    NS_ENDHANDLER
    return result;
}




//-- There is no mechanizim in MySQL for generating a primary key BEFORE the row is
// inserted.  MySQL uses Auto Increment which is quite nice, but that happens
// AFTER the row is inserted and this framework needs the key BEFORE it is
// inserted so that it can be used when child rows are being inserted within
// the same save operation.
//
// Because of all this we will FAKE primary key generation by using a MySQL table
// The sql to GENERATE this table will be stored in the adaptor bundle, but this
// code will not automatically create it.  It is up to the Database administrator
// to create the sequence table.
- (NSArray *)primaryKeysForNewRowsWithEntity:(EOEntity *)entity count:(int)count
{
    NSMutableArray		*keys;
    NSArray				*attribs;
    NSString            *seqName;
    NSString            *cols = @"SEQUENCE_INCREMENT, SEQUENCE_MIN_VALUE, SEQUENCE_MAX_VALUE, SEQUENCE_CUR_VALUE, SEQUENCE_CYCLE";

    int					index;
    NSMutableString		*sql;
    NSNumber			*pk;
    NSDictionary		*row;
    EOSQLExpression     *expression;
    BOOL                pkLocalTransaction;
    unsigned long long  startValue;
    unsigned long long  endValue;
    unsigned long long  maxValue;
    unsigned long long  remaining;
    unsigned long long  key;

    unsigned int        minValue;
    unsigned int        incValue;
    unsigned int        increment;
    int                 cycleValue;
    NSString            *reasonFmt;
    NSNumber            *colValue;
    NSString            *name;
    BOOL                createTable;
    
    createTable = NO;
    reasonFmt = [NSString stringWithFormat:@"Unable to create next primary Key using MySQL Table ajr_sequence_data for entity \"%@\": %%@ Make sure this table Exists!  This must be created manually.  The script for creating this table is in the Database Adaptor bundle resource.", [entity externalName]];

    // if primary key is compond, bail
    attribs = [entity primaryKeyAttributes];
    if ([attribs count] != 1)
        return nil;
    
    // Hopefully the sequence table exists.
    //
    // First select the current sequecne number with a lock
    // we will start a transaction specific to primary key generation
    // if a transaction is not currently in effect that is
    if (! [adaptorContext hasOpenTransaction])
    {
        pkLocalTransaction = YES;
        [adaptorContext beginTransaction]; // which actually does nothing, but still ..
    }
    else
        pkLocalTransaction = NO;
    
    sql = [[NSMutableString alloc] initWithCapacity:200];
    seqName = [[NSString stringWithFormat:@"%@_SEQ", [entity externalName]] retain];

    [sql appendString:@"SELECT "];
    [sql appendString:cols];
    [sql appendString:@" FROM AJR_SEQUENCE_DATA WHERE SEQUENCE_NAME = '"];
    [sql appendString:seqName];
    [sql appendString:@"' FOR UPDATE"];

    expression = [[[[adaptorContext adaptor] expressionClass] expressionForString:sql] retain];

    NS_DURING
    [self evaluateExpression: expression];
    NS_HANDLER
    // This is flaky as hell because the error message could EASILY change.
    // but if it does then, the user will have to create the sequence table
    // so, this is acceptable.
    if ([[localException reason] hasSuffix:@"ajr_sequence_data' doesn't exist"])
    {
        createTable = YES;
    }
    else
    {
        [sql release];
        [expression release];
        [seqName release];
        [self cancelFetch];
        [NSException raise:EODatabaseException format:reasonFmt, [localException reason]];
    }
    NS_ENDHANDLER
    [expression release];
    if (createTable)
    {
        // Last ditch effort to create the sqeuence table and then try again
        if ([self createSequenceTable])
        {
            expression = [[[[adaptorContext adaptor] expressionClass] expressionForString:sql] retain];
            NS_DURING
            [self evaluateExpression: expression];
            NS_HANDLER
            [sql release];
            [expression release];
            [seqName release];
            [self cancelFetch];
            [NSException raise:EODatabaseException format:reasonFmt, [localException reason]];
            NS_ENDHANDLER
        }
        else
        {
            [sql release];
            [expression release];
            [seqName release];
            [NSException raise:EODatabaseException format:reasonFmt, @"Failure of last ditch effort to create sequence table."];
        }
    }
    
    [sql release];
    row = nil;
    if ([self isFetchInProgress])
    {
        // get the array of attributes from the result set
        NS_DURING
        [self setAttributesToFetch:[self describeResults]];
        NS_HANDLER
        [seqName release];
        [self cancelFetch];
        [NSException raise:EODatabaseException format:reasonFmt, [localException reason]];
        NS_ENDHANDLER
        row = [self fetchRowWithZone:[self zone]];

        if (row)
        {
            // since the EO Framework attributes are stored as Attribute1,
            // Attribute2, lets deal with that.
            // our order is:
            // SEQUENCE_INCREMENT   incValue    Attribute0
            // SEQUENCE_MIN_VALUE   minValue    Attribute1
            // SEQUENCE_MAX_VALUE   maxValue    Attribute2
            // SEQUENCE_CUR_VALUE   startValue  Attribute3
            // SQEUENCE_CYCLE       cycleValue  Attribute4
            colValue = [row objectForKey:@"Attribute0"];
            incValue = [colValue unsignedIntValue];
            colValue = [row objectForKey:@"Attribute1"];
            minValue = [colValue unsignedIntValue];
            colValue = [row objectForKey:@"Attribute2"];
            maxValue = [colValue unsignedLongLongValue];
            colValue = [row objectForKey:@"Attribute3"];
            startValue = [colValue unsignedLongLongValue];
            colValue = [row objectForKey:@"Attribute4"];
            cycleValue = [colValue intValue];
            [self cancelFetch];
        }
    }

    if (! row)
    {
        // no row was found for this entity.  That's fine. Just create a new one.
        // this will create a row with the defaults set up.
        startValue = 0;
        endValue = startValue + count;
        maxValue = NSUIntegerMax;
        minValue = 1;
        incValue = 1;
        cycleValue = 0;
        sql = [[NSMutableString alloc] initWithCapacity:200];
        [sql appendString:@"INSERT INTO AJR_SEQUENCE_DATA (sequence_name, sequence_cur_value) VALUE ('"];
        [sql appendString:seqName];
        [sql appendFormat:@"', %llu)", endValue];
        expression = [[[[adaptorContext adaptor] expressionClass] expressionForString:sql] retain];
        [sql release];
        [seqName release];
        NS_DURING
        [self evaluateExpression: expression];
        NS_HANDLER
        [expression release];
        [self cancelFetch];
        [NSException raise:EODatabaseException format:reasonFmt, [localException reason]];
        NS_ENDHANDLER
        [expression release];
    }
    else
    {
        // oh good, we got a row.  We need to UPDATE that row with a new sequence_cur_value
        
        // I'm concerned about overflow here because max may be at the limit of a long long
        // therefor it is not safe to ADD anything to it.
        increment = incValue * count;
        remaining = maxValue - startValue;
        if (remaining < increment)
        {
            // the endValue will exceed maxValue,  recycle, if that is okay
            // if not then raise I guess
            if (cycleValue)
            {
                endValue = remaining - increment;
            }
            else
            {
                [seqName release];
                [NSException raise:EODatabaseException
                 format:@"primaryKeysForNewRowsWithEntity: currentSequece number will exceed max_value"];
            }
        }
        else
        {
            // we can just add
            endValue = startValue + increment;
        }
        // DO the update.
        sql = [NSMutableString stringWithFormat:
               @"UPDATE AJR_SEQUENCE_DATA SET SEQUENCE_CUR_VALUE = %llu WHERE SEQUENCE_NAME = '%@'",
               endValue, seqName];
        expression = [[[[adaptorContext adaptor] expressionClass] expressionForString:sql] retain];
        [seqName release];
        NS_DURING
        [self evaluateExpression: expression];
        NS_HANDLER
        [expression release];
        [self cancelFetch];
        [NSException raise:EODatabaseException format:reasonFmt, [localException reason]];
        NS_ENDHANDLER
        [expression release];
    }
    
    // If we made it this far then the sequence number has been updated
    // All we need to do now is return an array of primary key dictionarys
    // for the range requested.
    name = [[(EOAttribute *)[attribs objectAtIndex:0] name] retain];
    keys = [[NSMutableArray alloc] initWithCapacity:count];
    key = startValue;
    increment = incValue * count;
    remaining = maxValue - startValue;
    for (index = 0; index < count; ++index)
    {
        if (remaining)
        {
            --remaining;
            key += increment;
        }
        else
        {
            remaining = maxValue - 1;
            key = minValue;
        }
        pk = [NSNumber numberWithUnsignedLongLong:key];
        [keys addObject:[NSDictionary dictionaryWithObject:pk forKey:name]];
    }

    if (pkLocalTransaction)
    {
        [adaptorContext commitTransaction];
    }
    
    return [keys autorelease];
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
    NSMutableArray		*tableNames = [NSMutableArray arrayWithCapacity:500];
    NSString            *tableName;
    MYSQL_RES           *resSet;
    MYSQL_ROW           row;

    resSet = mysql_list_tables(mysql, NULL);
    if (!resSet)
    {
        [NSException raise:EODatabaseException
                    format:
         @"MySQL function mysql_list_tables() failed to return a result: %s",
         mysql_error(mysql)];
    }
    else
    {
        while ((row = mysql_fetch_row(resSet)))
        {
            tableName = [NSString stringWithUTF8String:row[0]];
            [tableNames addObject:tableName];
        }
    }
    mysql_free_result(resSet);
    
    return tableNames;
}


//---(Private)-- Translate equivlant data types to types we actually HANDLE
- (NSString *)_standardAttribTypeForAttribNamed:(NSString *)attribName
{
    /*
     ALL Tyoes
     * TINYINT[(M)]
     * SMALLINT[(M)]
     * MEDIUMINT[(M)]
     * INT[(M)]
     * BIGINT[(M)]
     * FLOAT(p)
     FLOAT[(M,D)] ??
     DOUBLE[(M,D)]??
     * DECIMAL[(M,[D])]
     * BIT[(M)]
     * TINYINT(1)
     * CHAR[(M)]
     * VARCHAR(M)
     TINYTEXT -> TEXT
     * TEXT
     MEDIUMTEXT -> TEXT
     LONGTEXT -> TEXT
     * BINARY[(M)]
     * VARBINARY(M)
     TINYBLOB -> BLOB
     * BLOB
     MEDIUMBLOB -> BLOB
     LONGBLOB -> BLOB
     * ENUM
     * SET
     * DATE
     * DATETIME
     * TIME
     * TIMESTAMP
     * YEAR
     */
    
    NSDictionary *trans = @{ @"TINYTEXT" : @"TEXT",
                             @"MEDIUMTEXT" : @"TEXT",
                             @"LONGTEXT" : @"TEXT",
                             @"TINYBLOB" : @"BLOB",
                             @"MEDIUMBLOB" : @"BLOB",
                             @"LONGBLOB" : @"BLOB"};
    NSString    *result;
    
    result = [trans objectForKey:attribName];
    if (result)
        return result;
    else
        return attribName;
}


- (EOAttribute *)_attributeForName:(NSString *)colName
                              type:(NSString *)colType
                               len:(int)dataLen
                             scale:(int)dataScale
                         allowNull:(BOOL)allowNull
                         isPrimary:(BOOL)aPrimaryKey
                        isUnsigned:(BOOL)isUnsigned
{
    NSDictionary    *dataTypes;
    NSDictionary    *dataTypeDict;
    NSString        *aString;
    EOAttribute		*attribute = [[EOAttribute allocWithZone:[self zone]] init];
    
    colType = [self _standardAttribTypeForAttribNamed:colType];
    [attribute setName:colName];
    [attribute beautifyName];
    [attribute setColumnName:colName];
    [attribute setAllowsNull:allowNull];
    [attribute setExternalType:colType];
    
    dataTypes = [MySQLAdaptor dataTypes];
    dataTypeDict = [dataTypes objectForKey:colType];
    if (dataTypeDict)
    {
        [attribute setValueClassName:[dataTypeDict objectForKey:@"valueClassName"]];
        if ([dataTypeDict objectForKey:@"useWidth"])
            [attribute setWidth:dataLen];
        else if ([dataTypeDict objectForKey:@"isNumber"])
        {
            if ([dataTypeDict objectForKey:@"hasPrecision"])
            {
                // This would be NSDecimalNumber
                [attribute setScale:dataScale];
                [attribute setPrecision:dataLen];
            }
            else
            {
                aString = [dataTypeDict objectForKey:@"valueType"];
                if (aString)
                {
                    if (isUnsigned)
                        [attribute setValueType:[aString uppercaseString]];
                    else
                        [attribute setValueType:aString];
                }
                else
                    [attribute setValueType:@"i"];
            }
        }
        else if ([dataTypeDict objectForKey:@"isDate"])
        {
            [attribute setValueClassName:@"NSDate"];
        }
    }
    else
    {
        [EOLog logWarningWithFormat:@"Unknown type: %@\n", colType];
        [attribute setValueClassName:@"NSString"];
    }
    
    return [attribute autorelease];
}

- (EOEntity *)_createEntityForTableNamed:(NSString *)name
{
    NSDictionary		*row;
    EOSQLExpression     *expression;
    EOEntity            *entity;
    NSArray             *attributes;
    EOAttribute         *attribute;
    
    // this should return: Field, Type, Null, Key, Default, Extra
    // The order is undefined
    expression = [[[[[self adaptorContext] adaptor] expressionClass] alloc] init];
    [expression setStatement:[NSString stringWithFormat:@"DESCRIBE `%@`", name]];
    
    entity = nil;
    NS_DURING
    [self evaluateExpression:expression];
    NS_HANDLER
    [expression release];
    [localException raise];
    NS_ENDHANDLER
    [expression release];
    
    if ([self isFetchInProgress])
    {
        entity = [[EOEntity allocWithZone:[self zone]] init];
        [entity setName:name];
        [entity beautifyName];
        [entity setExternalName:name];
        [entity setClassName:@"EOGenericRecord"];

        // get the array of attributes from the result set
        NS_DURING
        attributes = [self describeResults];
        NS_HANDLER
        [self cancelFetch];
        [entity release];
        entity = nil;
        NS_ENDHANDLER
        if (entity)
        {
            // since the EO Framework attributes are stored as Attribute1,
            // Attribute2, etc,
            // lets fix up the attribute names
            for (attribute in attributes)
                [attribute setName:[[attribute columnName] uppercaseString]];
            
            // The NSDictionary contains all the data for one row
            [self setAttributesToFetch:attributes];
            while ((row = [self fetchRowWithZone:NULL]) != nil)
            {
                NSString		*colType;
                NSString        *colTypeInfo;
                int             dataLen, dataScale, dataPrecision;
                NSString        *colName;
                BOOL            nullable;
                BOOL            isPrimary;
                BOOL            isUnsigned;
                NSArray         *words;
                NSString        *word;
                id              value;
        
                isPrimary = NO;
                isUnsigned = NO;
                dataLen = 0;
                dataScale = 0;
                dataPrecision = 0;
                colType = nil;
                colName = [row objectForKey:@"FIELD"];
                value = [row objectForKey:@"TYPE"];
                if ([value isKindOfClass:[NSData class]]){
                    char *buffer;
                    NSInteger len;
                    len = [(NSData *)value length];
                    buffer = malloc(len);
                    [(NSData *)value getBytes:buffer length:len];
                    colTypeInfo = [[NSString alloc] initWithBytes:buffer length:len encoding:NSUTF8StringEncoding];
                    free(buffer);
                }
                else
                    colTypeInfo = (NSString *)[row objectForKey:@"TYPE"];
                nullable = ([[row objectForKey:@"NULL"] isEqualToString:@"YES"]) ? YES : NO;
                if ([[row objectForKey:@"KEY"] isEqualToString:@"PRI"])
                    isPrimary = YES;
                
                // get more info from the TYPE field  example is 'smallint(5) unsigned'
                // or 'decimal(5,2)'
                words = [colTypeInfo componentsSeparatedByString:@" "];
                if ([words count] > 1)
                {
                    // I am pretty darn sure the ONLY attribute is unsigned.  so if
                    // there is more than one word then unsigned is yes.
                    // it is possible that ZEROFILL and maybe BINARY will show up here.
                    // I need to test for that
                    if ([[words objectAtIndex:1] isEqualToString:@"unsigned"])
                        isUnsigned = YES;
                }
                if ([words count])
                {
                    word = [words objectAtIndex:0];
                    // this would be the type EXCLUDING the attribute so
                    // 'decimal(5,2)' for example.  Could also be somethign like 'datetime'
                    words = [word componentsSeparatedByString:@"("];
                    if ([words count] > 1)
                    {
                        colType = [[words objectAtIndex:0] uppercaseString];
                        words = [[words objectAtIndex:1] componentsSeparatedByString:@","];
                        if ([words count] > 1)
                        {
                            // this is precision and scale
                            dataLen = [[words objectAtIndex:0] intValue];
                            dataScale = [[words objectAtIndex:1] intValue];
                        }
                        else
                        {
                            // this is simply dataLen
                            dataLen = [[words objectAtIndex:0] intValue];
                        }
                    }
                    else if ([words count] == 1)
                    {
                        colType = [[words objectAtIndex:0] uppercaseString];
                    }
                }
    
                attribute = [self _attributeForName:colName type:colType
                                  len:dataLen scale:dataScale
                                  allowNull:nullable isPrimary:isPrimary
                                  isUnsigned:isUnsigned];
                [entity addAttribute:attribute];
            }
            [entity setClassProperties:[entity attributes]];
            [entity setAttributesUsedForLocking:[entity attributes]];
        }
    }
    
    return [entity autorelease];
}

- (EOModel *)describeModelWithTableNames:(NSArray *)tableNames
{
    EOModel		*model;
    NSString	*tableName;
    NSString	*EOName;
    
    model = [[EOModel allocWithZone:[self zone]] init];
    EOName = [[[[self adaptorContext] adaptor] connectionDictionary] objectForKey:@"databaseName"];
    if (EOName == nil)
        EOName = NSUserName();
    [model setName:EOName];
    [model setAdaptorName:[[[self adaptorContext] adaptor] name]];
    [model setConnectionDictionary:[[[self adaptorContext] adaptor] connectionDictionary]];
    
    for (tableName in tableNames)
    {
        EOEntity *entity = [self _createEntityForTableNamed:tableName];
        if (entity)
            [model addEntity:entity];
    }
    
    return [model autorelease];
}

- (MYSQL_BIND *)bindArray { return bindArray; }
- (MYSQL_BIND *)defineArray { return bindArray; }
- (MYSQL_STMT *)stmt { return stmt; }

@end
