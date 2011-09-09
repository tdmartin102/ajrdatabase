//
//  _EOSnapshotMutableDictionary.h
//  EOAccess/
//
//  Created by Alex Raftis on 10/14/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface _EOSnapshotMutableDictionary : NSMutableDictionary
{
	NSMutableDictionary		*dictionary;
}

- (id)objectForKey:(id)key after:(NSTimeInterval)timestamp;

- (NSTimeInterval)timestampForKey:(id)key;

- (void)incrementReferenceCountForKey:(id)key;
- (void)decrementReferenceCountForKey:(id)key;

@end
