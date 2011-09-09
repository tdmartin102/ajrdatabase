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
// $Id: EODetailDataSource.m,v 1.3 2008/01/10 09:37:46 davelopper Exp $

#include "EODetailDataSource.h"
#include "NSClassDescription-EO.h"
#include "EOKeyValueCoding.h"
#import "NSObject-EORelationshipManipulation.h"

#ifndef ASSIGN
#  define ASSIGN(object, value) \
({id __object = (id)object;    \
	id __value = (id)value;      \
		if (__value != __object) { if (__value) [__value retain]; \
			if (__object) [__object release]; \
				object = __value;}})
#endif

@implementation EODetailDataSource

- (id)initWithMasterClassDescription:(EOClassDescription *)_cd
  detailKey:(NSString *)_relKey
{
  if ((self = [super init])) {
    self->masterClassDescription = [_cd retain];

    [self qualifyWithRelationshipKey:_relKey ofObject:nil];
  }
  return self;
}

- (id)initWithMasterDataSource:(EODataSource *)_ds
  detailKey:(NSString *)_relKey
{
  if ((self = [self initWithMasterClassDescription:nil detailKey:_relKey])) {
    self->masterDataSource = [_ds retain];
  }
  return self;
}

- (id)init {
  return [self initWithMasterClassDescription:nil detailKey:nil];
}

- (void)dealloc {
  [self->detailKey              release];
  [self->masterObject           release];
  [self->masterClassDescription release];
  [self->masterDataSource       release];
  [super dealloc];
}

/* reflection */

- (void)setMasterClassDescription:(EOClassDescription *)_cd {
  ASSIGN(self->masterClassDescription, _cd);
}
- (EOClassDescription *)masterClassDescription {
  return self->masterClassDescription;
}

- (EODataSource *)masterDataSource {
  return self->masterDataSource;
}

/* editing context */

- (id)editingContext {
  return [[self masterObject] editingContext];
}

/* master-detail */

- (id)masterObject {
  return self->masterObject;
}
- (NSString *)detailKey {
  return self->detailKey;
}

- (void)qualifyWithRelationshipKey:(NSString *)_relKey ofObject:(id)_object {
  id tmp;

  tmp = self->detailKey;
  self->detailKey = [_relKey copy];
  [tmp release];

  ASSIGN(self->masterObject, _object);
}

/* operations */

- (NSArray *)fetchObjects {
  id       eo;
  NSString *dk;
  
  if ((eo = [self masterObject]) == nil)
    return [NSArray array];

  if ((dk = [self detailKey]) == nil)
    return [NSArray arrayWithObject:eo];

  return [eo valueForKey:dk];
}

- (void)insertObject:(id)_object {
  id       eo;
  NSString *dk;
  
  if ((eo = [self masterObject]) == nil) {
    [NSException raise:@"NSInternalInconsistencyException"
                 format:
                   @"detail datasource %@ has no master object set "
                   @"for insertion of object %@",
                   self, _object];
  }
  if ((dk = [self detailKey]) == nil) {
    [NSException raise:@"NSInternalInconsistencyException"
                 format:
                   @"detail datasource %@ has no detail key set "
                   @"for insertion of object %@ into master %@",
                   self, _object, eo];
  }
  
  [eo addObject:_object toBothSidesOfRelationshipWithKey:dk];
}

- (void)deleteObject:(id)_object {
  id       eo;
  NSString *dk;
  
  if ((eo = [self masterObject]) == nil) {
    [NSException raise:@"NSInternalInconsistencyException"
                 format:
                   @"detail datasource %@ has no master object set "
                   @"for deletion of object %@",
                   self, _object];
  }
  if ((dk = [self detailKey]) == nil) {
    [NSException raise:@"NSInternalInconsistencyException"
                 format:
                   @"detail datasource %@ has no detail key set "
                   @"for deletion of object %@ from master %@",
                   self, _object, eo];
  }
  
  [eo removeObject:_object fromPropertyWithKey:dk];
}

#pragma mark <EOKeyValueArchiving>

- (id)initWithKeyValueUnarchiver:(EOKeyValueUnarchiver *)unarchiver
{
    /*
     dataSource = {
         class                  = EODetailDataSource; 
         detailKey              = roles; 
         masterClassDescription = Movie; 
     }; 
     */
    if ((self = [super init])) {
        NSString *ename;
        
        detailKey = [[unarchiver decodeObjectForKey:@"detailKey"] copy];
        
        ename = [unarchiver decodeObjectForKey:@"masterClassDescription"];
        masterClassDescription = [[EOClassDescription classDescriptionForEntityName:ename] retain];
    }
    return self;
}

- (void)encodeWithKeyValueArchiver:(EOKeyValueArchiver *)archiver 
{
    [archiver encodeObject:[self detailKey] forKey:@"detailKey"];
    [archiver encodeObject:[[self masterClassDescription] entityName]
                    forKey:@"masterClassDescription"];
}

@end /* EODetailDataSource */
