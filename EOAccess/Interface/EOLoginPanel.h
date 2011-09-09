
#import <Foundation/Foundation.h>

@class EOAdaptor;

@interface EOLoginPanel : NSObject
{
}

- (NSDictionary *)administrativeConnectionDictionaryForAdaptor:(EOAdaptor *)adaptor;
- (NSDictionary *)runPanelForAdaptor:(EOAdaptor *)adaptor validate:(BOOL)flag allowsCreation:(BOOL)allowsCreation;

@end
