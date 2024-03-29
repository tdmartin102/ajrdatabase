//
//  OracleContext.h
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



#import <EOAccess/EOAccess.h>
#import <EOControl/EOControl.h>

#import <oci.h>

@interface OracleContext : EOAdaptorContext
{
	OCISvcCtx		*serviceContexthp;
	OCIServer		*serverhp;
	OCIError		*errhp;
	text			*connectText;
	sword			status;
	BOOL			attached;
}

- (OCISvcCtx *)serviceContexthp;
- (OCIServer *)serverhp;

// The following should never be called except by OracleChannel
- (void)detachFromServer;  // called when all channels are closed.
- (void)attachToServer;    // called when a channel is opened but the context is not attached.
- (BOOL)attached;

@end
