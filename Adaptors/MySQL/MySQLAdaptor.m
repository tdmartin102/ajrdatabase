//
//  MySQLAdaptor.m
//  Adaptors
//
//  Created by Tom Martin on 9/12/15.
//
//

#import "MySQLAdaptor.h"

#import <mysql.h>

@implementation MySQLAdaptor

//=================================================================
//        Public Methods
//=================================================================

+ (void)initialize
{
    if (dataTypes == nil)
    {
        NSBundle		*bundle = [NSBundle bundleForClass:[self class]];
        NSString		*path;
        
        path = [bundle pathForResource:@"MySQLDataTypes" ofType:@"plist"];
        
        if (path)
        {
            dataTypes = [[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL] propertyList] retain];
            if (!dataTypes)
                [NSException raise:NSInternalInconsistencyException format:@"Unable to load MySQL data types."];
        }
        else
            [NSException raise:NSInternalInconsistencyException format:@"Unable to find MySQL data types."];
    }
    if ([self class] == [MySQLAdaptor class])
    {
        if (mysql_library_init(0, NULL, NULL))
            [NSException raise:NSInternalInconsistencyException format:@"Could not initialize MySQL library."];
    }
}

+ (NSString *)adaptorName
{
    return @"MySQL";
}

/*
 As maintainer of a fairly large C application that makes MySQL calls from multiple threads, I can say I've had no problems with simply making a new connection in each thread. Some caveats that I've come across:
 
 Edit: it seems this bullet only applies to versions < 5.5; see this page for your appropriate version: Like you say you're already doing, link against libmysqlclient_r.
 Call mysql_library_init() (once, from main()). Read the docs about use in multithreaded environments to see why it's necessary.
 Make a new MYSQL structure using mysql_init() in each thread. This has the side effect of calling mysql_thread_init() for you.  mysql_real_connect() as usual inside each thread, with its thread-specific MYSQL struct.
 If you're creating/destroying lots of threads, you'll want to use mysql_thread_end() at the end of each thread (and mysql_library_end() at the end of main()). It's good practice anyway.
 Basically, don't share MYSQL structs or anything created specific to that struct (i.e. MYSQL_STMTs) and it'll work as you expect.
 
 This seems like less work than making a connection pool to me.
 */
    
- (id)initWithName:(NSString *)aName
{
    if (self = [super initWithName:aName])
    {
        if (mysql_library_init(0, NULL, NULL)) {
            [NSException raise:@"EOGeneralAdaptorException"
                        format:@"MySQL failed to initialize.  Most likely the mysql library was not found, or invalid."];
        }
        mysql = mysql_init(NULL);
    }
    
    return self;
}

- (void)dealloc
{
    mysql_close(mysql);
    mysql_library_end();
    [super dealloc];
}
    
- (NSString *)checkStatus:(MYSQL *)value
{
    NSString		*errStr = nil;
    const char      *str;
    
    str = mysql_error(mysql);
    if (str)
    {
        errStr = [NSString stringWithUTF8String:str];
        NSException *ouch;
        ouch = [[NSException alloc] initWithName:@"EOGeneralAdaptorException" reason:errStr userInfo:nil];
        [ouch raise];
    }
    return [errStr autorelease];
}
    
- (EOAdaptorContext *)createAdaptorContext
{
    EOAdaptorContext	*context = nil;
    
    context = [[MySQLContext allocWithZone:[self zone]] initWithAdaptor:self];
    [adaptorContexts addObject:context];
    [context autorelease];
    
    return context;
}

- (Class)defaultExpressionClass
{
    return [super defaultExpressionClass];
    //return [MySQLSQLExpression class];
}

+ (Class)connectionPaneClass
{
    return nil;
    // return NSClassFromString(@"MySQLConnectionPane");
}

- (EOSchemaGeneration *)synchronizationFactory
{
    return nil;
    // return [[[MySQLSchemaGeneration allocWithZone:[self zone]] init] autorelease];
}

/*
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
*/

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
