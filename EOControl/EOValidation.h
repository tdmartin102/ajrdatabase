
#import <Foundation/Foundation.h>

@protocol EOValidation

- (NSException *)validateForDelete;
- (NSException *)validateForInsert;
- (NSException *)validateForSave;
- (NSException *)validateForUpdate;
- (NSException *)validateValue:(id *)valuePointer forKey:(NSString *)key;

@end
