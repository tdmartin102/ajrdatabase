//
//  MySQLBindInfo.m
//  
//
//  Created by Tom Martin on 4/26/16.
/*  Copyright (C) 2011 Riemer Reporting Service, Inc.
 
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

#import "MySQLBindInfo.h"
#import "MySQLAdaptor.h"

//  ------ MYSQL Types (all of them)
//   1 MYSQL_TYPE_TINY,
//   2 MYSQL_TYPE_SHORT,
//   3 MYSQL_TYPE_LONG,
//   4 MYSQL_TYPE_FLOAT,
//   5 MYSQL_TYPE_DOUBLE,
//   6 MYSQL_TYPE_NULL,
//   7 MYSQL_TYPE_TIMESTAMP,
//   8 MYSQL_TYPE_LONGLONG,
//   9 MYSQL_TYPE_INT24,
//  10 MYSQL_TYPE_DATE,
//  11 MYSQL_TYPE_TIME,
//  12 MYSQL_TYPE_DATETIME,
//  13 MYSQL_TYPE_YEAR,
//  14 MYSQL_TYPE_NEWDATE,
//  15 MYSQL_TYPE_VARCHAR,
//  16 MYSQL_TYPE_BIT,
//  17 MYSQL_TYPE_TIMESTAMP2,
//  18 MYSQL_TYPE_DATETIME2,
//  19 MYSQL_TYPE_TIME2,
// 246  MYSQL_TYPE_NEWDECIMAL=246,
// 247 MYSQL_TYPE_ENUM=247,
// 248 MYSQL_TYPE_SET=248,
// 249 MYSQL_TYPE_TINY_BLOB=249,
// 250 MYSQL_TYPE_MEDIUM_BLOB=250,
// 251 MYSQL_TYPE_LONG_BLOB=251,
// 252 MYSQL_TYPE_BLOB=252,
// 253 MYSQL_TYPE_VAR_STRING=253,
// 254 MYSQL_TYPE_STRING=254,
// 255 MYSQL_TYPE_GEOMETRY=255

@implementation MySQLBindInfo

//====================================================================================================
//                     Private Methods
//====================================================================================================

//---(Private)--- set a MSQL_STRING buffer from a NSString, NSNumber, NSDecimal
- (void)setStringValueBuffer
{
    NSString        *str;
    unsigned char   *strPtr;
    
    // we need a NSString
    str = [MySQLAdaptor convert:value toValueClassNamed:@"NSString"];
    strPtr = (unsigned char *)[str UTF8String];
    valueSize = strlen((char *)strPtr);
    if (bufferSize < SIMPLE_BUFFER_SIZE)
    {
        strcpy((char *)bufferValue.simplePtr, (char *)strPtr);
        bind->buffer = bufferValue.simplePtr;
        bufferSize = SIMPLE_BUFFER_SIZE;
    }
    else
    {
        freeWhenDone = YES;
        bufferSize = (valueSize + 1) * sizeof(unsigned char);
        bufferValue.charPtr = calloc((valueSize + 1), sizeof(unsigned char));
        strcpy((char *)bufferValue.charPtr, (char *)strPtr);
        bind->buffer = bufferValue.charPtr;
    }
    bind->length = &valueSize;
    bind->is_null = 0;
}

//---(Private)--- Convert to scaler MYSQL types from a NSNumber.  Larger numbers
// will be stored as NSDecimalNumber most likely which are handled as strings typically.
// but sometimes a NSDecimalNumber is stored in a MYSQL_int or BIGINT in which case
// it will come through here, which is fine.
//
// The unsigned flag is not really handled very well.  The basic issue is that
// EOAttribute has no mechanizim for it.  IF however there is a scaler value type
// selected it can provide whether or not it should be treated as unsigned. So we will go
// with that.  It is a bit flaky but if carefully done it will work.
//---(Private)-- set a scalar buffer from NSNumber
- (void)setNumberValueScalarBuffer
{
    NSNumber	*num;
    
    // we need a NSNumber
    num = [MySQLAdaptor convert:value toValueClassNamed:@"NSNumber"];
    // try to get whether or not this is unsigned from the valueType
    // this may be flaky but it is better than no attempt at all.
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
    
    // dataValue should now be ONLY the values below
    bind->buffer_type = dataType;
    bind->is_null = 0;
    bind->length = 0;
    bind->is_unsigned = is_unsigned;
    
    switch (dataType)
    {
        case MYSQL_TYPE_TINY:
            // TINYINT
            // use signed char
            bufferValue.sCharValue = [num charValue];
            if (is_unsigned)
            {
                bufferValue.uCharValue = [num unsignedCharValue];
                bind->buffer = (char *)&bufferValue.uCharValue;
            }
            else
            {
                bufferValue.sCharValue = [num charValue];
                bind->buffer = (char *)&bufferValue.sCharValue;
            }
            break;
        case MYSQL_TYPE_SHORT:
            // SMALLINT
            // use short
            if (is_unsigned)
            {
                bufferValue.uShortValue = [num unsignedShortValue];
                bind->buffer = (char *)&bufferValue.uShortValue;
            }
            else
            {
                bufferValue.sShortValue = [num shortValue];
                bind->buffer = (char *)&bufferValue.sShortValue;
            }
            break;
        case MYSQL_TYPE_LONG:
            // INT
            // MYSQL_TYPE_INT24 gets translated to this
            // use int
            if (is_unsigned)
            {
                bufferValue.uIntValue = [num unsignedIntValue];
                bind->buffer = (char *)&bufferValue.uIntValue;
            }
            else
            {
                bufferValue.sIntValue = [num intValue];
                bind->buffer = (char *)&bufferValue.sIntValue;
            }
            break;
        case MYSQL_TYPE_LONGLONG:
            // BIGINT
            // use long long int
            if (is_unsigned)
            {
                bufferValue.uLLValue = [num  unsignedLongLongValue];
                bind->buffer = (char *)&bufferValue.uLLValue;
            }
            else
            {
                bufferValue.sLLValue = [num longLongValue];
                bind->buffer = (char *)&bufferValue.sLLValue;
            }
            break;
        case MYSQL_TYPE_FLOAT:
            // FLOAT
            // use float
            bufferValue.floatValue = [num floatValue];
            bind->buffer = (char *)&bufferValue.floatValue;
            break;
        case MYSQL_TYPE_DOUBLE:
            // DOUBLE
            // use double
            bufferValue.doubleValue = [num doubleValue];
            bind->buffer = (char *)&bufferValue.doubleValue;
            break;
    }
}

//---(Private)-- Convert a NSData to a char buffer
- (void)setDataValueBuffer
{
    // primitive target can be NSData
    // The buffer is our internal buffer allocated to the maxiume size for RAW (2000 bytes + 2)
    // This is used for RAW only
    //
    NSData	*data;
    data = [MySQLAdaptor convert:value toValueClassNamed:@"NSData"];
    
    bufferSize = [data length];
    valueSize = bufferSize;
    if (bufferSize <= SIMPLE_BUFFER_SIZE)
    {
        [data getBytes:bufferValue.simplePtr];
        bind->buffer = bufferValue.simplePtr;
    }
    else
    {
        freeWhenDone = YES;
        bufferValue.charPtr = calloc(bufferSize, sizeof(unsigned char));
        [data getBytes:bufferValue.charPtr];
        bind->buffer = bufferValue.charPtr;
    }
    bind->length = &valueSize;
    bind->is_null = 0;
}

//---(Private)-- Convert to a DATE buffer fron a NSCalendarDate or NSDate if this is 10.6 or better
- (void)setDateValueForDateBuffer
{
    if (! value)
    {
        is_null = 1;
        bind->buffer_type = MYSQL_TYPE_NULL;
        bind->is_null = &is_null;
        bind->buffer = NULL;
        bind->length = 0;
        return;
    }
    
    is_null = 0;
    bind->buffer_type = dataType;
    bind->buffer = (char *)&bufferValue.dateTime;
    bind->is_null = &is_null;
    bind->length = 0;
    
    NSDate *aDate = [MySQLAdaptor convert:value toValueClassNamed:@"NSDate"];
    NSDateComponents *dateComponents;
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    // write time in server time zone
    [currentCalendar setTimeZone:[attrib serverTimeZone]];
    NSUInteger	flags;
    flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSCalendarUnitNanosecond;
    dateComponents = [currentCalendar components:flags fromDate:aDate];
    bufferValue.dateTime.year = (unsigned int)[dateComponents year];
    bufferValue.dateTime.month = (unsigned int)[dateComponents month];
    bufferValue.dateTime.day = (unsigned int)[dateComponents day];
    bufferValue.dateTime.hour = (unsigned int)[dateComponents hour];
    bufferValue.dateTime.minute = (unsigned int)[dateComponents minute];
    bufferValue.dateTime.second = (unsigned int)[dateComponents second];
    // second_part is in miliseconds
    bufferValue.dateTime.second_part = [dateComponents nanosecond] * 1000;
}

//---(Private)-----
// move the data into the bind variable.  Note that the bind does not actually take place HERE
// the bind is actually done in MySQLChannel
- (void)createBind
{
    BOOL				useWidth;

    // lets set our datatype and allocate the buffer to the max size
    // if the type is something big, long, raw clob then a call back will
    // allocate the buffer.
    dataType = [MySQLAdaptor dataTypeForAttribute:attrib useWidth:&useWidth];
    
    
    // depending upon the datatype things get set differently
    // the following are all the datatypes we currently support
    // if we encounter one not support we will throw an exception
    freeWhenDone = NO;
    
    //  MYSQL_TYPE_STRING
    if (! value)
    {
        bind->buffer_type = dataType;
        bind->is_null = &is_null;
        bind->buffer = NULL;
        bind->length = 0;
    }
    else
    {
        switch (dataType)
        {
            case MYSQL_TYPE_TINY:
            case MYSQL_TYPE_BIT:
                // TINYINT
                // use signed char
                dataType = MYSQL_TYPE_TINY;
                [self setNumberValueScalarBuffer];
                break;
            case MYSQL_TYPE_SHORT:
            case MYSQL_TYPE_YEAR:
                dataType = MYSQL_TYPE_SHORT;
                [self setNumberValueScalarBuffer];
                break;
            case MYSQL_TYPE_LONG:
            case MYSQL_TYPE_INT24:
                // INT
                // use int
                dataType = MYSQL_TYPE_LONG;
                [self setNumberValueScalarBuffer];
                break;
            case MYSQL_TYPE_LONGLONG:
                // BIGINT
                // use long long
            case MYSQL_TYPE_FLOAT:
                // FLOAT
                // use float
            case MYSQL_TYPE_DOUBLE:
                // DOUBLE
                // use double
                [self setNumberValueScalarBuffer];
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
                [self setDateValueForDateBuffer];
                break;
            case MYSQL_TYPE_NULL:
                // NULL
                // return EONull
                is_null = 1;
                bind->buffer_type = MYSQL_TYPE_NULL;
                bind->is_null = &is_null;
                bind->buffer = NULL;
                bind->length = 0;
                break;
            case MYSQL_TYPE_BLOB:
                // BLOB, BINARY, VARBINARY
                // use char[]
                [self setDataValueBuffer];
                break;
            case MYSQL_TYPE_DECIMAL:
            case MYSQL_TYPE_NEWDECIMAL:
            case MYSQL_TYPE_STRING:
            case MYSQL_TYPE_VAR_STRING:
            case MYSQL_TYPE_VARCHAR:
            case MYSQL_TYPE_SET:
            case MYSQL_TYPE_ENUM:
            default:
                // use char[]
                dataType = MYSQL_TYPE_STRING;
                [self setStringValueBuffer];
                break;
        }
    }
}

//====================================================================================================
//                     Public Methods
//====================================================================================================

- (instancetype)initWithBindDictionary:(NSDictionary *)aValue
                             mysqlBind:(MYSQL_BIND *)aBind;
{
    if ((self = [super init]))
    {
        bindDict = [aValue retain];
        bind = aBind;
        // get the attribute and value from the dictionary
        attrib = [[bindDict objectForKey:EOBindVariableAttributeKey] retain];
        value = [bindDict objectForKey:EOBindVariableValueKey];
        
        // if this is a custom class we need to convert it to a standard class
        value = [attrib adaptorValueByConvertingAttributeValue:value];
        [value retain];
        [self createBind];
    }
    
    return self;
}

- (void)dealloc
{
    [attrib release];
    [value release];
    [bindDict release];
    // our bind handle will be released when the statement is released.
    // free any memory we allocated
    if (freeWhenDone)
        free(bufferValue.charPtr);
    [super dealloc];
}

@end
