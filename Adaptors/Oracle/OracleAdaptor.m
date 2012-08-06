//
//  OracleAdaptor.m
//  ociTest
//
//  Created by Tom Martin on 4/11/10.
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


#import "OracleAdaptor.h"
#import "OracleContext.h"
#import "OracleSQLExpression.h"
#import "OracleSchemaGeneration.h"

#define FALLBACK_TNS_ADMIN  @"/Library/Oracle/network/admin"
#define TNS_ADMIN_DEFAULT_KEY @"com.ajr.OracleAdaptor.TNS_ADMIN"

#import <wchar.h>

static ub4 ociMode = OCI_DEFAULT;
static NSMutableDictionary 	*dataTypes = nil;

@implementation NSString (OracleAdaptor)

// why wcslen returns an incorrect result is beyond me.  Soooo this does the same thing.  correctly.
+ (int)unicodeLen:(unichar *)ptr;
{
	int result = 0;
	if (! ptr)
		return result;
	while (*ptr++)
		++result;
	return result;
}

+ (NSString *)stringFromOCIText:(text *)value
{
	int len = [NSString unicodeLen:(unichar *)value];
	return [NSString stringWithCharacters:(unichar *)value length:len];
}

+ (NSString *)stringFromOCIText:(text *)value length:(ub4)len
{
	return [NSString stringWithCharacters:(unichar *)value length:len];
}

+ (NSString *)stringFromVarLenOCIText:(text *)value
{
	ub4 len;
	memcpy(&len,value,4);  // this is the BYTE length, but we need the character length
	len /= sizeof(unichar);
	// I would prefer stringWithCharacters:length:noCopy: but alas no method exists of that
	// type and I just don't want to subclass NSString just so I can get it.
	return [NSString stringWithCharacters:(unichar *)(value + 4) length:len];
}

- (unsigned int)ociTextZLength
{
	return ([self length] + 1) * sizeof(unichar);
}

- (unsigned int)ociTextLength
{
	return ([self length]) * sizeof(unichar);
}

- (text *)ociText
{
	unichar *buffer;
	unsigned int	len;
	
	// add on a null terminator becuse SOMETIMES this is required.
	len = [self ociTextZLength];
	buffer = [EOAutoreleasedMemory autoreleasedMemoryWithCapacity:len];
	// set null terminator
	memset((buffer + len - sizeof(unichar)), 0, sizeof(unichar));
	[self getCharacters:buffer];
	
	return (text *)buffer;
}

- (void)getOCIText:(text *)buffer
{
	unsigned int	len;

	// add on a null terminator becuse SOMETIMES this is required.
	len = [self ociTextZLength];
	memset((buffer + len - sizeof(unichar)), 0, sizeof(unichar));
	[self getCharacters:(unichar *)buffer];
}

@end


@implementation OracleAdaptor

//=================================================================
//        Private Methods
//=================================================================

//=================================================================
//        Public Methods
//=================================================================

+ (void)initialize
{	
	if (dataTypes == nil) 
	{
		NSBundle		*bundle = [NSBundle bundleForClass:[self class]];
		NSString		*path;
		
		path = [bundle pathForResource:@"OracleDataTypes" ofType:@"plist"];
		
		if (path) 
		{
			dataTypes = [[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL] propertyList] retain];
			if (!dataTypes) 
				[NSException raise:NSInternalInconsistencyException format:@"Unable to load Oracle data types."];
		} 
		else 
			[NSException raise:NSInternalInconsistencyException format:@"Unable to find Oracle data types."];
	}
}

+ (void)load 
{
	NSDictionary		*environment;
	NSString			*tnsLocation;
    NSUserDefaults		*defaults;
	BOOL				tnsSet;

   	// set the environment varible TNS_ADMIN to the path of the tnsnames.ora file
	// int putenv(const char *string);
	// we should be doing something more clever here such as grabbing this from
	// the defaults system
	// 1) Check to see if a default is set for TNS_ADMIN
	// 2) Check to see if TNS_ADMIN is already set
	// 3) Check to see if ORACLE_HOME is already set
	// 4) set default

	tnsSet = NO;
	// Check defaults
	defaults = [NSUserDefaults standardUserDefaults];
	tnsLocation = [defaults objectForKey:TNS_ADMIN_DEFAULT_KEY];
	if (tnsLocation)
		tnsSet = YES;
		
	// Try the environment
	if (! tnsSet)
	{
		environment = [[NSProcessInfo processInfo] environment];
		if ([environment objectForKey:@"TNS_ADMIN"])
		{
			// TNS_ADMIN was set in the environment so we do nothing
			tnsSet = YES;
		}
		else if ([environment objectForKey:@"ORACLE_HOME"])
		{
			// ORACLE_HOME was set in the environment so we do nothing
			tnsSet = YES;
		}
	}
	
	// Do Fallback if we found nothing
	if (! tnsSet)
		tnsLocation = FALLBACK_TNS_ADMIN;
		
	// set the TNS location if we need to. user setenv here becuase putenv does not copy the buffer
	// and the source buffer should never be altered or freed.  Obviously that is a problem here.
	if (tnsLocation)
		setenv("TNS_ADMIN",  [tnsLocation UTF8String], 1);
}

+ (NSString *)adaptorName
{
   return @"Oracle";
}

+ (ub4)ociMode { return ociMode; }
+ (void)setOciMode:(ub4)value { ociMode = value; }

+ (NSArray *)externalTypesWithModel:(EOModel *)model
{
	NSMutableSet		*types = [NSMutableSet set];
	NSEnumerator		*enumerator = [dataTypes objectEnumerator];
	NSDictionary		*entry;
	NSString			*external;
	
	while ((entry = [enumerator nextObject]) != nil) 
	{
		external = [entry objectForKey:@"externalType"];
		if (external)
			[types addObject:external];
	}
	
	return [[types allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

+ (NSDictionary *)dataTypes
{
	return dataTypes;
}

- (id)initWithName:(NSString *)aName;
{
	sword		errcode = 0;

	[super initWithName:aName];
	
	// create the Environment handle everything is realative to this.
	// errcode = OCIEnvCreate((OCIEnv **) &envhp, ociMode,
	//					   (dvoid *) 0, (dvoid * (*)(dvoid *,size_t)) 0,
	//					   (dvoid * (*)(dvoid *, dvoid *, size_t)) 0,
	//					   (void (*)(dvoid *, dvoid *)) 0, (size_t) 0, (dvoid **) 0);
	
	// we will do EVERYTHING in unicode
	errcode = OCIEnvNlsCreate((OCIEnv **)&envhp, ociMode,
							(void *)0, (void *(*) ()) 0, (void *(*) ()) 0,
							(void(*) ()) 0, (size_t) 0, (void **)0,
							(ub2)OCI_UTF16ID, /* Metadata and SQL CHAR character set */
							(ub2)OCI_UTF16ID /* SQL NCHAR character set */);
							
	if (errcode != 0)
		[NSException raise:@"EOGeneralAdaptorException" 
					format:@"OCIEnvCreate failed with errcode = %d.", errcode];
		
	return self;
}

- (void)dealloc
{	
	// our server handle should go when the environment handle goes
	OCIHandleFree((dvoid *) envhp, OCI_HTYPE_ENV);
	[super dealloc];
}

- (EOAdaptorContext *)createAdaptorContext
{
	EOAdaptorContext	*context;
	
	context = [[OracleContext allocWithZone:[self zone]] initWithAdaptor:self];
	[adaptorContexts addObject:context];
	[context autorelease];
	
	return context;
}

- (Class)defaultExpressionClass
{
   return [OracleSQLExpression class];
}

+ (Class)connectionPaneClass
{
	return NSClassFromString(@"OracleConnectionPane");
}

- (EOSchemaGeneration *)synchronizationFactory
{
	return [[[OracleSchemaGeneration allocWithZone:[self zone]] init] autorelease];
}

- (OCIEnv  *)envhp { return envhp; }

- (NSString *)checkErr:(sword)aStatus inHandle:(OCIError *)anErrhp
{
	text			errbuf[512];
	sb4				errcode = 0;
	NSString		*errStr;

	errStr = nil;
	switch (aStatus)
	{
		case OCI_SUCCESS:
			break;
		case OCI_SUCCESS_WITH_INFO:
			errStr = @"Error - OCI_SUCCESS_WITH_INFO";
			break;
		case OCI_NEED_DATA:
			errStr = @"Error - OCI_NEED_DATA";
			break;
		case OCI_NO_DATA:
			errStr = @"Error - OCI_NODATA";
			break;
		case OCI_ERROR:
			(void) OCIErrorGet((dvoid *)anErrhp, (ub4) 1, (text *) NULL, &errcode,
							   errbuf, (ub4) sizeof(errbuf), OCI_HTYPE_ERROR);							   
			errStr = [[NSString stringWithFormat:@"Error - %@", [NSString stringFromOCIText:errbuf]] retain];
			break;
		case OCI_INVALID_HANDLE:
			errStr = @"Error - OCI_INVALID_HANDLE";
			break;
		case OCI_STILL_EXECUTING:
			errStr = @"Error - OCI_STILL_EXECUTE";
			break;
		case OCI_CONTINUE:
			errStr = @"Error - OCI_CONTINUE";
			break;
		default:
			break;
	}
	if (errStr)
    {
        NSException *ouch;
        ouch = [[NSException alloc] initWithName:@"EOGeneralAdaptorException" reason:errStr userInfo:nil];
        [ouch raise];
    }
	return [errStr autorelease];
}

+ (ub2)dataTypeForAttribute:(EOAttribute *)attrib useWidth:(BOOL *)useWidth nationalCharSet:(BOOL *)useNationalCharSet
{
	NSDictionary		*dataTypes;
	NSDictionary		*dataTypeDict;
	ub2					dataType;
	unichar				valueType;

	dataTypes = [OracleAdaptor dataTypes];
	dataTypeDict = [dataTypes objectForKey:[attrib externalType]];
	dataType = [[dataTypeDict objectForKey:@"ociDataType"] intValue];
	if (! dataType)
		[NSException raise:EODatabaseException format:@"OracleAdaptor.dataTypeForAttribute: Attempt to read an unsupported Oracle Datatype '%@'",
			[attrib externalType]];
	if ([[dataTypeDict objectForKey:@"useWidth"] intValue])
		*useWidth = YES;
	else
		*useWidth = NO;
		
	if ([[dataTypeDict objectForKey:@"nationalCharSet"] intValue])
		*useNationalCharSet = YES;
	else
		*useNationalCharSet = NO;
	
	// if the external column is NUMBER then the dataType will be SQLT_AVC which
	// is fine for a valueClass of NSDecimalNumber, but for NSNumber we may want change the
	// type if the number is realatively small.  We will do this by using valueType 
	// if the valueType is less than a long or a double or float we will use native 
	// scalar variables.  If it is bigger than an int we will store it in a string and then
	// convert it.  This is what is ALWAYS is done for a NSDecimalNumber
	if ((dataType == SQLT_AVC) && ([[attrib valueClassName] isEqualToString:@"NSNumber"]))
	{
		if ([[attrib valueType] length])
		{
			valueType = [[attrib valueType] characterAtIndex:0];
			switch (valueType)
			{
				case  'c':
				case  'C':
				case  's':
				case  'S':
				case  'i':
					dataType = SQLT_INT;  // signed integer
					break;
				case  'f':
					dataType = SQLT_BFLOAT;
					break;
				case  'd':
					dataType = SQLT_BFLOAT;
					break;
				case  'I':
				case  'l':
				case  'L':
				case  'q':
				case  'Q':					
				default:
					// we will keep SQLT_AVC and convert a string to an NSNumber
					break;
			}
		}
	}
	
	return dataType;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
+ (NSCalendarDate *)calendarDateFromDate:(NSDate *)aDate
{
    NSCalendarDate  *result;
    NSCalendar *localCalendar = [NSCalendar currentCalendar];
    NSDateComponents *comp = [localCalendar components:(NSYearCalendarUnit |  NSMonthCalendarUnit
                                                    | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | 
                                                    NSSecondCalendarUnit) fromDate:aDate];
   
    result = [[NSCalendarDate alloc] initWithYear:[comp year]
                                            month:[comp month]
                                              day:[comp day]
                                             hour:[comp hour]
                                           minute:[comp minute]
                                           second:[comp second] 
                                         timeZone:[localCalendar timeZone]];
    
    return [result autorelease];
}
#endif

+ (id)valueForClassNamed:(NSString *)vcn forNSString:(NSString *)value
{	
	if ([vcn isEqualToString:@"NSString"]) 
		return value;
		
	if ([vcn isEqualToString:@"NSNumber"])
	{
		NSScanner	*scanner;
		long long	longLongValue;
		scanner = [[NSScanner allocWithZone:[self zone]] initWithString:value];
		[scanner scanLongLong:&longLongValue];
		[scanner release];
		return [NSNumber numberWithLongLong:longLongValue];
	}
	if ([vcn isEqualToString:@"NSDecimalNumber"])
		return [NSDecimalNumber decimalNumberWithString:value];
	if ([vcn isEqualToString:@"NSData"])
	{
		id result = [[NSData alloc] initWithBytes:[value UTF8String] 
			length:[value lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
		return [result autorelease];
	}
	
    #if MAC_OS_X_VERSION_MAX_ALLOWED > 1060   
        if ([vcn isEqualToString:@"NSDate"] || [vcn isEqualToString:@"NSCalendarDate"])
            return [NSDate dateWithString:value];
    #else
        if ([vcn isEqualToString:@"NSCalendarDate"])
            return [NSCalendarDate dateWithString:value];
        if ([vcn isEqualToString:@"NSDate"])
            return [NSDate dateWithString:value];
    #endif
    
	return nil;
}

+ (id)valueForClassNamed:(NSString *)vcn forNSData:(NSData *)value
{	
	if ([vcn isEqualToString:@"NSData"])
		return value;

	// NSString -- we COULD convert to Base64 or something, but ....
	// NSNumber
	// NSDecimalNumber
	// NSCalendarDate
	return nil;
}

+ (id)valueForClassNamed:(NSString *)vcn forNSNumber:(NSNumber *)value
{
	NSString	*str;	
	if ([vcn isEqualToString:@"NSNumber"])
		return value;
	
	// everything else is created from a string
	str = [value stringValue];
	if ([vcn isEqualToString:@"NSString"]) 
		return str;
		
	if ([vcn isEqualToString:@"NSData"])
	{
		id result = [[NSData alloc] initWithBytes:[str UTF8String] 
			length:[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
		return [result autorelease];
	}

	if ([vcn isEqualToString:@"NSDecimalNumber"])
		return [NSDecimalNumber decimalNumberWithString:str];
	
	// NSCalendarDate
	return nil;
}

+ (id)valueForClassNamed:(NSString *)vcn forNSDecimalNumber:(NSDecimalNumber *)value
{
	NSString	*str;

	if ([vcn isEqualToString:@"NSDecimalNumber"])
		return value;
	if ([vcn isEqualToString:@"NSNumber"])
		return value;
	
	// everything else is created from a string
	str = [value stringValue];
	if ([vcn isEqualToString:@"NSString"]) 
		return str;
		
	if ([vcn isEqualToString:@"NSData"])
	{
		id result = [[NSData alloc] initWithBytes:[str UTF8String] 
			length:[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
		return [result autorelease];
	}
	
	// NSCalendarDate
	return nil;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070   
+ (id)valueForClassNamed:(NSString *)vcn forNSCalendarDate:(NSCalendarDate *)value
{
	if ([vcn isEqualToString:@"NSCalendarDate"])
		return value;
	if ([vcn isEqualToString:@"NSDate"])
		return value;	
    
	if ([vcn isEqualToString:@"NSString"])
		return [value description];
    
	if ([vcn isEqualToString:@"NSData"])
	{
		NSString *str = [value description];
		id result = [[NSData alloc] initWithBytes:[str UTF8String] 
                                           length:[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
		return [result autorelease];
	}
	
	// NSNumber
	// NSDecimalNumber	
	return nil;
}
#endif

+ (id)valueForClassNamed:(NSString *)vcn forNSDate:(NSDate *)value
{
    #if MAC_OS_X_VERSION_MAX_ALLOWED < 1070   
	if ([vcn isEqualToString:@"NSCalendarDate"])
		return [self calendarDateFromDate:value];
    #endif
	if ([vcn isEqualToString:@"NSDate"])
		return value;	
    
	if ([vcn isEqualToString:@"NSString"])
		return [value description];
    
	if ([vcn isEqualToString:@"NSData"])
	{
		NSString *str = [value description];
		id result = [[NSData alloc] initWithBytes:[str UTF8String] 
                                           length:[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
		return [result autorelease];
	}
	
	// NSNumber
	// NSDecimalNumber	
	return nil;
}

+ (id)convert:(id)value toValueClassNamed:(NSString *)aClassName
{
	id result = nil;
	
	if (! value)
		return value;
	
	if ([value isKindOfClass:[NSString class]])
		result =  [self valueForClassNamed:aClassName forNSString:(NSString *)value];
	else if ([value isKindOfClass:[NSDecimalNumber class]])
		result = [self valueForClassNamed:aClassName forNSDecimalNumber:(NSDecimalNumber *)value];
	else if ([value isKindOfClass:[NSNumber class]])
		result = [self valueForClassNamed:aClassName forNSNumber:(NSNumber *)value];
    else if ([value isKindOfClass:[NSDate class]])
        result = [self valueForClassNamed:aClassName forNSDate:(NSDate *)value];
    #if MAC_OS_X_VERSION_MAX_ALLOWED < 1070   
        else if ([value isKindOfClass:[NSCalendarDate class]])
            result = [self valueForClassNamed:aClassName forNSCalendarDate:(NSCalendarDate *)value];
    #endif
	else if ([value isKindOfClass:[NSData class]])
		result = [self valueForClassNamed:aClassName forNSData:(NSData *)value];
		
	if (! result)
		[NSException raise:EODatabaseException format:@"OracleAdaptor: Unable to convert object type to or from primitive adaptor object.  Check for mismatch between database data type and object class type in model."];
	return result;

}

@end
