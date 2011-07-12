//
//  StopEntity.h
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 7/4/11.
//  Copyright (c) 2011 blue sky computing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TripEntity;

@interface StopEntity : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSString * details;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, copy) NSString * photoSourceURLString;
@property (nonatomic, copy) NSString * photoIdString;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, copy) NSString * photoThumbURLString;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, copy) NSString * photoURLString;
@property (nonatomic, retain) TripEntity * Trip;

@end
