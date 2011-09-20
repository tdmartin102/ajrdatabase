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

@class EOEntity, EOGlobalID, EOEditingContext;

extern NSString *EOValidationException;
extern NSString *EOObjectDidUpdateGlobalIDNotification;

@interface EOGenericRecord : NSObject
{
	// mont_rothstein @ yahoo.com 2005-02-25
	// _entityName has to be stored here because otherwise there is no way to know
	// what entity the EOGenericRecord is for.  Trying to call classDescription directly
	// on EOGenericRecord would always cause the first entity that has a generic record
	// to be returned.
	NSString					*_entityName;
	NSMutableDictionary	*_values;
	// mont_rothstein @ yahoo.com 2004-12-05
	// Commented this out because we should be getting the globalID from the editingContext.
	//   EOGlobalID				*_globalID;
	
	EOEditingContext		*_editingContext;
	
	BOOL						_isDeallocating:1;
	unsigned int			_padding:31;
}

- (id)initWithEditingContext:(EOEditingContext *)editingContext classDescription:(NSClassDescription *)classDescription globalID:(EOGlobalID *)globalID;


//=========== Methods deprecated ==========
//- (void)takeStoredValue:(id)value forKey:(NSString *)key;
//- (id)storedValueForKey:(NSString *)key;
//========== The Old methods ===============
//- (id)handleQueryWithUnboundKey:(NSString *)key;
//- (void)handleTakeValue:(id)value forUnboundKey:(NSString *)key;
//- (void)unableToSetNilForKey:(NSString *)key;
//========== and the new methods ===============
- (id)valueForUndefinedKey:(NSString *)key;
- (void)setValue:(id)value forUndefinedKey:(NSString *)key;
- (void)setNilValueForKey:(NSString *)key;

- (BOOL)isNull:(NSString *)key;
- (NSDictionary *)values;

@end
