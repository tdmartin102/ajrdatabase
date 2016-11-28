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

#import "EOEntity-ObjCCode.h"

#import "EOAttributeP.h"
#import "EOEntityP.h"
#import "EORelationship.h"

#import <EOControl/EOControl.h>

@implementation EOEntity (ObjCCode)

- (NSDictionary *)scalarTypeDictionary {
  return @{
                                       @"c" : @"char",
                                       @"C" : @"unsigned char",
                                       @"i" : @"int",
                                       @"I" : @"unsigned int",
                                       @"l" : @"long",
                                       @"L" : @"unsigned long",
                                       @"s" : @"short",
                                       @"S" : @"unsigned short",
                                       @"q" : @"long long",
                                       @"q" : @"unsigned long long",
                                       @"f" : @"float",
                                       @"d" : @"double" };
}

- (NSString *)objectiveCInterface
{
    NSMutableString		*string = [NSMutableString string];
    EOAttribute			*attribute;
    EORelationship		*relationship;
    NSMutableArray		*temp;
    BOOL                first;
    BOOL                hadToMany;
    NSDictionary *scalarTypeDictionary = [self scalarTypeDictionary];
    NSMutableDictionary *scalarAttribDict;
    NSString *scalarType;
    
    [self _initialize];
    
    hadToMany = NO;
    scalarAttribDict = [[NSMutableDictionary alloc] initWithCapacity:40];
   
    [string appendString:@"\n"];
    [string appendString:@"#import <EOAccess/EOAccess.h>\n"];
    [string appendString:@"\n"];

    temp = [[NSMutableArray alloc] init];
    for (relationship in relationships) {
        if ([classPropertyNames containsObject:[relationship name]]) {
            if (![[[relationship destinationEntity] className] isEqualToString:@"EOGenericRecord"]) {
                [temp addObject:[[relationship destinationEntity] className]];
            }
        }
    }

   if ([temp count]) {
       NSString *aClassName;
       
	   [string appendString:@"@class "];
       first = YES;
       for (aClassName in temp) {
           if (! first)
               [string appendString:@", "];
           else
               first = NO;
           [string appendString:aClassName];
       }
       [string appendString:@";\n\n"];
    }
   
    [string appendFormat:@"@interface %@ : %@\n", [self className], [self parentEntity] ? [[self parentEntity] className] : @"EOEnterpriseObject"];
    
    //============
    // Properties
    //============
    
    // attribs ivar declarations
    for (attribute in attributes) {
        if ([attribute _isClassProperty]) {
            // find out if this is a scalar
            scalarType = nil;
            if ([[attribute valueClassName] isEqualToString:@"NSNumber"] || [[attribute valueClassName] isEqualToString:@"NSDecimalNumber"]) {
                if ([[attribute valueType] length]) {
                    scalarType = [scalarTypeDictionary objectForKey:[attribute valueType]];
                    if (scalarType) {
                        // save this for later
                        [scalarAttribDict setObject:scalarType forKey:[attribute name]];
                    }
                }
            }
            if (scalarType) {
                [string appendFormat:@"@property (nonatomic, assign) \t%@ %@;\n", scalarType, [attribute name]];
            }
            else {
                if ([[attribute valueClassName] isEqualToString:@"NSString"]) {
                    [string appendFormat:@"@property (nonatomic, copy) \t%@ *%@;\n", [attribute _valueClass], [attribute name]];
                }
                else {
                    [string appendFormat:@"@property (nonatomic, retain) \t%@ *%@;\n", [attribute _valueClass], [attribute name]];
                }
            }
        }
    }
    [scalarAttribDict release];
    
    // to-One ivar declarations
    [string appendString:@"\n// To-One Relationships\n\n"];
    for (relationship in relationships) {
        if (![relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
            [string appendFormat:@"@property (nonatomic, retain) \t%@ *%@;\n", [[relationship destinationEntity] className],
             [relationship name]];
        }
    }
        
    // to-Many ivar declarations
    [string appendString:@"\n// To-Many Relationships\n\n"];
    for (relationship in relationships) {
        if ([relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
            [string appendFormat:@"@property (nonatomic, retain) \tNSArray *%@;\n", [relationship name]];
            hadToMany = YES;
        }
    }
    
    [string appendString:@"\n\n"];

    //============
    // Methods
    //============
    if (hadToMany) {
        [string appendString:@"\n// To-Many Relationships\n\n"];

        for (relationship in relationships) {
            if ([relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
                [string appendFormat:@"- (void)addTo%@:(%@ *)value;\n", [[relationship name] capitalizedName],
                 [[relationship destinationEntity] className]];
                [string appendFormat:@"- (void)removeFrom%@:(%@ *)value;\n",
                 [[relationship name] capitalizedName], [[relationship destinationEntity] className]];
            }
        }
    }

    [string appendString:@"\n"];
    [string appendString:@"@end\n"];
    [string appendString:@"\n"];
   
    [temp release];
   
    return string;
}

- (NSString *)objectiveCImplementation
{
    NSMutableString		*string = [NSMutableString string];
    EOAttribute			*attribute;
    EORelationship		*relationship;
    NSMutableArray		*temp;
    BOOL                hadToMany;
    BOOL                hadToOne;
    NSString            *aClassName;
    NSDictionary *scalarTypeDictionary = [self scalarTypeDictionary];
    NSString *scalarType;

    [self _initialize];
    
    temp = [[NSMutableArray alloc] init];
    for (relationship in relationships) {
        if ([classPropertyNames containsObject:[relationship name]]) {
            if (![[[relationship destinationEntity] className] isEqualToString:@"EOGenericRecord"]) {
                [temp addObject:[[relationship destinationEntity] className]];
            }
        }
    }

    [string appendString:@"\n"];
    [string appendFormat:@"#import \"%@.h\"\n", [self className]];
    [string appendString:@"\n"];

    if ([temp count]) {
        for (aClassName in temp) {
            [string appendFormat:@"#import \"%@.h\"\n", aClassName];
        }
        [string appendString:@"\n"];
    }

    [string appendFormat:@"@implementation %@\n", [self className]];
    [string appendString:@"\n"];
    
    // to-Many ivar declarations
    hadToMany = NO;
    hadToOne = NO;
    for (relationship in relationships) {
        if ([relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
            if ([relationship isToMany])
                hadToMany = YES;
            else
                hadToOne = YES;
        }
    }

    // private ivars
    if (hadToMany) {
        [string appendString:@"\n// To-Many Relationships\n\n"];
        [string appendString:@"{\n"];
        for (relationship in relationships) {
            if ([relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
                [string appendFormat:@"    NSMutableArray\t*_%@;\n", [relationship name]];
            }
        }
        [string appendString:@"}\n\n"];
        
        [string appendString:@"- (instancetype)init {\n"];
        [string appendString:@"    if ((self = [super init])) {\n"];
        for (relationship in relationships) {
            if ([relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
                [string appendFormat:@"        _%@ = [[NSMutableArray alloc] initWithCapacity:100];\n",
                 [relationship name]];
            }
        }
        [string appendString:@"    }\n"];
        [string appendString:@"    return self;\n"];
        [string appendString:@"}\n\n"];
    }
    
    for (attribute in attributes) {
        if ([attribute _isClassProperty]) {
            // find out if this is a scalar
            scalarType = nil;
            if ([[attribute valueClassName] isEqualToString:@"NSNumber"] || [[attribute valueClassName] isEqualToString:@"NSDecimalNumber"]) {
                if ([[attribute valueType] length]) {
                    scalarType = [scalarTypeDictionary objectForKey:[attribute valueType]];
                }
            }
            if (scalarType) {
                [string appendFormat:@"- (void)set%@:(%@)value {\n", [[attribute name] capitalizedName], scalarType];
                [string appendString:@"   [self willChange];\n"];
                [string appendFormat:@"   _%@ = value;\n", [attribute name]];
            }
            else {
                [string appendFormat:@"- (void)set%@:(%@ *)value {\n", [[attribute name] capitalizedName], [attribute _valueClass]];
                [string appendString:@"   [self willChange];\n"];
                if ([[attribute valueClassName] isEqualToString:@"NSString"]) {
                    [string appendFormat:@"   _%@ = [value copy];\n", [attribute name]];
                }
                else {
                    [string appendFormat:@"   _%@ = value;\n", [attribute name]];
                }
            }
            [string appendString:@"}\n\n"];
        }
    }

    if (hadToOne) {
        [string appendString:@"\n// To-One Relationships\n\n"];
        for (relationship in relationships) {
            if (![relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
                [string appendFormat:@"- (void)set%@:(%@ *)value {\n", [[relationship name] capitalizedName], [[relationship destinationEntity] className]];
                [string appendFormat:@"   [self willChange];\n"];
                [string appendFormat:@"   _%@ = value;\n", [relationship name]];
                [string appendFormat:@"}\n\n"];
            }
        }
    }

    if (hadToMany) {
        [string appendString:@"\n// To-Many Relationships\n\n"];
        for (relationship in relationships) {
            if ([relationship isToMany] && [classPropertyNames containsObject:[relationship name]]) {
                [string appendFormat:@"- (void)set%@:(%@ *)value {\n", [[relationship name] capitalizedName], @"NSArray"];
                [string appendString:@"   [self willChange];\n"];
                [string appendFormat:@"   _%@ = [value mutableCopy];\n", [relationship name]];
                [string appendString:@"}\n"];
                [string appendString:@"\n"];
                [string appendFormat:@"- (%@ *)%@ {\n", @"NSArray", [relationship name]];
                [string appendFormat:@"   return _%@;\n", [relationship name]];
                [string appendString:@"}\n"];
                [string appendString:@"\n"];
                [string appendFormat:@"- (void)addTo%@:(%@ *)value {\n",
                 [[relationship name] capitalizedName], [[relationship destinationEntity] className]];
                [string appendString:@"   [self willChange];\n"];
                [string appendFormat:@"   [_%@ addObject:value];\n", [relationship name]];
                [string appendString:@"}\n"];
                [string appendString:@"\n"];
                [string appendFormat:@"- (void)removeFrom%@:(%@ *)value {\n",
                 [[relationship name] capitalizedName], [[relationship destinationEntity] className]];
                [string appendString:@"   [self willChange];\n"];
                [string appendFormat:@"   [_%@ removeObject:value];\n", [relationship name]];
                [string appendString:@"}\n\n"];
            }
        }
    }

    [string appendString:@"@end\n\n"];

    [temp release];
   
    return string;
}

@end
