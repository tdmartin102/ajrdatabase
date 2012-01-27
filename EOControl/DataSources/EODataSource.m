/*
 Copyright (C) 2000-2003 SKYRIX Software AG
 
 This file is part of OGo
 
 OGo is free software; you can redistribute it and/or modify it under
 the terms of the GNU Lesser General Public License as published by the
 Free Software Foundation; either version 2, or (at your option) any
 later version.
 
 OGo is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or
 FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with OGo; see the file COPYING.  If not, write to the
 Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA.
 */
// $Id: EODataSource.m,v 1.3 2006/07/03 14:11:11 araftis Exp $

#import "EODataSource.h"
#import "EOEditingContext.h"
#import "EOTemporaryGlobalID.h"
#import "NSClassDescription-EO.h"

@implementation EODataSource

+ (int)version 
{
	return 1;
}

/* reflection */

- (EOClassDescription *)classDescriptionForObjects
{
	return nil;
}

/* master-detail */

- (EODataSource *)dataSourceQualifiedByKey:(NSString *)relKey 
{
	[NSException raise:@"NSInvalidArgumentException"
               format:@"datasource %@ can't return a ds qualified by key '%@'", self, relKey];
	return nil;
}

- (void)qualifyWithRelationshipKey:(NSString *)relKey ofObject:(id)object
{
	[NSException raise:@"NSInvalidArgumentException"
               format:@"datasource %@ can't qualify by key '%@' of object %@", self, relKey, object];
}

/* operations */

- (NSArray *)fetchObjects
{
	return nil;
}

- (void)deleteObject:(id)object
{
	[NSException raise:@"NSInvalidArgumentException"
               format:@"datasource %@ can't delete object %@",	self, object];
}

- (void)insertObject:(id)object
{
	[NSException raise:@"NSInvalidArgumentException"
               format:@"datasource %@ can't insert object %@",	self, object];
}

- (id)createObject 
{
	EOClassDescription	*classDescription;
	EOEditingContext	*editingContext = [self editingContext];
	id					newObject;
    EOGlobalID          *gid;
	
	if ((classDescription = [self classDescriptionForObjects]) == nil) {
		return nil;
	}
	
    gid = [[EOTemporaryGlobalID alloc] init];
	newObject = [classDescription createInstanceWithEditingContext:editingContext 
        globalID:gid zone:[self zone]];
    [gid release];
	[editingContext insertObject:newObject];
	
	return newObject;
}

- (EOEditingContext *)editingContext
{
	return nil;
}

@end /* EODataSource */
