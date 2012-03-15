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

#import "EOArrayFaultHandler.h"

#import "EODatabase.h"
#import "EODatabaseContext.h"
#import "EOEntity.h"
#import "EOEntityClassDescription.h"
#import "EOMutableArray.h"
#import "EORelationship.h"

#import "NSObject-EOAccess.h"

#import <EOControl/EOAndQualifier.h>
#import <EOControl/EOEditingContext.h>
#import <EOControl/EOFetchSpecification.h>
#import <EOControl/EOGlobalID.h>
#import <EOControl/EOKeyValueQualifier.h>
#import <EOControl/EOKeyGlobalID.h>
#import <EOControl/EOFaultP.h>

#import <objc/objc-class.h>

@implementation EOArrayFaultHandler

+ (void)initialize
{
}

- (id)initWithSourceGlobalID:(EOGlobalID *)sourceGlobalID
            relationshipName:(NSString *)aRelationshipName
              editingContext:(EOEditingContext *)anEditingContext;
{
	if (self = [super init])
	{
		globalID = [sourceGlobalID retain];
		relationshipName = [aRelationshipName retain];
		editingContext = [anEditingContext retain];
	}
	return self;
}

- (void)dealloc
{
   [relationshipName release];
	// mont_rothstein @ yahoo.com 2004-12-13
	// Commented out along with all references to restrictingQualifier in teh fault
//	[restrictingQualifier release];

   [super dealloc];
}

- (void)faultObject:(id)object
{
	NSArray                     *newObjects;
    EOEntityClassDescription	*classDescription;
	EODatabaseContext			*aDatabaseContext;
    NSMutableArray              *gids;
    id                          anEO;

	// mont_rothstein @ yahoo.com 2004-12-12
	// Support for restricting qualifier moved to EORelationships
//	if (restrictingQualifier) {
//		EOQualifier		*qualifier;
//		
//		qualifier = [[EOAndQualifier allocWithZone:[self zone]] initWithArray:[NSArray arrayWithObjects:[(EOKeyGlobalID *)globalID buildQualifier], restrictingQualifier, nil]];
//		newObjects = [editingContext objectsWithFetchSpecification:[EOFetchSpecification fetchSpecificationWithEntityName:[globalID entityName] qualifier:qualifier sortOrderings:nil]];
//		[qualifier release];
//	} else {
		newObjects = [editingContext objectsForSourceGlobalID:globalID relationshipName:relationshipName editingContext:editingContext];
//	}

    // Tom.Martin @ Riemer.com 2012-03-01
    // register the snapshot of the objects in the SOURCE snapshot
    // as far as I can see this would be the ONLY place we need to register a to-many snapshot in the database
    // snapshot.
    classDescription = (EOEntityClassDescription *)[EOEntityClassDescription classDescriptionForEntityName:[globalID entityName]];
	aDatabaseContext = [EODatabaseContext registeredDatabaseContextForModel:[[classDescription entity] model] editingContext:editingContext];
    gids = [[NSMutableArray alloc] initWithCapacity:[newObjects count] + 1];
    for (anEO in newObjects) 
    {
        EOGlobalID *gid = [anEO globalID];
        if (gid)
            [gids addObject:gid];
    }
    [[aDatabaseContext database] recordSnapshot:gids forSourceGlobalID:globalID relationshipName:relationshipName];
    [gids release];
     
	// mont_rothstein @ yahoo.com 2004-12-06
	// We have to set the handler pointer on the object to nil, otherwise KVC will try
	// and autorelese it as we set the data on the object.
	[self retain];
	[EOFault clearFault: (EOFault *)object];
    // This isn't 100%, since we're not dealing with retain / release counts.
	// object->isa = [self faultedClass];
	// tom.martin @ riemer.com 2011-12-5
	// using object_setClass is just a hair safer.
	object_setClass(object, [self faultedClass]);

	[object init];
	[object addObjectsFromArray:newObjects];
	
    // We release ourself, because our fault had retained us, but we're faulted, it can no longer release us, since we've over written it's pointer to us.
	[self release];
}

- (NSString *)descriptionWithLocale:(NSDictionary *)locale indent:(unsigned int)indent
{
   return [NSString stringWithFormat:@"[EOArrayFault (0x%x): %@, %@]", self, relationshipName, globalID];
}

- (Class)faultedClass
{
   return [EOMutableArray class];
}

// mont_rothstein @ yahoo.com 2004-12-12
// Support for restrictring qualifier moved to EORelationship.
//- (void)setRestrictingQualifier:(EOQualifier *)qualifier
//{
//	if (restrictingQualifier != qualifier) {
//		[restrictingQualifier release];
//		restrictingQualifier = [qualifier retain];
//	}
//}
//
//- (EOQualifier *)restrictingQualifier
//{
//	return restrictingQualifier;
//}
//
@end
