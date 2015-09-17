//
//  MySQLContext.m
//  Adaptors
//
//  Created by Tom Martin on 9/15/15.
//
//

#import "MySQLContext.h"

#import "MySQLAdaptor.h"
#import "MySQLChannel.h"

#import <mysql.h>

@implementation MySQLContext

//============================================================================
//                    Private Methods
//============================================================================

- (NSString *)checkStatus:(MYSQL *)value
{
    return [(MySQLAdaptor *)adaptor checkStatus:value];
}

//============================================================================
//                    Public API Methods
//============================================================================

/*
- initWithAdaptor:(EOAdaptor *)value
{    
    if (self = [super initWithAdaptor:value])
    {
    }
    
    return self;
}
*/

- (void)dealloc
{
    // we need to close any open channels
    // this will have the side affect of disconnecting the server handle
    if ([self hasOpenChannels])
    {
        id enumArray;
        EOAdaptorChannel *channel;
        enumArray = [adaptorChannels objectEnumerator];
        while ((channel = [enumArray nextObject]) != nil)
        {
            if ([channel isOpen])
                [channel closeChannel];
        }
    }
    
    [super dealloc];
}

- (EOAdaptorChannel *)createAdaptorChannel
{
    MySQLChannel		*channel;
    
    if ([adaptorChannels count])
    {
        int			x;
        int numAdaptorChannels;
        
        numAdaptorChannels = (int)[adaptorChannels count];
        for (x = 0; x < numAdaptorChannels; x++) {
            channel = [adaptorChannels objectAtIndex:x];
            if (![channel isFetchInProgress])
                return channel;
        }
        [EOLog logWarningWithFormat:@"%C (%p) creating an additional adaptor channel\n", self, self];
    }
    
    channel = [[MySQLChannel allocWithZone:[self zone]] initWithAdaptorContext:self];
    [adaptorChannels addObject:channel];
    
    return [channel autorelease];
}

- (BOOL)canNestTransactions
{
    return NO;
}

- (void)beginTransaction
{
    if ([delegate respondsToSelector:@selector(adaptorContextShouldBegin:)])
    {
        if (![delegate adaptorContextShouldBegin:self])
            return;
    }
    
    [super beginTransaction];
    // In MySQL I think we get this for free
    // since we set autocommit to 0 when the channel was opened.
    [self transactionDidBegin];
}

- (void)commitTransaction
{
    if ([delegate respondsToSelector:@selector(adaptorContextShouldCommit:)])
    {
        if (![delegate adaptorContextShouldCommit:self])
            return;
    }
    
    [super commitTransaction];
    
    if ([self hasOpenTransaction])
    {
        MYSQL *mysql =[(MySQLChannel *)transactionChannel mysql];
        if (!mysql_commit(mysql))
            [self checkStatus:mysql];
        [self transactionDidCommit];
    }
}

- (void)rollbackTransaction
{
    if ([delegate respondsToSelector:@selector(adaptorContextShouldRollback:)])
    {
        if (![delegate adaptorContextShouldRollback:self]) return;
    }
    
    [super rollbackTransaction];
    
    if ([self hasOpenTransaction])
    {
        MYSQL *mysql =[(MySQLChannel *)transactionChannel mysql];
        if (!mysql_rollback(mysql))
            [self checkStatus:mysql];
        [self transactionDidRollback];
    }
}

@end
