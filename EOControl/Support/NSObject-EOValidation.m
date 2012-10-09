
#import "NSObject-EOValidation.h"

#import "NSClassDescription-EO.h"
#import "NSException-EO.h"

@implementation NSObject (EOValidation)

- (NSException *)validateForDelete
{
	return [[self classDescription] validateObjectForDelete:self];
}

- (NSException *)validateForInsert
{
	// mont_rothstein @ yahoo.com 2004-12-29
	// Modified this to call validateForSave, as per the WO 4.5 API docs.
//	return nil;
	return [self validateForSave];
}

- (NSException *)validateForSave
{
	return [[self classDescription] validateObjectForSave:self];
}

- (NSException *)validateForUpdate
{
	// mont_rothstein @ yahoo.com 2004-12-29
	// Modified this to call validateForSave, as per the WO 4.5 API docs.
	//	return nil;
	return [self validateForSave];
}

// mont_rothstein @ yahoo.com 2004-12-29
// Added code to look for and call a property specific validation method if it exists.  This
// is now more complete but lacks proper value coercion.
- (NSException *)validateValue:(id *)valuePointer forKey:(NSString *)key
{
	NSException *exception;
	
	exception = [[self classDescription] validateValue:valuePointer forKey:key];
	
	if (!exception)
	{
		NSString *selectorString;
		NSString *firstLetter;
		SEL selector;
		
		firstLetter = [[key substringToIndex: 1] uppercaseString];
		selectorString = [[NSString alloc] initWithFormat: @"validate%@%@:", firstLetter, [key substringFromIndex: 1]]; 
		selector = NSSelectorFromString(selectorString);
        [selectorString release];
		
		if ([self respondsToSelector: selector])
		{
			NSMethodSignature *methodSig;
			const char *argumentType;
			
			methodSig = [self methodSignatureForSelector: selector];
			argumentType = [methodSig getArgumentTypeAtIndex: 2];
			
			/*! @todo Coerce Values: This should coerce the object to the appropriate type, object or scalar and call the validation method (ex: NSString -> NSDate, NSNumber -> int ) */
			// jean_alexis 2005-12-18
			// Corrected below if statement
//			if (argumentType == "@") 
			if (strcmp(argumentType, "@") == 0)
			{
				return [self performSelector: selector withObject: *valuePointer];
			}
			else
			{
				[NSException raise:NSInternalInconsistencyException format:@"Scalar type coercion not implemented in validateValue:forKey:, key = %@, type = %s, object = %@", key, argumentType, self];
			}
		}
		else // Property specific validation method not implemented
		{
			return nil;
		}
	}
	else // EOClassDescription validateValue:forKey: returned an exception
	{
		return exception;
	}
}

- (void)prepareForSave
{
}

- (void)prepareForInsert
{
}

- (void)prepareForUpdate
{
}

- (void)prepareForDelete
{
}

- (void)objectDidSave
{
}

- (void)objectDidDelete
{
}

@end
