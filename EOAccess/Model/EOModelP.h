
#import "EOModel.h"

@interface EOModel (EOPrivate)

+ (NSString *)_validateName:(NSString *)name;

- (void)_setPath:(NSURL *)aPath;
- (void)_setURL:(NSURL *)aPath;
- (void)_setupEntities;
- (EOAdaptor *)_adaptor;
- (EOEntity *)_entityForClass:(Class)targetClass;

- (NSURL *)_urlForEntityNamed:(NSString *)aName;
- (NSURL *)_urlForFetchSpecificationForEntityNamed:(NSString *)aName;
- (NSURL *)_urlForStoredProcedureNamed:(NSString *)aName;

- (NSMutableDictionary *)_propertiesForEntityNamed:(NSString *)aName;
- (NSMutableDictionary *)_propertiesForFetchSpecificationForEntityNamed:(NSString *)aName;
- (NSMutableDictionary *)_propertiesForStoredProcedureNamed:(NSString *)aName;

@end
