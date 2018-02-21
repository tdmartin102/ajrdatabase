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

#import "EOLog.h"

@implementation EOLog

static NSMutableArray	*loggers = nil;
static EOLog				*SELF = nil;

- (instancetype) initUniqueInstance
{
    if ((self = [super init]))
    {
        if (lock == nil) {
            lock = [[NSLock alloc] init];
            [[self class] registerLogger:[[[EOLogger allocWithZone:[self zone]] init] autorelease]];
        }
    }
    return self;
}

+ (void) initialize {
    // subclassing would result in an instance per class, probably not what we want
    NSAssert([EOLog class] == self, @"Subclassing is not welcome");
    SELF = [[super alloc] initUniqueInstance];
}

+ (id)sharedInstance
{
    return SELF;
}

+ (void)registerLogger:(EOLogger *)logger
{
	if (loggers == nil) {
		loggers = [[NSMutableArray alloc] init];
		[loggers addObject:logger];
	}
}

- (NSArray *)loggers
{
	return loggers;
}

- (void)registerLogger:(Class)aLogger
{
   [loggers addObject:[[[aLogger allocWithZone:[self zone]] init] autorelease]];
}

+ (void)log:(NSString *)string
{
   [[self sharedInstance] log:EOLogInfo string:string];
}

+ (void)log:(EOLogLevel)level string:(NSString *)string
{
   [[self sharedInstance] log:level string:string];
}

+ (void)logWithFormat:(NSString *)format arguments:(va_list)argList
{
   [[self sharedInstance] log:EOLogInfo withFormat:format arguments:argList];
}

+ (void)log:(EOLogLevel)level withFormat:(NSString *)format arguments:(va_list)argList
{
   [[self sharedInstance] log:level withFormat:format arguments:argList];
}

+ (void)logWithFormat:(NSString *)format, ...
{
    va_list		ap;
    NSString    *str;

    va_start(ap, format);
    str = [[NSString alloc] initWithFormat:format arguments:ap];
    [[self sharedInstance] log:EOLogInfo string:str];
    [str release];
    va_end(ap);
}

+ (void)log:(EOLogLevel)level withFormat:(NSString *)format, ...
{
    va_list		ap;
    NSString    *str;

    va_start(ap, format);
    str = [[NSString alloc] initWithFormat:format arguments:ap];
    [[self sharedInstance] log:level string:str];
    [str release];
    va_end(ap);
}

+ (void)logWarningWithFormat:(NSString *)format, ...
{
    va_list		ap;
    NSString    *str;

    va_start(ap, format);
    str = [[NSString alloc] initWithFormat:format arguments:ap];
    [[self sharedInstance] log:EOLogWarning string:str];
    [str release];
    va_end(ap);
}

+ (void)logErrorWithFormat:(NSString *)format, ...
{
    va_list		ap;
    NSString    *str;

    va_start(ap, format);
    str = [[NSString alloc] initWithFormat:format arguments:ap];
    [[self sharedInstance] log:EOLogError string:str];
    [str release];
    va_end(ap);
}

+ (void)logDebugWithFormat:(NSString *)format, ...
{
    va_list		ap;
    NSString    *str;

    va_start(ap, format);
    str = [[NSString alloc] initWithFormat:format arguments:ap];
    [[self sharedInstance] log:EOLogDebug string:str];
    [str release];
    va_end(ap);
}

+ (void)setDelegate:(id)aDelegate
{
   [[self sharedInstance] setDelegate:aDelegate];
}

+ (id)delegate
{
   return [[self sharedInstance] delegate];
}

- (void)log:(NSString *)string
{
   [self log:EOLogInfo string:string];
}

- (void)log:(EOLogLevel)level string:(NSString *)string
{
    int			x;
	int numLoggers;
    BOOL			found;

    [lock lock];
   
    found = NO;
    x = [string length];
    while (x) {
        if ([string characterAtIndex:x - 1] == '\n') {
            x--;
            found = YES;
        } else {
         break;
      }
   }
   if (found) {
      x++; // Keep one newline
      string = [string substringToIndex:x];
   }

   numLoggers = [loggers count];
   for (x = 0; x < numLoggers; x++) {
      NS_DURING
         [[loggers objectAtIndex:x] log:level string:string];
      NS_HANDLER
      NS_ENDHANDLER
   }

   [lock unlock];
}

- (void)logWithFormat:(NSString *)format arguments:(va_list)argList
{
    NSString    *str;
    str = [[NSString alloc] initWithFormat:format arguments:argList];
    [self log:EOLogInfo string:str];
    [str release];
}

- (void)log:(EOLogLevel)level withFormat:(NSString *)format arguments:(va_list)argList
{
    NSString    *str;
    str = [[NSString alloc] initWithFormat:format arguments:argList];
    [self log:level string:str];
    [str release];
}

- (void)logWithFormat:(NSString *)format, ...
{
    va_list		ap;
    NSString    *str;
    
    va_start(ap, format);
    str = [[NSString alloc] initWithFormat:format arguments:ap];
    [self log:EOLogInfo string:str];
    [str release];
    va_end(ap);
}

- (void)log:(EOLogLevel)level withFormat:(NSString *)format, ...
{
    va_list		ap;
    NSString    *str;
    
    va_start(ap, format);
    str = [[NSString alloc] initWithFormat:format arguments:ap];
    [self log:level string:str];
    [str release];
    va_end(ap);
}

- (void)setDelegate:(id)aDelegate
{
   delegate = aDelegate;
}

- (id)delegate
{
   return delegate;
}

@end

static BOOL defaultLogDebug = NO;
static BOOL defaultLogInfo = NO;
static BOOL defaultLogWarning = YES;
static BOOL defaultLogError = YES;

@implementation EOLogger

- (instancetype)init
{
    if ((self = [super init]))
    {
        logDebug = defaultLogDebug;
        logInfo = defaultLogInfo;
        logWarning = defaultLogWarning;
        logError = defaultLogError;
    }
   return self;
}

+ (EOLogger *)logger
{
   return [[[EOLog sharedInstance] loggers] objectAtIndex:0];
}

+ (void)setLogDebug:(BOOL)flag
{
   defaultLogDebug = flag;
}

+ (BOOL)logDebug
{
   return defaultLogDebug;
}

+ (void)setLogInfo:(BOOL)flag
{
   defaultLogInfo = flag;
}

+ (BOOL)logInfo
{
   return defaultLogInfo;
}

+ (void)setLogWarning:(BOOL)flag
{
   defaultLogWarning = flag;
}

+ (BOOL)logWarning
{
   return defaultLogWarning;
}

+ (void)setLogError:(BOOL)flag
{
   defaultLogError = flag;
}

+ (BOOL)logError
{
   return defaultLogError;
}

- (void)log:(EOLogLevel)level string:(NSString *)string
{
   NSString		*levelString;

   switch (level) {
      case EOLogInfo:
         if (!logInfo) return;
         levelString = @"Info";
         break;
      case EOLogWarning:
         if (!logWarning) return;
         levelString = @"Warning";
         break;
      case EOLogError:
         if (!logError) return;
         levelString = @"Error";
         break;
      case EOLogDebug:
         if (!logDebug) return;
         levelString = @"Debug";
         break;
      default:
         return;
   }
   NSLog(@"%@: %@", levelString, string);
}

@end
