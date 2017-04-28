//
//  MySQLSchemaGeneration.m
//  Adaptors
//
//  Created by Tom Martin on 4/27/17.
//
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

#import "MySQLSchemaGeneration.h"

@implementation MySQLSchemaGeneration

/*  Build something like:
 
CREATE TABLE `member` (
   `accepted`           INT DEFAULT NULL,
   `applied`            INT DEFAULT NULL,
   `assoc`              SMALLINT unsigned NOT NULL,
   `bill_rep`           INT NOT NULL,
   `customer`           INT NOT NULL,
   `datasite`           INT DEFAULT NULL,
   `division`           INT DEFAULT NULL,
   `fiscal_year_start`  INT DEFAULT NULL,
   `note`               INT DEFAULT NULL,
   `num`                SMALLINT NOT NULL,
   `purchase_order`     INT DEFAULT NULL,
   `resigned`           INT DEFAULT NULL,
   `roster_note`        VARCHAR(1024) DEFAULT NULL,
   `service_rep`        INT DEFAULT NULL,
   `status`             VARCHAR(1) DEFAULT NULL,
   `sub`                VARCHAR(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8

 */

- (NSArray *)createTableStatementsForEntityGroup:(NSArray *)entityGroup
{
    NSMutableArray	*statements;
    Class			ExpressionClass = [self expressionClass];
    EOEntity		*entity;
    NSArray         *numTypeArray = @[@"DOUBLE",
        @"FLOAT", @"DECIMAL", @"TINYINT", @"SMALLINT", @"MEDIUMINT",
        @"INT", @"BIGINT", @"DOUBLE"];
    
    statements = [[NSMutableArray alloc] initWithCapacity:[entityGroup count]];
    for (entity in entityGroup)
    {
        NSArray				*attributes = [entity attributes];
        NSInteger			width = 0;
        NSMutableString		*statement = [[NSMutableString alloc] init];
        EOSQLExpression		*expression;
        NSString			*pad;
        EOAttribute         *attribute;
        BOOL                first;

        for (attribute in attributes)
        {
            if (width < [[attribute columnName] length])
                width = [[attribute columnName] length];
        }
        width +=2;
        
        [statement appendString:@"CREATE TABLE `"];
        [statement appendString:[entity externalName]];
        [statement appendString:@"` (\n"];
        first = YES;
        for (attribute in attributes)
        {
            NSString		*externalType = [[attribute externalType] uppercaseString];
            NSRange			aRange;
            BOOL            isString;
            BOOL            isNumber;
            NSString        *attribName;
            char            t;
            NSString        *valueType;
            
            isString = NO;
            isNumber = NO;
            if (! first)
                [statement appendString:@",\n"];
            else
                first = NO;
            
            [statement appendString:@"   "];
            attribName = [NSString stringWithFormat:@"`%@`", [attribute columnName]];
            pad = [attribName stringByPaddingToLength:width withString:@" " startingAtIndex:0];
            [statement appendString:pad];
            [statement appendString:@"  "];
            // check for VARCHAR, CHAR as syntax is the same
            aRange = [externalType rangeOfString:@"CHAR"];
            if (aRange.length > 0)
                isString = YES;
            // test for FLOAT, DOUBLE and DECIMAL as syntax is the same
            else if ([numTypeArray containsObject:externalType])
                isNumber = YES;
            
            if (isString)
            {
                [statement appendString:externalType];
                if ([attribute width])
                    [statement appendFormat:@"(%d)", [attribute width]];
            }
            else if (isNumber)
            {
                [statement appendString:externalType];
                if ([attribute precision] || [attribute scale])
                {
                    [statement appendFormat:@"(%d", [attribute precision]];
                    if ([attribute scale])
                        [statement appendFormat:@",%d", [attribute scale]];
                    [statement appendString:@")"];
                }
                valueType = [attribute valueType];
                if (valueType)
                {
                    t = [valueType characterAtIndex:0];
                    if (t < 'a')
                    {
                        // this is unsigned
                        [statement appendString:@" unsigned"];
                    }
                }
            }
            else
                [statement appendString:externalType];
            
            if (![attribute allowsNull])
                [statement appendString:@" NOT NULL"];
            else
                [statement appendString:@" DEFAULT NULL"];
        }
        
        [statement appendString:EOFormat(@"\n) ENGINE=InnoDB DEFAULT CHARSET=utf8")];
        
        expression = [[ExpressionClass alloc] init];
        [expression setStatement:statement];
        [statement release];
        [statements addObject:expression];
        [expression release];
    }
    
    return [statements autorelease];
}

- (NSArray *)dropPrimaryKeySupportStatementsForEntityGroup:(NSArray *)entityGroup
{
    NSMutableArray      *statements;
    EOSQLExpression		*expression;
    EOEntity			*entity;
    NSMutableString		*sql;
    NSString            *seqName;
    
    if ([entityGroup count] == 0)
        return [NSArray array];
    
    statements = [[NSMutableArray alloc] initWithCapacity:[entityGroup count]];
    for (entity in entityGroup)
    {
        expression = [[[self expressionClass] allocWithZone:[self zone]] init];
        sql = [@"DELETE FROM `ajr_sequence_data` WHERE `sequence_name` = " mutableCopy];
        seqName = [NSString stringWithFormat:@"%@_SEQ", [entity externalName]];
        [sql appendString:seqName];
        [expression setStatement:sql];
        [sql release];
        [statements addObject:expression];
        [expression release];
    }
    
    return [statements autorelease];
}


- (NSArray *)primaryKeySupportStatementsForEntityGroup:(NSArray *)entityGroup
{
    NSMutableArray      *statements;
    EOSQLExpression     *expression;
    EOEntity			*entity;
    NSMutableString		*sql;
    unsigned long long  startValue;
    NSString            *seqName;

    if ([entityGroup count] == 0)
        return [NSArray array];
    
    statements = [[NSMutableArray alloc] initWithCapacity:[entityGroup count]];
    for (entity in entityGroup)
    {
        startValue = 1;
        seqName = [NSString stringWithFormat:@"%@_SEQ", [entity externalName]];
        sql = [[NSMutableString alloc] initWithCapacity:200];
        [sql appendString:@"INSERT INTO AJR_SEQUENCE_DATA (sequence_name, sequence_cur_value) VALUE ('"];
        [sql appendString:seqName];
        [sql appendFormat:@"', %llu)", startValue];
        expression = [[[self expressionClass] allocWithZone:[self zone]] init];
        [expression setStatement:sql];
        [sql release];
        [statements addObject:expression];
        [expression release];
    }
    return [statements autorelease];
}

@end
