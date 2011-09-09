//
//  EOQualifier-Model.h
//  EOAccess/
//
//  Created by Alex Raftis on 9/27/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <EOControl/EOQualifier.h>
#import <EOControl/EOAndQualifier.h>
#import <EOControl/EOOrQualifier.h>
#import <EOControl/EOKeyValueQualifier.h>
#import <EOAccess/EOSQLQualifier.h>

@interface EOQualifier (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;

@end

@interface EOAndQualifier (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;

@end

@interface EOOrQualifier (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;

@end

@interface EOKeyValueQualifier (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;

@end

@interface EOSQLQualifier (Model)

- (id)initWithPropertyList:(NSDictionary *)properties owner:(id)owner;
- (void)encodeIntoPropertyList:(NSMutableDictionary *)properties;

@end
