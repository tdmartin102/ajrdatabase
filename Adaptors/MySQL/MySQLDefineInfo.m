//
//  MySQLDefineInfo.m
//  Adaptors
//
//  Created by Tom Martin on 5/9/16.
/*

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

Tom Martin
24600 Detroit Road
Westlake, OH 44145
mailto:tom.martin@riemer.com
*/


#import "MySQLDefineInfo.h"

#import "MySQLContext.h"
#import "MySQLChannel.h"

@implementation MySQLDefineInfo

//====================================================================================================
//                     Private Methods
//====================================================================================================


//---(Private)--- Convert NUMBER from char buffer to NSNumber or NSDecimalNumber
// Note:  just return a string here because it will get converted to a number later.
- (id)numberValueFromChar
{
	// target is NSDecimalNumber (probably)
    return [NSString stringWithUTF8String:(char *)bufferValue.simplePtr];
}

//---(Private)--- Convert BIT from char buffer to NSNumber
- (id)numberValueFromBitChar
{
    // The buffer is bits  NOT characters as the documentation implies.'
    // I need a 64 bit accumulator;
    unsigned long long total = 0;
    BOOL first = YES;
    unsigned char *ptr = (unsigned char *)bufferValue.simplePtr;
    while (*ptr)
    {
        if (! first)
            total = total << 8;
        else
            first = NO;
        total += *ptr;
        ++ptr;
    }
    return [NSNumber numberWithUnsignedLongLong:total];
}

//---(Private)--- Convert scaler value Buffer into a NSNumber. We only handle value types cCsSiIfd
//                Types lL is not used, we use iI as they are equivilent.
- (id)objectValueFromScalar
{
	id		result;
    result = nil;
    // ignore the valueType set in the attribute.
    // This was considered, but it may not be what was actually USED
	switch (usedValueType)
	{
		case  'c':
			result = [NSNumber numberWithChar:bufferValue.sCharValue];
			break;
		case  'C':
			result = [NSNumber numberWithUnsignedChar:bufferValue.uCharValue];
			break;
		case  's':
			result = [NSNumber numberWithShort:bufferValue.sShortValue];
			break;
		case  'S':
			result = [NSNumber numberWithUnsignedShort:bufferValue.uShortValue];
			break;
		case  'i':
			result = [NSNumber numberWithInt:bufferValue.sIntValue];
			break;
		case  'I':
			result = [NSNumber numberWithUnsignedInt:bufferValue.uIntValue];
			break;
        case  'q':
            result = [NSNumber numberWithLongLong:bufferValue.sLLValue];
            break;
        case  'Q':
            result = [NSNumber numberWithUnsignedLongLong:bufferValue.uLLValue];
            break;
		case  'f':
			result = [NSNumber numberWithFloat:bufferValue.floatValue];
			break;
		case  'd':
			result = [NSNumber numberWithDouble:bufferValue.doubleValue];
			break;
	}
	return result;
}

//---(Private)-- Convert VARCHAR buffer into NSString (VARCHAR2, CHAR, TIMESTAMP++) -----
- (id)stringValueForVarchar
{
    // This is a string where the buffer was LESS than SIMPLE_BUFFER_SIZE
	// target can be NSString or NSData
    return [NSString stringWithUTF8String:(char *)bufferValue.simplePtr];
}

//---(Private)-- Convert LONG VARCHAR buffer into NSString -----
- (id)stringValueForLongChar
{
    id      result = nil;
    BOOL    needFree;
    
    needFree = NO;
    // This is for when the buffer length is unknown or LARGER than SIMPLE_BUFFER_SIZE
    // for this type we have to REFETCH in order to get the size.
    if (bufferSize > 0)
    {
        bind->buffer_length= bufferSize;
        if (bufferSize >= SIMPLE_BUFFER_SIZE)
        {
            // make sure we have a null terminator for the string
            bufferValue.charPtr = calloc(bufferSize + 1, sizeof(unsigned char));
            bind->buffer= bufferValue.charPtr;
            needFree = YES;
        }
        else
        {
            memset(bufferValue.simplePtr, 0, SIMPLE_BUFFER_SIZE);
            bind->buffer= bufferValue.simplePtr;
        }
        if (mysql_stmt_fetch_column([channel stmt], bind, bindIndex, 0) == 0)
        {
            if (needFree)
                result = [NSString stringWithUTF8String:(char *)bufferValue.charPtr];
            else
                result = [NSString stringWithUTF8String:(char *)bufferValue.simplePtr];
        }
        if (needFree)
        {
            free(bufferValue.charPtr);
            bufferValue.charPtr = NULL;
        }
    }
    if (! result)
        result = [EONull null];
    
    return result;
}

//---(Private)-- Convert from a VARRAW buffer to NSData
- (id)dataValueForForChar
{
    id result = nil;
    BOOL    needFree;
    
    needFree = NO;
    // This is for binary data
    // for this type we have to REFETCH in order to get the size.
    if (bufferSize > 0)
    {
        bind->buffer_length= bufferSize;
        if (bufferSize > SIMPLE_BUFFER_SIZE)
        {
            bufferValue.charPtr = calloc(bufferSize, sizeof(unsigned char));
            bind->buffer= bufferValue.charPtr;
            needFree = YES;
        }
        else
        {
            memset(bufferValue.simplePtr, 0, SIMPLE_BUFFER_SIZE);
            bind->buffer= bufferValue.simplePtr;
        }
        if (mysql_stmt_fetch_column([channel stmt], bind, bindIndex, 0) == 0)
        {
            if (needFree)
                result = [[NSData alloc] initWithBytes:bufferValue.charPtr length:bufferSize];
            else
                result = [[NSData alloc] initWithBytes:bufferValue.simplePtr length:bufferSize];
            [result autorelease];
        }
        if (needFree)
        {
            free(bufferValue.charPtr);
            bufferValue.charPtr = NULL;
        }
    }
    if (! result)
        result = [EONull null];
    
    return result;
}

//---(Private)-- Convert from a DATE buffer to a NSDate
- (id)objectForDate
{
	id	result;
	
    NSDateComponents *dateComponents;
    NSCalendar *currentCalendar;
    
    dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setYear:bufferValue.dateTime.year];
    [dateComponents setMonth:bufferValue.dateTime.month];
    [dateComponents setDay:bufferValue.dateTime.day];
    [dateComponents setHour:bufferValue.dateTime.hour];
    [dateComponents setMinute:bufferValue.dateTime.minute];
    [dateComponents setSecond:bufferValue.dateTime.second];
    [dateComponents setNanosecond:bufferValue.dateTime.second_part/ 1000];
    currentCalendar = [NSCalendar currentCalendar];
    [currentCalendar setTimeZone:[attrib serverTimeZone]];
    // NSDate is not time zone dependent so we do not need to adjust time zones
    result = [[currentCalendar dateFromComponents:dateComponents] retain];
    [dateComponents release];
                                 
	return [result autorelease];
}

//---(Private)--- set the bind variable -------
// -- This is the main method, and it creates the bind for the attribute
- (void)createDefine
{
    BOOL				useWidth;
    
    // lets set our datatype and allocate the buffer to the max size
    // if the type is something big, long, raw clob then a call back will
    // allocate the buffer.
    dataType = [MySQLAdaptor dataTypeForAttribute:attrib useWidth:&useWidth];
    
    // depending upon the datatype things get set differently
    // the following are all the datatypes we currently support
    // if we encounter one not support we will throw an exception
    width = [attrib width];  // we will trust this to be correct
    is_unsigned = 0;
    if ([attrib valueType])
    {
        switch ([[attrib valueType] characterAtIndex:0])
        {
            case  'C': // unsigned char
            case  'S': // unsigned short
            case  'I': // usniged int
            case  'L': // unsigned long
            case  'Q': // unsigned long long
                is_unsigned = 1;
                break;
        }
    }
    is_null = 0;
    bind->buffer = NULL;
    bind->length = 0;
    bind->is_unsigned = 0;
    getLength = NO;

    switch (dataType)
    {
        case MYSQL_TYPE_TINY:
            // TINYINT
            // use signed char
            dataType = MYSQL_TYPE_TINY;
            if (is_unsigned)
            {
                usedValueType = 'C';
                bind->buffer = (char *)&bufferValue.uCharValue;
            }
            else
            {
                usedValueType = 'c';
                bind->buffer = (char *)&bufferValue.sCharValue;
            }
            bind->is_unsigned = is_unsigned;
            break;
        case MYSQL_TYPE_SHORT:
        case MYSQL_TYPE_YEAR:
            dataType = MYSQL_TYPE_SHORT;
            if (is_unsigned)
            {
                usedValueType = 'S';
                bind->buffer = (char *)&bufferValue.uShortValue;
            }
            else
            {
                usedValueType = 's';
                bind->buffer = (char *)&bufferValue.sShortValue;
            }
            bind->is_unsigned = is_unsigned;
            break;
        case MYSQL_TYPE_LONG:
        case MYSQL_TYPE_INT24:
            // INT
            // use int
            dataType = MYSQL_TYPE_LONG;
            if (is_unsigned)
            {
                usedValueType = 'I';
                bind->buffer = (char *)&bufferValue.uIntValue;
            }
            else
            {
                usedValueType = 'i';
                bind->buffer = (char *)&bufferValue.sIntValue;
            }
            bind->is_unsigned = is_unsigned;
            break;
        case MYSQL_TYPE_LONGLONG:
            // BIGINT
            // use long long
            if (is_unsigned)
            {
                usedValueType = 'Q';
                bind->buffer = (char *)&bufferValue.uLLValue;
            }
            else
            {
                usedValueType = 'q';
                bind->buffer = (char *)&bufferValue.sLLValue;
            }
            bind->is_unsigned = is_unsigned;
            break;
        case MYSQL_TYPE_BIT:
            memset(bufferValue.simplePtr, 0, SIMPLE_BUFFER_SIZE);
            bind->buffer = bufferValue.simplePtr;
            bind->buffer_length= SIMPLE_BUFFER_SIZE;
            break;
        case MYSQL_TYPE_FLOAT:
            // FLOAT
            // use float
            usedValueType = 'f';
            bind->buffer = (char *)&bufferValue.floatValue;
            break;
        case MYSQL_TYPE_DOUBLE:
            // DOUBLE
            // use double
            usedValueType = 'd';
            bind->buffer = (char *)&bufferValue.doubleValue;
            break;
        case MYSQL_TYPE_TIME:
            // TIME
            // use MYSQL_TIME
        case MYSQL_TYPE_DATE:
            // DATE
            // use MYSQL_TIME
        case MYSQL_TYPE_DATETIME:
            // DATETIME
            // use MYSQL_TIME
        case MYSQL_TYPE_TIMESTAMP:
            // TIMESTAMP
            // use MYSQL_TIME
            // method: setDateValueForDateBuffer
            bind->buffer = (char *)&bufferValue.dateTime;
            break;
        case MYSQL_TYPE_NULL:
            // NULL
            // return EONull
            is_null = 1;
            bind->buffer = NULL;
            bind->length = 0;
            break;
        case MYSQL_TYPE_BLOB:
            // BLOB, BINARY, VARBINARY
            // use char[]
            // we get the size AFTER the fetch, then
            // refetch this column
            getLength = YES;
            bind->buffer_length= 0;
            bind->length= &bufferSize;
            break;
        case MYSQL_TYPE_DECIMAL:
        case MYSQL_TYPE_NEWDECIMAL:
            dataType = MYSQL_TYPE_NEWDECIMAL;
            memset(bufferValue.simplePtr, 0, SIMPLE_BUFFER_SIZE);
            bind->buffer = bufferValue.simplePtr;
            bind->buffer_length= SIMPLE_BUFFER_SIZE;
            break;
        case MYSQL_TYPE_STRING:
        case MYSQL_TYPE_VAR_STRING:
        case MYSQL_TYPE_VARCHAR:
            dataType = MYSQL_TYPE_STRING;
            if (width >= MAX_UTF8_WIDTH || width == 0)
            {
                // we get the size AFTER the fetch, then
                // refetch this column
                getLength = YES;
                bind->buffer_length= 0;
                bind->length= &bufferSize;
            }
            else
            {
                memset(bufferValue.simplePtr, 0, SIMPLE_BUFFER_SIZE);
                bind->buffer = bufferValue.simplePtr;
                bind->buffer_length = SIMPLE_BUFFER_SIZE;
                bind->length = &bufferSize;
            }
            break;
        case MYSQL_TYPE_SET:
        case MYSQL_TYPE_ENUM:
        default:
            // use char[]
            dataType = MYSQL_TYPE_STRING;
            // we get the size AFTER the fetch, then
            // refetch this column
            bind->buffer_length= 0;
            bind->length= &bufferSize;
            break;
    }
    
    bind->is_null = &is_null;
    bind->buffer_type = dataType;
}

//====================================================================================================
//                     Public Methods
//====================================================================================================

//--- Designated initializer
- (instancetype)initWithAttribute:(EOAttribute *)value
            channel:(MySQLChannel *)aChannel;
{
	if ((self = [super init]))
    {
        attrib = [value retain];
        channel = aChannel;
        bindArray = [channel bindArray];
        bind = NULL;
        getLength = NO;
    }
	return self;
}

- (unsigned int)bindIndex { return bindIndex; }
- (void)setBindIndex:(unsigned int)value
{
    bindIndex = value;
    bind = &bindArray[bindIndex];
    [self createDefine];
}

//----- Free things we allocated
- (void)dealloc
{
	[attrib release];
	[super dealloc];
}

// return the object value from the buffer
- (id)objectValue
{
	id object = nil;
	
	// if is_null is set, then just return EONull.
	if (is_null)
		return [EONull null];
	
    switch (dataType)
    {
        case MYSQL_TYPE_TINY:
        case MYSQL_TYPE_SHORT:
        case MYSQL_TYPE_LONG:
        case MYSQL_TYPE_LONGLONG:
        case MYSQL_TYPE_FLOAT:
        case MYSQL_TYPE_DOUBLE:
            object = [self objectValueFromScalar];
            break;
        case MYSQL_TYPE_TIME:
        case MYSQL_TYPE_DATE:
        case MYSQL_TYPE_DATETIME:
        case MYSQL_TYPE_TIMESTAMP:
             object = [self objectForDate];
            break;
        case MYSQL_TYPE_NULL:
            object = [EONull null];
            break;
        case MYSQL_TYPE_BLOB:
            object = [self dataValueForForChar];
            break;
        case MYSQL_TYPE_NEWDECIMAL:
            object = [self numberValueFromChar];
            break;
        case MYSQL_TYPE_BIT:
            object = [self numberValueFromBitChar];
            break;
        case MYSQL_TYPE_STRING:
        default:
            // use char[]
            if (getLength)
                object = [self stringValueForLongChar];
            else
                object = [self stringValueForVarchar];
            break;
    }

	if ([attrib valueFactoryMethodName])
	{
		// object is the primitive class type, we now need to 
		// convert that to the target customClass
		if (object)
		{
			// make sure our object is in the primative type we need
			Class valueClass = NSClassFromString([attrib valueClassName]);
			NSString	*primitiveTargetClassName;
			BOOL		customTypeisRawBytes = NO;
			switch ([attrib factoryMethodArgumentType])
			{
				case EOFactoryMethodArgumentIsNSData:
					primitiveTargetClassName = @"NSData";
					break;
				case EOFactoryMethodArgumentIsNSString:
					primitiveTargetClassName = @"NSString";
					break;
				case EOFactoryMethodArgumentIsBytes:
					primitiveTargetClassName = @"NSData";
					customTypeisRawBytes = YES;
					break;
				default:
					[NSException raise:EODatabaseException format:@"fetchRowWithZone: Unsupported factory data Type for custom object"];
					break;
			}
            object = [MySQLAdaptor convert:object toValueClassNamed:primitiveTargetClassName];
			if (customTypeisRawBytes)
				object = [valueClass performSelector:[attrib valueFactoryMethod] 
					withObject:(id)[(NSData *)object bytes]];
			else if ([attrib valueFactoryMethod])
				object = [valueClass performSelector:[attrib valueFactoryMethod] withObject:object];
		}
		else
			object = [EONull null];
	}
	else if (! object)
		object = [EONull null];
    else if (object != [EONull null])
		// convert the low level primitive object to the target class
		object = [MySQLAdaptor convert:object toValueClassNamed:[attrib valueClassName]];
	return object;	
}

- (EOAttribute *)attribute { return attrib; }

@end
