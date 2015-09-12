//
//  MySQLAdaptor.m
//  Adaptors
//
//  Created by Tom Martin on 9/12/15.
//
//

#import "MySQLAdaptor.h"

@implementation MySQLAdaptor

//=================================================================
//        Public Methods
//=================================================================

+ (NSString *)adaptorName
{
    return @"MySQL";
}

- (id)initWithName:(NSString *)aName;
{
    int		errcode = 0;
    
    if (self = [super initWithName:aName])
    {
         if (errcode != 0)
            [NSException raise:@"EOGeneralAdaptorException"
                        format:@"OCIEnvCreate failed with errcode = %d.", errcode];
    }
    
    return self;
}

- (void)dealloc
{
     [super dealloc];
}

- (EOAdaptorContext *)createAdaptorContext
{
    EOAdaptorContext	*context = nil;
    /*
    context = [[MySQLContext allocWithZone:[self zone]] initWithAdaptor:self];
    [adaptorContexts addObject:context];
    [context autorelease];
     */
    
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
                    dataType = SQLT_BDOUBLE;
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
    if ([vcn isEqualToString:@"NSCalendarDate"])
        return [NSCalendarDate dateWithString:value];
    if ([vcn isEqualToString:@"NSDate"])
    {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSDate *result = [formatter dateFromString:value];
        [formatter release];
        return result;
    }
    
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

+ (id)valueForClassNamed:(NSString *)vcn forNSDate:(NSDate *)value
{
    if ([vcn isEqualToString:@"NSCalendarDate"])
        return [value  dateWithCalendarFormat:nil timeZone:nil];
    
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
    else if ([value isKindOfClass:[NSCalendarDate class]])
        result = [self valueForClassNamed:aClassName forNSCalendarDate:(NSCalendarDate *)value];
    else if ([value isKindOfClass:[NSDate class]])
        result = [self valueForClassNamed:aClassName forNSDate:(NSDate *)value]; 
    else if ([value isKindOfClass:[NSData class]])
        result = [self valueForClassNamed:aClassName forNSData:(NSData *)value];
    
    if (! result)
        [NSException raise:EODatabaseException format:@"OracleAdaptor: Unable to convert object type to or from primitive adaptor object.  Target class is %@, source object is %@. Check for mismatch between database data type and object class type in model.", aClassName, NSStringFromClass([value class])];
    return result;
}

@end
