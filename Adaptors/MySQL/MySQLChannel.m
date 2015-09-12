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

//=========================================================================================
//            Public (API) Methods
//=========================================================================================

- (id)initWithAdaptorContext:(EOAdaptorContext *)aContext
{
    if (self = [super initWithAdaptorContext:aContext])
    {
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
    NSDictionary		*info = [[[self adaptorContext] adaptor] connectionDictionary];
    NSString			*url = [info objectForKey:@"URL"];
    NSString			*username = [info objectForKey:@"username"];
    NSString			*password = [info objectForKey:@"password"];
    NSString			*hostname, *databaseName;
    int					port;
    NSArray				*urlParts = [url componentsSeparatedByString:@":"];
    
    if (connected) {
        [NSException raise:EODatabaseException format:@"EOAdaptorChannel is already open"];
    }
    
    url = [info objectForKey:@"URL"];
    username = [info objectForKey:@"username"];
    password = [info objectForKey:@"password"];
    databaseName = [info objectForKey:@"databaseName"];
    hostname = [info objectForKey:@"hostname"];
    port = [[info objectForKey:@"port"] intValue];
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
    
    if (connected)
        [NSException raise:EODatabaseException format:@"EOAdaptorChannel is already open"];
    
    if ([self isDebugEnabled])
    {
        [EOLog logDebugWithFormat:@"%@ attempting to connect with dictionary:{password = <password deleted for log>; url = %@; host = %@; port = %d; database = %@; userName = %@;}",
         [self description], url, host, port, databaseName, username];
    }
    
    // this next step could certainly fail.
    
    okay = YES;
    NS_DURING
    if (! mysql_real_connect(mysql, [host UTF8String], [username UTF8String], [password UTF8String],
                             [databaseName UTF8String] , port, const char *unix_socket, unsigned long client_flag))
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
    if (mysql)
        mysql_close(mysql);

    connected = NO;
    
    if ([self isDebugEnabled]) 
        [EOLog logDebugWithFormat:@"%@ Disconnected from database.\n", 
         [self description]];
}

- (BOOL)isFetchInProgress { return fetchInProgress; }

@end
