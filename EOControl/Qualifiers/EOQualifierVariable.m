//
//  EOQualifierVariable.m
//  EOControl
//
//  Created by Mont Rothstein on 12/2/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "EOQualifier.h"


@implementation EOQualifierVariable

+ (id)variableWithKey:(NSString *)_key {
	return [[[self alloc] initWithKey:_key] autorelease];
}

- (id)initWithKey:(NSString *)_key {
    if (self = [super init])
		self->varKey = [_key copyWithZone:[self zone]];
	return self;
}
- (id)init {
	return [self initWithKey:nil];
}

- (void)dealloc {
	[self->varKey release];
	[super dealloc];
}

/* accessors */

- (NSString *)key {
	return self->varKey;
}

/* NSCoding */

- (void)encodeWithCoder:(NSCoder *)_coder {
	[_coder encodeObject:self->varKey];
}
- (id)initWithCoder:(NSCoder *)_coder {
	self->varKey = [[_coder decodeObject] copyWithZone:[self zone]];
	return self;
}

/* Comparing */

- (BOOL)isEqual:(id)_obj {
	if ([_obj isKindOfClass:[self class]])
		return [self isEqualToQualifierVariable:(EOQualifierVariable *)_obj];
	
	return NO;
}

- (BOOL)isEqualToQualifierVariable:(EOQualifierVariable *)_obj {
	return [self->varKey isEqual:[_obj key]];
}

/* description */

- (NSString *)qualifierDescription {
	return [@"$" stringByAppendingString:[self key]];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@[0x%08lX]: variable=%@>",
		NSStringFromClass([self class]), (unsigned long)self,
		[self key]];
}

#pragma mark <EOKeyValueArchiving>

- (id)initWithKeyValueUnarchiver:(EOKeyValueUnarchiver *)_unarchiver {
    if ((self = [super init]) != nil) {
        self->varKey = [[_unarchiver decodeObjectForKey:@"key"] copy];
    }
    return self;
}
- (void)encodeWithKeyValueArchiver:(EOKeyValueArchiver *)_archiver {
    [_archiver encodeObject:[self key] forKey:@"key"];
}

@end /* EOQualifierVariable */
