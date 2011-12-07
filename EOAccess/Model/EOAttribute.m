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

#import "EOAttribute.h"

#import "EODatabase.h"
#import "EOEntity.h"
#import "EOEntityP.h"
#import "EOModelP.h"
#import "EOSQLFormatter.h"
#import "EOStoredProcedure.h"
#import "NSString-EOAccess.h"

#import <EOControl/EOControl.h>

NSString *EOAttributeDidChangeNameNotification = @"EOAttributeDidChangeNameNotification";

@implementation EOAttribute

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner
{
	NSString		*work;
	
	if ((self = [super init]) == nil)
		return nil;
	// Don't retain owner, because it's suppose to retain us.
	parent = owner;
	
	name = [[properties objectForKey:@"name"] retain];
	columnName = [[properties objectForKey:@"columnName"] retain];
	externalType = [[properties objectForKey:@"externalType"] retain];
	[self setValueClassName:[properties objectForKey:@"valueClassName"]];

	allowsNull = [[properties objectForKey:@"allowsNull"] hasPrefix:@"Y"];
	scale = [[properties objectForKey:@"scale"] intValue];
	width = [[properties objectForKey:@"width"] intValue];
	precision = [[properties objectForKey:@"precision"] intValue];
	valueType = [[properties objectForKey:@"valueType"] retain];
	definition = [[properties objectForKey:@"definition"] retain];
	flattened = NO;
	if (definition)
	{
		NSRange	aRange;
		// if the definition is a path then it is flattened
		// if it has no spaces and contains at least one period, I am going to 
		// say it is a path
		aRange = [definition rangeOfString:@" "];
		if (aRange.length == 0)
		{
			aRange = [definition rangeOfString:@"."];
			if (aRange.length)
				flattened = YES;
		}
	}
	[self setAdaptorValueConversionMethodName:[properties objectForKey:@"adaptorValueConversionMethodName"]];
	[self setValueFactoryMethodName:[properties objectForKey:@"valueFactoryMethodName"]];
	[self setValueClassName:[properties objectForKey:@"valueClassName"]];
	work = [properties objectForKey:@"factoryMethodArgumentType"];
	if ([work isEqualToString:@"EOFactoryMethodArgumentIsNSData"]) {
		[self setFactoryMethodArgumentType:EOFactoryMethodArgumentIsNSData];
	} else if ([work isEqualToString:@"EOFactoryMethodArgumentIsNSString"]) {
		[self setFactoryMethodArgumentType:EOFactoryMethodArgumentIsNSString];
	} else if ([work isEqualToString:@"EOFactoryMethodArgumentIsBytes"]) {
		[self setFactoryMethodArgumentType:EOFactoryMethodArgumentIsBytes];
	}
	readOnly = [[properties objectForKey:@"isReadOnly"] hasPrefix:@"Y"];
	isClassProperty = NO;
	isPrimaryKey = NO;
	readFormat = [[properties objectForKey:@"readFormat"] retain];
	writeFormat = [[properties objectForKey:@"writeFormat"] retain];
	userInfo = [[properties objectForKey:@"userInfo"] mutableCopyWithZone:[self zone]];
	parameterDirection = [[properties objectForKey:@"parameterDirection"] intValue];
    work = [properties objectForKey:@"serverTimeZone"];
    if (work)
        serverTimeZone = [[NSTimeZone timeZoneWithName:work] retain];

   return self;
}

- (void)dealloc
{
   [name release];
   [columnName release];
   [externalType release];
   [valueClassName release];
   [valueType release];
   [serverTimeZone release];
   [definition release];
   [valueFactoryMethodName release];
   [adaptorValueConversionMethodName release];
   [readFormat release];
   [writeFormat release];
   [userInfo release];

   [super dealloc];
}

- (void)awakeWithPropertyList:(NSDictionary *)properties
{
}

- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties
{
	if (allowsNull) [properties setObject:@"Y" forKey:@"allowsNull"];
	if (width) [properties setObject:[NSNumber numberWithInt:width] forKey:@"width"];
	if (columnName) [properties setObject:columnName forKey:@"columnName"];
	if (externalType) [properties setObject:externalType forKey:@"externalType"];
	if (name) [properties setObject:name forKey:@"name"];
	if (precision != 0) [properties setObject:[NSNumber numberWithInt:precision] forKey:@"precision"];
	if (scale != 0) [properties setObject:[NSNumber numberWithInt:scale] forKey:@"scale"];
	if (valueClassName) [properties setObject:valueClassName forKey:@"valueClassName"];
	if (valueType) [properties setObject:valueType forKey:@"valueType"];
	if (readFormat) [properties setObject:readFormat forKey:@"readFormat"];
	if (writeFormat) [properties setObject:writeFormat forKey:@"writeFormat"];
	if (userInfo) [properties setObject:userInfo forKey:@"userInfo"];
	if (parameterDirection != EOVoid) [properties setObject:[NSNumber numberWithInt:parameterDirection] forKey:@"parameterDirection"];
	if (definition) [properties setObject:definition forKey:@"definition"];
	if (adaptorValueConversionMethodName) [properties setObject:adaptorValueConversionMethodName forKey:@"adaptorValueConversionMethodName"];
	if (valueFactoryMethodName) {
		[properties setObject:valueFactoryMethodName forKey:@"valueFactoryMethodName"];
		switch (factoryMethodArgumentType) {
			case EOFactoryMethodArgumentIsNSData:
				[properties setObject:@"EOFactoryMethodArgumentIsNSData" forKey:@"factoryMethodArgumentType"];
				break;
			case EOFactoryMethodArgumentIsNSString:
				[properties setObject:@"EOFactoryMethodArgumentIsNSString" forKey:@"factoryMethodArgumentType"];
				break;
			case EOFactoryMethodArgumentIsBytes:
				[properties setObject:@"EOFactoryMethodArgumentIsBytes" forKey:@"factoryMethodArgumentType"];
				break;
		}
	}
	if (readOnly) [properties setObject:@"Y" forKey:@"isReadOnly"];
    if (serverTimeZone) [properties setObject:[serverTimeZone name] forKey:@"serverTimeZone"];
}

- (void)_setParent:(id)aParent
{
	parent = aParent;
}

- (id)parent
{
	return parent;
}

- (EOEntity *)entity
{
	if ([parent isKindOfClass:[EOEntity class]]) return parent;
	return nil;
}

- (void)setName:(NSString *)aName
{
   if (name != aName && ![name isEqualToString:aName]) {
		NSString		*oldName = [name retain];
		
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[(EOAttribute *)[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setName:name];
		}
      [name release];
      name = [aName retain];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:EOAttributeDidChangeNameNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldName, @"oldName", name, @"newName", nil]];
		[oldName release];
   }
}

- (NSString *)name
{
   return name;
}

- (NSException *)validateName:(NSString *)aName
{
	NSString *error = [EOModel _validateName:aName];
	
	if (!error && [parent attributeNamed:aName] != nil) {
		[NSException raise:NSInvalidArgumentException format:@"Another attribute with that name already exists."];
	}
	if (!error && [[parent model] storedProcedureNamed:aName]) {
		[NSException raise:NSInvalidArgumentException format:@"A stored procedure already exists with that name."];
	}
	return nil;
}

- (void)beautifyName
{
	[self setName:[NSString nameForExternalName:name separatorString:@"_" initialCaps:NO]];
}

- (NSTimeZone *)serverTimeZone
{
	if (serverTimeZone == nil) return [NSTimeZone localTimeZone];
	return serverTimeZone;
}

- (void)setServerTimeZone:(NSTimeZone *)aTimeZone
{
	if (serverTimeZone != aTimeZone && ![serverTimeZone isEqualToTimeZone:aTimeZone]) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setServerTimeZone:serverTimeZone];
		}
		[serverTimeZone release];
		serverTimeZone = [aTimeZone retain];
	}
}

- (void)setColumnName:(NSString *)aName
{
   if (columnName != aName && ![columnName isEqualToString:aName]) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setColumnName:columnName];
		}
      [columnName release];
      columnName = [aName retain];
   }
}

- (NSString *)columnName
{
   return columnName;
}

- (void)setDefinition:(NSString *)aDefinition
{
	if (definition != aDefinition && ![definition isEqualToString:definition]) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setDefinition:definition];
		}
		[definition release];
		definition = [aDefinition retain];
	}
}

- (NSString *)definition
{
	return definition;
}

- (void)setExternalType:(NSString *)aType
{
   if (externalType != aType && ![externalType isEqualToString:aType]) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setExternalType:externalType];
		}
      [externalType release];
      externalType = [aType retain];
   }
}

- (NSString *)externalType
{
   return externalType;
}

- (void)setValueClassName:(NSString *)className
{
	if ([className length] == 0) className = nil;
	
	if (valueClassName != className && ![valueClassName isEqualToString:className]) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setValueClassName:valueClassName];
		}
		[valueClassName release];
		valueClassName = [className retain];
		
		if (valueClassName == nil) {
			valueClass = Nil;
		} else {
			valueClass = NSClassFromString(valueClassName);
			if (!valueClass) {
				[EOLog logWarningWithFormat:@"Unable to find class named %@.", valueClassName];
			}
		}
	}
}

- (NSString *)valueClassName
{
   return valueClassName;
}

- (Class)_valueClass
{
   return valueClass;
}

- (void)setValueType:(NSString *)aType
{
   if (valueType != aType && ![valueType isEqualToString:aType]) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setValueType:valueType];
		}
      [valueType release];
      valueType = [aType retain];
   }
}

- (NSString *)valueType
{
   return valueType;
}

- (void)setAllowsNull:(BOOL)flag
{
	if (allowsNull != flag) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setAllowsNull:flag];
		}
		allowsNull = flag;
	}
}

- (BOOL)allowsNull
{
	return allowsNull;
}

- (void)setPrecision:(int)aPrecision
{
	if (precision != aPrecision) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setPrecision:precision];
		}
		precision = aPrecision;
	}
}

- (int)precision
{
   return precision;
}

- (void)setScale:(int)aScale
{
	if (scale != aScale) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setScale:scale];
		}		
		scale = aScale;
	}
}

- (int)scale
{
   return scale;
}

- (void)setWidth:(int)aWidth
{
	if (width != aWidth) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[(EOAttribute *)[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setWidth:width];
		}		
		width = aWidth;
	}
}

- (int)width
{
   return width;
}

- (NSException *)validateValue:(id *)valuePointer
{
	// mont_rothstein @ yahoo.com 2004-12-29
	// Augmented this to also check to see if valuePointer is an empty string
	if (![self allowsNull] && 
		((*valuePointer == nil) || (([*valuePointer isKindOfClass: [NSString class]]) && (![(NSString *)(*valuePointer) length])))) {
		return [NSException validationExceptionWithFormat:@"Attribute %@ may not be null", name];
	}
	if ([(id)[self _valueClass] isKindOfClass:[NSString class]] && [self width] && [(NSString *)*valuePointer length] > [self width]) {
		return [NSException validationExceptionWithFormat:@"Attribute %@ exceeds allowed length %d", name, [self width]];
	}
	return nil;
}

- (id)adaptorValueByConvertingAttributeValue:(id)value
{
	id result;
	// if value is custom class, convert it to standard value class	
	// if there is no custom class, then no conversion is needed
	result = value;
	
	// if there is nothing to convert then return the nothing.
	if (! value || [value isKindOfClass:[NSNull class]])
		return [NSNull null];
	
	if ([adaptorValueConversionMethodName length])
	{
		// If the data type to be fetched is EOAdaptorBytesType then
		// the conversion method is "archiveData"
		if (! adaptorValueConversionMethod)
		{
			if ([self adaptorValueType] == EOAdaptorBytesType)
				result = [value performSelector:NSSelectorFromString(@"archiveData")];
		}
		else
			result =  [value performSelector:adaptorValueConversionMethod];
	}
	return result;
}

- (NSString *)adaptorSqlStringForStandardValue:(id)value
{
	return [[EOSQLFormatter formatterForValue:value inAttribute:self] format:value inAttribute:self];
}


- (EOAdaptorValueType)adaptorValueType
{
	if ([valueClassName isEqualToString:@"NSString"]) return EOAdaptorCharactersType;
	if ([valueClassName isEqualToString:@"NSNumber"]) return EOAdaptorNumberType;
	if ([valueClassName isEqualToString:@"NSDecimalNumber"]) return EOAdaptorNumberType;
	if ([valueClassName isEqualToString:@"NSData"]) return EOAdaptorBytesType;
	#if MAC_OS_X_VERSION_MAX_ALLOWED > 1060
	if ([valueClassName isEqualToString:@"NSDate"]) return EOAdaptorDateType;
	#endif
	if ([valueClassName isEqualToString:@"NSCalendarDate"]) return EOAdaptorDateType;

	return -1;
}

- (void)setValueFactoryMethodName:(NSString *)aMethodName
{
	if (valueFactoryMethodName != aMethodName && ![valueFactoryMethodName isEqualToString:valueFactoryMethodName]) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setValueFactoryMethodName:valueFactoryMethodName];
		}
		[valueFactoryMethodName release];
		valueFactoryMethodName = [aMethodName retain];
		valueFactoryMethod = NSSelectorFromString(valueFactoryMethodName);
	}
}

- (SEL)valueFactoryMethod
{
	return valueFactoryMethod;
}

- (NSString *)valueFactoryMethodName
{
	return valueFactoryMethodName;
}

- (void)setFactoryMethodArgumentType:(EOFactoryMethodArgumentType)type
{
	if (factoryMethodArgumentType != type) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setFactoryMethodArgumentType:factoryMethodArgumentType];
		}		
		factoryMethodArgumentType = type;
	}
}

- (EOFactoryMethodArgumentType)factoryMethodArgumentType
{
	return factoryMethodArgumentType;
}

- (void)setAdaptorValueConversionMethodName:(NSString *)aMethodName
{
	if (adaptorValueConversionMethodName != aMethodName && ![adaptorValueConversionMethodName isEqualToString:aMethodName]) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setAdaptorValueConversionMethodName:adaptorValueConversionMethodName];
		}
		[adaptorValueConversionMethodName release];
		adaptorValueConversionMethodName = [aMethodName retain];
		adaptorValueConversionMethod = NSSelectorFromString(adaptorValueConversionMethodName);
	}
}

- (SEL)adaptorValueConversionMethod
{
	return adaptorValueConversionMethod;
}

- (NSString *)adaptorValueConversionMethodName
{
	return adaptorValueConversionMethodName;
}

- (void)setReadOnly:(BOOL)flag
{
	if (readOnly != flag) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setReadOnly:readOnly];
		}
		readOnly = flag;
	}
}

- (BOOL)isReadOnly
{
	return readOnly;
}

- (BOOL)isDerived
{
	return definition != nil;
}

- (BOOL)isFlattened
{
	return flattened;
}

- (void)setReadFormat:(NSString *)aFormat
{
	if (readFormat != aFormat && ![readFormat isEqualToString:aFormat]) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setReadFormat:readFormat];
		}
		[readFormat release];
		readFormat = [aFormat retain];
	}
}

- (NSString *)readFormat
{
	return readFormat;
}

- (void)setWriteFormat:(NSString *)aFormat
{
	if (writeFormat != aFormat && ![writeFormat isEqualToString:aFormat]) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setWriteFormat:writeFormat];
		}
		[writeFormat release];
		writeFormat = [aFormat retain];
	}
}

- (NSString *)writeFormat
{
	return writeFormat;
}

- (void)setUserInfo:(NSDictionary *)someInfo
{
	[self willChange];
	if ([[[self parent] model] undoManager]) {
		[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setUserInfo:userInfo];
	}
	[userInfo release];
	userInfo = [someInfo mutableCopyWithZone:[self zone]];
}

- (NSDictionary *)userInfo
{
	return userInfo;
}

- (NSString *)description
{
	NSMutableDictionary *p;
	
	p = [NSMutableDictionary dictionaryWithCapacity:15];
	[self encodeIntoPropertyList:p];
	return EOFormat([p description]);
}

- (void)_setIsClassProperty:(BOOL)flag
{
	if (isClassProperty != flag) [self willChange]; // Don't worry about undo, just worry about notifying observers of the change.
   isClassProperty = flag;
}

- (BOOL)_isClassProperty
{
   return isClassProperty;
}

- (void)_setIsPrimaryKey:(BOOL)flag
{
	if (isPrimaryKey != flag) [self willChange]; // Don't worry about undo, just worry about notifying observers of the change.
   isPrimaryKey = flag;
}

- (BOOL)_isPrimaryKey
{
   return isPrimaryKey;
}

- (EOAdaptor *)_adaptor
{
	return [[parent model] _adaptor];
}

- (BOOL)_isIntegralNumeric
{
	if ([valueClassName isEqualToString:@"NSNumber"]) {
		return [valueType isEqualToString:@"l"] || [valueType isEqualToString:@"q"] || [valueType isEqualToString:@"c"] || [valueType isEqualToString:@"i"];
	}
	return NO;
}

- (NSCalendarDate *)newDateForYear:(int)year month:(unsigned)month day:(unsigned)day hour:(unsigned)hour minute:(unsigned)minute second:(unsigned)second millisecond:(unsigned)millisecond timeZone:(NSTimeZone *)timeZone zone:(NSZone *)zone
{
	return [[NSCalendarDate allocWithZone:zone] initWithYear:year month:month day:day hour:hour minute:minute second:second timeZone:timeZone];
}

- (id)newValueForBytes:(const void *)bytes length:(int)length
{
	if (adaptorValueConversionMethod && factoryMethodArgumentType == EOFactoryMethodArgumentIsBytes) {
		// May be dangerous, if the runtime tries to retain bytes, but I seem to remember that it doesn't.
		return [[valueClass alloc] performSelector:adaptorValueConversionMethod withObject:(id)bytes];
	} else if ([valueClassName isEqualToString:@"NSString"]) {
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1030
		// Mac OS X 10.3 only code...
		return [[NSString alloc] initWithBytes:bytes length:length encoding:NSISOLatin1StringEncoding];
#else
		return [[NSString alloc] initWithCharacters:(const unichar *)bytes length:length];
#endif
	} else if ([valueClassName isEqualToString:@"NSData"]) {
		return [[NSData alloc] initWithBytes:bytes length:length];
	} else if ([valueClassName isEqualToString:@"NSNumber"]) {
		return nil;
	} else if ([valueClassName isEqualToString:@"NSCalendarDate"]) {
		return nil;
	}
	
	return nil;
}

- (id)newValueForBytes:(const void *)bytes length:(int)length encoding:(NSStringEncoding)encoding
{
	if (adaptorValueConversionMethod && factoryMethodArgumentType == EOFactoryMethodArgumentIsBytes) {
		// May be dangerous, if the runtime tries to retain bytes, but I seem to remember that it doesn't.
		return [[valueClass alloc] performSelector:adaptorValueConversionMethod withObject:(id)bytes];
	} else if ([valueClassName isEqualToString:@"NSString"]) {	
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1030
		// Mac OS X 10.3 only code...
		return [[NSString alloc] initWithBytes:bytes length:length encoding:encoding];
#else
		return [[NSString alloc] initWithCharacters:(const unichar *)bytes length:length];
#endif
	} else if ([valueClassName isEqualToString:@"NSData"]) {
		return [[NSData alloc] initWithBytes:bytes length:length];
	} else if ([valueClassName isEqualToString:@"NSNumber"]) {
		return nil;
	} else if ([valueClassName isEqualToString:@"NSCalendarDate"]) {
		return nil;
	}
	
	return nil;
}

- (void)setParameterDirection:(EOParameterDirection)aDirection
{
	if (parameterDirection != aDirection) {
		[self willChange];
		if ([[[self parent] model] undoManager]) {
			[[[[[self parent] model] undoManager] prepareWithInvocationTarget:self] setParameterDirection:parameterDirection];
		}
		parameterDirection = aDirection;
	}
}

- (EOParameterDirection)parameterDirection
{
	return parameterDirection;
}

- (EOStoredProcedure *)storedProcedure
{
	if ([parent isKindOfClass:[EOStoredProcedure class]]) return parent;
	return nil;
}

- (NSComparisonResult)compare:(id)other
{
	if ([other isKindOfClass:[EOAttribute class]]) {
		return [[self name] caseInsensitiveCompare:[other name]];
	}
	
	return NSOrderedAscending;
}

@end
