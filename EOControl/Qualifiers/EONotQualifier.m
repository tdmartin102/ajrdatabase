
#import "EOQualifier.h"

@implementation EONotQualifier

+ (id)qualifierWithQualfier:(EOQualifier *)aQualifier
{
	return [[[EONotQualifier alloc] initWithQualifier:aQualifier] autorelease];
}

- (id)initWithQualifier:(EOQualifier *)aQualifier
{
	[super init];
	
	qualifier = [aQualifier retain];
	
	return self;
}

- (EOQualifier *)qualifier
{
	return qualifier;
}

// jean_alexis @ users.sourceforge.net 2005-09-08
// Added method
- (EOQualifier *)qualifierWithBindings:(NSDictionary *)bindings requiresAllVariables:(BOOL)requiresAll
{
	EOQualifier *newQualifier;
	
	newQualifier = [[self qualifier] qualifierWithBindings: bindings requiresAllVariables: requiresAll];
	if (newQualifier != nil) {
		return  [[[EONotQualifier alloc] initWithQualifier: newQualifier] autorelease];
	} else {
		return nil;
	}
}

- (BOOL)evaluateWithObject:(id)object
{
   return ![qualifier evaluateWithObject:object];
}

- (NSString *)description
{
   NSMutableString		*string;
	
	string = [[[NSMutableString allocWithZone:[self zone]] initWithString:@"NOT ("] autorelease];
	[string appendString:[qualifier description]];
   [string appendString:@")"];
	
   return string;
}

- (id)initWithCoder:(NSCoder *)coder
{
	[super initWithCoder:coder];
	
	if ([coder allowsKeyedCoding]) {
		qualifier = [[coder decodeObjectForKey:@"qualifier"] retain];
	} else {
		qualifier = [[coder decodeObject] retain];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	
	if ([coder allowsKeyedCoding]) {
		[coder encodeObject:qualifier forKey:@"qualifier"];
	} else {
		[coder encodeObject:qualifier];
	}
}

#pragma mark <EOKeyValueArchiving>

- (id)initWithKeyValueUnarchiver:(EOKeyValueUnarchiver *)_unarchiver {
    self->qualifier = [[_unarchiver decodeObjectForKey:@"qualifier"] copy];
    return self;
}
- (void)encodeWithKeyValueArchiver:(EOKeyValueArchiver *)_archiver {
    [_archiver encodeObject:[self qualifier] forKey:@"qualifier"];
}

@end
