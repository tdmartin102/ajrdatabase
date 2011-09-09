//
//  ModelOutlineCell.h
//  AJRDatabase
//
//  Created by Alex Raftis on 9/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <AJRInterface/AJRInterface.h>

@interface ModelOutlineCell : NSTextFieldCell
{
	NSString		*imageName;
}

- (void)setImageName:(NSString *)anImageName;
- (NSString *)imageName;

@end
