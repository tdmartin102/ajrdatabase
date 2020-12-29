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

#import <EOControl/EOGlobalID.h>

@class EOEntity, EOQualifier;

@interface EOTemporaryGlobalID : EOGlobalID
{
   NSString			*entityName;
   NSString			*uniqueID;
	EOGlobalID		*newGlobalID;
}

- (id)initWithEntityName:(NSString *)anEntityName;

- (BOOL)isTemporary;

- (NSString *)entityName;
- (EOQualifier *)buildQualifier;
- (id)valueForKey:(NSString *)key;

/*!
 * @method setTempGlobalID:
 *
 * @discussion The new global ID is used when the primary key is generated for the object during the save process. The currently temporary global ID will get the new global ID. If the save succeeds, the new global ID will replace the current global ID on the object. If the save fails, then the new global ID will be discarded. Normally this method is called by the database layer during the save process.
 */
- (void)setTempGlobalID:(EOGlobalID *)aGlobalID;

/*!
 * @method tempGlobalID
 *
 * @discussion Returns the new global ID. See setNewGlobalID: for details.
 */
- (EOGlobalID *)tempGlobalID;

@end
