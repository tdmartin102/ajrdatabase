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

#import <Foundation/Foundation.h>

@class EOAdaptor, EOAdaptorChannel;

extern NSString *EOAdaptorContextBeginTransactionNotification;
extern NSString *EOAdaptorContextCommitTransactionNotification;
extern NSString *EOAdaptorContextRollbackTransactionNotification;

@interface EOAdaptorContext : NSObject
{
	EOAdaptor			*adaptor;
	NSMutableArray		*adaptorChannels;
	EOAdaptorChannel	*transactionChannel;
	id					delegate;
	BOOL				debugging:1;
	BOOL				openTransaction:1;
}

// Creating an EOAdaptorContext
- (id)initWithAdaptor:(EOAdaptor *)anAdaptor;

// Accessing the adaptor
- (EOAdaptor *)adaptor;

// Creating adaptor channels
- (NSArray *)channels;
- (EOAdaptorChannel *)createAdaptorChannel;

// Checking connection status
- (BOOL)hasBusyChannels;
- (BOOL)hasOpenChannels;

// Controlling transactions
- (BOOL)canNestTransactions;
- (int)transactionNestingLevel;  // Depreciated
- (BOOL)hasOpenTransaction;
- (void)beginTransaction;
- (void)commitTransaction;
- (void)rollbackTransaction;
- (void)transactionDidBegin;
- (void)transactionDidCommit;
- (void)transactionDidRollback;

// Debugging
+ (BOOL)debugEnabledDefault;
+ (void)setDebugEnabledDefault:(BOOL)flag;
- (void)setDebugEnabled:(BOOL)flag;
- (BOOL)isDebugEnabled;

// Accessing the delegate
+ (id)defaultDelegate;
+ (void)setDefaultDelegate:(id)defaultDelegate;
- (void)setDelegate:(id)aDelegate;
- (id)delegate;

// Extensions to EOF
/*! 
 * @method transactionChannel
 *
 * @discussion Returns the current adaptor channel being used for a prolonged transaction. Only one channel may be used at a time for this purpose. This channel is created during beginTransaction and remains valid until either commitTransaction or rollbackTransaction is called.
 *
 * @result Returns a EOAdaptorChannel being used for a prolonged transaction.
 */
- (EOAdaptorChannel *)transactionChannel;
	
@end

@interface NSObject (EOAdaptorContextDelegate)

/*! @todo EOAdaptorChannel: delegate methods */

- (void)adaptorContextDidBegin:(EOAdaptorContext *)context;
- (void)adaptorContextDidCommit:(EOAdaptorContext *)context;
- (void)adaptorContextDidRollback:(EOAdaptorContext *)context;
- (BOOL)adaptorContextShouldBegin:(EOAdaptorContext *)context;
- (BOOL)adaptorContextShouldCommit:(EOAdaptorContext *)context;
- (BOOL)adaptorContextShouldConnect:(EOAdaptorContext *)context;
- (BOOL)adaptorContextShouldRollback:(EOAdaptorContext *)context;

@end
