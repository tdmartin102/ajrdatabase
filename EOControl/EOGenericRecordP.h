
#import "EOGenericRecord.h"

@interface EOGenericRecord (EOPrivate)

// Tom.martin@Riemer.com  THis now inherits this method
//- (void)_setEditingContext:(EOEditingContext *)aContext;
// mont_rothstein @ yahoo.com 2004-12-05
// Commented this out because we should be getting the globalID from the editingContext.
//- (void)_setGlobalID:(EOGlobalID *)aGlobalID;

// mont_rothstein @ yahoo.com 2005-02-25
// A globalID method needed to be added because of many-to-many join objects.  Unlike
// other EOGenericRecords they don't have an editing context and therefore NSObject's
// globalID method does not work.  Therefore they store their globalID in the _values
// dictionary.  This method checks for a globalID there first, and then calls super if
// on isn't found.
- (EOGlobalID *)globalID;

// mont_rothstein @ yahoo.com 2005-02-25
// Moved this declaration here from .m because there are other private methods in this
// category already here.
- (BOOL)_isPrimitive:(NSString *)key;

@end
