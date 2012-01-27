
#import "EOQualifierParser.h"

#import "EOAndQualifier.h"
#import "EOFormat.h"
#import "EOKeyValueQualifier.h"
#import "EONotQualifier.h"
#import "EOOrQualifier.h"

#import <Foundation/Foundation.h>

static NSCharacterSet	*whitespaceSet = nil;
static NSCharacterSet	*operatorSet;
static NSCharacterSet	*literalStartSet;
static NSCharacterSet	*literalSet;
static NSCharacterSet	*numberStartSet;
static NSCharacterSet	*numberSet;

@implementation EOQualifierParser

+ (void)initialize
{
	if (whitespaceSet == nil) {
		whitespaceSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
		operatorSet = [[NSCharacterSet characterSetWithCharactersInString:@"=!<>"] retain];
		numberStartSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+"] retain];
		numberSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] retain];
		literalStartSet = [[NSCharacterSet characterSetWithCharactersInString:
			@"_"
			@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			@"abcdefghijklmnopqrstuvwxyz"] retain];
		// mont_rothstein @ yahoo.com 2004-12-03
		// Added a period to the literal set so that key paths will be treated as a
		// single token.
		literalSet = [[NSCharacterSet characterSetWithCharactersInString:
			@"_"
			@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			@"abcdefghijklmnopqrstuvwxyz"
			@"0123456789."] retain];
	}
}

// mont_rothsetin @ yahoo.com 2004-12-02
// Renamed this method because of changes in EOQualifier to comply with WO 4.5 API.
- (id)initWithString:(NSString *)aString varargList:(va_list)someArguments
{
	if (self = [super init])
    {
        input = [aString retain];
        length = [input length];
        position = 0;
        //arguments = someArguments;
        // tom.martin @ riemer.com - 2011/09/15
        isVaList = YES;
        va_copy(arguments, someArguments);
    }
    return self;
}

// mont_rothsetin @ yahoo.com 2004-12-02
// New method because EOQualifier needed to handle array to be WO 4.5 compliant.
- (id)initWithString:(NSString *)aString arguments:(NSArray *)someArguments
{
	if (self = [super init])
    {
        input = [aString retain];
        length = [input length];
        position = 0;
        isVaList = NO;
        // arguments = NULL;
        argEnumerator = [[someArguments objectEnumerator] retain];
    }
	return self;
}

- (void)dealloc
{
	[input release];
	[stack release];
	[argEnumerator release];
	// tom.martin @ riemer.com 2011/09-15
	if (isVaList)
		va_end(arguments);
	
	[super dealloc];
}

- (void)readWhitespace
{
	while (position < length && [whitespaceSet characterIsMember:[input characterAtIndex:position]]) position++;
}

- (EOQualifierToken *)readOperator
{
	EOQualifierToken	*token;
	int					start = position;
	
	while (position < length && [operatorSet characterIsMember:[input characterAtIndex:position]]) {
		position++;
	}
	
	token = [EOQualifierToken tokenWithType:EOTokenOperator value:[input substringWithRange:(NSRange){start, position - start}]];
	position++;
	
	return token;
}

- (EOQualifierToken *)readNumber
{
	int					start = position;
	BOOL					hasDecimal = NO;
	id						value;
	
	// Make sure we move over a +/-
	if (![numberSet characterIsMember:[input characterAtIndex:position]]) position++;
	while (position < length) {
		unichar character = [input characterAtIndex:position];
		
		if (![numberSet characterIsMember:character]) break;
		if (character == '.') {
			if (hasDecimal) break;
			hasDecimal = YES;
		}
		
		position++;
	}
	
	value = [input substringWithRange:(NSRange){start, position - start}];
	if (hasDecimal) {
		value = [NSNumber numberWithDouble:[value floatValue]];
	} else {
		value = [NSNumber numberWithInt:[value intValue]];
	}
	
	return [EOQualifierToken tokenWithType:EOTokenNumber value:value];
}

- (EOQualifierToken *)readLiteral
{
	EOQualifierToken	*token;
	int					start = position;
	NSString				*value;
	int					type = EOTokenLiteral;
	
	while (position < length && [literalSet characterIsMember:[input characterAtIndex:position]]) {
		position++;
	}
	
	value = [input substringWithRange:(NSRange){start, position - start}];
	if ([value caseInsensitiveCompare:@"and"] == NSOrderedSame) {
		type = EOTokenLogic;
		value = @"and";
	} else if ([value caseInsensitiveCompare:@"or"] == NSOrderedSame) {
		type = EOTokenLogic;
		value = @"or";
	} else if ([value caseInsensitiveCompare:@"not"] == NSOrderedSame) {
		type = EOTokenLogic;
		value = @"not";
	} else if ([value caseInsensitiveCompare:@"in"] == NSOrderedSame) {
		type = EOTokenOperator;
		value = @"in";
	// mont_rothstein @ yahoo.com 2005-05-04
	// Added support for the LIKE operator
	} else if ([value caseInsensitiveCompare:@"like"] == NSOrderedSame) {
		type = EOTokenOperator;
		value = @"like";
	// mont_rothstein@yahoo.com 2006-01-22
	// Added support for the CASEINSENSITIVELIKE operator
	} else if ([value caseInsensitiveCompare: @"CASEINSENSITIVELIKE"] == NSOrderedSame) {
		type = EOTokenOperator;
		value = @"CASEINSENSITIVELIKE";
	// mont_rothstein@yahoo.com 2006-01-22
	// Added support for CASEINSENSITIVEEQUAL operator.  Note: this is an extension to the WO 4.5 API
	} else if ([value caseInsensitiveCompare: @"CASEINSENSITIVEEQUAL"] == NSOrderedSame) {
		type = EOTokenOperator;
		value = @"CASEINSENSITIVEEQUAL";
	}
	// mont_rothstein @ yahoo.com 2005-06-10
	// Added handling of attribute = nil in the qualifier string
	else if ([value isEqualToString: @"nil"])
	{
		type = EOTokenString;
		value = nil;
	}
	
	
	token = [EOQualifierToken tokenWithType:type value:value];
	
	return token;
}

#define INCREMENT_POSITION() { \
	outPosition++; \
	if (outPosition == max) { \
		max += 32; \
			buffer = (unichar *)NSZoneRealloc([self zone], buffer, sizeof(unichar) * max); \
	} \
}


- (EOQualifierToken *)readStringWithStartCharacter:(unichar)startCharacter
{
	EOQualifierToken	*token;
	unichar				*buffer;
	int					max = 32;
	int					outPosition = 0;
	unichar				character;
	
	buffer = (unichar *)NSZoneMalloc([self zone], sizeof(unichar) * max);
	
	position++; // skip past the opening quote
	while (position < length) {
		character = [input characterAtIndex:position];
		if (character == startCharacter) {
			break;
		} else if (character == '\\') {
			position++;
			if (position >= length) break;
			character = [input characterAtIndex:position];
			if (character == 'n') {
				character = '\n';
			} else if (character == 'r') {
				character = '\r';
			} else if (character == 'e') {
				character = '\e';
			} else if (character == 't') {
				character = '\t';
			} else if (character == '\'') {
				character = '\'';
			} else if (character == '"') {
				character = '"';
			}
			buffer[outPosition] = character;
			INCREMENT_POSITION();
		} else {
			buffer[outPosition] = character;
			INCREMENT_POSITION();
		}
		position++;
	}
	
	token = [EOQualifierToken tokenWithType:EOTokenString value:[NSString stringWithCharacters:buffer length:outPosition]];
	NSZoneFree([self zone], buffer);
	position++;
	
	return token;
}

// mont_rothstein @ yahoo.com 2004-12-02
// Modified this to work with and enumerator of the argumentes, in addition to a va_list
// because of the need of EOQualifier to take an NSArray.
- (EOQualifierToken *)readArgument
{
	unichar		character;
	
	if (position >= length) {
		[NSException raise:NSInvalidArgumentException format:@"No modifier to %%"];
	}
	
	character = [input characterAtIndex:position];
	position++;
	if (character == 'd') {
		if (isVaList)
		{
			int		arg = va_arg(arguments, int);
			return [EOQualifierToken tokenWithType:EOTokenNumber value:[NSNumber numberWithInt:arg]];
		}
		else
		{
			return [EOQualifierToken tokenWithType:EOTokenNumber value:[argEnumerator nextObject]];
		}
	} else if (character == 's') {
		if (isVaList)
		{
			char		*arg = va_arg(arguments, char *);
			return [EOQualifierToken tokenWithType:EOTokenNumber value:[NSString stringWithUTF8String:arg]];
		}
		else
		{
			return [EOQualifierToken tokenWithType:EOTokenNumber value:[argEnumerator nextObject]];
		}
	} else if (character == '@') {
		if (isVaList)
		{
			id		arg = va_arg(arguments, id);
			return [EOQualifierToken tokenWithType:EOTokenNumber value:arg];
		}
		else
		{
			return [EOQualifierToken tokenWithType:EOTokenNumber value:[argEnumerator nextObject]];
		}
	} else if (character == 'f') {
		if (isVaList)
		{
			double		arg = va_arg(arguments, double);
			return [EOQualifierToken tokenWithType:EOTokenNumber value:[NSNumber numberWithDouble:arg]];
		}
		else
		{
			return [EOQualifierToken tokenWithType:EOTokenNumber value:[argEnumerator nextObject]];
		}
	} else {
		[NSException raise:NSInvalidArgumentException format:@"No modifier to %%: %c", character];
	}
	
	return nil;
}

- (EOQualifierToken *)nextToken
{
	unichar		character;
	
	// Ignore any leading whitespace
	[self readWhitespace];
	
	while (position < length) {
		character = [input characterAtIndex:position];
		if (character == '(') {
			position++;
			return [EOQualifierToken tokenWithType:EOTokenOpenParen];
		} else if (character == ')') {
			position++;
			return [EOQualifierToken tokenWithType:EOTokenCloseParen];
		} else if ([whitespaceSet characterIsMember:character]) {
			// Do nothing
		} else if ([operatorSet characterIsMember:character]) {
			return [self readOperator];
		} else if ([literalStartSet characterIsMember:character]) {
			return [self readLiteral];
		} else if ([numberStartSet characterIsMember:character]) {
			return [self readNumber];
		} else if (character == '"' || character == '\'') {
			return [self readStringWithStartCharacter:character];
		} else if (character == '%') {
			position++;
			return [self readArgument];
		}
		position++;
	}
	
	return nil;
}

- (EOQualifier *)qualifier
{
	EOQualifierToken			*token;
	EOQualifierStackFrame	*frame;
	EOQualifier					*returnQualifier;
	
	[stack release];
	stack = [[NSMutableArray alloc] init];
	[stack addObject:[EOQualifierStackFrame frame]];
	
	while ((token = [self nextToken])) {
		// Used by a lot below...
		frame = [stack lastObject];
		
		switch ([token type]) {
			case EOTokenString:
			case EOTokenNumber:
			case EOTokenLiteral:
			case EOTokenOperator:
			case EOTokenLogic:
				[frame addToken:token];
				break;
			case EOTokenOpenParen:
				if ([[[frame operator] value] isEqualToString:@"in"]) {
					[frame addToken:[EOQualifierToken arrayToken]];
				} else {
					[stack addObject:[EOQualifierStackFrame frame]];
				}
				break;
			case EOTokenCloseParen:
				if ([[[frame operator] value] isEqualToString:@"in"]) {
					// We've completed the "right" value, so tell the frame to create it's qualifier
					[frame applyQualifier];
				} else {
					if ([stack count] <= 0) {
						[NSException raise:NSInvalidArgumentException format:@"Unbalanced parentheses in qualifier"];
					} else {
						// Make sure this doesn't free itself when we remove it from the stack.
						[frame retain];
						[stack removeLastObject];
						[[stack lastObject] applyFrame:frame];
						[frame release];
					}
				}
				break;
		}
	}
	
	// mont_rothstein @ yahoo.com 10/28/04
	// Modified the below line to check for one than one item on the stack.  If no parenthesis were used then there will only be one item on the stack.
	//if ([stack count]) {
	if ([stack count] > 1) {
		frame = [[stack lastObject] retain];
		[stack removeLastObject];
		[[stack lastObject] applyFrame:frame];
		[frame release];
	}
	
	returnQualifier = [[[stack lastObject] qualifier] retain];
	[stack release]; stack = nil;
	
	return [returnQualifier autorelease];
}

@end


static EOQualifierToken		*openParen = nil;
static EOQualifierToken		*closeParen = nil;


@implementation EOQualifierToken : NSObject

+ (id)tokenWithType:(EOQualifierTokenType)aType
{
	return [self tokenWithType:aType value:nil];
}

+ (id)tokenWithType:(EOQualifierTokenType)aType value:(id)aValue
{
	if (aType == EOTokenOpenParen) {
		if (openParen == nil) {
			openParen = [[EOQualifierToken alloc] initWithType:EOTokenOpenParen value:nil];
		}
		return openParen;
	} else if (aType == EOTokenCloseParen) {
		if (closeParen == nil) {
			closeParen = [[EOQualifierToken alloc] initWithType:EOTokenCloseParen value:nil];
		}
		return closeParen;
	}
	
	return [[[EOQualifierToken alloc] initWithType:aType value:aValue] autorelease];
}

+ (id)arrayToken
{
	EOQualifierToken		*token;
	NSMutableArray			*array;
	
	array = [[NSMutableArray alloc] init];
	token = [[EOQualifierToken alloc] initWithType:EOTokenLiteral value:array];
	[array release];
	
	return [token autorelease];
}

- (id)initWithType:(EOQualifierTokenType)aType value:(id)aValue
{
	if (self = [super init])
    {
        type = aType;
        value = [aValue retain];
	}
	return self;
}

- (void)dealloc
{
	[value release];
	
	[super dealloc];
}

- (EOQualifierTokenType)type
{
	return type;
}

- (void)setValue:(id)aValue
{
	if (value != aValue) {
		[value release];
		value = [aValue retain];
	}
}

- (id)value
{
	return value;
}

- (NSString *)_stringForType:(EOQualifierTokenType)aType
{
	switch (aType) {
		case EOTokenString:		return @"String";
		case EOTokenNumber:		return @"Number";
		case EOTokenLiteral:		return @"Literal";
		case EOTokenOperator:	return @"Operator";
		case EOTokenOpenParen:	return @"OpenParen";
		case EOTokenCloseParen:	return @"CloseParen";
		case EOTokenLogic:		return @"Logic";
	}
	
	return nil;
}

- (NSString *)description
{
	if (value) {
		return EOFormat(@"[Token: %@: %@]", [self _stringForType:type], value);
	}
	return EOFormat(@"[Token: %@]", [self _stringForType:type]);
}

@end


@implementation EOQualifierStackFrame

+ (id)frame
{
	return [[[self alloc] init] autorelease];
}

- (void)dealloc
{
	[qualifier release];
	[left release];
	[right release];
	[operator release];
	[logic release];
	
	[super dealloc];
}

- (void)addToken:(EOQualifierToken *)aValue
{
	if ([aValue type] == EOTokenOperator) {
		[self setOperator:aValue];
	} else if ([aValue type] == EOTokenLogic) {
		[self setLogic:aValue];
	} else  if (left == nil) {
		left = [aValue retain];
	} else if (right == nil) {
		if (!operator) {
			[NSException raise:NSInvalidArgumentException format:@"Encountered an expression with no operator"];
		}
		
		// Just to make reading the code below easier to follow.
		right = [aValue retain];
		if (![[right value] isKindOfClass:[NSArray class]]) {
			[self applyQualifier];
		}
	} else if ([[right value] isKindOfClass:[NSMutableArray class]]) {
		// This happens when we're parsing the IN operator.

		// mont_rothstein @ yahoo.com 2004-12-2
		// Modified this to handle when an array is been passed in as the 
		// right hand side of the IN clause.
		// mont_rothstein @ yahoo.com 2005-04-03
		// This wasn't properly dealing with empty array objects being passed in.  Now it does.
		if ([[aValue value] isKindOfClass: [NSArray class]])
		{
			if ([[aValue value] count]) 
				[(NSMutableArray *)[right value] addObjectsFromArray:[aValue value]];
		}
		else if ([aValue value])
			[(NSMutableArray *)[right value] addObject:[aValue value]];
	}
}

- (void)setLeft:(EOQualifierToken *)aValue
{
	[left release];
	left = [aValue retain];
}

- (EOQualifierToken *)left
{
	return left;
}

- (void)setRight:(EOQualifierToken *)aValue
{
	[right release];
	right = [aValue retain];
}

- (EOQualifierToken *)right
{
	return right;
}

- (void)setOperator:(EOQualifierToken *)aValue
{
	[operator release];
	operator = [aValue retain];
}

- (EOQualifierToken *)operator
{
	return operator;
}

- (void)setNegate:(BOOL)flag
{
	negates = flag;
}

- (BOOL)negates
{
	return negates;
}

- (EOQualifier *)qualifier
{
	return qualifier;
}

- (void)setLogic:(EOQualifierToken *)aValue
{
	if ([[aValue value] isEqualToString:@"not"]) {
		[self setNegate:!negates];
	} else {
		if (logic) {
			[NSException raise:NSInvalidArgumentException format:@"Encountered more than one logical expression between qualifiers"];
		}
		[logic release];
		logic = [aValue retain];
	}
}

- (EOQualifierToken *)logic
{
	return logic;
}

- (void)applyQualifier
{
	// We have our left and right side, so let's build a qualifier.
	EOQualifier	*newQualifier;
	
	// mont_rothstein @ yahoo.com 2004-12-03
	// Removed special case in favor of handling it in addToken:
	//	if ([[right value] isKindOfClass:[NSArray class]]) {
	//		// This is a special case. Basically, when parsing an IN operation, we can have something like (one, two, three), or we might have (%@) where the prgramming is passing us the array. In this case, our right have value will be an array of length one, with the one object being an array.
	//		NSArray		*test = (NSArray *)[right value];
	//		
	//		if ([test count] == 1 && [[test objectAtIndex:0] isKindOfClass:[NSArray class]]) {
	//			[right setValue:[test objectAtIndex:0]];
	//		}
	//	}
	newQualifier = [[EOKeyValueQualifier alloc] initWithKey:[left value] operation:[EOQualifier operatorSelectorForString:[operator value]] value:[right value]];
	[self applyQualifier:newQualifier];
	[newQualifier release];
}

- (void)applyQualifier:(EOQualifier *)newQualifier
{
	// mont_rothstein @ yahoo.com 2004-12-03
	// If the new qualifier is nil all we want to do is clear out the variables.
	if (newQualifier != nil)
	{
		// Now, what do we do with it?
		if (negates) {
		// We had a not operator, so let's negate our qualifier.
			newQualifier = [EONotQualifier qualifierWithQualfier:newQualifier];
		}
		
		if (qualifier) {
		// Apply the logic operation to what's on the stack. Note that "NOT" is a special case, since it won't necessarily have anything on it's left.
			NSString		*logicValue;
			
		// Let's see if we can put two qualifiers together.
			if (logic == nil) {
				[NSException raise:NSInvalidArgumentException format:@"Encountered two qualifiers not joined by a logical expression"];
			}
			
			logicValue = [logic value];
			
			if ([logicValue isEqualToString:@"and"]) {
				// mont_rothstein @ yahoo.com 2004-12-03
				// Unlike what the below comment says we can not just add a new qualifier
				// to an AND qualifier, the qualiers array is not mutable.
				//				if ([qualifier isKindOfClass:[EOAndQualifier class]]) {
				//					// We can just add to the qualifier
				//					[(NSMutableArray *)[(EOAndQualifier *)qualifier qualifiers] addObject:qualifier];
				//					qualifier = [[EOAndQualifier alloc] initWithQualifiers:[qualifier autorelease], newQualifier, nil];
				//				} else {
				// We have to create a new qualifier.
				qualifier = [[EOAndQualifier alloc] initWithQualifiers:[qualifier autorelease], newQualifier, nil];
//				}
			} else if ([logicValue isEqualToString:@"or"]) {
				if ([qualifier isKindOfClass:[EOOrQualifier class]]) {
				// We can just add to the qualifier
					// mont_rothstein@yahoo.com 2006-01-22
					// The line below was incorrectly adding the quallifer to its own array, causing a recursive loop.  This was a problem any time there were more than two ORs.
					[(NSMutableArray *)[(EOOrQualifier *)qualifier qualifiers] addObject:newQualifier];
				} else {
				// We have to create a new qualifier.
					qualifier = [[EOOrQualifier alloc] initWithQualifiers:[qualifier autorelease], newQualifier, nil];
				}
			}
		} else {
			qualifier = [newQualifier retain];
		}
	}
	
	[left release]; left = nil;
	[right release]; right = nil;
	[operator release]; operator = nil;
	[logic release]; logic = nil;
	negates = NO;
}

- (void)applyFrame:(EOQualifierStackFrame *)frame
{
	[self applyQualifier:[frame qualifier]];
}

@end
