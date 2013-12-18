
#import "EOEnterpriseObject.h"

@interface NSObject (EOEnterpriseObject)

// tom.martin @ riemer.com 2011-11-16
// it turns out that the purpose of takeStoredValue is basically to 
// avoid calling the accessor method so that willChange will NOT be called
// I have implemented setPrimitiveValue:forKey here to replace takeStoredValue:forKey:
- (void)setPrimitiveValue:(id)value forKey:(NSString *)key;

// tom.martin @ riemer.com 2012-04-19
// calling storedValueForKey bypasses EO logic to access the same values set by
// setPrimitiveValue:forKey:  This is what we want to do when we are working with
// database and context snapshots.  It also will prevent an object from firing a 
// fault for a relationship when there is EO code that would case that to happen
// with the normal accessor methods.  To replace that depreciated method I have
// supplied the following which will do the same thing as storedValueForKey.
// not as fast I am sure, but at least it gets the job done.
- (id)primitiveValueForKey:(NSString *)key;

@end
