//
//  OracleContext.m
//  ociTest
//
//  Created by Tom Martin on 4/11/10.
/*  Copyright (C) 2011 Riemer Reporting Service, Inc.

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

Tom Martin
24600 Detroit Road
Westlake, OH 44145
mailto:tom.martin@riemer.com
*/


#import "OracleContext.h"

#import "OracleAdaptor.h"
#import "OracleChannel.h"

@implementation OracleContext

//============================================================================
//                    Private Methods
//============================================================================

- (NSString *)checkStatus
{
	return [(OracleAdaptor *)adaptor checkErr:status inHandle:errhp];
}

//============================================================================
//                    Public Oracle Context Methods
//============================================================================

- (OCISvcCtx *)serviceContexthp { return serviceContexthp; }

//============================================================================
//                    Public API Methods
//============================================================================
- initWithAdaptor:(EOAdaptor *)value
{
	OCIEnv			*envhp;	

	if (self = [super initWithAdaptor:value])
    {
        envhp = [(OracleAdaptor *)adaptor envhp];
        
        // Create the Error handle
        (void) OCIHandleAlloc( (dvoid *) envhp, (dvoid **)&errhp, OCI_HTYPE_ERROR,
                              (size_t) 0, (dvoid **) 0);
                
        // create the server handle
        (void) OCIHandleAlloc( (dvoid *) envhp, (dvoid **)&serverhp, OCI_HTYPE_SERVER,
                              (size_t) 0, (dvoid **) 0);
        attached = NO;
                                      
        // create the service context handle
        (void) OCIHandleAlloc( (dvoid *) envhp, (dvoid **)&serviceContexthp,
                              OCI_HTYPE_SVCCTX, (size_t) 0, (dvoid **) 0);
        
        /* set attribute server context in the service context */
        status = OCIAttrSet( (dvoid *)serviceContexthp, OCI_HTYPE_SVCCTX, 
                          (dvoid *)serverhp, (ub4)0, OCI_ATTR_SERVER, errhp);
        [self checkStatus];
    }
	
	return self;
}

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
		
	// free our handles
	OCIHandleFree((dvoid *) serviceContexthp, OCI_HTYPE_SVCCTX);
	OCIHandleFree((dvoid *) serverhp, OCI_HTYPE_SERVER);
	OCIHandleFree((dvoid *) errhp, OCI_HTYPE_ERROR);
	if (connectText)
		NSZoneFree([self zone], connectText);
	[super dealloc];
}

- (EOAdaptorChannel *)createAdaptorChannel
{
	OracleChannel		*channel;
	
	if ([adaptorChannels count]) 
	{
		int			x;
		int numAdaptorChannels;
		
		numAdaptorChannels = [adaptorChannels count];
		for (x = 0; x < numAdaptorChannels; x++) {
			channel = [adaptorChannels objectAtIndex:x];
			if (![channel isFetchInProgress]) 
				return channel;
		}
		[EOLog logWarningWithFormat:@"%C (%p) creating an additional adaptor channel\n", self, self];
	}
	
	channel = [[OracleChannel allocWithZone:[self zone]] initWithAdaptorContext:self];
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
	// In Oracle I think we get this for free
	//
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
		status = OCITransCommit((OCISvcCtx *)serviceContexthp, (OCIError *)errhp, OCI_DEFAULT);
		[self checkStatus];
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
		status = OCITransRollback((OCISvcCtx *)serviceContexthp, (OCIError *)errhp, OCI_DEFAULT);
		[self checkStatus];
		[self transactionDidRollback];
   }
}

// called when all channels are closed.
- (void)detachFromServer
{
	if (attached)
	{
		status = OCIServerDetach(serverhp, errhp, [OracleAdaptor ociMode]);
		[self checkStatus];
        attached = NO;
	}
}

// called when a channel is opened but the context is not attached.
- (void)attachToServer
{
	
	if (! attached)
	{
		NSString	*connectionString;
		sb4			len;
		
		connectionString = (NSString *)[[adaptor connectionDictionary] objectForKey:ConnectionStringKey];
		if ([connectionString length] == 0)
			connectionString = (NSString *)[[adaptor connectionDictionary] objectForKey:ServerIdKey];
		len = [connectionString length] * sizeof(unichar); // len is in bytes... 
		if (connectText)
			NSZoneFree([self zone], connectText);
		connectText = NSZoneMalloc([self zone], len + sizeof(unichar));
		[connectionString getOCIText:connectText];
		status = OCIServerAttach(serverhp, errhp, connectText, len, [OracleAdaptor ociMode]);
		// DEBUG LEAK
		// NSZoneFree([self zone],connectText);
		[self checkStatus];
		attached = YES;
	}	
}

- (BOOL)attached { return attached; }

- (OCIServer *)serverhp { return serverhp; }


@end

