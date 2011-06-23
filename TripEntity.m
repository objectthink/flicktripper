//
//  TripEntity.m
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 6/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TripEntity.h"
#import "StopEntity.h"


@implementation TripEntity
@dynamic number;
@dynamic details;
@dynamic name;
@dynamic Stops;

- (void)addStopsObject:(StopEntity *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"Stops" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"Stops"] addObject:value];
    [self didChangeValueForKey:@"Stops" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeStopsObject:(StopEntity *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"Stops" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"Stops"] removeObject:value];
    [self didChangeValueForKey:@"Stops" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addStops:(NSSet *)value {    
    [self willChangeValueForKey:@"Stops" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"Stops"] unionSet:value];
    [self didChangeValueForKey:@"Stops" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeStops:(NSSet *)value {
    [self willChangeValueForKey:@"Stops" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"Stops"] minusSet:value];
    [self didChangeValueForKey:@"Stops" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
