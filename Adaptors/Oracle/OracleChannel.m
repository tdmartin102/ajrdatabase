//
//  OracleChannel.m
//  ociTest
//
//  Created by Tom Martin on 8/30/10.
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


#import "OracleChannel.h"

#import "OracleAdaptor.h"
#import "OracleContext.h"
#import "OracleDefineInfo.h"
#import "OracleBindInfo.h"

#import "AvailabilityMacros.h"

@implementation OracleChannel
//=========================================================================================
//            Private Methods
//=========================================================================================

//---(Private)--- Return the Oracle Adaptor -------------------------
- (OracleAdaptor *)oraAdaptor
{
	return (OracleAdaptor *)[adaptorContext adaptor];
}

//---(Private----- return our environment handle
- (OCIEnv  *)envhp { return [(OracleAdaptor *)[adaptorContext adaptor] envhp]; }

- (NSString *)checkStatus
{
	return [(OracleAdaptor *)[adaptorContext adaptor] checkErr:status inHandle:errhp];
}

- (void)_getDatabaseEncoding
{
	// our database says it is WE8ISO8859P1 which is basically 8 bit single byte ASCII
      
	// it seems that ORACLE instant Client supports the following character sets
	// The following are all single byte character sets and can not be used
	// for the Oracle Natational character set
	// US7ASCII   -> NSASCIIStringEncoding
	// WE8DEC     -> NSASCIIStringEncoding  (not quite right, but should be close)
	// WE8MSWIN1252  -> NSWindowsCP1251StringEncoding
	// WE8ISO8859P1 -> NSISOLatin1StringEncoding
	//
	// AND then following Unicode character sets which can be used for the national
	// character set OR the database character set (except for AL16UTF16 which can
	// NOT be used for a database character set)
	// UTF8             -> NSUTF8StringEncoding   
	// AL16UTF16  (This is big endian which was hard to find out btw)  -> NSUTF16BigEndianStringEncoding  (National CS only)
	// AL32UTF8         -> NSUTF8StringEncoding 
   
	// I figure if the character set is not one of these I will just use
	// NSASCIIStringEncoding and a lossy conversion.  Oracle of course supports
	// MANY more character encodings, but I'm NOT so sure about OCI.  Also
	// as time goes by I am sure more and more people will use the
	// universal sets.
   
    //
	// It turns out that I can tell OCI to use UTF16 for both the database character set
	// and also the national character set.  This means it will CONVERT whatever it reads
	// to UTF16 internally.  So ALL of my buffers are in UTF16 regraless of whether the
	// internal type is VARCHAR  or NVARCHAR2 for instance.  This conversion would not be lossy
	// as UTF16 is a superset of any other character set.  Also to consider this conversion is
	// not a bad thing as NSStrings use UTF16 for there internal representation and so would
	// be converted to UTF16 ANYWAY at some point.  By doing this in OCI I am simplifying the
	// code and also most likely streamlining the process.  win win.
	//
	// SOOOO bottom line it really dosen't matter WHAT character set the database is using
	// except if we we're going to try to figure out if a string will FIT into a 
	// Oracle Column given the Oracle database character set and the source data.
	// I decieded not to bother checking, I will simply let Oracle throw an error if
	// it does not fit.
	//
    // Check out this oci call.  There may be more as well
    //	plus we can FETCH the character set type from the database
	//	if we have to.
    //	OCIINisEnvronmentVariableGet()
   
	//status = OCINlsEnvironmentVariableGet (dvoid *val, size_t size, ub2 item, ub2 charset, size_t *rsize);	
	//status = OCINlsEnvironmentVariableGet (dvoid *val, size_t size, OCI_NLS_CHARSET_ID, ub2 charset, size_t *rsize);

	//OCI_NLS_CHARSET_ID:
	//databaseEncoding = NSISOLatin1StringEncoding;
	//nationalDatabaseEncoding = NSUTF8StringEncoding;
	
	databaseEncoding = NSUnicodeStringEncoding;  // should be NSUTF16BigEndianStringEncoding but that is Leopard only
	nationalDatabaseEncoding = NSUnicodeStringEncoding;		
}

- (int)rowsAffected { return rowsAffected; }

- (int)parseErrorOffset 
{ 
	ub2 pe;
	
	status = OCIAttrGet(stmthp, OCI_HTYPE_STMT, (dvoid *)&pe, NULL, OCI_ATTR_PARSE_ERROR_OFFSET, errhp);
	if (status == OCI_SUCCESS)
		return pe;
	else
		return 0;
}

//---(Private)--- find the attribute in the evaluateAttributes by attempting to match the column names
- (int)indexOfAttribute:(EOAttribute *)attrib
{	
	EOAttribute	*anAttrib;
	id			enumArray;
	int			result, index;
	
	index = 0;
	result = -1;
	enumArray = [evaluateAttributes objectEnumerator];
	while ((anAttrib = [enumArray nextObject]) != nil)
	{
		if ([[anAttrib columnName] caseInsensitiveCompare:[attrib columnName]] == NSOrderedSame)
		{
			result = index;
			break;
		}
		++index;
	}
	if (result < 0)
	{
		// We are going to raise here.  I don't know what else to do.
		[NSException raise:EODatabaseException format:@"fetchRowWithZone: could not find attribute with column name %@ among fetched attributes.",
			[attrib columnName]];
	}
	return result;
}

//---(Private)---- create OCI binds using the expression bind dictionaries
- (void)createBindsForExpression:(EOSQLExpression *)expression
{
	id					bindEnum;
	NSMutableDictionary	*bindDict;
	OracleBindInfo		*oracleBindInfo;
	
	if (bindCache)
		[bindCache release];
	bindCache = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:
		[[expression bindVariableDictionaries] count] + 1];
	
	bindEnum = [[expression bindVariableDictionaries] objectEnumerator];
	while ((bindDict = [bindEnum nextObject]) != nil)
	{
		// associated with every bind is a bindHandle and a lot of info about
		// how to do a bind.  We will wrap all that in an object
		oracleBindInfo = [[OracleBindInfo alloc] initWithBindDictionary:bindDict];
		[bindCache addObject:oracleBindInfo];
		[oracleBindInfo release];
		[oracleBindInfo createBindForChannel:self];
	}
}

//---(Private)---- describe bindings for debug logging --------
- (NSString *)bindingsDescription:(NSArray *)b
{ 
	NSDictionary		*binding;
	id					enumArray = [b objectEnumerator]; 
	NSMutableString		*result;
	id					v;
	NSString			*str;
	
	result = [@"{" mutableCopy];
	while ((binding = [enumArray nextObject]) != nil)
	{
		[result appendString:(NSString *)[binding objectForKey:EOBindVariableNameKey]];
		[result appendString:@" = "];
		v = [binding objectForKey:EOBindVariableValueKey];
		if ([v isKindOfClass:[NSNumber class]])
			[result appendString:[v description]];
		else
		{
			[result appendString:@"'"];
			// output no more than the first 200 characaters
			str = [v description];
			if ([str length] > 200)
				str = [str substringToIndex:199];
			[result appendString:str];
			[result appendString:@"'"];
		}
		[result appendString:@"; "];
	}
	[result appendString:@"}"];
	
	return [result autorelease];
}

//=========================================================================================
//            Public (Oracle Adaptor ) Methods
//=========================================================================================
- (OCIStmt *)stmthp { return stmthp; }
- (OCIError *)errhp { return errhp; }
- (NSStringEncoding)nationalDatabaseEncoding { return nationalDatabaseEncoding; }
- (NSStringEncoding)databaseEncoding { return databaseEncoding; }

//=========================================================================================
//            Public (API) Methods
//=========================================================================================

- (id)initWithAdaptorContext:(EOAdaptorContext *)aContext
{	
	[super initWithAdaptorContext:aContext];
	
	(void) OCIHandleAlloc( (dvoid *) [self envhp], (dvoid **) &stmthp,
								   OCI_HTYPE_STMT, (size_t) 0, (dvoid **) 0);
	databaseEncoding = -1;
	
	return self;
}

- (void)dealloc
{
	if ([self isFetchInProgress]) {
		[self cancelFetch];
	}
	if ([self isOpen]) {
		[self closeChannel];
	}

	if (stmthp)
		OCIHandleFree((dvoid *) stmthp, OCI_HTYPE_STMT);
	
	// free our statement buffer if we have one
	if (statement)
		NSZoneFree([self zone], statement);

	// the session and error handle are freed when the session is closed
	[super dealloc];
}

- (void)openChannel
{
	NSDictionary	*cd;
	NSString		*strValue;
	ub4				len;

    if (connected)
      [NSException raise:EODatabaseException format:@"EOAdaptorChannel is already open"];
	  
	// If the adaptorContext has not yet attached to the server, then we need to do that
	// now
	if (! [adaptorContext hasOpenChannels])
		[(OracleContext *)adaptorContext attachToServer];
		
	// Create the Error handle
	(void) OCIHandleAlloc( (dvoid *) [self envhp], (dvoid **) &errhp, OCI_HTYPE_ERROR,
						  (size_t) 0, (dvoid **) 0);
			
	// allocate the session handle
	(void) OCIHandleAlloc((dvoid *)[self envhp], (dvoid **)&sessionhp,
						  (ub4) OCI_HTYPE_SESSION, (size_t) 0, (dvoid **) 0);
	
	// if there is a user id then set it. 
	cd = [[self oraAdaptor] connectionDictionary];
	strValue = (NSString *)[cd objectForKey:UserNameKey];
	if ([strValue length])
	{	
		// assuming our max username/password length is 30 characters, we will be
		// safe and not allow an overrun.
		len =  MIN(64,[strValue length] * sizeof(unichar));
		[strValue getOCIText:u];
		(void) OCIAttrSet((dvoid *) sessionhp, (ub4) OCI_HTYPE_SESSION,
						  (dvoid *) u, len,
						  (ub4) OCI_ATTR_USERNAME, errhp);
	}
	
	strValue = (NSString *)[cd objectForKey:PasswordKey];
	if ([strValue length])
	{	
		len =  MIN(64,[strValue length] * sizeof(unichar));
		[strValue getOCIText:p];
		(void) OCIAttrSet((dvoid *) sessionhp, (ub4) OCI_HTYPE_SESSION,
						  (dvoid *) p, len,
						  (ub4) OCI_ATTR_PASSWORD, errhp);
	}
	if ([self isDebugEnabled]) 
	{
		NSString *sid;
		sid = [cd objectForKey:ServerIdKey];
		if (! sid)
			sid = [cd objectForKey:ConnectionStringKey];
		[EOLog logDebugWithFormat:@"%@ attempting to connect with dictionary:{password = <password deleted for log>; serviceId = %@; userName = %@;}",
			[self description], sid, [cd objectForKey:UserNameKey]];
	}
	
	// this next step could certainly fail.
	status = OCISessionBegin ( (dvoid *)[(OracleContext *)adaptorContext serviceContexthp],  errhp, sessionhp, 
							  OCI_CRED_RDBMS, (ub4)OCI_DEFAULT);
	NS_DURING
	[self checkStatus];
	NS_HANDLER
	if ([self isDebugEnabled]) 
	{
		[EOLog logDebugWithFormat:@"%@ Failed to connect to Oracle database %@\n", 
		 [self description]];
	}
	[localException raise];
	NS_ENDHANDLER
	connected = YES;
	// set the user session attribute in the service context handle
	(void) OCIAttrSet ((dvoid *)[(OracleContext *)adaptorContext serviceContexthp], OCI_HTYPE_SVCCTX,
					   (dvoid *)sessionhp, (ub4) 0, OCI_ATTR_SESSION, errhp);
		
	if ([self isDebugEnabled]) 
	{
		[EOLog logDebugWithFormat:@"%@ Connected to Oracle database %@\n", 
			[self description], [cd objectForKey:ServerIdKey]];
	}

	if (databaseEncoding == -1) 
		[self _getDatabaseEncoding];
}

- (void)closeChannel
{
	if (!connected)
      [NSException raise:EODatabaseException format:@"The database connection has already been closed."];
	  
	// shutdown the session
	OCISessionEnd([(OracleContext *)adaptorContext serviceContexthp], errhp, sessionhp, [OracleAdaptor ociMode]);
	
	// free our handles
	OCIHandleFree((dvoid *) errhp, OCI_HTYPE_ERROR);
	OCIHandleFree((dvoid *) sessionhp, OCI_HTYPE_SESSION);
	
    connected = NO;

	// if there are no more open channels for this context then discounect the
	// context from the server
	if (! [adaptorContext hasOpenChannels])
		[(OracleContext *)adaptorContext detachFromServer];	
	
    if ([self isDebugEnabled]) 
		[EOLog logDebugWithFormat:@"%@ Disconnected from database.\n", 
		 [self description]];
}

- (BOOL)isFetchInProgress { return fetchInProgress; }

- (NSArray *)describeResults
{
	OCIParam			*param;
	sb4					paramStatus;
	ub2					dataType, colWidth;
	ub4					counter, colNameLen;
	ub1					nullOk;
	NSString			*colNameStr;
	text				*colName;
	EOAttribute			*tempAttribute;
	sb2					precision;
	sb1					scale;
	NSDictionary		*dataTypes;
	NSDictionary		*dataTypeDict;
	NSMutableArray		*rawAttributes;
	NSAutoreleasePool	*pool;

	if (! [self isFetchInProgress])
		[NSException raise:EODatabaseException format:@"describeResults called while a fetch was not in progress."];
		
	// regardless of whether of not the fetch attributes have been set
	// we will return what the DATABASE sees ad the restultig attributes
	// in other words we do NOT return fetchAttributes which may be set
	// by setAttributesToFetch, but rather what the AVAILABLE in the rulting
	// fetch.  
	
	//We MIGHT already know this if evaluateExpression was called
	if (evaluateAttributes)
		return evaluateAttributes;
	
	// get the parameters returned.
	// get the first param (if any) at position 1 (why not zero? strange)
	param = (OCIParam *)0;
	counter = 1;
	paramStatus = OCIParamGet((dvoid *)stmthp, OCI_HTYPE_STMT, errhp, (dvoid **)&param, counter);
	rawAttributes = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:30];

	// if that worked, get the rest
	while (paramStatus == OCI_SUCCESS)
	{
		pool = [[NSAutoreleasePool alloc] init];

		// Get the datatype
		status = OCIAttrGet((dvoid *)param, (ub4)OCI_DTYPE_PARAM, 
			(dvoid *)&dataType, (ub4 *)0, (ub4)OCI_ATTR_DATA_TYPE, errhp);
		[self checkStatus];
		
		// Get the column name
		colNameLen = 0;
		status = OCIAttrGet((dvoid *)param, (ub4)OCI_DTYPE_PARAM, 
			(dvoid **)&colName, (ub4 *)&colNameLen,(ub4) OCI_ATTR_NAME, errhp);
		[self checkStatus];
		colNameLen /= sizeof(unichar);
		colNameStr = [NSString stringFromOCIText:colName length:colNameLen];
		
		// Get the null status
		nullOk = 1;
		status = OCIAttrGet((dvoid *)param, (ub4)OCI_DTYPE_PARAM, 
			(dvoid **)&nullOk, (ub4 *)0, (ub4)OCI_ATTR_IS_NULL, errhp);
		[self checkStatus];
		
		// Get the length sysmantics
		//charSemantics = 0;
		//status = OCIAttrGet((dvoid *)param, (ub4)OCI_DTYPE_PARAM, 
		//	(dvoid *)&charSemantics, (ub4 *)0, (ub4) OCI_ATTR_CHAR_USED, errhp);
		//[self checkStatus];
		
		colWidth = 0;
		//if (charSemantics)
		//{
		//	// Get column width in characters
		//	status = OCIAttrGet((dvoid *)param, (ub4)OCI_DTYPE_PARAM, 
		//		(dvoid *)&colWidth, (ub4 *)0, (ub4) OCI_ATTR_CHAR_SIZE, errhp);
		//	[self checkStatus];
		//}
		//else
		//{
			// Get column width in bytes NO MATTER WHAT
			status = OCIAttrGet((dvoid *)param, (ub4)OCI_DTYPE_PARAM, 
				(dvoid *)&colWidth, (ub4 *)0, (ub4) OCI_ATTR_DATA_SIZE, errhp);
			[self checkStatus];
		//}
		
		// Build and store the column attribute						
		tempAttribute = [[EOAttribute alloc] init];
		[tempAttribute setName:[NSString stringWithFormat:@"Attribute%d", counter - 1]];
		[tempAttribute setColumnName:colNameStr];
		[tempAttribute setAllowsNull:(nullOk) ? YES : NO];

		// Look up the datatype and map it appropriately, but if we don't recognize the database, we can still treat as a string.
		dataTypes = [OracleAdaptor dataTypes];
		dataTypeDict = [dataTypes objectForKey:EOFormat(@"%d", dataType)];
		if (dataTypeDict) 
		{
			[tempAttribute setValueClassName:[dataTypeDict objectForKey:@"valueClassName"]];
			[tempAttribute setExternalType:[dataTypeDict objectForKey:@"externalType"]];
			[tempAttribute setValueType:[dataTypeDict objectForKey:@"valueType"]];
			
			#ifdef MAC_OS_X_VERSION_MAX_ALLOWED
				#if MAC_OS_X_VERSION_MAX_ALLOWED > 1060   
					// translate NSCalendarDate to NSDate if this is Lion or latter
					if ([[dataTypeDict objectForKey:@"valueClassName"] isEqualToString:@"NSCalendarDate"])
						[tempAttribute setValueClassName:@"NSDate"];
				#endif
			#else
				#error Max Version not defined and it HAS TO BE
			#endif                                         

			if ([[dataTypeDict objectForKey:@"isNumber"] intValue])
			{
				// Get scale and precission if we can
				status = OCIAttrGet((dvoid *)param, (ub4)OCI_DTYPE_PARAM, 
					(dvoid *)&precision, (ub4 *)0, (ub4) OCI_ATTR_PRECISION, errhp);
				[self checkStatus];
				
				status = OCIAttrGet((dvoid *)param, (ub4)OCI_DTYPE_PARAM, 
					(dvoid *)&scale, (ub4 *)0, (ub4) OCI_ATTR_SCALE, errhp);
				[self checkStatus];
				if (precision > 0)
				{
					[tempAttribute setPrecision:precision];
					if (scale > 0) // else is float
						[tempAttribute setScale:scale];
					else if (scale == -127)
					{
						// This is a FLOAT
						[tempAttribute setExternalType:@"FLOAT"];
						[tempAttribute setValueClassName:@"NSNumber"];
						[tempAttribute setValueType:@"f"];
					}
				}
				
				// set the value class according to the scale and precision
				// but only for the internal type 'NUMBER'
				if ([[tempAttribute externalType] isEqualToString:@"NUMBER"])
				{
					if (scale == 0 && (precision > 0 && precision < 10)) 
					{
						// int
						[tempAttribute setValueClassName:@"NSNumber"];
						[tempAttribute setValueType:@"i"];
					} 
					//else if (scale == 0 && precision < 20) 
					//{
						// long long
					//	[tempAttribute setValueClassName:@"NSNumber"];
					//	[tempAttribute setValueType:@"q"];
					//} 
					else 
					{
						[tempAttribute setValueClassName:@"NSDecimalNumber"];
						[tempAttribute setValueType:nil];
					}
				}
			}
			else if ([[dataTypeDict objectForKey:@"hasWidth"] intValue])
			{
				if (colWidth)
					[tempAttribute setWidth:colWidth];
			}
		} 
		else 
		{
			[EOLog logWarningWithFormat:@"Unknown data type for %@: %d  We treat it like a string with no width\n", [tempAttribute name], dataType];
			[tempAttribute setValueClassName:@"NSString"];
			[tempAttribute setExternalType:@"VARCHAR2"];
			[tempAttribute setValueType:@"s"];
		}
					
		if (tempAttribute)
		{
			[rawAttributes addObject:tempAttribute];
			[tempAttribute release];
		}
		
		// get the next param
		++counter;
		paramStatus = OCIParamGet((dvoid *)stmthp, OCI_HTYPE_STMT, errhp, (dvoid **)&param, counter);
		[pool release];
	}
	
	return [rawAttributes autorelease];
}

	/* Thoughts on conversions
	INTERNAL                 CODE   External       Value  Description   BufferLen   Default Data  Comments
	======================== ===    =============  ====	 ============	=========	==========
	VARCHAR2, NVARCHAR2        1    SQLT_LVC      94	  LONG VARCHAR	width		NSString		buffersize is defined column width
	NUMBER				       2    various                             90          NSNumber/NSDecimalNumber The type used depends upon precision and scale
	LONG                       8    SQLT_LVC	  94      LONG VARCHAR  dynamic		NSString	    dynamic memory allocation
	DATE                      12    SQLT_DAT      12	  DATE			7			NSDate
	RAW                       23    SQLT_VBI      15      VARRAW		2002		NSData
	LONG RAW                  24    SQLT_LVB      24      LONG VARRAW   dynamic		NSData			dynamic memory allocation
	ROWID	                  69    SQLT_RDD      104     OCIRowid							        not implemented
	CHAR, NCHAR               96    SQLT_LVC      94      LONG VARCHAR	width       NSString		buffersize is defined column width
	FLOAT					   2    SQLT_BFLOAT   12      BINARY FLOAT  float       NSNumber        detect FLOAT from NUMBER by scale = -127 (odd)
	BINARY_FLOAT             100    SQLT_BFLOAT   21      BINARY FLOAT  float       NSNumber
	BINARY_DOUBLE            101    SQLT_BDOUBLE  22      BINARY DOUBLE double		NSNumber
	VARRAY                   108    no
	REF                      111    no
	CLOB, NCLOB              112    SQLT_LVC	  94      LONG VARCHAR  dynamic     NSString        dynamic memory allocation
	BLOB                     113    SQLT_LVB      24      LONG VARRAW   dynamic     NSData          dynamic memory allocation
	BFILE                    114    no               
	TIMESTAMP                180    SQLT_DAT	  12      DATE          7           NSDate			(This should change, loses precision)
	TIMESTAMP WITH TIME ZONE 181    SQLT_DAT	  12      DATE          7           NSDate			(This should change, loses precision)
	INTERVAL YEAR TO MONTH   182    no             
	INTERVAL DAY TO SECOND   183    no
	UROWID                   208    SQLT_RDD      104     OCIRowid							        not implemented
	TIMESTAMP WITH LOCAL TZ  231    SQLT_DAT	  12      DATE          7           NSDate			(This should change, loses precision)e
	*/

- (void)evaluateExpression:(EOSQLExpression *)expression
{
	ub2			commandType;
	ub4			rowCount;
	NSString	*sqlString;
	ub4			len;
	ub4			iterations;

	if (!connected)
      [NSException raise:EODatabaseException format:@"The database is not connected durring an evaluateExpression:."];

	if ([self isFetchInProgress])
	      [NSException raise:EODatabaseException format:@"fetch in progress when evaluateExpression: called."];


	if (stmthp)
		OCIHandleFree((dvoid *) stmthp, OCI_HTYPE_STMT);
	stmthp = NULL;
	OCIHandleAlloc( (dvoid *) [self envhp], (dvoid **) &stmthp,
								   OCI_HTYPE_STMT, (size_t) 0, (dvoid **) 0);
								   
	sqlString = [[expression statement] retain];		
	if ([self isDebugEnabled])
	{ 
		if ([[expression bindVariableDictionaries] count] > 0)
			[EOLog logDebugWithFormat:@"%@ evaluateExpression: %@ With bindings:%@", [self description], sqlString, 
				[self bindingsDescription:[expression bindVariableDictionaries]]];
		else
			[EOLog logDebugWithFormat:@"%@ evaluateExpression: %@", [self description], sqlString];
	}
	
	// Check with our delegate
	if (_delegateRespondsTo.shouldEvaluateExpression)
	{
		if (![delegate adaptorChannel:self shouldEvaluateExpression:expression])
		{
			if ([self isDebugEnabled])
				[EOLog logDebugWithFormat:@"AdaptorChannel delegate responded 'NO' to shouldEvaluateExpression"];
			return;
		}
	}
	
	// if we are not in a transaction, then we need to create one and then END the transaction
	// once we are done with the statement or the fetch.	
	if (! [adaptorContext hasOpenTransaction])
	{
		localTransaction = YES;
		[adaptorContext beginTransaction]; 
	}
	else
		localTransaction = NO;		

	// prepare the SQL statement
	// convert the NSString into OCI text and KEEP it.
	// we will just keep our buffer and it will grow to the max statement length ever used.
	// This might not be a good idea, but I doubt statements will get huge.
	// buffer lentgh is string lengh + null terminator, all in unichar 
	len = [sqlString length] * sizeof(unichar);
	if (! statement)
		statement = NSZoneMalloc([self zone], len + sizeof(unichar));
	else if (statementLen < len)
		statement = NSZoneRealloc([self zone], statement, len + sizeof(unichar));
	statementLen = len;
	[sqlString getOCIText:statement];

    status = OCIStmtPrepare(stmthp, errhp, (OraText *)statement, len, (ub4)OCI_NTV_SYNTAX, (ub4)OCI_DEFAULT); 
	[sqlString release];
	[self checkStatus]; // okay to raise

	// If we have binds, then do that
	if ([[expression bindVariableDictionaries] count] > 0)
		[self createBindsForExpression:expression];  // okay to raise - will call cancel fetch
		
	// find out what kind of statement this is.
	OCIAttrGet(stmthp, OCI_HTYPE_STMT, (dvoid *)&commandType, NULL, OCI_ATTR_STMT_TYPE, errhp);
	iterations = 1;
	if (commandType == OCI_STMT_SELECT)
	{
		// we are doing a fetch
		fetchInProgress = YES;
		iterations = 0;
	}
	
	// execute the SQL
	status = OCIStmtExecute([(OracleContext *)adaptorContext serviceContexthp], stmthp, errhp, iterations, 0, 
		(OCISnapshot *)0, (OCISnapshot *)0, OCI_DEFAULT);

	NS_DURING	
	[self checkStatus];
	NS_HANDLER	
	[self cancelFetch];
	[localException raise];
	NS_ENDHANDLER

	if (! fetchInProgress)
	{
		// mont_rothstein @ yahoo.com 2005-06-26
		// Set number of rows affected by the expression so that it can be used to determine if the expression
		// evaluated successfully.
		// Tom.Martin @ Riemer.com 2010-01-21 
		// This should work for update, delete, but probably not for select ...
		// For that I am thinking that I will need to update it it with every call to fetch as it will
		// return whatever is in the buffer.		
		status = OCIAttrGet((dvoid *)stmthp, (ub4)OCI_HTYPE_STMT, 
							(dvoid *)&rowCount, (ub4 *)0, (ub4)OCI_ATTR_ROW_COUNT, errhp);
		rowsAffected = rowCount;
		if ([self isDebugEnabled])
			[EOLog logDebugWithFormat:@"%@ %d rows processed", [self description], rowsAffected];
		
		// this is not a fetch.  if a local transaction is in progress, then end it
		if (localTransaction)
		{
			[adaptorContext commitTransaction];
			localTransaction = NO;
		}
	}
	else
	{
		rowsAffected = 0;
		// If we are doing a select then we need attributes
		// get our attributes so that we can support someone setting attributesToFetch other than
		// the attributes ACTUALLY fetched
		// This HAS to be a non mutable array so that it we can check to see if 
		// fetchAttributes == evaluateAttributes
		// if fetchAttributes is already set, then these are the attributes
		if (! evaluateAttributes)
			evaluateAttributes = [[NSArray allocWithZone:[self zone]] initWithArray:[self describeResults]];
	}
		
	// Notify our delegate
	if (_delegateRespondsTo.didEvaluateExpression)
		[delegate adaptorChannel:self didEvaluateExpression:expression];
}

- (void)selectAttributes:(NSArray *)attributes fetchSpecification:(EOFetchSpecification *)fetch lock:(BOOL)lock entity:(EOEntity *)entity
{
	EOSQLExpression		*expression;
	
	if ([self isFetchInProgress])
		[NSException raise:EODatabaseException format:@"Attempt to select objects while a fetch was already in progress."];
	if (! [self isOpen])
		[NSException raise:EODatabaseException format:@"Attempt to select attributes on an unopened adaptor channel (%p).", self];

	fetchEntity = [entity retain];

	if ([attributes count] == 0)
		attributes = [fetchEntity attributes];
	// Make sure this won't change on us. Otherwise we'd get some really strange errors.
	fetchAttributes = [attributes mutableCopyWithZone:[self zone]];
	// by setting evaluateAttributes to fetchAttributes we are telling evaluateExpression that it does not
	// NEED to call describe results to describe the result set.  IF then subsequently fetchAttributes is not reset
	// by a call to setAttributesToFetch:, then fethAttributes will equal evaluateAttributes and finding the
	// attributes by possition is extremely easy.  No lookup need to be performed.
	evaluateAttributes = [fetchAttributes retain];
	
	// mont_rothstein @ yahoo.com 2005-09-22
	// When prepareSelectExpressionWithAttributes:... raised an exception (for example when a qualifier referenced items not in the model, the app basically locked up because the fetch was left open.  Modified to catch exception and cancel fetch.
	NS_DURING
	{
		expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:fetchEntity];
		// mont_rothstein @ yahoo.com 2005-06-23
		// Modified to pass in lock parameter
		[expression setUseAliases:YES];
		[expression prepareSelectExpressionWithAttributes:fetchAttributes 
													lock:[fetch locksObjects] 
									  fetchSpecification:fetch];
		[self evaluateExpression: expression];
	}
	NS_HANDLER
	{
		[expression release];
		[self cancelFetch];
		[localException raise];
	}
	NS_ENDHANDLER
	
	[expression release]; // We're now done with the expression.   
}

- (NSMutableDictionary *)fetchRowWithZone:(NSZone *)aZone
{
	NSMutableDictionary		*row;
	id						enumArray;
	EOAttribute				*attrib;
	OracleDefineInfo		*defineInfo;
	NSAutoreleasePool		*pool;
	BOOL					mustFindPosition;
	int						attribIndex;
	
	if (! [self isFetchInProgress])
		[NSException raise:EODatabaseException format:@"fetchRowWithZone: called while a fetch was not in progress."];
		
	if (! [fetchAttributes count])
		[NSException raise:EODatabaseException format:@"fetchRowWithZone: called with no fetch attributes set.."];

	if (! defineCache)
	{
		// before we do our fetch we need to set up all our defines
		// There are two different situations that must be handled in different ways...
		// if the fetch is a result of evaluateExpression:, then there is no guarantee that there is
		// a one to one relationship between the order and number of attributes and the order and
		// number of attributes returned.  In this case we must try to match the attribute to the 
		// COLUMN name and hope that all works out.
		//
		// If the fetch is a result of selectAttributes:fetchSpecification:lock:entity,
		// then there IS a one to one coralation between the attributes array and the
		// attributes that are feteched and we CAN rely upon the index value.
		//
		// The valueForAttribute:atIndex:inZone: blindly gets the value at the index supplied
		// so IF the fetch is a result of evaluateExpression we will attempt to determine
		// the index of the returned attribute before calling the method..  The way we will
		// do this is by comparing the current Attributes to the attributes generated
		// during evaluate (describeResults).  If the current attributes is exactly the 
		// same array, then there is no need to translate.  If it is different then we will
		// need to find the index.
		mustFindPosition = NO;
		if (evaluateAttributes)
		{
			// there is a VERY good chance that the fetchAttributes array is 
			// the SAME array as that returned by describeResults in which
			// case there is nothing we need to do
			if (evaluateAttributes != fetchAttributes)
				mustFindPosition = YES;  // darn
		}
		// else evaluateExpression: was not called

		// we need to create a define for every attribute in fetchAttributes
		defineCache = [[NSMutableArray allocWithZone:aZone] initWithCapacity:[fetchAttributes count]];
		enumArray = [[fetchAttributes objectEnumerator] retain];
		attribIndex = 1;
		while ((attrib = [enumArray nextObject]) != nil)
		{
			pool = [[NSAutoreleasePool allocWithZone:aZone] init];
			defineInfo = [[OracleDefineInfo allocWithZone:aZone] initWithAttribute:attrib];
			if (mustFindPosition)
			{
				attribIndex = [self indexOfAttribute:attrib];  // this can raise if it can not identify the attribute
				[defineInfo setPos:attribIndex + 1];
			}
			else
				[defineInfo setPos:attribIndex++];
			[defineInfo createDefineForChannel:self];	
			[defineCache addObject:defineInfo];
			[defineInfo release];
			[pool release];
		}
		[enumArray release];	
	}
		
    // 3rd parm is number of rows to fetch, 5th is record offest which is ignored with OCI_FETCH_NEXT
	status = OCIStmtFetch2(stmthp, errhp, (ub4)1, OCI_FETCH_NEXT, (sb4)0, OCI_DEFAULT);
	
	// check the status
	if (status == OCI_NO_DATA)
	{
		// we are done
		status = OCI_SUCCESS;
		fetchInProgress = NO;
	   // if we are in a local transaction, commit it
		if (localTransaction)
		{
			[adaptorContext commitTransaction];
			localTransaction = NO;
		}
		[self cancelFetch];
	}

	NS_DURING
	[self checkStatus];
	NS_HANDLER
	[self cancelFetch];
	[localException raise];
	NS_ENDHANDLER	
		
	if (fetchInProgress)
	{	
		++rowsAffected;
		row = [[NSMutableDictionary allocWithZone:aZone] initWithCapacity:[fetchAttributes count]];
		enumArray = [[defineCache objectEnumerator] retain];
		while ((defineInfo = [enumArray nextObject]) != nil)
		{
			pool = [[NSAutoreleasePool allocWithZone:aZone] init];
			[row setValue:[defineInfo objectValue] 
					forKey:[[defineInfo attribute] name]];
			[pool release];
		}
		[enumArray release];
	}
	else
		row = nil;
	
	return [row autorelease];
}

- (void)cancelFetch
{
	// clear attributes if any
	[fetchAttributes release];
	fetchAttributes = nil;
	
	[evaluateAttributes release];
	evaluateAttributes = nil;
	
	// clear our define cache
	[defineCache release];
	defineCache = nil;
	
	[bindCache release];
	bindCache = nil;
	
	// if a fetch is in progress cancel it.
	if (fetchInProgress)
	{
		fetchInProgress = NO;
		if ([self isDebugEnabled])
			[EOLog logDebugWithFormat:@"%@ %d rows processed", [self description], rowsAffected];
	   // 3rd parm is number of rows to fetch, which, to cancel the cursor is set to 0
		status = OCIStmtFetch2(stmthp, errhp, (ub4)0, OCI_FETCH_NEXT, (sb4)0, OCI_DEFAULT);
		[self checkStatus];
	}
	// if we are in a local transaction roll it back
	// if we are in a transaction but it is not local, then I figure it is the callers
	// responsibility to decide if the transaction needs to be commited, rolled back, 
	// or just continue on.
	if (localTransaction)
	{
		[adaptorContext commitTransaction];
		localTransaction = NO;
	}
}

- (unsigned int)updateValues:(NSDictionary *)row inRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
  EOSQLExpression     *expression;

   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression setUseAliases:NO];
   [expression prepareUpdateExpressionWithRow:row qualifier:qualifier];
   
    NS_DURING
	   [self evaluateExpression: expression];
   NS_HANDLER
	   [expression autorelease];
	   [localException raise];
   NS_ENDHANDLER
   
   // Evaluate starts a whole fetch cycle, so stop it from progressing.
   [self cancelFetch];
   
   [expression release];
   
   return rowsAffected;
}

- (void)insertRow:(NSDictionary *)row forEntity:(EOEntity *)entity;
{
   EOSQLExpression     *expression;

   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression setUseAliases:NO];
   [expression prepareInsertExpressionWithRow:row];
   
    NS_DURING
	   [self evaluateExpression: expression];
   NS_HANDLER
	   [expression autorelease];
	   [localException raise];
   NS_ENDHANDLER
   
   // Evaluate starts a whole fetch cycle, so stop it from progressing.
   [self cancelFetch];
   
   [expression release];
}

- (unsigned int)deleteRowsDescribedByQualifier:(EOQualifier *)qualifier entity:(EOEntity *)entity
{
   EOSQLExpression     *expression;

   expression = [[[[adaptorContext adaptor] expressionClass] allocWithZone:[self zone]] initWithRootEntity:entity];
   [expression setUseAliases:NO];
   [expression prepareDeleteExpressionForQualifier:qualifier];
   
   // mont_rothstein @ yahoo.com 2005-06-26
   // Modified to use evaluateExpression.
   //   [self execute:expression]; // release handled by above!
   NS_DURING
	   [self evaluateExpression: expression];
   NS_HANDLER
	   [expression autorelease];
	   [localException raise];
   NS_ENDHANDLER
   
   // mont_rothstein @ yahoo.com 2005-07-10
   // Added cancelFetch to clean up resources used by evaluateExpression
   // Evaluate starts a whole fetch cycle, so stop it from progressing.
   [self cancelFetch];
   
   [expression release];
   
   return rowsAffected;
}

- (NSArray *)primaryKeysForNewRowsWithEntity:(EOEntity *)entity count:(int)count
{
	NSMutableArray		*keys;
	NSArray				*attribs;
	NSString			*name;
	int					index;
	NSMutableString		*sql;
	id					pk;
	NSDictionary		*row;
	EOSQLExpression     *expression;
	
	// if primary key is compond, bail
	attribs = [entity primaryKeyAttributes];
	if ([attribs count] != 1)
		return nil;
		
	// I can't think of any way to optimize for multiple sequence numbers,
	// at least not safely.  So, we will get one at a time.
	name = [[(EOAttribute *)[attribs objectAtIndex:0] name] retain];	
	sql = [[NSMutableString allocWithZone:[self zone]] initWithCapacity:200];
	keys = [[NSMutableArray allocWithZone:[self zone]] initWithCapacity:count];
	[sql appendString:@"SELECT "];
	[sql appendString:[entity externalName]];
	[sql appendString:@"_SEQ.NEXTVAL FROM DUAL"];
	expression = [[[[adaptorContext adaptor] expressionClass] expressionForString:sql] retain];
	[sql release];
	for (index=0; index<count; ++index)
	{
		NS_DURING
			[self evaluateExpression: expression];
		NS_HANDLER
			[expression release];
			[keys release];
			[name release];
			[NSException raise:EODatabaseException format:@"unable to create next primary Key using Oracle Sequence for entity \"%@\": %@", 
				[entity externalName], [localException reason]];
		NS_ENDHANDLER
		[self setAttributesToFetch:[self describeResults]];
		row = [self fetchRowWithZone:[self zone]];
		pk = [[row allValues] objectAtIndex:0];
		if (pk)
			[keys addObject:[NSDictionary dictionaryWithObject:pk forKey:name]];
		[self cancelFetch];
	}
	[expression release];
	[name release];
	
	return [keys autorelease];
}

- (void)setAttributesToFetch:(NSArray *)someAttributes
{
	if (fetchAttributes != someAttributes) {
		[fetchAttributes release];
		fetchAttributes = [someAttributes retain];
	}
}

- (NSArray *)attributesToFetch
{
   return fetchAttributes;
}

- (NSArray *)describeTableNames
{
	NSMutableArray		*tableNames = [[[NSMutableArray allocWithZone:[self zone]] init] autorelease];
	NSDictionary		*row;
	EOSQLExpression     *expression;
    NSString            *table;
	
	expression = [[[[[self adaptorContext] adaptor] expressionClass] alloc] init];
	[expression setStatement:@"SELECT TABLE_NAME FROM USER_TABLES"];
	
	NS_DURING
    [self evaluateExpression:expression];
	NS_HANDLER
    [expression release];
    [localException raise];
	NS_ENDHANDLER
	[expression release];
    
	[self setAttributesToFetch:[self describeResults]];
	while ((row = [self fetchRowWithZone:NULL]) != nil) 
    {
		table = [[row allValues] objectAtIndex:0];
        [tableNames addObject:table];
	}
	
	return tableNames;
}

- (EOAttribute *)_newAttributeFoName:(NSString *)colName type:(NSString *)colType 
                                len:(int)dataLen scale:(int)dataScale precision:(int)dataPrecision
                                allowNull:(BOOL)allowNull
{
    NSDictionary    *dataTypes;
    NSDictionary    *dataTypeDict;
    NSString        *aString;
    EOAttribute		*attribute = [[EOAttribute allocWithZone:[self zone]] init];
    
    [attribute setName:colName];
    [attribute beautifyName];
    [attribute setColumnName:colName];
    [attribute setAllowsNull:allowNull];
    [attribute setExternalType:colType];
    
    dataTypes = [OracleAdaptor dataTypes];
    dataTypeDict = [dataTypes objectForKey:colType];
    if (dataTypeDict)
    {
        [attribute setValueClassName:[dataTypeDict objectForKey:@"valueClassName"]];
        if ([dataTypeDict objectForKey:@"useWidth"])
            [attribute setWidth:dataLen];
        else if ([dataTypeDict objectForKey:@"isNumber"])
        {
            if ([dataTypeDict objectForKey:@"hasPrecision"])
            {
                // This is the NUMBER type. The value class
                // is dependent upon the precision which may
                // not be set at all.  Also the type is dependednt
                // upon precission and scale
                // first check is precission is set at all
                // if not use NSDecimalNumber and we are done
                if (dataPrecision == 0)
                {
                    [attribute setValueClassName:@"NSDecimalNumber"];
                }
                else
                {
                    // if precision is less than 10 use NSNumber
                    // which it is already set to.  if we HAVE scale
                    // set type to double otherwise integer
                    if (dataPrecision < 10)
                    {
                        // use NSNumber
                        [attribute setValueClassName:@"NSNumber"];
                        if (dataScale)
                            [attribute setValueType:@"d"];
                        else
                            [attribute setValueType:@"i"];
                    }
                    else
                    {
                        // use NSDecimalNumber
                        [attribute setValueClassName:@"NSDecimalNumber"];
                    }
                    [attribute setScale:dataScale];
                    [attribute setPrecision:dataPrecision];
                }
            }
            else
            {
                aString = [dataTypeDict objectForKey:@"valueType"];
                if (aString)
                    [attribute setValueType:aString];
                else
                    [attribute setValueType:@"i"];
            }
        }
        else if ([dataTypeDict objectForKey:@"isDate"])
        {
            #ifdef MAC_OS_X_VERSION_MAX_ALLOWED
                #if MAC_OS_X_VERSION_MAX_ALLOWED > 1060 
                    // translate NSCalendarDate to NSDate if this is Lion or latter
                    [attribute setValueClassName:@"NSDate"];
                #else
                    [attribute setValueClassName:@"NSCalendarDate"];
                #endif
            #else
                #error Max Version not defined and it HAS TO BE
            #endif                   
        }  
    }
    else
    {
        [EOLog logWarningWithFormat:@"Unknown type: %@\n", colType];
        [attribute setValueClassName:@"NSString"];
    }
    
    return [attribute autorelease];
}

- (EOEntity *)_createEntityForTableNamed:(NSString *)name
{
	NSDictionary		*row;
	EOSQLExpression     *expression;
    EOEntity            *entity;
	
	expression = [[[[[self adaptorContext] adaptor] expressionClass] alloc] init];
	[expression setStatement:EOFormat(@"SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE, NULLABLE FROM USER_TAB_COLUMNS WHERE TABLE_NAME = '%@'", name)];
    
    NS_DURING
	[self evaluateExpression:expression];
    NS_HANDLER
    [expression release];
    [localException raise];
	NS_ENDHANDLER
    [expression release];

    entity = [[EOEntity allocWithZone:[self zone]] init];
    [entity setName:name];
    [entity beautifyName];
    [entity setExternalName:name];
    [entity setClassName:@"EOGenericRecord"];

    [self setAttributesToFetch:[self describeResults]];
	
    while ((row = [self fetchRowWithZone:NULL]) != nil) 
    {
        EOAttribute		*attribute = [[EOAttribute allocWithZone:[self zone]] init];
        NSString		*colType;
        int             dataLen, dataScale, dataPrecision;
        NSString        *colName;
        BOOL            nullable;
        id              value;
        
        colName = [row objectForKey:@"Attribute0"];
        colType = [row objectForKey:@"Attribute1"];
        dataLen = [[row objectForKey:@"Attribute2"] intValue];
        nullable = [[row objectForKey:@"Attribute5"] isEqualToString:@"Y"];

        // the following two attributes may be null, so we
        // need to deal with that.  if one is null they both are null
        dataPrecision = 0;
        dataScale = 0;
        value = [row objectForKey:@"Attribute3"];
        if ([EONull null] != value)
        {
            dataPrecision = [value intValue];
            dataScale = [[row objectForKey:@"Attribute4"] intValue];
        }
        
        attribute = [self _newAttributeFoName:colName type:colType 
                                len:dataLen scale:dataScale precision:dataPrecision
                                allowNull:nullable];  				
        [entity addAttribute:attribute];
        [attribute release];
    }
		
    [entity setClassProperties:[entity attributes]];
    [entity setAttributesUsedForLocking:[entity attributes]];
	
	return [entity autorelease];
}

- (EOModel *)describeModelWithTableNames:(NSArray *)tableNames
{
	EOModel		*model;
    NSString	*tableName;
	NSString	*EOName;
	
	model = [[EOModel allocWithZone:[self zone]] init];
	EOName = [[[[self adaptorContext] adaptor] connectionDictionary] objectForKey:@"databaseName"];
	if (EOName == nil) 
        EOName = NSUserName();
	[model setName:EOName];
	[model setAdaptorName:[[[self adaptorContext] adaptor] name]];
	[model setConnectionDictionary:[[[self adaptorContext] adaptor] connectionDictionary]];
	    
    for (tableName in tableNames)
	{		
		EOEntity *entity = [self _createEntityForTableNamed:tableName];
		if (entity)
			[model addEntity:entity];
	}
	
	return [model autorelease];
}

@end
