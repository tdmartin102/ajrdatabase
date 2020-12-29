
#import <Foundation/Foundation.h>

#import <EOControl/EOValidation.h>

@interface NSObject (EOValidation) <EOValidation>

- (NSException *)validateForDelete;
- (NSException *)validateForInsert;
- (NSException *)validateForSave;
- (NSException *)validateForUpdate;
- (NSException *)validateValue:(id *)valuePointer forKey:(NSString *)key;

#pragma mark EOF Extensions
/*!
 * Invoked by -[EOEditingContext sendPrepareMessages]. Could be invoked multiple
 * times in same save phase. Default implementation does nothing.
 *
 * @compatibility EOF Extension
 */
- (void)prepareForSave;
- (void)prepareForInsert;
- (void)prepareForUpdate;
- (void)prepareForDelete;

- (void)objectDidSave;
- (void)objectDidDelete;

@end
