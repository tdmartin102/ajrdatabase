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

#import <EOControl/EOFaultHandler.h>

@class EOQualifier;

@interface EOArrayFaultHandler : EOFaultHandler
{
   NSString		*relationshipName;
	// mont_rothstein @ yahoo.com 2004-12-12
	// I commented this variable out because adding the restricting qualifier belonged in the
	// relationship not in the fault.
//	EOQualifier	*restrictingQualifier;
}

- (id)initWithSourceGlobalID:(EOGlobalID *)sourceGlobalID
            relationshipName:(NSString *)relationshipName
              editingContext:(EOEditingContext *)anEditingContext;

@end
