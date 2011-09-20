
#import <Foundation/Foundation.h>

@class EOQualifier;

typedef enum _eoQualifierTokenType {
	EOTokenString,
	EOTokenNumber,
	EOTokenLiteral,
	EOTokenOperator,
	EOTokenOpenParen,
	EOTokenCloseParen,
	EOTokenLogic
} EOQualifierTokenType;

@interface EOQualifierParser : NSObject
{
	NSString			*input;
	int					length;
	int					position;
	va_list				arguments;
	NSMutableArray		*stack;
	NSEnumerator		*argEnumerator;
	BOOL				isVaList;
}

- (id)initWithString:(NSString *)aString varargList:(va_list)arguments;
- (id)initWithString:(NSString *)aString arguments:(NSArray *)arguments;

- (EOQualifier *)qualifier;

@end

@interface EOQualifierToken : NSObject
{
	EOQualifierTokenType	type;
	id							value;
}

+ (id)tokenWithType:(EOQualifierTokenType)aType;
+ (id)tokenWithType:(EOQualifierTokenType)aType value:(id)aValue;
+ (id)arrayToken;
- (id)initWithType:(EOQualifierTokenType)aType value:(id)aValue;

- (EOQualifierTokenType)type;
- (id)value;

@end

@interface EOQualifierStackFrame : NSObject
{
	EOQualifier	*qualifier;
	id				left;
	id				operator;
	id				right;
	id				logic;
	BOOL			negates;
}

+ (id)frame;

- (void)addToken:(EOQualifierToken *)aValue;
- (void)setLeft:(EOQualifierToken *)aValue;
- (EOQualifierToken *)left;
- (void)setRight:(EOQualifierToken *)aValue;
- (EOQualifierToken *)right;
- (void)setOperator:(EOQualifierToken *)aValue;
- (EOQualifierToken *)operator;
- (void)setLogic:(EOQualifierToken *)aValue;
- (EOQualifierToken *)logic;
- (void)setNegate:(BOOL)flag;
- (BOOL)negates;
- (EOQualifier *)qualifier;

- (void)applyQualifier;
- (void)applyQualifier:(EOQualifier *)newQualifier;
- (void)applyFrame:(EOQualifierStackFrame *)frame;

@end
