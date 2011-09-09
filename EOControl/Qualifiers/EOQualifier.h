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

#import <Foundation/Foundation.h>
#import <EOControl/EOKeyValueArchiver.h>

// mont_rothstein @ yahoo.com 2005-01-10
// Added #ifndef to prevent redefinition errors

#ifndef __EOQualifier__
#define __EOQualifier__

typedef SEL EOQualifierOperation;

extern EOQualifierOperation EOQualifierEquals;
extern EOQualifierOperation EOQualifierNotEquals;
extern EOQualifierOperation EOQualifierLessThan;
extern EOQualifierOperation EOQualifierLessThanOrEqual;
extern EOQualifierOperation EOQualifierGreaterThan;
extern EOQualifierOperation EOQualifierGreaterThanOrEqual;
extern EOQualifierOperation EOQualifierIn;
extern EOQualifierOperation EOQualifierLike;
extern EOQualifierOperation EOQualifierCaseInsensitiveLike;
extern EOQualifierOperation EOQualifierNotLike;
extern EOQualifierOperation EOQualifierCaseInsensitiveNotLike;

// mont_rothstein@yahoo.com 2006-01-22
// Added support for EOQualifierCaseInsensitiveEqual and EOQualifierCaseInsensitiveNotEqual.  Note: These are extensions to the WO 4.5 API.
#if !defined(STRICT_EOF)
extern EOQualifierOperation EOQualifierCaseInsensitiveEqual;
extern EOQualifierOperation EOQualifierCaseInsensitiveNotEqual;
#endif

@interface EOQualifier : NSObject <NSCoding>
{
}

// Creating a qualifier
/*! @todo EOQualifier: qualifierWithQualifierFormat: */
+ (id)qualifierWithQualifierFormat:(NSString *)format, ...;
+ (id)qualifierWithQualifierFormat:(NSString *)format varargList:(va_list)args;
+ (id)qualifierWithQualifierFormat:(NSString *)format arguments:(NSArray *)args;
+ (id)qualifierToMatchAllValues:(NSDictionary *)values;
+ (id)qualifierToMatchAnyValue:(NSDictionary *)values;
/*! @todo Implement: qualifierWIthBindings:requiresAllVariables: */ 
- (EOQualifier *)qualifierWithBindings:(NSDictionary *)bindings requiresAllVariables:(BOOL)requiresAll;

// Converting strings and operators
+ (SEL)operatorSelectorForString:(NSString *)aString;
+ (NSString *)stringForOperatorSelector:(SEL)aSelector;

// Get EOQualifier operators
+ (NSArray *)allQualifierOperators;
+ (NSArray *)relationalQualifierOperators;

- (BOOL)evaluateWithObject:(id)object;

@end

@protocol EOQualifierEvaluation
- (BOOL)evaluateWithObject:(id)_object;
@end

#define EOQualifierOperatorEqual EOQualifierEquals
// jean_alexis 2005-12-18
// Corrected below #define from EOQualifierEquals to EOQualifierNotEquals
#define EOQualifierOperatorNotEqual EOQualifierNotEquals
#define EOQualifierOperatorLessThan EOQualifierLessThan
#define EOQualifierOperatorGreaterThan EOQualifierGreaterThan
#define EOQualifierOperatorLessThanOrEqualTo EOQualifierLessThanOrEqual
#define EOQualifierOperatorGreaterThanOrEqualTo EOQualifierGreaterThanOrEqual
#define EOQualifierOperatorContains EOQualifierIn
#define EOQualifierOperatorLike EOQualifierLike
#define EOQualifierOperatorCaseInsensitiveLike EOQualifierCaseInsensitiveLike

@interface EOKeyValueQualifier : EOQualifier <EOQualifierEvaluation, EOKeyValueArchiving>
{
   NSString					*key;
   id							value;
   EOQualifierOperation	operation;
   BOOL                 caseSensitive;
}

+ (EOQualifier *)qualifierWithKey:(NSString *)key value:(id)value;
+ (EOQualifier *)qualifierWithKey:(NSString *)key operation:(EOQualifierOperation)operation value:(id)value;

- (id)initWithKey:(NSString *)aKey value:(id)aValue;
- (id)initWithKey:(NSString *)aKey operation:(EOQualifierOperation)anOperation value:(id)aValue;
- (id)initWithKey:(NSString *)aKey operatorSelector:(SEL)operator value:(id)aValue;

- (NSString *)key;
- (SEL)selector;
- (id)value;

#if !defined(STRICT_EOF)
- (void)setCaseSensitive:(BOOL)flag;
- (BOOL)isCaseSensitive;
#endif

@end

#  ifndef sel_eq
#    define sel_eq(sela,selb) (sela==selb?YES:NO)
#  endif


@interface EOKeyComparisonQualifier : EOQualifier < EOQualifierEvaluation, NSCoding, EOKeyValueArchiving >
{
	/* this is a '%A selector %A' qualifier */
	NSString *leftKey;
	NSString *rightKey;
	SEL      operator;
}

- (id)initWithLeftKey:(NSString *)_leftKey
	 operatorSelector:(SEL)_selector
			 rightKey:(NSString *)_rightKey;

- (NSString *)leftKey;
- (NSString *)rightKey;
- (SEL)selector;

@end


@interface EOAndQualifier : EOQualifier <EOQualifierEvaluation, EOKeyValueArchiving>
{
   NSArray		*qualifiers;
}

+ (EOQualifier *)qualifierWithArray:(NSArray *)qualifiers;
+ (EOQualifier *)qualifierWithQualifiers:(id)aQualifier, ...;
+ (EOQualifier *)qualifierFor:(EOQualifier *)aLeft and:(EOQualifier *)aRight;

- (id)initWithArray:(NSArray *)qualifiers;
- (id)initWithQualifierArray:(NSArray *)qualifiers;
- (id)initWithQualifiers:(id)aQualifier, ...;
- (id)initWithLeft:(EOQualifier *)aLeft and:(EOQualifier *)aRight;

- (NSArray *)qualifiers;

@end


@interface EOOrQualifier : EOQualifier <EOQualifierEvaluation, EOKeyValueArchiving>
{
   NSArray		*qualifiers;
}

+ (EOQualifier *)qualifierWithArray:(NSArray *)qualifiers;
+ (EOQualifier *)qualifierWithQualifiers:(id)aQualifier, ...;
+ (EOQualifier *)qualifierFor:(EOQualifier *)aLeft or:(EOQualifier *)aRight;

- (id)initWithArray:(NSArray *)qualifiers;
- (id)initWithQualifierArray:(NSArray *)qualifiers;
- (id)initWithQualifiers:(id)aQualifier, ...;
- (id)initWithLeft:(EOQualifier *)aLeft or:(EOQualifier *)aRight;

- (NSArray *)qualifiers;

@end


@interface EONotQualifier : EOQualifier <EOQualifierEvaluation, EOKeyValueArchiving>
{
	EOQualifier		*qualifier;
}

+ (id)qualifierWithQualfier:(EOQualifier *)aQualifier;
- (id)initWithQualifier:(EOQualifier *)aQualifier;

- (EOQualifier *)qualifier;

@end


@interface EOQualifierVariable : NSObject <NSCoding, EOKeyValueArchiving>
{
	NSString *varKey;
}

+ (id)variableWithKey:(NSString *)_key;
- (id)initWithKey:(NSString *)_key;

- (NSString *)key;

	/* Comparing */

- (BOOL)isEqual:(id)_obj;
- (BOOL)isEqualToQualifierVariable:(EOQualifierVariable *)_obj;

@end


@interface NSArray (EOQualifierExtras)
- (NSArray *)filteredArrayUsingQualifier:(EOQualifier *)qualifier;
@end

#endif // __EOQualifier__
