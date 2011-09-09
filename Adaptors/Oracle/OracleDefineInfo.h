//
//  OracleDefineInfo.h
//  Adaptors
//
//  Created by Tom Martin on 2/21/11.
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

@interface OracleDefineInfo : NSObject
{
	OCIDefine			*defineHandle;
	EOAttribute			*attrib;
	int					pos;
	ub2					dataType;
	sb2					indicator;
	sb4					bufferSize;
	ub4					lastPieceLen;
	NSMutableData		*dynamicData;
	unsigned char		*buffer;
	// the following must be 2 byte aligned
	ociBufferValue		bufferValue;
	BOOL				freeWhenDone:1;
}
// set the database and allocate the buffer according to dataType
- initWithAttribute:(EOAttribute *)value;

- (void)setPos:(int)value;
- (void)createDefineForChannel:(OracleChannel *)channel;
- (int)pos;
- (id)objectValue;
- (EOAttribute *)attribute;

@end

