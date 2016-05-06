//
//  MySQLBindInfo.h
//  
//
//  Created by Tom Martin on 4/26/16.
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

#import "MySQLAdaptor.h"

@class MySQLChannel;

@interface MySQLBindInfo : NSObject
{
    EOAttribute         *attrib;
    NSDictionary        *bindDict;
    MYSQL_BIND          *bind;
    int                 dataType;
    short               indicator;   // flag indicating NULL
    unsigned long       bufferSize;  // size of the actual buffer
    unsigned long       valueSize;   // total size of the data to be passed to MySQL
                                     //THROUGH the buffer
    
    // which is bufferSize unless we are doing callbacks via a dynamic bind
    mysqlBufferValue	bufferValue;
z    my_bool             is_null;
    
    BOOL                freeWhenDone:1;
    id                  value;
}

// set the database and allocate the buffer according to dataType
- (instancetype)initWithBindDictionary:(NSDictionary *)value
                             mysqlBind:(MYSQL_BIND *)mysqlBind;

- (void)createBindForChannel:(MySQLChannel *)channel;

@end
