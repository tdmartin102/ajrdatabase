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

#import "EOFormat.h"

typedef enum _eoFormatStage {
   EOFormatStageAPriori,
   EOFormatStageFlags,
   EOFormatStageWidth,
   EOFormatStagePrecision,
   EOFormatStageType
} EOFormatStage;

#define _AJRExpandBufferIfNeeded(length) { \
   while (outputBufferPosition + length >= outputBufferMaxLength) { \
      outputBufferMaxLength += 1024; \
      outputBuffer = NSZoneRealloc(zone, outputBuffer, sizeof(unichar) * outputBufferMaxLength); \
   } \
}

#define _AJRPad(count) { \
   unichar pad = (flags & EOZeroPadding) ? '0' : ' '; \
   int	  rCount = (count); \
   while (rCount) { \
      outputBuffer[outputBufferPosition] = pad; \
      outputBufferPosition++; \
      rCount--; \
   } \
}

static char _eoDecimalDigits[] = "0123456789";
static char _eoHexidecimalDigits[] = "0123456789abcdef";
static char _eoHEXIDECIMALDigits[] = "0123456789ABCDEF";
static char _eoOctalDigits[] = "01234567";

#define EOAlternateForm	 		1			// '#'
#define EOZeroPadding			2			// '0'
#define EOLeftJustified			4			// '-'
#define EOSpaceForPlus			8			// ' '
#define EOShowPlus				16			// '+'
#define EOGroupThousands		32			// ','
#define EOShortType				64			// 'h'
#define EOLongType				128		// 'l'
#define EOLongLongType			256		// 'll' or 'L' or 'q'
#define EOSizeTType				512		// 'z'

/** @todo There should now-a-days be a function defined in System.framework for this, but I couldn't readily find it - AJR */
static size_t ustrlen(const unichar *string)
{
   int      x = 0;
	
   while (string[x] != 0) x++;
	
   return x;
}

char *_eoIntegerToString(unsigned long long value, int base, char *digits)
{
   static char		buffer[50];
   int				x;

	if (value == 0LL) return "0";
   
   buffer[49] = '\0';
   
   for (x = 48; (x > 0) && (value != 0); x--) {
      buffer[x] = digits[value % base];
      value /= base;
   }

   return buffer + x + 1;
}

static inline unsigned long long _eoLLAbs(long long value)
{
   return (value < 0 ? -value : value);
}

NSString *EOFormatv(NSString *format, va_list ap)
{
   unichar				character;
   int					position, x;
   int					length = [format length];
   unichar				*outputBuffer;
   int					outputBufferPosition = 0;
   int					outputBufferMaxLength = 1024;
   NSZone				*zone = [format zone];
   NSRange				range;
   EOFormatStage		stage = EOFormatStageAPriori;
   NSUInteger			flags = 0;
   NSUInteger			width = NSNotFound, precision = NSNotFound;
   NSCharacterSet		*digits = [NSCharacterSet decimalDigitCharacterSet];
   char					*stringValue = NULL;
   unichar				*unicharStringValue = NULL;
   id				 	objectValue = nil;
   int					numericBase = 0;
   char					*prefix = NULL;
   BOOL					isSigned = NO;
   char					*displayDigits = _eoDecimalDigits;
   BOOL					doingFloat = NO;
   double				floatValue = 0.0;
   BOOL					doingTimeInterval = NO;
	OSType				osType;
   BOOL					doingOSType = NO;
	BOOL					booleanValue;
   BOOL					doingBooleanType = NO;
	NSTimeInterval		timeIntervalValue = 0.0;

   outputBuffer = NSZoneMalloc(zone, sizeof(unichar) * outputBufferMaxLength);

   range.location = 0;
   range.length = 0;
   for (position = 0; position < length; position++) {
      character = [format characterAtIndex:position];
      if (stage == EOFormatStageAPriori) {
         if (character == '%') {
            range.length = position - range.location;
            _AJRExpandBufferIfNeeded(range.length);
            [format getCharacters:outputBuffer + outputBufferPosition range:range];
            range.location = position + 1;
            outputBufferPosition += range.length;
            stage = EOFormatStageFlags;
            flags = 0;
            width = NSNotFound;
            precision = NSNotFound;
            stringValue = NULL;
            unicharStringValue = NULL;
            objectValue = nil;
            numericBase = 0;
            prefix = NULL;
            doingFloat = NO;
         }
      } else {
         if (stage == EOFormatStageFlags) {
            switch (character) {
               case '%':
                  stage = EOFormatStageAPriori;
                  continue;
               case '#':
                  flags |= EOAlternateForm;
                  range.location++;
                  break;
               case '0':
                  flags |= EOZeroPadding;
                  range.location++;
                  break;
               case '-':
                  flags |= EOLeftJustified;
                  range.location++;
                  break;
               case ' ':
                  flags |= EOSpaceForPlus;
                  range.location++;
                  break;
               case '+':
                  flags |= EOShowPlus;
                  range.location++;
                  break;
               case ',':
                  flags |= EOGroupThousands;
                  range.location++;
                  break;
               default:
                  stage = EOFormatStageWidth;
                  break;
            }
         }
         if (stage == EOFormatStageWidth) {
            if (character == '*') {
               width = va_arg(ap, int);
               range.location++;
            } else if ([digits characterIsMember:character]) {
               if (width == NSNotFound) {
                   width = character - '0';
               } else {
                  width = (width * 10) + (character - '0');
               }
               range.location++;
            } else if (character == '.') {
               stage = EOFormatStagePrecision;
               continue; // We don't want fall through in this case.
            } else {
               stage = EOFormatStageType;
            }
         }
         if (stage == EOFormatStagePrecision) {
            if (character == '*') {
               precision = va_arg(ap, int);
               range.location++;
            } else if ([digits characterIsMember:character]) {
               if (precision == NSNotFound) {
                  precision = character - '0';
               } else {
                  precision = (precision * 10) + (character - '0');
               }
               range.location++;
            } else {
               stage = EOFormatStageType;
               range.location++;
            }
         }
         if (stage == EOFormatStageType) {
            switch (character) {
               case 'h':
                  flags |= EOShortType;
                  range.location++;
                  break;
               case 'l':
                  if (flags & EOLongType) {
                     flags |= EOLongLongType;
                  } else {
                     flags |= EOLongType;
                  }
                  range.location++;
                  break;
               case 'q':
               case 'L':
                  flags |= EOLongLongType;
                  range.location++;
                  break;
               case 'z':
                  flags |= EOSizeTType;
                  range.location++;
                  break;
               case 'd':
               case 'i':
                  numericBase = 10;
                  prefix = flags & EOAlternateForm ? "0" : NULL;
                  isSigned = YES;
                  displayDigits = _eoDecimalDigits;
                  break;
               case 'b':
                  numericBase = 2;
                  prefix = NULL;
                  isSigned = NO;
                  displayDigits = _eoDecimalDigits;
                  break;
               case 'o':
                  numericBase = 8;
                  prefix = flags & EOAlternateForm ? "0" : NULL;
                  isSigned = YES;
                  displayDigits = _eoOctalDigits;
                  break;
               case 'u':
                  numericBase = 10;
                  prefix = NULL;
                  isSigned = NO;
                  displayDigits = _eoDecimalDigits;
                  break;
               case 'x':
                  numericBase = 16;
                  prefix = flags & EOAlternateForm ? "0x" : NULL;
                  isSigned = NO;
                  displayDigits = _eoHexidecimalDigits;
                  break;
               case 'X':
                  numericBase = 16;
                  prefix = flags & EOAlternateForm ? "0x" : NULL;
                  isSigned = NO;
                  displayDigits = _eoHEXIDECIMALDigits;
                  break;
               case 'e':
               case 'E':
               case 'f':
               case 'g':
               case 'G':
                  doingFloat = YES;
                  floatValue = va_arg(ap, double);
                  break;
               case 'c':
                  _AJRExpandBufferIfNeeded(1);
                  if (1 /*__alignof__(char) == 4*/) {
                     if (flags & EOLongType) {
                        outputBuffer[outputBufferPosition++] = va_arg(ap,
                                                                      unsigned int);
                     } else {
                        outputBuffer[outputBufferPosition++] = va_arg(ap,
                                                                      unsigned int);
                     }
                  } else {
                     if (flags & EOLongType) {
                        outputBuffer[outputBufferPosition++] = va_arg(ap, int /*unichar*/);
                     } else {
                        outputBuffer[outputBufferPosition++] = va_arg(ap, int /*char*/);
                     }
                  }
                  stage = EOFormatStageAPriori;
                  range.location++;
                  break;
               case 's':
                  if (flags & EOLongType) {
                     unicharStringValue = va_arg(ap, unichar *);
                     if (unicharStringValue == NULL) {
                        objectValue = @"*null*";
                     }
                  } else {
                     stringValue = va_arg(ap, char *);
                     if (stringValue == NULL) {
                        objectValue = @"*null*";
                     }
                  }
                  break;
               case 'p':
                  numericBase = 16;
                  prefix = "0x";
                  isSigned = NO;
                  displayDigits = _eoHexidecimalDigits;
                  break;
               case 'n':
                  {
                     int		*location = va_arg(ap, int *);
                     *location = outputBufferPosition;
                     stage = EOFormatStageAPriori;
                     range.location++;
                  }
                  break;
               case '@':
                  objectValue = va_arg(ap, id);
                  if (!objectValue) {
                     objectValue = @"*nil*";
                  }
                  break;
					/* These are special, extended formats not normally supported by printf */
               case 'S':
                  objectValue = NSStringFromSelector(va_arg(ap, SEL));
                  break;
               case 'C':
                  objectValue = NSStringFromClass([va_arg(ap, id) class]);
                  break;
					case 'R':
						objectValue = NSStringFromRect(va_arg(ap, NSRect));
						break;
					case 'Z':
						objectValue = NSStringFromSize(va_arg(ap, NSSize));
						break;
					case 'P':
						objectValue = NSStringFromPoint(va_arg(ap, NSPoint));
						break;
					case 'T':
						doingTimeInterval = YES;
						timeIntervalValue = va_arg(ap, NSTimeInterval);
						break;
					case 'O':
						doingOSType = YES;
						osType = va_arg(ap, OSType);
						break;
					case 'B':
						doingBooleanType = YES;
						booleanValue = va_arg(ap, int);
						break;
               default:
                  _AJRExpandBufferIfNeeded(2);
                  outputBuffer[outputBufferPosition++] = '%';
                  outputBuffer[outputBufferPosition++] = character;
                  stage = EOFormatStageAPriori;
                  range.location++;
                  break;
            }
            if (stringValue) {
               int	length = strlen(stringValue);
               int	vPos;

               if ((precision != NSNotFound) && (length > precision)) {
                  length = precision;
               }
               if (!(flags & EOLeftJustified) && (width != NSNotFound) && (length < width)) {
                  _AJRExpandBufferIfNeeded(width - length);
                  _AJRPad(width - length);
               }
               for (vPos = 0; vPos < length; vPos++) {
                  _AJRExpandBufferIfNeeded(1);
                  outputBuffer[outputBufferPosition] = *(stringValue + vPos);
                  outputBufferPosition++;
               }
               if ((flags & EOLeftJustified) && (width != NSNotFound) && (length < width)) {
                  _AJRExpandBufferIfNeeded(width - length);
                  _AJRPad(width - length);
               }
               stage = EOFormatStageAPriori;
               range.location++;

               stringValue = NULL;
            } else if (unicharStringValue) {
               int	length = ustrlen(unicharStringValue);
               int	vPos;

               if ((precision != NSNotFound) && (length > precision)) {
                  length = precision;
               }
               if (!(flags & EOLeftJustified) && (width != NSNotFound) && (length < width)) {
                  _AJRExpandBufferIfNeeded(width - length);
                  _AJRPad(width - length);
               }
               for (vPos = 0; vPos < length; vPos++) {
                  _AJRExpandBufferIfNeeded(1);
                  outputBuffer[outputBufferPosition] = *(unicharStringValue + vPos);
                  outputBufferPosition++;
               }
               if ((flags & EOLeftJustified) && (width != NSNotFound) && (length < width)) {
                  _AJRExpandBufferIfNeeded(width - length);
                  _AJRPad(width - length);
               }
               stage = EOFormatStageAPriori;
               range.location++;

               unicharStringValue = NULL;
            } else if (objectValue) {
               NSString		*value = [objectValue description];
               int			length = [value length];
               
               if ((precision != NSNotFound) && (length > precision)) {
                  length = precision;
               }
               if (!(flags & EOLeftJustified) && (width != NSNotFound) && (length < width)) {
                  _AJRExpandBufferIfNeeded(width - length);
                  _AJRPad(width - length);
               }
               _AJRExpandBufferIfNeeded(length);
               [value getCharacters:outputBuffer + outputBufferPosition];
               outputBufferPosition += length;
               if ((flags & EOLeftJustified) && (width != NSNotFound) && (length < width)) {
                  _AJRExpandBufferIfNeeded(width - length);
                  _AJRPad(width - length);
               }
               stage = EOFormatStageAPriori;
               range.location++;

               objectValue = nil;
            } else if (numericBase) {
               unichar					signChar = 0;
               long long				tValue;
               unsigned long long	value;
               int						length, trueLength;
               
               if (flags & EOShortType) {
                  if (isSigned) {
                     tValue = va_arg(ap, int /* short */);
                     if (tValue < 0) signChar = '-';
                     value = _eoLLAbs(tValue);
                  } else {
                     value = va_arg(ap, unsigned int /*unsigned short*/);
                  }
               } else if (flags & EOLongType) {
                  if (isSigned) {
                     tValue = va_arg(ap, long);
                     if (tValue < 0) signChar = '-';
                     value = _eoLLAbs(tValue);
                  } else {
                     value = va_arg(ap, unsigned long);
                  }
               } else if (flags & EOLongLongType) {
                  if (isSigned) {
                     tValue = va_arg(ap, long long);
                     if (tValue < 0) signChar = '-';
                     value = _eoLLAbs(tValue);
                  } else {
                     value = va_arg(ap, unsigned long long);
                  }
               } else {
                  if (isSigned) {
                     tValue = va_arg(ap, int);
                     if (tValue < 0) signChar = '-';
                     value = _eoLLAbs(tValue);
                  } else {
                     value = va_arg(ap, unsigned int);
                  }
               }

               if (signChar == 0) {
                  if (flags & EOSpaceForPlus) {
                     signChar = ' ';
                  } else if (flags & EOShowPlus) {
                     signChar = '+';
                  }
               }

               stringValue = _eoIntegerToString(value, numericBase, displayDigits);
               length = trueLength = strlen(stringValue);
               if (signChar != 0) length++;
               if (prefix) length += strlen(prefix);

               if ((width != NSNotFound) && (length < width) && (!(flags & EOLeftJustified) || (flags & EOZeroPadding))) {
                  if (flags & EOZeroPadding) {
                     if (signChar != 0) {
                        _AJRExpandBufferIfNeeded(1);
                        outputBuffer[outputBufferPosition++] = signChar;
                     }
                     if (prefix) {
                        for (x = 0; prefix[x]; x++) {
                           _AJRExpandBufferIfNeeded(1);
                           outputBuffer[outputBufferPosition++] = prefix[x];
                        }
                     }
                     for (x = 0; x < width - length; x++) {
                        _AJRExpandBufferIfNeeded(1);
                        outputBuffer[outputBufferPosition++] = '0';
                     }
                  } else {
                     for (x = 0; x < width - length; x++) {
                        _AJRExpandBufferIfNeeded(1);
                        outputBuffer[outputBufferPosition++] = ' ';
                     }
                     if (signChar != 0) {
                        _AJRExpandBufferIfNeeded(1);
                        outputBuffer[outputBufferPosition++] = signChar;
                     }
                     if (prefix) {
                        for (x = 0; prefix[x]; x++) {
                           _AJRExpandBufferIfNeeded(1);
                           outputBuffer[outputBufferPosition++] = prefix[x];
                        }
                     }
                  }
               } else if (signChar != 0) {
                  _AJRExpandBufferIfNeeded(1);
                  outputBuffer[outputBufferPosition++] = signChar;
                  if (prefix) {
                     for (x = 0; prefix[x]; x++) {
                        _AJRExpandBufferIfNeeded(1);
                        outputBuffer[outputBufferPosition++] = prefix[x];
                     }
                  }
               } else if (prefix) {
                  if (prefix) {
                     for (x = 0; prefix[x]; x++) {
                        _AJRExpandBufferIfNeeded(1);
                        outputBuffer[outputBufferPosition++] = prefix[x];
                     }
                  }
               }

               for (x = 0; x < trueLength; x++) {
                  _AJRExpandBufferIfNeeded(1);
                  outputBuffer[outputBufferPosition++] = stringValue[x];
               }

               if ((width != NSNotFound) && (length < width) && (flags & EOLeftJustified) && !(flags & EOZeroPadding)) {
                  for (x = 0; x < width - length; x++) {
                     _AJRExpandBufferIfNeeded(1);
                     outputBuffer[outputBufferPosition++] = ' ';
                  }
               }
               
               stage = EOFormatStageAPriori;
               range.location++;

               stringValue = NULL;
               numericBase = 0;
            } else if (doingFloat) {
               char		cFormat[20];
               char		cType[2] = { character, '\0' };
               char		tempBuffer[80];

               strcpy(cFormat, "%");
               if (flags & EOAlternateForm) strcat(cFormat, "#");
               if (flags & EOZeroPadding) strcat(cFormat, "0");
               if (flags & EOLeftJustified) strcat(cFormat, "-");
               if (flags & EOSpaceForPlus) strcat(cFormat, " ");
               if (flags & EOShowPlus) strcat(cFormat, "+");
               if (flags & EOGroupThousands) strcat(cFormat, ",");
               if ((width == NSNotFound) && (precision == NSNotFound)) {
                  strcat(cFormat, cType);
                  sprintf(tempBuffer, cFormat, floatValue);
               } else if ((width != NSNotFound) && (precision == NSNotFound)) {
                  strcat(cFormat, "*");
                  strcat(cFormat, cType);
                  sprintf(tempBuffer, cFormat, width, floatValue);
               } else if ((width == NSNotFound) && (precision != NSNotFound)) {
                  strcat(cFormat, ".*");
                  strcat(cFormat, cType);
                  sprintf(tempBuffer, cFormat, precision, floatValue);
               } else if ((width != NSNotFound) && (precision != NSNotFound)) {
                  strcat(cFormat, "*.*");
                  strcat(cFormat, cType);
                  sprintf(tempBuffer, cFormat, width, precision, floatValue);
               }

               _AJRExpandBufferIfNeeded(strlen(tempBuffer));
               for (x = 0; tempBuffer[x]; x++) {
                  outputBuffer[outputBufferPosition++] = tempBuffer[x];
               }
               
               stage = EOFormatStageAPriori;
               range.location++;

               floatValue = 0.0;
               doingFloat = NO;
            } else if (doingTimeInterval) {
					int			hours, minutes, seconds;
					int			hourLength = 0;
					int			fraction;
					BOOL			isNegative = timeIntervalValue < 0.0;
					char			*number;
					int			x;
					int			neededLength;
					
					timeIntervalValue = fabs(timeIntervalValue);
					
					hours = (int)floor(timeIntervalValue / (60.0 * 60.0));
					minutes = ((int)floor(timeIntervalValue) / 60) % 60;
					seconds = (int)floor(timeIntervalValue) % 60;
					if (precision != NSNotFound) {
						fraction = (int)rint((timeIntervalValue - floor(timeIntervalValue)) * pow(10.0, precision));
					}
					hourLength = hours == 0 ? 1 : rint(log10(hours)) + 1;
					
					neededLength = hourLength < 2 ? 2 : hourLength;
					neededLength += 6;
					if (isNegative) neededLength++;
					if (precision != NSNotFound) neededLength += precision + 1;
					_AJRExpandBufferIfNeeded(neededLength);
					//fprintf(stderr, "%d\n", neededLength);
					
					if (isNegative) outputBuffer[outputBufferPosition++] = '-';
					number = _eoIntegerToString(hours, 10, _eoDecimalDigits);
					if (hourLength < 2) outputBuffer[outputBufferPosition++] = '0';
					for (x = 0; x < hourLength; x++) {
						outputBuffer[outputBufferPosition++] = number[x];
					}
					outputBuffer[outputBufferPosition++] = ':';
					if (minutes < 10) outputBuffer[outputBufferPosition++] = '0';
					else outputBuffer[outputBufferPosition++] = '0' + (minutes / 10);
					outputBuffer[outputBufferPosition++] = '0' + (minutes % 10);
					outputBuffer[outputBufferPosition++] = ':';
					if (seconds < 10) outputBuffer[outputBufferPosition++] = '0';
					else outputBuffer[outputBufferPosition++] = '0' + (seconds / 10);
					outputBuffer[outputBufferPosition++] = '0' + (seconds % 10);
					if (precision != NSNotFound) {
						int		length;
						
						number = _eoIntegerToString(fraction, 10, _eoDecimalDigits);
						length = strlen(number);
						//fprintf(stderr, "%d, %d, %s\n", precision, length, number);
						outputBuffer[outputBufferPosition++] = '.';
						if (length < precision) {
							for (x = 0; x < precision - length; x++) {
								outputBuffer[outputBufferPosition++] = '0';
							}
						}
						for (x = length > precision ? 1 : 0; x < length; x++) {
							outputBuffer[outputBufferPosition++] = number[x];
						}
					}

               stage = EOFormatStageAPriori;
               range.location++;
					
               timeIntervalValue = 0.0;
               doingTimeInterval = NO;
				} else if (doingOSType) {
               stage = EOFormatStageAPriori;
               range.location++;
					
					_AJRExpandBufferIfNeeded(4);
					outputBuffer[outputBufferPosition++] = (osType >> 24) & 0x000000FF;
					outputBuffer[outputBufferPosition++] = (osType >> 16) & 0x000000FF;
					outputBuffer[outputBufferPosition++] = (osType >>  8) & 0x000000FF;
					outputBuffer[outputBufferPosition++] = (osType >>  0) & 0x000000FF;
					
               osType = 0;
               doingOSType = NO;
				} else if (doingBooleanType) {
               stage = EOFormatStageAPriori;
               range.location++;
					
					if (booleanValue) {
						_AJRExpandBufferIfNeeded(3);
						outputBuffer[outputBufferPosition++] = 'Y';
						outputBuffer[outputBufferPosition++] = 'E';
						outputBuffer[outputBufferPosition++] = 'S';
					} else {
						_AJRExpandBufferIfNeeded(2);
						outputBuffer[outputBufferPosition++] = 'N';
						outputBuffer[outputBufferPosition++] = 'O';
					}
					
               booleanValue = NO;
               doingBooleanType = NO;
				}
         }
      }
   }

   if ((range.length = position - range.location) > 0) {
      while (outputBufferPosition + range.length >= outputBufferMaxLength) {
         outputBufferMaxLength += 1024;
         outputBuffer = NSZoneRealloc(zone, outputBuffer, sizeof(unichar) * outputBufferMaxLength);
      }
      [format getCharacters:outputBuffer + outputBufferPosition range:range];
      outputBufferPosition += range.length;
   }

   return [[[NSString allocWithZone:zone] initWithCharactersNoCopy:outputBuffer length:outputBufferPosition freeWhenDone:YES] autorelease];
}

NSString *EOFormat(NSString *format, ...)
{
   va_list		ap;
   NSString		*returnValue;

   va_start(ap, format);
   returnValue = EOFormatv(format, ap);
   va_end(ap);

   return returnValue;
}
