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

#import "EOAdaptorContext.h"

#import "EOAdaptor.h"
#import "EOAdaptorChannel.h"
#import "EODatabase.h"
#import "EODebug.h"

#import <EOControl/EOControl.h>
#import <EOControl/EOLog.h>

NSString *EOAdaptorContextBeginTransactionNotification = @"EOAdaptorContextBeginTransactionNotification";
NSString *EOAdaptorContextCommitTransactionNotification = @"EOAdaptorContextCommitTransactionNotification";
NSString *EOAdaptorContextRollbackTransactionNotification = @"EOAdaptorContextRollbackTransactionNotification";

static id   _defaultDelegate = nil;

@implementation EOAdaptorContext

+ (BOOL)debugEnabledDefault {
    return EOAdaptorDebugEnabled;
}

+ (id)defaultDelegate {
    return _defaultDelegate;
}

+ (void)setDebugEnabledDefault:(BOOL)flag {
    EOAdaptorDebugEnabled = flag;
	if (flag)
	{
		// It does not hurt to turn on the logger no matter what
		// as logging is REALLY controlled by flags at higer levels
		[EOLogger setLogDebug:flag];
		[EOLogger setLogInfo:flag];
	}
}

+ (void)setDefaultDelegate:(id)defaultDelegate {
    _defaultDelegate = defaultDelegate;
}

- (id)initWithAdaptor:(EOAdaptor *)anAdaptor
{
	if (self = [super init])
	{
		// we retain the adaptor, but the adaptor does not retain us.
		// this way there is no retain cycle, and you only need to hang on
		// to the adaptorChannel to keep the adaptor and context around.
		adaptor = [anAdaptor retain];
		adaptorChannels = [[NSClassFromString(@"_EOWeakMutableArray") alloc] init];
		debugging = [[self class] debugEnabledDefault];
		[self setDelegate:[[self class] defaultDelegate]];
	}
   
   return self;
}

- (void)dealloc
{
   [adaptorChannels release];

   // Make sure the adaptor stops referencing us...
   [(NSMutableArray *)[adaptor contexts] removeObjectIdenticalTo:self];
   [adaptor release];

   [super dealloc];
}

- (EOAdaptor *)adaptor
{
   return adaptor;
}

- (NSArray *)channels
{
   return adaptorChannels;
}

- (EOAdaptorChannel *)createAdaptorChannel
{
   return nil;
}

- (BOOL)hasBusyChannels
{
	NSInteger x;
	NSInteger numAdaptorChannels;
	
	numAdaptorChannels = [adaptorChannels count];
	for (x = 0; x < numAdaptorChannels; x++) {
		if ([[adaptorChannels objectAtIndex:x] isFetchInProgress]) return YES;
	}
	
	return NO;
}

- (BOOL)hasOpenChannels
{
	NSInteger x;
	NSInteger numAdaptorChannels;
	
	numAdaptorChannels =  [adaptorChannels count];
	for (x = 0; x < numAdaptorChannels; x++) {
		if ([[adaptorChannels objectAtIndex:x] isOpen]) return YES;
	}
	
	return NO;
}

- (void)setDelegate:(id)aDelegate
{
	delegate = aDelegate;	
	[adaptorChannels makeObjectsPerformSelector:@selector(setDelegate:) withObject:aDelegate];
}

- (id)delegate
{
   return delegate;
}

- (BOOL)canNestTransactions
{
	return NO;
}

- (void)beginTransaction
{
	NSInteger			x;
	
   if (openTransaction) {
      [NSException raise:EODatabaseException format:@"Cannot begin another transaction, one in progress."];
   }
	
//	if ([self hasBusyChannels]) {
//		[NSException raise:EODatabaseException format:@"Cannot begin a transaction while a fetch is in progress."];
//	}
	// Ignore this for right now. This is how EOF does things, but I'm thinking it's going to be better to allow the creation of a "transactionChannel". This allows us to have a transaction in progress, but without prevent fetches on other channels.
//	if (![self hasOpenChannels]) {
//		[NSException raise:EODatabaseException format:@"Attempt to begin a transaction with no open channel."];
//	}
	
	if ([adaptorChannels count] == 0) {
		transactionChannel = [[self createAdaptorChannel] retain];
		[transactionChannel openChannel];
	} else {
		NSInteger numAdaptorChannels;
		
		numAdaptorChannels = [adaptorChannels count];
		for (x = 0; x < numAdaptorChannels; x++) {
			EOAdaptorChannel		*check = [adaptorChannels objectAtIndex:x];
			if ([check isOpen] && ![check isFetchInProgress]) {
				transactionChannel = [check retain];
				break;
			}
		}
		if (transactionChannel == nil) {
			transactionChannel = [[self createAdaptorChannel] retain];
			[transactionChannel openChannel];
		}
	}
}

- (void)commitTransaction
{
	if (! openTransaction) {
		[NSException raise:EODatabaseException format:@"Cannot commit a transaction with no transaction in progress."];
	}
}

- (void)rollbackTransaction
{
	if (! openTransaction) {
		[NSException raise:EODatabaseException format:@"Cannot rollback a transaction with no transaction in progress."];
	}
}

- (void)transactionDidBegin
{
	openTransaction = YES;
	if ([[self delegate] respondsToSelector:@selector(adaptorContextDidBegin:)]) {
		[[self delegate] adaptorContextDidBegin:self];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:EOAdaptorContextBeginTransactionNotification object:self];
    if([self isDebugEnabled])
        NSLog(@"*** Begin transaction ***");
}

- (void)transactionDidCommit
{
	if (openTransaction) {
		openTransaction = NO;
		if ([[self delegate] respondsToSelector:@selector(adaptorContextDidCommit:)]) {
			[[self delegate] adaptorContextDidCommit:self];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:EOAdaptorContextCommitTransactionNotification object:self];
		[transactionChannel release]; transactionChannel = nil;
		if([self isDebugEnabled])
			NSLog(@"*** Committed transaction ***");
   }
}

- (void)transactionDidRollback
{
	if (openTransaction) {
		openTransaction = NO;
		if ([[self delegate] respondsToSelector:@selector(adaptorContextDidRollback:)]) {
			[[self delegate] adaptorContextDidRollback:self];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:EOAdaptorContextRollbackTransactionNotification object:self];
		[transactionChannel release]; transactionChannel = nil;
		if([self isDebugEnabled])
			NSLog(@"*** Rollback transaction ***");
   }
}

- (int)transactionNestingLevel
{
   return (openTransaction) ? 1 : 0;
}

- (BOOL)hasOpenTransaction
{
	return openTransaction;
}

- (void)setDebugEnabled:(BOOL)flag
{
    NSEnumerator        *channelEnum = [[self channels] objectEnumerator];
    EOAdaptorChannel    *eachChannel;
    
	debugging = flag;
	if (flag)
	{
		// It does not hurt to turn on the logger no matter what
		// as logging is REALLY controlled by flags at higer levels
		[EOLogger setLogDebug:flag];
		[EOLogger setLogInfo:flag];
	}
    while(eachChannel = [channelEnum nextObject])
        [eachChannel setDebugEnabled:flag];
}

- (BOOL)isDebugEnabled
{
	return debugging;
}

- (EOAdaptorChannel *)transactionChannel
{
	return transactionChannel;
}

@end
