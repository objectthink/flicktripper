//
//  testAppDelegate.h
//  test
//
//  Created by stephen eshelman on 7/25/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import<ObjectiveFlickr.h>
#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>
#import "Trip.h"
#import "TripEntity.h"
#import "StopEntity.h"

#define OBJECTIVE_FLICKR_API_KEY             @"2a27ceabcdf4b005d9a1b7bcb4f0d488"
#define OBJECTIVE_FLICKR_API_SHARED_SECRET   @"105871eb12e708a4"

#define FLICKR_TOKEN_KEY      @"flickrAuthToken"
#define FLICKR_NSID_KEY       @"flickrAuthNsid"
#define FLICKR_USERNAME_KEY   @"flickrAuthUsername"
#define FLICKR_FULLNAME_KEY   @"flickrAuthFullname"

#define UPLOAD_FULLSIZE_KEY   @"uploadFullSizePhotos"
#define UPLOAD_PUBLIC_KEY     @"uploadPublic"
#define DELAY_UPLOAD_KEY      @"delayUpload"
#define HAS_PERSISTED_TRIPS   @"hasPersistedTrips"

@interface testAppDelegate : NSObject <
UIApplicationDelegate,
NSFetchedResultsControllerDelegate> 
{
    
   UIWindow *window;
   UINavigationController *navigationController;
   
   OFFlickrAPIContext* flickrContext;
   OFFlickrAPIRequest* flickrRequest;
   
   CLLocationManager* locationManager;
   
   id flickrDelegate;
   id flickrSession;
   
   NSManagedObjectContext* context;
   NSFetchedResultsController *results;
   
   NSMutableArray* trips;
   BOOL hasTrips;
}

-(void)initializeDatabase;
-(void)initializeDatabaseWith:(NSArray*)trips;
-(void)resetDatabase;
-(TripEntity*)addTripEntity:(Trip*)trip;
-(StopEntity*)addStopEntity:(Stop*)stop forTripEntity:(TripEntity*)tripEntity;
-(BOOL)persistEntities;
-(BOOL)fetchTrips;
-(BOOL)initializeTrips;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) CLLocationManager* locationManager;
@property (retain) NSMutableArray* trips;
@property (readonly, assign, getter=getHasTrips) BOOL hasTrips;

@property (retain) OFFlickrAPIContext* flickrContext;
@property (retain) OFFlickrAPIRequest* flickrRequest;
@property (retain) NSManagedObjectContext* context;
@property (nonatomic, retain) NSFetchedResultsController *results;

@end

