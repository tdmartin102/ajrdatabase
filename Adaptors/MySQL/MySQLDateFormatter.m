//
//  MySQLDateFormatter.m
//  MySQL
//
//  Created by Tom Martin on 12/12/18.
//

/*
 Copyright (C) 2018 Tom Martin
 
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
 Riemer Reporting Service
 24600 Detoit Rd
 Westlake OH 44145
 mailto:tom.martin@riemer.com
 */
//

#import "MySQLDateFormatter.h"
#import "MySQLAdaptor.h"

@implementation MySQLDateFormatter

+ (void)load
{
    [EOSQLFormatter registerFormatter:self];
}

+ (Class)formattedClass
{
    return [NSDate class];
}

+ (Class)adaptorClass
{
    return [MySQLAdaptor class];
}

- (id)format:(id)value inAttribute:(EOAttribute *)attribute
{
    time_t time = [(NSDate *)value timeIntervalSince1970];
    struct tm timeStruct;
    char buffer[80];
    NSString *str;
    
    localtime_r(&time, &timeStruct);
    strftime(buffer, 80, "STR_TO_DATE('%Y-%m-%d %H:%M:%S', '%%Y-%%m-%%d %%T')", &timeStruct);
    str = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
    return str;
}

@end
