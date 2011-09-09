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
// $Id: EODataSource.h,v 1.3 2006/08/09 12:31:49 araftis Exp $

#ifndef __EOControl_EODataSource_H__
#define __EOControl_EODataSource_H__

#import <Foundation/NSObject.h>

@class NSArray, NSEnumerator;
@class EOClassDescription, EOEditingContext;

@interface EODataSource : NSObject

// Accessing the objects
- (NSArray *)fetchObjects;

// Inserting and deleting objects
- (void)deleteObject:(id)anObject;
- (void)insertObject:(id)anObject;
- (id)createObject;

// Creating detail data sources
- (EODataSource *)dataSourceQualifiedByKey:(NSString *)_relKey;
- (void)qualifyWithRelationshipKey:(NSString *)aRelationshipKey ofObject:(id)anObject;

// Accessing the editing context
- (EOEditingContext *)editingContext;

// Accessing the class description
- (EOClassDescription *)classDescriptionForObjects;

@end

#endif /* __EOControl_EODataSource_H__ */
