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

// mont_rothstein @ yahoo.com 2005-09-11
// Added declaration of notification name.
extern NSString *EOGlobalIDChangedNotification;

@class EOEntity, EOEditingContext;

@interface EOGlobalID : NSObject
{
}

/*!
 * Returns true if the global ID is not temporary.
 */
- (BOOL)isTemporary;

/*!
 * The name of the represented entity.
 */
- (NSString *)entityName;

/*!
 * If the global ID represents a concrete value, this returns the protion
 * of the global ID based on key.
 */
- (id)valueForKey:(NSString *)key;

// tom.martin @ riemer.com - 2011-09-16
// replace depreciated method.  
- (NSDictionary *)dictionaryWithValuesForKeys:(NSArray *)keys;
- (NSDictionary *)valuesForKeys:(NSArray *)keys;

- (NSComparisonResult)compare:(id)other;

@end

