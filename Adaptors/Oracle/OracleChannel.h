//
//  OracleChannel.h
//  ociTest
//
//  Created by Tom Martin on 8/30/10.
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

#import "oci.h"

@interface OracleChannel : EOAdaptorChannel 
{
	OCISession				*sessionhp;
	OCIStmt					*stmthp;
	OCIError				*errhp;
	int						rowsAffected;
	NSStringEncoding		databaseEncoding;
	NSStringEncoding		nationalDatabaseEncoding;
	sword					status;
	NSArray					*fetchAttributes;
	NSArray					*evaluateAttributes;
	NSMutableArray			*defineCache;
	NSMutableArray			*bindCache;
	text					u[68];
	text					p[68];
	text					*statement;
	int						statementLen;
	BOOL					fetchInProgress;
	BOOL					localTransaction;
}

- (OCIStmt *)stmthp;
- (OCIError *)errhp;
- (NSStringEncoding)nationalDatabaseEncoding;
- (NSStringEncoding)databaseEncoding;

// --- handy things for low level stuff
- (int)rowsAffected;
	// this is set imediately after execution for insert, update, delete. but not for select.
	// it is incremented for each row fetched on a select.
	
- (int)parseErrorOffset;
  // if an syntax error is detected by oci in the sql expression this will be set the the 
  // CHARACTER offset into the string to where the error was detected.  This is useful if
  // you want to display the sql string and point out the location where the error was detected.

@end
