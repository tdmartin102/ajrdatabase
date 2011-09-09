//
//  OracleBindInfo.h
//  Adaptors
//
//  Created by Tom Martin on 6/23/11.
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

#import "OracleAdaptor.h"
#import "oci.h"

@class OracleChannel;

@interface OracleBindInfo : NSObject 	
{
	EOAttribute		*attrib;
	NSDictionary	*bindDict;
	OCIBind			*bindHandle;
	ub2				dataType;
	sb2				indicator;   // flag indicating NULL
	sb4				bufferSize;  // size of the actual oci buffer
	sb4				valueSize;   // total size of the data to be passed to oracle THROUGH the buffer
								 // which is bufferSize unless we are doing callbacks via a dynamic bind
	unsigned int	transferred;
	ub4				pieceLen;
	unsigned char	*buffer;
	// the following must be 2 byte aligned
	ociBufferValue	bufferValue;
	BOOL			freeWhenDone:1;
	text			*placeHolder;
	sb4				placeHolderLen;
	id				value;	
}

// set the database and allocate the buffer according to dataType
- initWithBindDictionary:(NSDictionary *)value;

- (void)createBindForChannel:(OracleChannel *)channel;

@end
