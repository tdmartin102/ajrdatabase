//
//  MySQLChannel.m
//  Adaptors
//
//  Created by Tom Martin on 9/12/15.
//
//

#import "MySQLChannel.h"

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
    NSString            *strValue;
    MYSQL               *status;
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
            mysql_protocol = MYSQL_PROTOCOL_SOCKET
        else
            mysql_protocol = MYSQL_PROTOCOL_TCP;

    }
    else
    {
        if ([protocol isEqualToString:@"SOCKET"])
            mysql_protocol = MYSQL_PROTOCOL_SOCKET
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
    mysql_options(&mysql,MYSQL_INIT_COMMAND,"SET autocommit=0");
    mysql_options(&mysql, MYSQL_OPT_PROTOCOL, &mysql_protocol)
    // we will set the character set to UTF8, we MIGHT want to use UTF16, I'm not certain, it may be faster
    // plus I don't understand yet the relationship betwen the DATABASE character set and the
    // connection character set.
    mysql_options(&mysql, MYSQL_SET_CHARSET_NAME, 'utf8');
    if (! mysql_real_connect(mysql, [host UTF8String], [username UTF8String], [password UTF8String],
                             [databaseName UTF8String] , port, NULL, 0))
        okay = NO;
    NS_HANDLER
    okay = NO;
    NS_ENDHANDLER
    if (okay == NULL)
    {
        if ([self isDebugEnabled])
        {
            [EOLog logDebugWithFormat:@"%@ Failed to connect to MySQL database %@ With status: %s\n",
             [self description], mysql_error(&mysql)];
        }
        [localException raise];
    }

    connected = YES;
    
    if ([self isDebugEnabled])
    {
        [EOLog logDebugWithFormat:@"%@ Connected to MySQL database %@\n",
         [self description], [cd objectForKey:ServerIdKey]];
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

@end
