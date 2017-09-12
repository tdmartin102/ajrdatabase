/*
 Copyright (c) 2017 Thomas D Martin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

#import "Additions.h"
#import "RRSeo.h"

// implement the show error method for the Application class-----------------------------
@implementation NSApplication(RRS)

// show an error message using NXRunAlertPanel-------------------------------------------
- showError:(NSString *)errorStr, ...
{
    va_list ap;
    NSString *appName;
    NSString *buffer;
    NSAlert *alert;
    
    va_start(ap, errorStr);
    buffer = [[NSString alloc] initWithFormat:errorStr arguments:ap];
    va_end(ap);
    appName = [[NSString alloc] initWithFormat:@"%@:",self.appName];
    
    alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    alert.messageText = appName;
    alert.informativeText = buffer;
    alert.alertStyle = NSAlertStyleWarning;
    [alert runModal];
    
    return self;
}

- (NSString *)appName
{
    return [[NSProcessInfo processInfo] processName];
}

@end

@implementation EOEditingContext (RRS)

- (EODatabaseContext *)databaseContext
{
    // Assuming that there is only ONE database context this will work
    EOModel *aModel = [[[EOModelGroup defaultGroup] models] objectAtIndex:0];
    return [EODatabaseContext registeredDatabaseContextForModel:aModel editingContext:self];
}

- (EOAdaptorChannel *)adaptorChannel
{
    EODatabaseContext	*dbContext;
	EOAdaptorChannel	*result;
    
	dbContext = [self databaseContext];
	[dbContext lock];
	result = [[dbContext availableChannel] adaptorChannel];
	[dbContext unlock];

    return result;
}

//--- You need to set EOEditingContext as the delegate to EODatabaseContext for this to work.
//--- This handles the special case of creating a primary key for the Experience and AcPhone tables
//--- because they conatins a key that may be zero, EOF will not handle it correctly
//----- (THIS IS NOT USED IN THIS EXAMPLE  This is usfull for legacy databases where primary
//       keys are not not standard such as keys where a zero value is valid, or primary keys
//       that are COMPOUND primary keys and one or more of the primary key components might
//       have a value of zero.  THis is ALSO usful in the case where the primary key is a
//       exposed property and it needs to be set upon insert so that it is visable.  These
//       conditions are very rare with modern database structure as right or wrong the new
//       paradigm is to have completely meaningless and opaque primary keys that are simply
//       used as identifiers.)
- (NSDictionary *)databaseContext:(EODatabaseContext *)context
           newPrimaryKeyForObject:(id)object entity:(EOEntity *)entity
{
    NSDictionary *primaryKey = nil;

	// primaryKeyForNewRow returns nil by default so this will only return non nil if it needs to
    if ( [object isKindOfClass:[RRSeo class]] )
        primaryKey = [(RRSeo *)object primaryKeyForNewRow];        

     return primaryKey;
}

@end

