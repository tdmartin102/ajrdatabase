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
// $Id: EODetailDataSource.h,v 1.2 2008/01/10 09:37:46 davelopper Exp $

#ifndef __EOControl_EODetailDataSource_H__
#define __EOControl_EODetailDataSource_H__

#include <EOControl/EODataSource.h>
#import <EOControl/EOKeyValueArchiver.h>

@class EOClassDescription;

@interface EODetailDataSource : EODataSource <EOKeyValueArchiving>
{
  EOClassDescription *masterClassDescription;
  EODataSource       *masterDataSource;
  id                 masterObject;
  NSString           *detailKey;
}

- (id)initWithMasterClassDescription:(EOClassDescription *)_cd
  detailKey:(NSString *)_relKey; // designated initializer
- (id)initWithMasterDataSource:(EODataSource *)_ds
  detailKey:(NSString *)_relKey;

/* reflection */

- (void)setMasterClassDescription:(EOClassDescription *)_cd;
- (EOClassDescription *)masterClassDescription;
- (EODataSource *)masterDataSource;

/* master-detail */

- (id)masterObject;
- (NSString *)detailKey;

@end

#endif /* __EOControl_EODetailDataSource_H__ */
