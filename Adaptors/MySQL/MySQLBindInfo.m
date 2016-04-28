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

#import "OracleDefineInfo.h"

#import "MySQLAdaptor.h"
#import "MySQLContext.h"
#import "MySQLChannel.h"

#import "AvailabilityMacros.h"

#define BUFFER_BLOCK_SIZE	2048

/*
@interface MySQLBindInfo ( Callback )
// oci callback support  NEVER CALL THESES !!!
- (ub4 *)pieceLen;
- (void)setPieceLen:(ub4)value;
- (unsigned char *)buffer;
- (sb4)bufferSize;
- (ub4)valueSize;
- (unsigned int)transferred;
- (void)putBufferPiece;
- (BOOL)isNull;
- (sb2 *)indicator;
- (void)setIndicator:(sb2)value;
@end
*/

/*
static sb4 ociInBindCallback(dvoid *ictxp, OCIBind *bindp, ub4 iter, ub4 index, dvoid **bufpp,
                             ub4 *alenp, ub1 *piecep, dvoid **indpp)
{
    OracleBindInfo	*bindInfo;
    ub4				toGo;
    ub4				valueLen;
    
    // ictxp - IN/OUT Our context, in this case is is an instance of OracleBindInfo
    // bindp - IN     dont care about bindp
    // iter -  IN     dont KNOW what iter is ....  it is IN only  (IN means it is given TO us, we do not SET it)
    // index - IN     Index of the current array ... not doing arrays so we ignore
    // bufpp - OUT    This is the buffer used by OCI for data, we create this and put data into this.
    // alenpp- OUT    size of the buffer we are providing ...
    //          soo.... this should be accessable by the OracleDefineInfo object.
    // piecep - OUT   Piece instruction
    // indpp  - OUT   This is the indicator variable pointer, if there is no data, we need to tell Oracle
    
    bindInfo = (OracleBindInfo *)ictxp;
    
    // If the value is null, this is a special cass, we tell Oracle and clean up
    // I'm thinking we can avoid this situation by not doing a dynamic in the case
    // where the value is null. Sooooo this code will probably never hit.
    if ([bindInfo isNull])
    {
        *indpp = [bindInfo indicator];
        [bindInfo setIndicator:-1];
        *piecep = OCI_LAST_PIECE;
        *alenp = 0;
        *bufpp = [bindInfo buffer];
        return OCI_CONTINUE;
    }
    
    // we have data
    // how much data is left?
    valueLen = [bindInfo valueSize];
    toGo = valueLen - [bindInfo transferred];
    // What to I set piece to if the piece is the first piece AND the last piece huh?
    // I am thinking maybe last_piece
    
    if (toGo <= BUFFER_BLOCK_SIZE)
        *piecep = OCI_LAST_PIECE;
    else if (toGo == valueLen)
        *piecep = OCI_FIRST_PIECE;
    else
        *piecep = OCI_NEXT_PIECE;
    [bindInfo setPieceLen:MIN(toGo, BUFFER_BLOCK_SIZE)];
    [bindInfo putBufferPiece];
    *bufpp = [bindInfo buffer];
    *alenp = *[bindInfo pieceLen];
    
    return OCI_CONTINUE;
}

static sb4 ociOutBindCallback(dvoid *octxp, OCIBind *bindp, ub4 iter, ub4 index, dvoid **bufpp,
                              ub4 **alenp, ub1 *piecep, dvoid **indpp, ub2 **rcodepp)
{
    [NSException raise:EODatabaseException format:@"OracleAdaptor: Out Bind called and we don't support that"];
    return OCI_CONTINUE;
}
*/

@implementation MySQLBindInfo

//====================================================================================================
//                     Private Methods
//====================================================================================================

//---(Private)--- Convience method to call Adaptors implementation of checkStatus
- (NSString *)checkStatusWithChannel:(OracleChannel *)channel;
{
    return [(MySQLAdaptor *)[[channel adaptorContext] adaptor] checkStatus:[channel mysql]];
}

/*
//---(Private)--- set a CHARZ buffer from a NSString, NSNumber, NSDecimal
- (void)setStringValueCharzBuffer
{
    NSString	*str;
    
    // we need a NSString
    str = [OracleAdaptor convert:value toValueClassNamed:@"NSString"];
    bufferSize = [str ociTextZLength];
    if (bufferSize <= SIMPLE_BUFFER_SIZE)
        buffer = bufferValue.simplePtr;
    else
    {
        freeWhenDone = YES;
        bufferValue.charPtr = NSZoneMalloc ([self zone], bufferSize);
        buffer = bufferValue.charPtr;
    }
    [str getOCIText:(text *)buffer];
}
*/

//---(Private)--- Convert scaler value Buffer into a NSNumber. We only handle value types cCsSiIfd
//                Types lLqQ do not use scaler values, but instead convert from a string, also
//                if no valueType is specified the object will be converted from a string as well.
//---(Private)-- set a scalar buffer from NSNumber
- (void)setNumberValueScalarBuffer
{
    NSNumber	*num;
    
    // we need a NSNumber
    num = [OracleAdaptor convert:value toValueClassNamed:@"NSNumber"];
    switch ([[attrib valueType] characterAtIndex:0])
    {
        case  'c':
        case  'C':
        case  's':
        case  'S':
        case  'i':
            bufferValue.intValue = [num intValue];
            bufferSize = sizeof(bufferValue.intValue);
            buffer = (unsigned char *)&bufferValue.intValue;
            break;
        case  'f':
            bufferValue.floatValue = [num floatValue];
            bufferSize = sizeof(bufferValue.floatValue);
            buffer = (unsigned char *)&bufferValue.floatValue;
            break;
        case  'd':
            bufferValue.doubleValue = [num doubleValue];
            bufferSize = sizeof(bufferValue.doubleValue);
            buffer = (unsigned char *)&bufferValue.doubleValue;
            break;
        default:
            bufferValue.intValue = 0;
            bufferSize = sizeof(bufferValue.intValue);
            buffer = (unsigned char *)&bufferValue.intValue;
            break;
    }
}

//---(Private)-- Convert from a BLOB buffer to NSData
- (void)setDataValueVarRawBuffer
{
    // primitive target can be NSData
    // The buffer is our internal buffer allocated to the maxiume size for RAW (2000 bytes + 2)
    // This is used for RAW only
    //
    /*
    ub2		len;
    NSData	*data;
    data = [OracleAdaptor convert:value toValueClassNamed:@"NSData"];
    
    len = [data length];
    bufferSize = len + 2;
    if (bufferSize <= SIMPLE_BUFFER_SIZE)
        buffer = bufferValue.simplePtr;
    else
    {
        freeWhenDone = YES;
        bufferValue.charPtr = NSZoneMalloc ([self zone], bufferSize);
        buffer = bufferValue.charPtr;
    }
    
    // the first two bytes are the length
    memcpy(buffer, &len, 2);
    [data getBytes:(buffer + 2)];
     */
}


//---(Private)-- Convert to a DATE buffer fron a NSCalendarDate or NSDate if this is 10.6 or better
//  Currently we are using this for TIMESTAMP datatypes as well, which means we are losing the
//  fractional seconds part for that type.
- (void)setDateValueForDateBuffer
{
    int y,m,d,h,mi,s;
    
    buffer = bufferValue.simplePtr;
    bufferSize = 7;
    if (! value)
    {
        memset(buffer,0,7);
        return;
    }
    
    NSDate *aDate = [OracleAdaptor convert:value toValueClassNamed:@"NSDate"];
    NSDateComponents *dateComponents;
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    // write time in server time zone
    [currentCalendar setTimeZone:[attrib serverTimeZone]];
    NSUInteger	flags;
    flags = NSYearCalendarUnit | NSMonthCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
    NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    dateComponents = [currentCalendar components:flags fromDate:aDate];
    y = [dateComponents year];
    m = [dateComponents month];
    d = [dateComponents day];
    h = [dateComponents hour];
    mi = [dateComponents minute];
    s = [dateComponents second];
    // year
    buffer[0] = (y / 100) + 100;
    buffer[1] = (y % 100) + 100;
    // month, day
    buffer[2] = m;
    buffer[3] = d;
    // hour minute second
    buffer[4] = h + 1;
    buffer[5] = mi + 1;
    buffer[6] = s + 1;
}

//=====================================================================================================
//                     Private Call Back Methods
//=====================================================================================================
- (ub4 *)pieceLen { return &pieceLen; }
- (void)setPieceLen:(ub4)aValue { pieceLen = aValue; }
- (unsigned char *)buffer { return buffer; }
- (sb4)bufferSize { return bufferSize; }

- (ub4)valueSize
{
    return valueSize;
}

- (unsigned int)transferred { return transferred; }
- (BOOL)isNull { return (value) ? NO : YES; }
- (sb2 *)indicator { return &indicator; }
- (void)setIndicator:(sb2)aValue { indicator = aValue; }

- (void)putBufferPiece
{
    NSRange	aRange;
    // This is dynamic
    // AND we KNOW the value has been converted to an NSString for SQLT_CHR
    // and NSData for SQLT_LBI
    
    if (dataType == SQLT_CHR)
    {
        // pieceLen MUST BE a multiple of sizeof(unichar)
        aRange.location = transferred / sizeof(unichar);
        aRange.length = pieceLen / sizeof(unichar);
        [(NSString *)value getCharacters:(unichar *)buffer range:aRange];
    }
    else
    {
        aRange.location = transferred;
        aRange.length = pieceLen;
        [(NSData *)value getBytes:(void *)buffer range:aRange];
    }
    transferred += pieceLen;
}

//====================================================================================================
//                     Public Methods
//====================================================================================================

- (instancetype)initWithBindDictionary:(NSDictionary *)aValue
{
    if ((self = [super init]))
    {
        bindHandle = NULL;
        
        
        bindDict = [aValue retain];
        
        // get the attribute and value from the dictionary
        attrib = [[bindDict objectForKey:EOBindVariableAttributeKey] retain];
        value = [bindDict objectForKey:EOBindVariableValueKey];
        
        // if this is a custom class we need to convert it to a standard class
        value = [attrib adaptorValueByConvertingAttributeValue:value];
        [value retain];
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
    free(placeHolder);
    [super dealloc];
}

- (void)createBindForChannel:(OracleChannel *)channel
{
    sword				status;
    int					width;
    BOOL				useWidth;
    BOOL				useNationalCharacterSet;
    NSString			*aString;
    
    // lets set our datatype and allocate the buffer to the max size
    // if the type is something big, long, raw clob then a call back will
    // allocate the buffer.
    dataType = [MySQLAdaptor dataTypeForAttribute:attrib useWidth:&[useWidth];
                
    
    // depending upon the datatype things get set differently
    // the following are all the datatypes we currently support
    // if we encounter one not support we will throw an exception
    width = [attrib width];  // we will trust this to be correct
    freeWhenDone = NO;
    
    // We tried lots of types but I decided on using the folowing:
    // SQLT_DAT (12 - DATE) for internal type:
    //		DATE
    //		method: objectForDate
    //		buffersize: 7
    // SQLT_VBI (15 - VARRAW) for internal type:
    //  		RAW
    //		method: objectForVarRaw
    //      	buffersize 2000 + 2
    // SQLT_BFLOAT (21 - native float) for internal type:
    //		BINARY_FLOAT and NUMBER when value type = 'f'
    //		method: objectValueForInt
    //		buffersize sizeof(float)
    // SQLT_BDOUBLE (22 - native double) for internal type:
    //		BINARY_DOUBLE and NUMBER when value type is 'd'
    //		method: objectValueForInt
    //		buffersize sizeof(double)
    // SQLT_INT (3 - INTEGER) for internal type:
    //		 NUMBER when the value type is less than 'I'
    //		method: objectValueForInt
    //		buffersize sizeof(unsigned int)
    // SQLT_AVC (97 - CHARZ) for internal type:
    // 		NUMBER when the value type is 'l' or greater, or there is no value type
    //		method: numberValueForCharz
    //		buffersize 90
    // SQLT_CHR (1- VARCHAR2) for internal types:
    //		LONG, CLOB, NCLOB,
    //		method: objectForVarchar2
    //		buffersize:  dynamic
    // SQLT_VCS (9 - VARCHAR) for internal types:
    //		VARCHAR2, NVARCHAR2, CHAR, NCHAR,
    //      TIMESTAMP, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH LOCAL TIME ZONE
    //		method: objectForVarchar
    //		buffersize:  attrib width + 2 for VARCHAR2, NVARCHAR2, CHAR, NCHAR
    //      300 for TIMESTAMP, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH LOCAL TIME ZONE
    // SQLT_LBI (24 - LONG RAW) for internal Types:
    //		LONG RAW, BLOB
    //		method: objectForLongRaw
    //		buffersize: dynamic
    
    //  MYSQL_TYPE_STRING
    
    switch (dataType)
    {
        case MYSQL_TYPE_TINY:
            // TINYINT
            // use signed char
            break;
        case MYSQL_TYPE_SHORT:
            // SMALLINT
            // short int
            break;
        case MYSQL_TYPE_LONG:
            // INT
            // use int
            break;
        case MYSQL_TYPE_LONGLONG:
            // BIGINT
            // use long long int
            break;
        case MYSQL_TYPE_FLOAT:
            // FLOAT
            // use float
            break;
        case MYSQL_TYPE_DOUBLE:
            // DOUBLE
            // use double
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
            break;
        case MYSQL_TYPE_NULL:
            // NULL
            // return EONull
            break;
        case MYSQL_TYPE_BLOB:
            // BLOB, BINARY, VARBINARY
            // use char[]
        case MYSQL_TYPE_STRING:
            // TEXT, CHAR, VARCHAR
            // use char[]
        default:
            // use char[]
            break;
    }
    
    if (! value)
        indicator = -1;
    switch (dataType)
    {
        case SQLT_VCS:   // VARCHAR used for:
            //   VARCHAR2, NVARCHAR2, CHAR, NCHAR,
            //   TIMESTAMP, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH LOCAL TIME ZONE
            //   but we will use CHARZ (SQLT_AVC)
        case SQLT_AVC:   // CHARZ used for:
            //   NUMBER  l,L,q,Q or no valueType, NSString
        case SQLT_VNU:   // VARNUM  not used
        case SQLT_STR:   // STRING not used
            dataType = SQLT_AVC;
            [self setStringValueCharzBuffer];
            break;
        case SQLT_DAT:   // DATE 12 used for DATE, TIMESTAMP
            [self setDateValueForDateBuffer];
            break;
        case SQLT_INT:      // ORANET TYPE integer 3  used for NUMBER c,C,s,S,i,I
        case SQLT_BFLOAT:   // Native Binary Float 21 used for BINARY_FLOAT, NUMBER f
        case SQLT_BDOUBLE:	// Native Binary Double 22 user for BINARY_DOUBLE, NUMBER d
            [self setNumberValueScalarBuffer];
            break;
        case SQLT_VBI: // VARRAW 15 - RAW
            [self setDataValueVarRawBuffer];
            break;
        case SQLT_CHR: // VARCHAR2 1 used for LONG, CLOB
        case SQLT_LBI: // LONG RAW 24 used for LONG RAW, BLOB
            // the buffer for both is identical
            // if this is null then do something SIMPLE
            if (! value)
            {
                bufferSize = 0;
                buffer = bufferValue.simplePtr;
            }
            else
            {
                // this IS dynamic
                mode = OCI_DATA_AT_EXEC;
                bufferSize = BUFFER_BLOCK_SIZE;
                freeWhenDone = YES;
                bufferValue.charPtr = NSZoneMalloc ([self zone], bufferSize);
                buffer = bufferValue.charPtr;
            }
            break;
        default:
            [NSException raise:EODatabaseException format:@"fetchRowWithZone: Unsupported external Oracle Datatype encountered (%d)", dataType];
            break;
    }
    
    // set ValueSize which is the TOTAL length of the data to be passed by oci to Oracle.  This is the
    // same as bufferSize UNLESS we are using a dynamic bind.
    if (dataType == SQLT_CHR)
        valueSize = [(NSString *)value length] * sizeof(unichar);
    else if (dataType == SQLT_LBI)
        valueSize = [(NSData *)value length];
    else
        valueSize = bufferSize;
    
    // create the bind handle
    bindHandle = NULL;
    indicator = 0;
    
    // get placeHolder
    aString = [bindDict objectForKey:EOBindVariablePlaceHolderKey];
    placeHolderLen = [aString ociTextLength];
    placeHolder = NSZoneMalloc([self zone], placeHolderLen + sizeof(unichar));
    [aString getOCIText:placeHolder];
    
    status = OCIBindByName((dvoid *)[channel stmthp], &bindHandle, [channel errhp], 
                           placeHolder, placeHolderLen, buffer, valueSize, dataType, (dvoid *)&indicator,
                           (ub2 *) 0, (ub2) 0, (ub4) 0, (ub4 *) 0, mode);
    
    if ((mode == OCI_DATA_AT_EXEC) && (status == OCI_SUCCESS))
        status = OCIBindDynamic(bindHandle, [channel errhp], (dvoid	*)self, ociInBindCallback, (dvoid	*)self, ociOutBindCallback);
    
    if ((status == OCI_SUCCESS) && (useNationalCharacterSet))
    {
        ub2 csid = OCI_UTF16ID;
        ub1 cform = SQLCS_NCHAR;
        
        // you must call set form BEFORE calling set character set
        status = OCIAttrSet((void *) bindHandle, (ub4) OCI_HTYPE_BIND, (void *) &cform, (ub4) 0,
                            (ub4)OCI_ATTR_CHARSET_FORM, [channel errhp]); 
        if (status == OCI_SUCCESS)
            status = OCIAttrSet((void *) bindHandle, (ub4) OCI_HTYPE_BIND, (void *) &csid, (ub4) 0,
                                (ub4)OCI_ATTR_CHARSET_ID, [channel errhp]); 
    }	
    
    NS_DURING
    [self checkStatus:status withChannel:channel];
    NS_HANDLER
    [channel cancelFetch];
    [localException raise];
    NS_ENDHANDLER	
}

@end
