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

/*!
 @header Functions

 @discussion EOFormat contains an alternative to Apple's <CODE>-[NSString stringWithFormat:]</CODE>. I felt compelled to write this because Apple's own implementation contains a number of truely annoying bugs for anyone that needs to use heavily formatted strings, and, unfortuneately, Apple has not yet felt compelled to fix these bugs.

 EOFormat works quite similar to <CODE>printf</CODE>, <CODE>fprintf</CODE>, and Apple's own <CODE>-[NSString stringWithFormat:]</CODE>. In fact, all formatting specifications that work for those calls should also work to calls to EOFormat or EOFormatv. Which of the two functions you use will depend on your calling conditions. We'll discuss both possibilities further down the page. For now, let's look at what format specifiers are supported.

 <STRONG>Formatting</STRONG>

 The format string is composed of zero or more directives: ordinary characters (not %), which are copied unchanged to the output stream; and conversion specifications, each of which results in fetching zero or more subsequent arguments.  Each conversion specification is introduced by the character %. The arguments must correspond properly (after type promotion) with the conversion specifier.  After the %, the following appear in sequence:

 <EM>Flags</EM>

 One of the following flags can appear. These modify the output behavior of the basic format specifiers discussed later.
 <TABLE CELLSPACING=2 CELLPADDING=2 BORDER=0 WIDTH=90%>
 <TR>
 <TH ALIGN=CENTER BGCOLOR=BLACK>&nbsp;<FONT COLOR=WHITE>Flag</FONT>&nbsp;</TH>
 <TH ALIGN=CENTER BGCOLOR=BLACK>&nbsp;<FONT COLOR=WHITE>Description</FONT>&nbsp;</TH>
 </TR>
 <TR>
 <TD ALIGN=CENTER VALIGN=TOP>#</TD>
 <TD>Use an alternate form, if available. For basic number conversion, this will prepend a '0' to the output. For hexidecimal representations, a '0x' will be preprended to the output. For e, E, f, g, and G, conversions, the result will always contain a decimal point, even if no digits follow it (normally, a decimal point appears in the results of those conversions only if a digit follows).  For g and G conversions, trailing zeros are not removed from the result as they would otherwise be.</TD>
 </TR>
 <TR BGCOLOR=#EEEEEE>
 <TD ALIGN=CENTER VALIGN=TOP>0</TD>
 <TD>Zero padding. For all conversions except n, the converted value is padded on the left with zeros rather than blanks. If a recision is given with a numeric conversion (Mc d, i, o, u, i, x, and X), the `0' flag is ignored.</TD>
 </TR>
 <TR>
 <TD ALIGN=CENTER VALIGN=TOP>-</TD>
 <TD>Indicates the converted value is to be left adjusted on the field boundary.  Except for n conversions, the converted value is padded on the right with blanks, rather than on the left with blanks or zeros.  A '-' overrides a '0' if both are given.</TD>
 </TR>
 <TR BGCOLOR=#EEEEEE>
 <TD ALIGN=CENTER VALIGN=TOP><EM>space</EM></TD>
 <TD>A space, specifying that a blank should be left before a positive number produced by a signed conversion (d, e, E, f, g, G, or i).</TD>
 </TR>
 <TR>
 <TD ALIGN=CENTER VALIGN=TOP>+</TD>
 <TD>Specifies that a sign always be placed before a number produced by a signed conversion.  A `+' overrides a space if both are used.
 </TD>
 </TR>
 </TABLE><BR>

 <EM>Width</EM>

 An optional decimal digit string specifying a minimum field width. If the converted value has fewer characters than the field width, it will be padded with spaces on the left (or right, if the left-adjustment flag has been given) to fill out the field width.

 <EM>Precision</EM>

 An optional precision, in the form of a period `.' followed by an optional digit string.  If the digit string is omitted, the precision is taken as zero.  This gives the minimum number of digits to appear for d, i, o, u, x, and X conversions, the number of digits to appear after the decimal-point for e, E, and f conversions, the maximum number of significant digits for g and G conversions, or the maximum number of characters to be printed from a string for s conversions.

 <EM>Optional Modifiers</EM>

 One of the following optional modifiers may then appear:
 <TABLE CELLSPACING=2 CELLPADDING=2 BORDER=0 WIDTH=90%>
 <TR>
 <TH ALIGN=CENTER BGCOLOR=BLACK>&nbsp;<FONT COLOR=WHITE>Modifier</FONT>&nbsp;</TH>
 <TH ALIGN=CENTER BGCOLOR=BLACK>&nbsp;<FONT COLOR=WHITE>Description</FONT>&nbsp;</TH>
 </TR>
 <TR>
 <TD ALIGN=CENTER VALIGN=TOP>h</TD>
 <TD>The optional character h, specifying that a following d, i, o, u, x, or X conversion corresponds to a <EM>short int</EM> or <EM>unsigned short int</EM> argument, or that a following n conversion corresponds to a pointer to a <EM>short int</EM> argument.</TD>
 </TR>
 <TR BGCOLOR=#EEEEEE>
 <TD ALIGN=CENTER VALIGN=TOP>l</TD>
 <TD>The optional character l (ell) specifying that a following d, i, o, u, x, or X conversion applies to a pointer to a <EM>long int</EM> or <EM>unsigned long int</EM> argument, or that a following n conversion corresponds to a pointer to a <EM>long int</EM> argument.<P>When applied to c or s conversions, the conversion will be applied to a <EM>unichar</EM> rather than <EM>char</EM>.</TD>
 </TR>
 <TR>
 <TD ALIGN=CENTER VALIGN=TOP>q</TD>
 <TD>The optional character q, specifying that a following d, i, o, u, x, or X conversion corresponds to a <EM>quad int</EM> or <EM>unsigned quad int</EM> argument, or that a following n conversion corresponds to a pointer to a <EM>quad int</EM> argument.</TD>
 </TR>
 <TR BGCOLOR=#EEEEEE>
 <TD ALIGN=CENTER VALIGN=TOP>L</TD>
 <TD>The character L specifying that a following e, E, f, g, or G conversion corresponds to a long double argument</TD>
 </TR>
 </TABLE>
 <BR>

 <EM>Conversion Character</EM>

 Specifies which conversion should actual take place. The following conversion types are supported:
 <TABLE CELLSPACING=2 CELLPADDING=2 BORDER=0 WIDTH=90%>
 <TR>
 <TH ALIGN=CENTER BGCOLOR=BLACK>&nbsp;<FONT COLOR=WHITE>Modifier</FONT>&nbsp;</TH>
 <TH ALIGN=CENTER BGCOLOR=BLACK>&nbsp;<FONT COLOR=WHITE>Description</FONT>&nbsp;</TH>
 </TR>
 <TR>
 <TD ALIGN=CENTER VALIGN=TOP>diouxX</TD>
 <TD>The <EM>int</EM> (or appropriate variant) argument is converted to signed decimal (d and i), unsigned octal (o), unsigned decimal (u), or unsigned hexadecimal (x and X) notation.  The letters abcdef are used for x conversions; the letters ABCDEF are used for X conversions.  The precision, if any, gives the minimum number of digits that must appear; if the converted value requires fewer digits, it is padded on the left with zeros.</TD>
 </TR>
 <TR BGCOLOR=#EEEEEE>
 <TD ALIGN=CENTER VALIGN=TOP>DOU</TD>
 <TD>The <EM>long</EM> int argument is converted to signed decimal, unsigned octal, or unsigned decimal, as if the format had been ld, lo, or lu respectively.  These conversion characters are deprecated, and will eventually disappear.</TD>
 </TR>
 <TR>
 <TD ALIGN=CENTER VALIGN=TOP>eE</TD>
 <TD>The <EM>double</EM> argument is rounded and converted in the style [-]d.ddde+-dd where there is one digit before the decimal-point character and the number of digits after it is equal to the precision; if the precision is missing, it is taken as 6; if the precision is zero, no decimal-point character appears.  An E conversion uses the letter E (rather than e) to introduce the exponent.  The exponent always contains at least two digits; if the value is zero, the exponent is 00.</TD>
 </TR>
 <TR BGCOLOR=#EEEEEE>
 <TD ALIGN=CENTER VALIGN=TOP>f</TD>
 <TD>The <EM>double</EM> argument is rounded and converted to decimal notation in the style [-]ddd.ddd, where the number of digits after the decimal-point character is equal to the precision specification. If the precision is missing, it is taken as 6; if the precision is explicitly zero, no decimal-point character appears.  If a decimal point appears, at least one digit appears before it.</TD>
 </TR>
 <TR>
 <TD ALIGN=CENTER VALIGN=TOP>g</TD>
 <TD>The double argument is converted in style f or e (or E for G conversions).  The precision specifies the number of significant digits.  If the precision is missing, 6 digits are given; if the precision is zero, it is treated as 1.  Style e is used if the exponent from its conversion is less than -4 or greater than or equal to the precision.  Trailing zeros are removed from the fractional part of the result; a decimal point appears only if it is followed by at least one digit.</TD>
 </TR>
 <TR BGCOLOR=#EEEEEE>
 <TD ALIGN=CENTER VALIGN=TOP>c</TD>
 <TD>The <EM>int</EM> argument is converted to an <EM>unsigned char</EM>, and the resulting character is written. If modified with 'l', the argument is converted to a <EM>unichar</EM> or <EM>unsigned short</EM>.</TD>
 </TR>
 <TR>
 <TD ALIGN=CENTER VALIGN=TOP>s</TD>
 <TD>The &#147;<EM>char *</EM>&#148; argument is expected to be a pointer to an array of character type (pointer to a string).  Characters from the array are written up to (but not including) a terminating NUL character; if a precision is specified, no more than the number specified are written.  If a precision is given, no null character need be present; if the precision is not specified, or is greater than the size of the array, the array must contain a terminating NUL character.<P>If the 'l' modifier is specified the argument is expected to be of type <EM>unichar *</EM>, and must be terminated by the (<EM>unsigned short</EM>)0. This isn't necesarily up to the unicode specification, but it's certainly handy in a lot of circumstances.</TD>
 </TR>
 <TR BGCOLOR=#EEEEEE>
 <TD ALIGN=CENTER VALIGN=TOP>p</TD>
 <TD>The &#147;void *&#148; pointer argument is printed in hexadecimal (as if
             by '%#x' or '%#lx')</TD>
 </TR>
 <TR>
 <TD ALIGN=CENTER VALIGN=TOP>%</TD>
 <TD>A '%' is written. No argument is converted. The complete conversion specification is '%%'.</TD>
 </TR>
 <TR BGCOLOR=#EEEEEE>
 <TD ALIGN=CENTER VALIGN=TOP>C</TD>
 <TD>The <EM>id</EM> object is converted to it's class name. This is short hand for calling <EM>NSClassToString()</EM> and passing the result to a '&#64;' format specififier.</TD>
 </TR>
 <TR>
 <TD ALIGN=CENTER VALIGN=TOP>S</TD>
 <TD>The agument is assumed to be of type <EM>SEL</EM> and is converted to it's human readable format.</TD>
 </TR>
 <TR BGCOLOR=#EEEEEE>
 <TD ALIGN=CENTER VALIGN=TOP>&#64;</TD>
 <TD>The argument is assumed to be type <EM>id</EM>. The <EM>descrption</EM> method is sent to the object and the result is appended to the output string.</TD>
 </TR>
 <TR>
 </TABLE>
 <BR>

 <STRONG>Extensions and Fixes</STRONG>

 As you can see, the formats supported are very similar to what is support by the c library format functions as well as by Apple's format methods. However, the following extensions have been added: 'S', 'C', '@', and unichar support. In addition, even though Apple supports '@', the EO functions support the width and precision fields for '@'.
 */

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

/*!
 @function EOFormatv

 @discussion Takes a string, <EM>format</EM>, and applies basic formatting rules to parameters passed in as part of the variable argument array, <EM>ap</EM>. This is similar to the function <EM>EOFormat</EM>, but accepts a va_list rather than a variable array list. Please refer to the man page for stdarg for more information.

 @param format The format specifier string.
 @param ap The variable argument list. Man stdarg for more information.

 @result An autoreleased string conforming to the rules in <EM>format</EM>.
 */
NSString *EOFormatv(NSString *format, va_list ap);

/*!
 @function ARJFormat
 
 @discussion Takes a string, format, and applies basic formatting rules to parameters passed as part of the variable argument list. See the top level documentation for  information on formats supported.

 @param format The string to format
 @param ... The arguments to be formatted into <EM>format</EM>.

 @result A formatted NSString. The value will be autoreleased.
 */
NSString *EOFormat(NSString *format, ...);
#ifdef __cplusplus
}
#endif
