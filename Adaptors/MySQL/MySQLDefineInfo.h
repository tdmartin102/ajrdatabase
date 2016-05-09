//
//  MySQLDefineInfo.h
//  Adaptors
//
//  Created by Tom Martin on 5/9/16.
/*

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

#import "MySQLAdaptor.h"

@class MySQLChannel;

@interface MySQLDefineInfo : NSObject
{
    MySQLChannel        __weak *channel;
    EOAttribute         *attrib;
    MYSQL_BIND          *bind;
    int                 dataType;
    unsigned long       bufferSize;
    mysqlBufferValue	bufferValue;
    my_bool             is_null;
    my_bool             is_unsigned;
    int					width;
    char                usedValueType;
    unsigned int        bindIndex;
}

// set the database and allocate the buffer according to dataType
- (instancetype)initWithAttribute:(EOAttribute *)value
            channel:(MySQLChannel *)aChannel
           withBindIndex:(unsigned int)aBindIndex;

- (id)objectValue;
- (EOAttribute *)attribute;

@end

