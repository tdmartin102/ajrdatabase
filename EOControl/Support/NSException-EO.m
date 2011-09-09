
#import "NSException-EO.h"

#import "EOFormat.h"

#import <Foundation/Foundation.h>

NSString *EOValidationException = @"EOValidationException";
NSString *EOAggregateException = @"EOAggregateException";

NSString *EOValidatedObjectUserInfoKey = @"EOValidatedObjectUserInfoKey";
NSString *EOValidatedPropertyUserInfoKey = @"EOValidatedPropertyUserInfoKey";

NSString *EOExceptionsKey = @"EOExceptionsKey";

@implementation NSException (EO)

+ (id)validationExceptionWithFormat:(NSString *)format, ...
{
	NSException		*exception;
	va_list			ap;
	
	va_start(ap, format);
	exception = [[[NSException alloc] initWithFormat:format arguments:ap] autorelease];
	va_end(ap);
	
	return exception;
}

- (id)initWithFormat:(NSString *)format arguments:(va_list)ap
{
	[self initWithName:EOValidationException reason:EOFormatv(format, ap) userInfo:nil];
	
	return self;
}

- (id)initWithFormat:(NSString *)format, ...
{
	NSException		*exception;
	va_list			ap;
	
	va_start(ap, format);
	exception = [self initWithFormat:format arguments:ap];
	va_end(ap);
	
	return exception;
}

- (id)initWithException:(NSException *)other
{
	NSMutableDictionary	*someUserInfo = [[NSMutableDictionary allocWithZone:[self zone]] init];
	NSMutableArray			*exceptions;
	
	[self initWithName:EOAggregateException reason:@"Multiple exceptions have occurred." userInfo:someUserInfo];
	[someUserInfo release];
	
	exceptions = [[NSMutableArray allocWithZone:[self zone]] initWithObjects:other, nil];
	[someUserInfo setObject:exceptions forKey:EOExceptionsKey];
	[exceptions release];
	
	return self;
}

+ (id)aggregateExceptionWithException:(NSException *)other
{
	return [[[self alloc] initWithException:other] autorelease];
}

+ (id)aggregateExceptionWithExceptions:(NSArray *)exceptions
{
    NSParameterAssert([exceptions count] > 0);
    
    NSException     *firstException = [exceptions objectAtIndex:0];
    NSDictionary    *aUserInfo = [[NSDictionary alloc] initWithObjectsAndKeys:exceptions, EOAdditionalExceptionsKey, nil];
    
    firstException = [[self alloc] initWithName:[firstException name] reason:[firstException reason] userInfo:aUserInfo];
    [aUserInfo release];
    
    return [firstException autorelease];
}

- (void)addException:(NSException *)exception
{
	[[[self userInfo] objectForKey:EOExceptionsKey] addObject:exception];
}

- (void)removeException:(NSException *)exception
{
	[[[self userInfo] objectForKey:EOExceptionsKey] removeObjectIdenticalTo:exception];
}

- (NSArray *)exceptions
{
	return [[self userInfo] objectForKey:EOExceptionsKey];
}

- (NSException *)exceptionAddingEntriesToUserInfo:(NSDictionary *)additions
{
	NSMutableDictionary		*dictionary = [[self userInfo] mutableCopyWithZone:[self zone]];
    NSException             *exception;
	
	if (dictionary == nil) dictionary = [[NSMutableDictionary allocWithZone:[self zone]] init];
	
	[dictionary addEntriesFromDictionary:additions];
	
	exception = [NSException exceptionWithName:[self name] reason:[self reason] userInfo:dictionary];
    [dictionary release];
    
    return [exception autorelease];
}

@end
