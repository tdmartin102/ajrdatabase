
#import <Foundation/Foundation.h>


extern NSString *EOValidationException;
extern NSString *EOAggregateException;

extern NSString *EOExceptionsKey;


#define EOAdditionalExceptionsKey                   EOExceptionsKey


extern NSString *EOValidatedObjectUserInfoKey;
extern NSString *EOValidatedPropertyUserInfoKey;


@interface NSException (EO)

+ (id)validationExceptionWithFormat:(NSString *)format, ...;
+ (id)aggregateExceptionWithException:(NSException *)other;
+ (id)aggregateExceptionWithExceptions:(NSArray *)other;

- (NSException *)exceptionAddingEntriesToUserInfo:(NSDictionary *)additions;
	
// Extensions to EOF
- (void)addException:(NSException *)exception;
- (void)removeException:(NSException *)exception;
- (NSArray *)exceptions;

@end
