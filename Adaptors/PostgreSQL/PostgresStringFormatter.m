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

#import "PostgresStringFormatter.h"

#import "PostgreSQLAdaptor.h"

#import <libpq-fe.h>

NSString *NULL_STRING = @"NULL";


@implementation PostgresStringFormatter

+ (void)load 
{
	[EOSQLFormatter registerFormatter:self];
}

+ (Class)formattedClass
{
   return [NSString class];
}

+ (Class)adaptorClass
{
   return [PostgreSQLAdaptor class];
}

#define CHECK_OUTPUT() { \
   if (output == NULL) { \
      output = NSZoneMalloc(zone, sizeof(unichar) * maxOutput); \
      output[0] = '\'';\
      memcpy(output + 1, input, x * sizeof(unichar)); \
   } \
}

- (id)format:(id)value inAttribute:(EOAttribute *)attribute
{
   NSZone				*zone = [value zone];
   int					x, length;
   unichar				*input, *output = NULL;
   int					outputPos = 0;
   int					maxOutput;
   BOOL					showme = NO;
	NSString				*returnValue;

	// mont_rothstein @ yahoo.com 2005-03-24
	// Added handling of NULL.  Ex: This now handles 'mycolumn = nil' like it should
	if ([value isEqualToString: @"nil"]) { return NULL_STRING; }
	
   length = [(NSString *)value length];
   if ([attribute width] > 0 && length > [attribute width]) {
      length = [attribute width];
   }

   input = NSZoneMalloc(zone, sizeof(unichar) * length);
   maxOutput = length * 2;
   [value getCharacters:input];

   output = NSZoneMalloc(zone, sizeof(unichar) * maxOutput);
   output[outputPos++] = '\'';
   for (x = 0; x < length; x++) {
      if (outputPos + 4 > maxOutput) {
         maxOutput += length / 4;
         if (output) {
            output = NSZoneRealloc(zone, output, sizeof(unichar) * maxOutput);
         }
      }
      if (input[x] < ' '/* || input[x] >= 127*/) {
         CHECK_OUTPUT();
         output[outputPos++] = '\\';
         output[outputPos++] = '0' + ((input[x] / 64) % 8);
         output[outputPos++] = '0' + ((input[x] / 8) % 8);
         output[outputPos++] = '0' + (input[x] % 8);
         //showme = YES;
      } else if (input[x] == '\\') {
         CHECK_OUTPUT();
         output[outputPos++] = '\\';
         output[outputPos++] = '\\';
      } else if (input[x] == '\'') {
         CHECK_OUTPUT();
         output[outputPos++] = '\'';
         output[outputPos++] = '\'';
      } else {
         if (output) {
            output[outputPos++] = input[x];
         }
      }
   }
   if (output) {
      output[outputPos++] = '\'';
   }

   if (showme) {
      [EOLog logDebugWithFormat:@"input = (%d) %*ls\n", length, length, input];
      [EOLog logDebugWithFormat:@"output = (%d) %*ls\n", outputPos, outputPos, output];
   }

   NSZoneFree(zone, input);

	// This was causing odd release errors.
   //return [[[NSString allocWithZone:zone] initWithCharactersNoCopy:output length:outputPos freeWhenDone:YES] autorelease];
   returnValue = [[[NSString allocWithZone:zone] initWithCharacters:output length:outputPos] autorelease];
	NSZoneFree(zone, output);
	
	return returnValue;
}

@end
