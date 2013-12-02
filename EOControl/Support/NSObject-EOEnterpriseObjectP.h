
#import "EOEnterpriseObject.h"

// mont_rothstein @ yahoo.com 2004-12-06
// This is defined here, but implemented in EOAccess.  changesFromSnapshot:
// Needs the class attribute keys, but has not way to get to them because they
// are a part of EOAccess.  It must have the class attributes, as opposed to
// all of the attributes (as is available with attributeKeys) because KVC
// raises an exception if a value does not exist, instead of quietly returning nil.
@interface NSObject (EOEnterpriseObject_P)

- (EOGlobalID *)globalID;
- (NSArray *)classAttributeKeys;

// mont_rothstein @ yahoo.com 2005-06-10
// Added declaration of below methods so they could be used elsewhere
// tom.martin@riemer.com 2013-11-26
// I really want to get rid of these methods which were used to associate
// an EOEdtingContext with any object.  I handeled EOEnterpriseObject, EOGenericObject
// and EOFault, but EOObjectStoreCoordinator was also using this for something else that
// I don't understand so I am leaving this intact just for that case.
- (void)_setEOFInstanceObject:(id)object forKey:(id)aKey;
- (id)_eofInstanceObjectForKey:(id)aKey;


@end