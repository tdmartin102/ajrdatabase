//
//  OracleDefineInfo.m
//  Adaptors
//
//  Created by Tom Martin on 2/21/11.
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


#import "OracleDefineInfo.h"

#import "OracleContext.h"
#import "OracleChannel.h"

#import "AvailabilityMacros.h"

#define BUFFER_BLOCK_SIZE	2048

@interface OracleDefineInfo ( OCICallback )
// oci callback support  NEVER CALL THESES !!!
- (unsigned char *)newDynamicBuffer;
- (ub4 *)lastPieceLen;
- (sb2 *)indicator;
- (void)setPieceLen:(ub4)value;
- (NSMutableData *)dynamicData;
- (unsigned char *)buffer;
@end

// everything will be unicode
#define characterEncoding	NSUnicodeStringEncoding

static sb4 ociDefineCallback(dvoid *octxp, OCIDefine *defnp, ub4 iter, dvoid **bufpp, 
	ub4 **alenpp, ub1 *piecep, dvoid **indpp, ub2 **rcodep)
{
	OracleDefineInfo	*defineInfo;
		
	// octxp - Our context, in this case is is an instance of OracleDefineInfo
	// defnp - dont care about defnp
	// iter -  dont KNOW what iter is ....  it is IN only  (IN means it is given TO us, we do not SET it)
	// bufpp - This is the buffer used by OCI to put our value into, we need to create this.
	// alenpp - size of the buffer we are providing
	//          AFTER the peice fetch it is set to the actual number of bytes written to the buffer.
    //          soo.... this should be accessable by the OracleDefineInfo object.  This will remain
	//          the same until the last piece.
	// indpp  - This is the indicator variable pointer, This needs to be set to the defineInfo indicator
	//          so that it will get set there.  This is NOT set for OCI_FIRST_PIECE, it is set after
	//          the first peice fecth.
	// rcodep - return code pointer, we don't use this because we DO use itne indicator.
	
	defineInfo = (OracleDefineInfo *)octxp;
	switch (*piecep)
	{
		case OCI_FIRST_PIECE:
			// we have no data yet, initialize / reset our buffer
			*bufpp = [defineInfo newDynamicBuffer];
			*alenpp = [defineInfo lastPieceLen];
			*indpp = [defineInfo indicator];
			[defineInfo setPieceLen:BUFFER_BLOCK_SIZE];
			break;
		case OCI_ONE_PIECE:
			// This should not happen
			break;
		case OCI_NEXT_PIECE:
			*piecep = OCI_NEXT_PIECE;
			// add to our NSData buffer and re-use the old character buffer
            // The length read is not predictable
            [[defineInfo dynamicData] appendBytes:(const void *)*bufpp length:**alenpp];
            
			break;
	}
	
	return OCI_CONTINUE;
}

@implementation OracleDefineInfo

//====================================================================================================
//                     Private Methods
//====================================================================================================

//---(Private)--- Convience method to call Adaptors implementation of checkStatus
- (NSString *)checkStatus:(sword)status withChannel:(OracleChannel *)channel;
{
	return [(OracleAdaptor *)[[channel adaptorContext] adaptor] checkErr:status inHandle:[channel errhp]];
}

//---(Private)--- Convert VARCHAR from CHARZ buffer to NSString (not used)
- (id)stringValueForCharz
{
	// This is no longer used,  but I'm going to leave it here, just in case I change my mind
	// target can be NSString or NSData	
	// if the target is NSData, I think we should STILL convert it to a string so that
	// we can handle the character encodings.  Frankly using NSData would be strange.  Why use
	// a oracle character field if you want raw data.  If you want raw data you should
	// be using raw, long raw, BLOB or some such NOT CHAR, NCHAR, VARCHAR2 or NVARCAR2
	// but ....  We will hand back UTF8 converted from whatever is in the database 
	// which is probably UTF8 or maybe Latin1 	
	return [NSString stringFromOCIText:(text *)buffer];
}

//---(Private)--- Convert NUMBER from CHARZ buffer to NSNumber or NSDecimalNumber
- (id)numberValueForCharz
{
	// target is NSDecimalNumber (probably)
	// I WAS going to convert the raw data, (see objectValueFormVarnum, but because NSDecmailNumber has no way 
	// of setting the mantisa othe than using a long long, I would lose precision on numbers using greater than 
	// 20 digits.  There IS an option to create a decimal number using NSDecmal which would not lose any precision,
	// unfortunatly there is no way to set NSDecimal and its internal structure is private and undocumented.  So 
	// the ONLY safe way left is to convert the number from a string.
	return [NSString stringFromOCIText:(text *)buffer];	
}

//---(Private)--- Convert from a VARNUM buffer to a NSDecimalNumber (not used)
// The following works, BUT becuase ultimately it calls NSDecimailNumber 
// decimalNumberWithMantissa:exponent:isNegative it is fundementally flawed.  The NSDecimalNumber
// method uses an long long for the mantisa. Because if this, it is limited to 20 digits.
// NSDeicmalNumber internal limit is 32 digits and so is the Oracle Number.  The problem is
// THERE IS NO WAY I KNOW OF, or anyone else knows of, to directly create an NSDecimalNumber
// from the mantisa, exponent.  This is a real shame becuase this seems a lot more effiecent
// than parsing a string into a NSDecmialNumber but I guess this is what we will have to do.
// I am going to leave this code here because, well, it was a bit of work to figure out the 
// Oracle internal NUMBER structure.  
//
// Bottom line.  This method is here, but NEVER used.
- (id)objectValueForVarnum
{
	char	len;
	short	exponent;
	BOOL	isNeg;
	unsigned char c;
	unsigned long long m;
	unsigned char *bPtr;
	
	bPtr = buffer;
	len = *bPtr++ - 1;
	c = *bPtr++;
	if ( !(c & 0x80))
	{
		isNeg = YES;
		exponent = ((~c & 0x7F) - 65);
		--len; // ignore the terminator byte
	}
	else
	{
		isNeg = NO;
	    exponent = ((c & 0x7F) - 65);
	}
	if (len)
	{
		// convert our exponent from base 100 to base 10
		exponent *= 2;
		if (*bPtr > 9)
			++exponent;
	}
	
	// convert the mantissa bytes
	m = 0;
	while (len)
	{
		--len;
		c = *bPtr++;
		m *= 100;
		if (isNeg)
			m += (101 - c);
		else
			m += (c - 1) ;
	}
	
	return [NSDecimalNumber decimalNumberWithMantissa:m exponent:exponent isNegative:isNeg];
}

//---(Private)--- Convert scaler value Buffer into a NSNumber. We only handle value types cCsSiIfd
//                Types lLqQ do not use scaler values, but instead convert from a string, also
//                if no valueType is specified the object will be converted from a string as well.
- (id)objectValueForInt
{
	id		result;
	char	valueType;
	union {
		char			charValue;
		unsigned char	ucharValue;
		short			shortValue;
		unsigned short	ushortValue;
		int				intValue;
		unsigned int	uintValue;
		float			floatValue;
		double			doubleValue;
	} myValue;
		
    result = nil;
	valueType = [[attrib valueType] characterAtIndex:0];
	switch (valueType)
	{
		case  'c':
			myValue.charValue = bufferValue.intValue;
			result = [NSNumber numberWithChar:myValue.charValue];
			break;
		case  'C':
			myValue.ucharValue = bufferValue.intValue;
			result = [NSNumber numberWithUnsignedChar:myValue.ucharValue];
			break;
		case  's':
			myValue.shortValue = bufferValue.intValue;
			result = [NSNumber numberWithShort:myValue.shortValue];
			break;
		case  'S':
			myValue.ushortValue = bufferValue.intValue;
			result = [NSNumber numberWithUnsignedShort:myValue.ushortValue];
			break;
		case  'i':
			myValue.intValue = bufferValue.intValue;
			result = [NSNumber numberWithInt:myValue.intValue];
			break;
		case  'I':
			myValue.uintValue = (unsigned int)bufferValue.intValue;
			result = [NSNumber numberWithUnsignedInt:myValue.uintValue];
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
- (id)objectForVarchar
{
	// target can be NSString or NSData	
	// get the length first
	ub2		len;
	
	memcpy(&len, buffer, 2);
	return [NSString stringFromOCIText:(text *)(buffer + 2) length:len / 2];
}

//---(Private)-- Convert VARCHAR2 buffer into NSString (LONG, CLOB) -------
- (id)objectForVarchar2
{
	// target can be NSString or NSData	
	//
	// This was generated using dynamic data generation and the data is either in our
	// mutableData object and / or our buffer	
	if (lastPieceLen)
		[dynamicData appendBytes:(const void *)buffer length:lastPieceLen];
	return [NSString stringFromOCIText:(text *)[dynamicData bytes] length:(ub4)([dynamicData length] / 2)];
}

//---(Private)-- Convert LONG VARCHAR buffer into NSString (not used) -----
- (id)objectForLongVarchar
{
	// primitive target can be NSString or NSData
	// The buffer MAY be using dynamic data...  or not.	
	return [NSString stringFromVarLenOCIText:(text *)buffer];
}

//---(Private)-- Convert from a VARRAW buffer to NSData
- (id)objectForVarRaw
{
	// primitive target can be NSData
	// The buffer is our internal buffer allocated to the maxiume size for RAW (2000 bytes + 2) 
	// This is used for RAW only
	//
	ub2		len;
	id		result;

	// the first two bytes are the length
	memcpy(&len, buffer, 2);
	
	// we are NOT using dynamic allocation, get the data from our built in buffer
	result = [[NSData alloc] initWithBytes:buffer + 2 length:len];
	return [result autorelease];
}

//---(Private)-- Convert from a LONG RAW to NSData  (LONG RAW, BLOB)
- (id)objectForLongRaw
{
	// primitive target can be NSData
	// The buffer WILL be using dynamic data
	// This is used for LONG RAW, BLOB
	//	
	// we ARE using dynamic allocation, pump the last pience into our our NSData object
	if (lastPieceLen)
		[dynamicData appendBytes:(const void *)buffer length:lastPieceLen];
	return dynamicData;
}

//---(Private)-- Convert from a DATE buffer to a NSCalendarDate or NSData if this is 10.6 or better
//  Currently we are using this for TIMESTAMP datatypes as well, which means we are losing the
//  fractional seconds part for that type.   Supporting TIMESTAMP would not be that hard, but
//  I think the best route would be to use OCIDateTime as the buffer (SQLT_TIMESTAMP_TZ)
//  then create a NSDate using that, then ADD the fractional second to NSTimeInterval and
//  create a NEW NSDate with that time Interval.  Kind of crazy but I can't think of any clean way
//  to get directly from OCIDateTime to a NSTimeInterval
- (id)objectForDate
{
	int y;
	id	result;
	
	y = ((buffer[0] - 100) * 100) + (buffer[1] - 100);
	
    NSDateComponents *dateComponents;
    NSCalendar *currentCalendar;
    
    dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setYear:y];
    [dateComponents setMonth:buffer[2]];
    [dateComponents setDay:buffer[3]];
    [dateComponents setHour:buffer[4] - 1];
    [dateComponents setMinute:buffer[5] - 1];
    [dateComponents setSecond:buffer[6] - 1];
    currentCalendar = [NSCalendar currentCalendar];
    [currentCalendar setTimeZone:[attrib serverTimeZone]];
    // NSDate is not time zone dependent so we do not need to adjust time zones
    result = [[currentCalendar dateFromComponents:dateComponents] retain];
    [dateComponents release];
                                 
	return [result autorelease];
}

//====================================================================================================
//                     Public Methods
//====================================================================================================

//--- Designated initializer
- initWithAttribute:(EOAttribute *)value
{
	if (self = [super init])
    {
        attrib = [value retain];
        pos = -1;
    }
	return self;
}

//----- Free things we allocated
- (void)dealloc
{
	// A define handle is freed when the statment handle is freed
	// or when a new statement is prepared
	[attrib release];
	// free any memory we allocated
	if (freeWhenDone)
		NSZoneFree([self zone], bufferValue.charPtr);
		
	[dynamicData release];
	
	// our define handle will be released when the statement is released.
	// but we hang onto the statment so release it here
	// 2011-08-23 Changed this so that the statement handle is freed with
	// every call to evaluate.  This then frees the bing handle.  Calling
	// free here was causing errors.
	//OCIHandleFree((dvoid *) defineHandle, OCI_HTYPE_DEFINE);

	[super dealloc];
}

//-- Dynamic allocation method called from our callback function on the first call to the call back
//   This method creates a new NSMutableData object which we MUST release at some point.
- (unsigned char *)newDynamicBuffer
{
	// we will also be using our mutableData.  The buffer gets pumped into the dynamicData
	// with each round trip to Oracle, or to OCI, I am unsure if it truley means a round trip
	// to the database.  Buffer and data are released when this object is released.
	// But we will create this mutable Data buffer each and every time a variable is 
	// read in.  This is so we do not need to do a COPY when we hand this data off.
	[dynamicData release];
	dynamicData = [[NSMutableData alloc] initWithCapacity:BUFFER_BLOCK_SIZE];
	return buffer;
}

// -- This is the main method, and it creates the OCI define for the attribute
- (void)createDefineForChannel:(OracleChannel *)channel
{
	ub4					mode;
	sword				status;
	int					width;
	BOOL				useWidth;
	BOOL				useNationalCharacterSet;

	// lets set our datatype and allocate the buffer to the max size
	// if the type is something big, long, raw clob then a call back will
	// allocate the buffer.
	dataType = [OracleAdaptor dataTypeForAttribute:attrib useWidth:&useWidth nationalCharSet:&useNationalCharacterSet];
	
	// depending upon the datatype things get set differently
	// the following are all the datatypes we currently support
	// if we encounter one not support we will throw an exception
	width = [attrib width];  // we will trust this to be correct
	freeWhenDone = NO;
	mode = OCI_DEFAULT;	
	
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
	
	switch (dataType)
	{
		case SQLT_AVC:   // CHARZ used NUMBER ONLY l,L,q,Q or no valueType
			bufferSize = SIMPLE_BUFFER_SIZE;
			buffer = bufferValue.simplePtr;
			break;
		case SQLT_VNU:   // VARNUM  not used
			bufferSize = 22;
			buffer = bufferValue.simplePtr;			
			break;
		case SQLT_INT:   // ORANET TYPE integer 3  used for NUMBER c,C,s,S,i
			bufferSize = sizeof(unsigned int);
			buffer = (unsigned char *)&(bufferValue.intValue);
			break;			
		case SQLT_DAT:   // DATE 12 used for DATE, TIMESTAMP
			bufferSize = 7;
			buffer = bufferValue.simplePtr;
			break;
		case SQLT_BFLOAT:  // Native Binary Float 21 used for BINARY_FLOAT, NUMBER f
			bufferSize = sizeof(float);
			buffer = (unsigned char *)&(bufferValue.floatValue);
			break;
		case SQLT_BDOUBLE:	// Native Binary Double 22 user for BINARY_DOUBLE, NUMBER d
			bufferSize = sizeof(double);
			buffer = (unsigned char *)&(bufferValue.doubleValue);
			break;
		case SQLT_VBI: // VARRAW 15 - RAW
			bufferSize = 2002; // MAX SIZE of raw + ub2
			freeWhenDone = YES;
			bufferValue.charPtr = NSZoneMalloc ([self zone], bufferSize);
			buffer = bufferValue.charPtr;
			break;
		case SQLT_STR:
		case SQLT_VCS: // VARCHAR 9 used for (N)VARCHAR2, TIMESTAMP variants
			// if the dictionary value useWidth is YES then it must be varchar or char
			// if useWidth is YES, but we don't have one, then we will used the max
			// size for varchar
			if (useWidth)
			{
				if (! width) // this should be the BYTE size as defined in the database maybe ....
					width = 4000;  // max size for varchar
				bufferSize = (width * sizeof(unichar)) + 2;
				if (bufferSize <= SIMPLE_BUFFER_SIZE)
					buffer = bufferValue.simplePtr;
				else
				{
					freeWhenDone = YES;
					bufferValue.charPtr = NSZoneMalloc ([self zone], bufferSize);
					buffer = bufferValue.charPtr;
				}
			}
			else
			{
				// this MUST be a timestamp vairan, just use a buffer of 150 characters
				// and hope that it will be big enough.  it SHOULD be ...
				bufferSize = 300;
				freeWhenDone = YES;
				bufferValue.charPtr = NSZoneMalloc ([self zone], bufferSize);
				buffer = bufferValue.charPtr;
			}
			break;
		case SQLT_CHR: // VARCHAR2 1 used for LONG, CLOB
		case SQLT_LBI: // LONG RAW 24 used for LONG RAW, BLOB
			// the buffer for both is identical
			// this IS dynamic
			mode = OCI_DYNAMIC_FETCH;
			bufferSize = SB4MAXVAL;  // set to max size.  It took me awhile to figure out this was necessary.
			freeWhenDone = YES;
			bufferValue.charPtr = NSZoneMalloc ([self zone], BUFFER_BLOCK_SIZE);
			buffer = bufferValue.charPtr;
			break;
		default:
			[NSException raise:EODatabaseException format:@"fetchRowWithZone: Unsupported external Oracle Datatype encountered (%d)", dataType];
			break;
	}

	// create the define handle
	defineHandle = NULL;
	indicator = 0;
	status = OCIDefineByPos((dvoid *)[channel stmthp], &defineHandle, [channel errhp], 
			(ub4)pos, (dvoid *)buffer, bufferSize, dataType, (dvoid *)&indicator,
			(ub2 *)0, (ub2 *)0, mode );
	if ((mode == OCI_DYNAMIC_FETCH) && (status == OCI_SUCCESS))
		status = OCIDefineDynamic(defineHandle, [channel errhp], (dvoid	*)self, ociDefineCallback);

	if ((status == OCI_SUCCESS) && (useNationalCharacterSet))
	{
		ub2 csid = OCI_UTF16ID;
		ub1 cform = SQLCS_NCHAR;
		
		// you must call set form BEFORE calling set character set
		OCIAttrSet((void *) defineHandle, (ub4)  OCI_HTYPE_DEFINE, (void *) &cform, (ub4) 0,
           (ub4)OCI_ATTR_CHARSET_FORM, [channel errhp]); 
		OCIAttrSet((void *) defineHandle, (ub4)  OCI_HTYPE_DEFINE, (void *) &csid, (ub4) 0,
           (ub4)OCI_ATTR_CHARSET_ID, [channel errhp]); 
	}	
		
	NS_DURING
	[self checkStatus:status withChannel:channel];
	NS_HANDLER
	[channel cancelFetch];
	[localException raise];
	NS_ENDHANDLER	
}

// return the object value from the buffer
- (id)objectValue
{
	id object = nil;
	
	// if our indicator says nil, then just return EONull.
	if (indicator == -1)
		return [EONull null];
		
	if (indicator > 0 || indicator == -2)
		// the data was truncated on output. we should LOG something here
		[EOLog logErrorWithFormat:@"SQL Error: data truncated on fetch for %@.%@.  Original length was: %d\n", [[attrib entity] name], [attrib name], indicator];		
	
	switch (dataType)
	{
	    case SQLT_CHR:   // VARCHAR2 used for LONG, (N)CLOB, 
			object = [self objectForVarchar2];
			break;
		case SQLT_STR:
		case SQLT_AVC:   // CHARZ used for NUMBER
			// This can be NSString or NSData
			if ([attrib adaptorValueType] == EOAdaptorNumberType)
				object = [self numberValueForCharz];
			else
				object = [self stringValueForCharz]; // this should not be called, but if so, it will work.
			break;
		case SQLT_VNU:   // VARNUM could be used for NUMBER, but we don't do it. (not used)
			object = [self objectValueForVarnum];
			break;
		case SQLT_INT:   // ORANET TYPE integer 3
		case SQLT_BFLOAT:  // Native Binary Float 21
		case SQLT_BDOUBLE:	// Native Binary Double 22
			object = [self objectValueForInt];
			break;
		case SQLT_VCS:   // VARCHAR 9 used for VARCHAR2, CHAR, TIMESTAMP++
			object = [self objectForVarchar];
			break;
		case SQLT_DAT:   // DATE 12
			object = [self objectForDate];
			break;
		case SQLT_VBI:   // VARRAW
			object = [self objectForVarRaw];
			break;
		case SQLT_LVC:   // LONG VARCHAR (not used)
			object = [self objectForLongVarchar];
			break;
		case SQLT_LBI:   // LONG RRAW, BLOB
			object = [self objectForLongRaw];
			break;
		default:
			[NSException raise:EODatabaseException format:@"fetchRowWithZone: Unsupported external Oracle Datatype encountered (%d)", 
				dataType];
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
			object = [OracleAdaptor convert:object toValueClassNamed:primitiveTargetClassName];
			if (customTypeisRawBytes)
				object = [valueClass performSelector:[attrib valueFactoryMethod] 
					withObject:(id)[(NSData *)object bytes]];
			else if ([attrib valueFactoryMethod])
				object = [valueClass performSelector:[attrib valueFactoryMethod] withObject:object];
			// object not being created in correct zone, but no way to do it.
		}
		else
			object = [EONull null];
	}
	else if (! object)
		object = [EONull null];
	else
		// convert the low level primitive object to the target class
		object = [OracleAdaptor convert:object toValueClassNamed:[attrib valueClassName]];

	return object;	
}

- (void)setPos:(int)value { pos = value; }
- (int)pos { return pos; }
- (void)setDefine:(OCIDefine *)value { defineHandle = value; }
- (OCIDefine *)define { return defineHandle; }
- (EOAttribute *)attribute { return attrib; }
- (ub4 *)lastPieceLen { return &lastPieceLen; }
- (sb2 *)indicator { return &indicator; }
- (void)setPieceLen:(ub4)value { lastPieceLen = value; }
- (NSMutableData *)dynamicData { return dynamicData; }
- (unsigned char *)buffer { return buffer; }

@end
