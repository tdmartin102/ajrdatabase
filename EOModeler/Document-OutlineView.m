
#import "Document.h"
#import "Additions.h"

#import "ModelOutlineCell.h"

#import "Additions.h"

#import <EOAccess/EOAccess.h>

@implementation Document (OutlineView)

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil) {
		return 1;
	} else if ([item isKindOfClass:[EOModel class]]) {
		return [[item entities] count] + 1;
	} else if ([item isKindOfClass:[EOEntity class]]) {
		AJRPrintf(@"%@\n", [item fetchSpecificationNames]);
		return [[item relationships] count] + [[item fetchSpecificationNames] count];
	} else if ([item isKindOfClass:[EORelationship class]]) {
		return [[(EOEntity *)[item destinationEntity] relationships] count];
	} else if ([item isKindOfClass:[NSString class]]) {
		if ([item isEqualToString:StoredProcedures]) {
			return [[model storedProcedures] count];
		}
	}
	
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (item == nil) {
		return YES;
	} else if ([item isKindOfClass:[EOModel class]]) {
		return YES;
	} else if ([item isKindOfClass:[EOEntity class]]) {
		return [[item relationships] count] != 0 || [[item fetchSpecificationNames] count] != 0;
	} else if ([item isKindOfClass:[EORelationship class]]) {
		return [[(EOEntity *)[item destinationEntity] relationships] count] != 0;
	} else if ([item isKindOfClass:[EOStoredProcedure class]]) {
		return NO;
	} else if ([item isKindOfClass:[EOFetchSpecification class]]) {
		return NO;
	} else if ([item isKindOfClass:[NSString class]]) {
		if ([item isEqualToString:StoredProcedures]) {
			return [[model storedProcedures] count] != 0;
		}
	}
	
	return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (item == nil) {
		return model;
	} else if ([item isKindOfClass:[EOModel class]]) {
		NSArray		*entities = [item entities];
		
		if (index >= [entities count]) {
			return StoredProcedures;
		}
		
		return [entities objectAtIndex:index];
	} else if ([item isKindOfClass:[EOEntity class]]) {
		NSArray		*relationships = [item relationships];
		NSArray		*fetchNames = [item fetchSpecificationNames];
		
		if (index < [relationships count]) {
			return [relationships objectAtIndex:index];
		} else {
			NSString						*name = [fetchNames objectAtIndex:index - [relationships count]];
			EOFetchSpecification		*fetch = [item fetchSpecificationNamed:name];
			
			[fetch setInstanceObject:name forKey:@"_name"];
			[fetch setInstanceObject:item forKey:@"_entity"];
			
			return fetch;
		}
	} else if ([item isKindOfClass:[EORelationship class]]) {
		return [[(EOEntity *)[item destinationEntity] relationships] objectAtIndex:index];
	} else if ([item isKindOfClass:[NSString class]]) {
		if ([item isEqualToString:StoredProcedures]) {
			return [[model storedProcedures] objectAtIndex:index];
		}
	}
	
	return nil; 
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if ([item isKindOfClass:[EOModel class]]) {
		return [item name];
	} else if ([item isKindOfClass:[EOEntity class]]) {
		return [item name];
	} else if ([item isKindOfClass:[EOStoredProcedure class]]) {
		return [item name];
	} else if ([item isKindOfClass:[EORelationship class]]) {
		return [item name];
	} else if ([item isKindOfClass:[NSString class]]) {
		if ([item isEqualToString:StoredProcedures]) {
			return StoredProcedures;
		}
	} else if ([item isKindOfClass:[EOFetchSpecification class]]) {
		return [item instanceObjectForKey:@"_name"];
	}
	
	return @"hum?";
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([item isKindOfClass:[EOModel class]]) {
		[cell setImageName:@"EOModel"];
	} else if ([item isKindOfClass:[EORelationship class]]) {
		[cell setImageName:@"EORelationship"];
	} else if ([item isKindOfClass:[EOStoredProcedure class]]) {
		[cell setImageName:@"EOStoredProcedure"];
	} else if ([item isKindOfClass:[EOEntity class]]) {
		[cell setImageName:@"EOEntity"];
	} else if ([item isKindOfClass:[NSString class]] && [item isEqualToString:StoredProcedures]) {
		[cell setImageName:@"folder"];
	} else if ([item isKindOfClass:[EOFetchSpecification class]]) {
		[cell setImageName:@"EOFetchSpecification"];
	} else {
		[cell setImageName:nil];
	}
}

@end
