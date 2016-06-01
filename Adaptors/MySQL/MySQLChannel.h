//
//  MySQLChannel.h
//  Adaptors
//
//  Created by Tom Martin on 9/12/15.
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

#import <mysql.h>

@interface MySQLChannel : EOAdaptorChannel
{
    MYSQL                   *mysql;
    MYSQL_STMT              *stmt;
    unsigned long long		rowsAffected;
    NSArray					*fetchAttributes;
    NSArray					*evaluateAttributes;
    NSMutableArray			*defineCache;
    NSMutableArray			*bindCache;
    BOOL					fetchInProgress;
    BOOL					localTransaction;
    MYSQL_BIND              *bindArray;
    int                     bindCount;
}

// --- handy things for low level stuff
- (unsigned int)rowsAffected;
// this is set imediately after execution for insert, update, delete. but not for select.
// it is incremented for each row fetched on a select.

- (MYSQL *)mysql;
- (MYSQL_BIND *)bindArray;
- (MYSQL_BIND *)defineArray;
- (MYSQL_STMT *)stmt;

@end