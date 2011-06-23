//
//  TripEntity.h
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 6/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class StopEntity;

@interface TripEntity : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSString * details;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* Stops;

@end
