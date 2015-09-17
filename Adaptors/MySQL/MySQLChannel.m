//
//  MySQLChannel.m
//  Adaptors
//
//  Created by Tom Martin on 9/12/15.
//
//

#import "MySQLChannel.h"
#import "MySQLAdaptor.h"

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

- (NSString *)checkStatus:(MYSQL *)value
{
    return [[self mysqlAdaptor] checkStatus:value];
}


- (NSString *)fieldTypeNameForTypeValue:(int)value isBinary:(BOOL)isBinary
{
    /*
     For Reference these are ALL the types in the enum
     I only deal with the types that are returned by the funtion
     mysql_fetch_field which is apparently a subset of the complete set.
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


//=========================================================================================
//            Public (API) Methods
//=========================================================================================

- (id)initWithAdaptorContext:(EOAdaptorContext *)aContext
{
    if (self = [super initWithAdaptorContext:aContext])
    {
        // I think this should be in the channel, so that we can have one structure per channel.
        // Having multiple channels per mysql is probably okay, having multiple channels in multiple
        // threads sharing the same mysql structure, I'm thinking that is NOT okay.
        mysql = mysql_init(NULL);
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
    username = [info objectForKey:@"username"];
    password = [info objectForKey:@"password"];
    databaseName = [info objectForKey:@"databaseName"];
    hostname = [info objectForKey:@"hostname"];
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
        [EOLog logDebugWithFormat:@"%@ attempting to connect with dictionary:{password = <password deleted for log>; protocol = %@; host = %@; port = %d; database = %@; userName = %@;}",
         [self description], protocol, hostname, port, databaseName, username];
    }
    
    // this next step could certainly fail.
    okay = YES;
    NS_DURING
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
    // I think the mysql structure can be re-used if the channel is re-opened.
    if (mysql)
        mysql_close(mysql);

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
    NSString            *fieldType;
    MYSQL_RES           *fetchResult;
    int                 fieldCount;
    int                 index;
    int					counter;
    int                 colWidth;
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
        isBinary = (field->flags & NOT_NULL_FLAG) ? YES : NO;
        fieldType = [self fieldTypeNameForTypeValue:field->type isBinary:isBinary];
        
       // NEED WIDTH!!!!
        colWidth = 0;

        // Look up the datatype and map it appropriately, but if we don't recognize the database,
        // we can still treat as a string.
        if (fieldType)
            dataTypeDict = [dataTypes objectForKey:fieldType];
        else
            dataTypeDict = nil;
        if (dataTypeDict)
        {
            [tempAttribute setValueClassName:[dataTypeDict objectForKey:@"valueClassName"]];
            [tempAttribute setExternalType:fieldType];
            [tempAttribute setValueType:[dataTypeDict objectForKey:@"valueType"]];
            // There does not seem to be any way to get precision and scale for
            // the DECIMAL type.
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

@end
