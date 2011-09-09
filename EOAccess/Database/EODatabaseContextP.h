//
//  EODatabaseContextP.h
//  EOAccess
//
//  Created by Mont Rothstein on 12/20/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EODatabaseContext.h"

@interface EODatabaseContext (EOPrivate)

// mont_rothstein @ yahoo.com 2004-12-20
// Added interface declaration for private methods.  These are used by array faults when sort orderings exist
- (NSArray *)_objectsForFlattenedOneToManyWithGlobalID:(EOGlobalID *)globalID relationship:(EORelationship *)relationship editingContext:(EOEditingContext *)editingContext sortOrderings:(NSArray *)sortOrderings;
- (NSArray *)_objectsForOneToManyWithGlobalID:(EOGlobalID *)globalID relationship:(EORelationship *)relationship editingContext:(EOEditingContext *)editingContext sortOrderings:(NSArray *)sortOrderings;

// This method copies the values from the snapshot, into the object, but doesn't do reference counting. Also, it shouldn't be passed newly inserted objects, only fetched objects.
- (void)_initializeObject:(id)object withGlobalID:(EOGlobalID *)globalID editingContext:(EOEditingContext *)anEditingContext;

@end
