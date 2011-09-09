//
//  EOFault-EOAccess.h
//  EOAccess
//
//  Created by Mont Rothstein on 12/5/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EOControl/EOFault.h>

// This should possibly be a subclass instead of a category, but I am not a big fan of class
// clusters.  Particularly when, as in this case, the class cluster would have to create
// instance from classes in a framework it wasn't aware of (EOFault is in EOControl and can't
// see EOAccess).  Therefore, I decided to do it as a category.  Feel free to change it if
// you like.
@interface EOFault (EOAccess)

+ (id)createObjectFaultWithGlobalID:(EOGlobalID *)globalID inEditingContext:(EOEditingContext *)editingContext;

+ (id)createArrayFaultWithSourceGlobalID:(EOGlobalID *)sourceGlobalID relationshipName:(NSString *)relationshipName inEditingContext:(EOEditingContext *) editingContext;

@end
