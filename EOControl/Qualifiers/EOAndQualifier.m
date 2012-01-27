/*%*%*%*%*
Copyright (C) 1995-2004 Alex J. Raftis

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

Or, contact the author,

Alex J. Raftis
709 Bay Area Blvd.
League City, TX 77573
mailto:alex@raftis.net
http://www.raftis.net/~alex/
 *%*%*%*%*/

#import "EOQualifier.h"

@implementation EOAndQualifier : EOQualifier

- (id)_initWithQualifier:(EOQualifier *)qualifier andList:(va_list)ap
{
	NSMutableArray		*temp ;
	id					object;

	if (self = [super init])
	{
		temp = [[NSMutableArray allocWithZone:[self zone]] initWithObjects:qualifier, nil];
	   while ((object = va_arg(ap, id))) {
		  [temp addObject:object];
	   }
	   [self initWithArray:temp];
	   [temp release];
	}
   return self;
}

+ (EOQualifier *)qualifierWithArray:(NSArray *)someQualifiers
{
   return [[[self alloc] initWithArray:someQualifiers] autorelease];
}

+ (EOQualifier *)qualifierWithQualifiers:(id)aQualifier, ...
{
   va_list				ap;
   id						returnValue;

   va_start(ap, aQualifier);
   returnValue = [[(EOAndQualifier *)[self alloc] _initWithQualifier:aQualifier andList:ap] autorelease];
   va_end(ap);

   return returnValue;
}

// jean_alexis @ users.sourceforge.net 2005-09-08
// Method added
- (EOQualifier *)qualifierWithBindings:(NSDictionary *)bindings requiresAllVariables:(BOOL)requiresAll
{
	NSMutableArray *newQualifiers = nil;
	EOQualifier *newQualifier;
	EOQualifier *eachQualifier;
	NSEnumerator *qualifiersEnumerator = [[self qualifiers] objectEnumerator];
	
	while (eachQualifier = [qualifiersEnumerator nextObject]) {
		newQualifier = [eachQualifier qualifierWithBindings: bindings requiresAllVariables: requiresAll];
		if (newQualifier != nil) {
			if (newQualifiers == nil) {
				newQualifiers = [NSMutableArray array];
			}
			[newQualifiers addObject: newQualifier];
		}
	}
	if (newQualifiers != nil) {
		if ([newQualifiers count] > 1) {
			return [[self class] qualifierWithArray: newQualifiers];
		} else {
			return [newQualifiers lastObject];
		}
	}
	return nil;
}


+ (EOQualifier *)qualifierFor:(EOQualifier *)aLeft and:(EOQualifier *)aRight
{
   return [[[self alloc] initWithLeft:aLeft and:aRight] autorelease];
}

- (id)initWithQualifierArray:(NSArray *)someQualifiers
{
	return [self initWithArray: someQualifiers];
}

- (id)initWithArray:(NSArray *)someQualifiers
{
	// mont_rothstein @ yahoo.com 2004-12-22
	// The return value of [super init] was not being assign to self, corrected.
   self = [super init];

   qualifiers = [someQualifiers mutableCopyWithZone:[self zone]];

   return self;
}

- (id)initWithQualifiers:(id)aQualifier, ...
{
   va_list				ap;

   va_start(ap, aQualifier);
   self = [self _initWithQualifier:aQualifier andList:ap];
   va_end(ap);

   return self;
}

- (id)initWithLeft:(EOQualifier *)aLeft and:(EOQualifier *)aRight;
{
   return [self initWithArray:[NSArray arrayWithObjects:aLeft, aRight, nil]];
}

- (void)dealloc
{
   [qualifiers release];

   [super dealloc];
}

- (BOOL)evaluateWithObject:(id)object
{
	int		x;
	int numQualifiers;
	
	numQualifiers = [qualifiers count];
	
	for (x = 0; x < numQualifiers; x++) {
		if (![[qualifiers objectAtIndex:x] evaluateWithObject:object]) return NO;
	}
	
	return YES;
}

- (NSString *)description
{
	NSMutableString		*string = [[[NSMutableString allocWithZone:[self zone]] initWithString:@"("] autorelease];
	int						x;
	int numQualifiers;
	
	numQualifiers = [qualifiers count];
	
	for (x = 0; x < numQualifiers; x++) {
		if (x > 0) {
			[string appendString:@" AND "];
		}
		[string appendString:[[qualifiers objectAtIndex:x] description]];
	}
	[string appendString:@")"];
	
	return string;
}

- (NSArray *)qualifiers
{
	return qualifiers;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	
	if ([coder allowsKeyedCoding]) {
		qualifiers = [[coder decodeObjectForKey:@"qualifiers"] retain];
	} else {
		qualifiers = [[coder decodeObject] retain];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	
	if ([coder allowsKeyedCoding]) {
		[coder encodeObject:qualifiers forKey:@"qualifiers"];
	} else {
		[coder encodeObject:qualifiers];
	}
}

#pragma mark <EOKeyValueArchiving>

- (id)initWithKeyValueUnarchiver:(EOKeyValueUnarchiver *)_unarchiver {
    self->qualifiers = [[_unarchiver decodeObjectForKey:@"qualifiers"] copy];
    return self;
}
- (void)encodeWithKeyValueArchiver:(EOKeyValueArchiver *)_archiver {
    [_archiver encodeObject:[self qualifiers] forKey:@"qualifiers"];
}

@end
