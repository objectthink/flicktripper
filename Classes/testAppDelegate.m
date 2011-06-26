//
//  testAppDelegate.m
//  test
//
//  Created by stephen eshelman on 7/25/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "testAppDelegate.h"
#import "RootViewController.h"

@interface AUIViewController : UIViewController
@end

@implementation AUIViewController
///////////////////////////////////////////////////////////////////////////////
//The viw was touched - test only
-(void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event 
{
}
@end

@interface AUIView : UIView 
{
}
@end
@implementation AUIView
@end

@implementation testAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize flickrContext;
@synthesize flickrRequest;
@synthesize locationManager;
@synthesize context;
@synthesize results;
@synthesize trips;
@synthesize hasTrips;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.
   //RootViewController* rvc = (RootViewController*)navigationController.view;
   //rvc.tableView.backgroundColor = [UIColor clearColor];

   ////////////////////////////////////////////////////////////////////////////
   //SHOW SPLASH FOR SOME TIME
   [NSThread sleepForTimeInterval:1];
   
    // Load in the backsplash image into a view
   //UIImageView *iv = 
   //[[[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:@"backsplash.png"]] autorelease];
      
   // Add the navigation controller's view to the window and display.
   //[window addSubview:iv];
   [window addSubview:navigationController.view];   
   [window makeKeyAndVisible];

   //CREATE OBJECTIVE FLICKR CONTEXT
   if(!flickrContext)
   {
      flickrContext=
      [[OFFlickrAPIContext alloc] 
       initWithAPIKey:OBJECTIVE_FLICKR_API_KEY 
       sharedSecret:OBJECTIVE_FLICKR_API_SHARED_SECRET];
   }
   
   if (!flickrRequest) 
   {
      flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:flickrContext];
      flickrRequest.requestTimeoutInterval = 60.0;
   }   
   
   //CREATE THE LOCATION MANAGER INSTANCE
   locationManager = [[CLLocationManager alloc] init];
   [locationManager setDistanceFilter:kCLDistanceFilterNone];
   [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
   
   if (![locationManager locationServicesEnabled]) 
   {
      UIAlertView *servicesDisabledAlert = 
      
      [[UIAlertView alloc] 
       initWithTitle:@"Location Services Disabled" 
       message:@"You currently have all location services for this device disabled. The next time add new stop you will be asked to confirm whether location services should be reenabled." 
       delegate:nil 
       cancelButtonTitle:@"OK" 
       otherButtonTitles:nil
       ];
      
      [servicesDisabledAlert show];
      [servicesDisabledAlert release];
   }

   //determine if we have persisted trips
   self.hasTrips = [[NSUserDefaults standardUserDefaults] boolForKey:HAS_PERSISTED_TRIPS];
   
   //initialize the database interface
   [self initializeDatabase];

   if(self.hasTrips == YES)
   {
      [self fetchTrips];
      [self initializeTrips];
   }
   else
   {
      //initialize the database interface
      //remove the file if it exists
      //and initialize the database interface
      //again
      [self resetDatabase];
      [self initializeDatabase];
   }

   return YES;
}

/////////////////////////////////////////
-(void)initializeDatabase
{
   NSError* error;
   
   //path to database file
   NSString* path = [NSHomeDirectory() stringByAppendingString:@"/Documents/isimpletripjournal_database.sqlite"];
   NSURL* url = [NSURL fileURLWithPath:path];
   
   //init the model
   NSManagedObjectModel* managedObjectModel= [NSManagedObjectModel mergedModelFromBundles:nil];
   
   //establish persistent store
   NSPersistentStoreCoordinator* persistenStoreCoodinator =
   [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
   
   if(![persistenStoreCoodinator 
        addPersistentStoreWithType:NSSQLiteStoreType 
        configuration:nil 
        URL:url options:nil 
        error:&error])
      NSLog(@"Error %@", [error localizedDescription]);
   else
   {
      //create context and assign coordinator
      self.context =
      [[[NSManagedObjectContext alloc] init] autorelease];
      
      [self.context setPersistentStoreCoordinator:persistenStoreCoodinator];
   }
      
   [persistenStoreCoodinator release];
   
   //TRY TO READ DATABASE
//   [self fetchTrips];
   
   //TRY TO SAVE SOMETHING
//   TripEntity* aTrip  = 
//   (TripEntity*)[NSEntityDescription 
//                 insertNewObjectForEntityForName:@"TripEntity"
//                 inManagedObjectContext:self.context];
//   
//   aTrip.name = @"my trip name";
//   aTrip.details = @"some details";
//   aTrip.number = [NSNumber numberWithInt:77];
//
//   StopEntity* aStop  = 
//   (StopEntity*)[NSEntityDescription 
//                 insertNewObjectForEntityForName:@"StopEntity"
//                 inManagedObjectContext:self.context];
//
//   aStop.name = @"my stop";
//   aStop.details = @"stop details";
//   aStop.Trip = aTrip;
//   
//   if(![self.context save:&error])
//      NSLog(@"Error saving trip:%@", [error localizedDescription]);
}

-(void)resetDatabase
{
   NSPersistentStoreCoordinator* 
   persistentStoreCoordinator = [self.context persistentStoreCoordinator];
   
   
   NSArray *stores = [persistentStoreCoordinator persistentStores];
   
   for(NSPersistentStore *store in stores) 
   {
      [persistentStoreCoordinator removePersistentStore:store error:nil];
      [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
   }
   
   //[persistentStoreCoordinator release];
   
   //self.context = nil;
}

-(TripEntity*)addTripEntity:(Trip*)trip
{
   TripEntity* aTripEntity  = 
   (TripEntity*)[NSEntityDescription 
                 insertNewObjectForEntityForName:@"TripEntity"
                 inManagedObjectContext:self.context];
   
   aTripEntity.name = trip.name;
   aTripEntity.details = trip.details;
   aTripEntity.number = [NSNumber numberWithInt:trip.number];

   [aTripEntity retain];
   
   return aTripEntity;
}

-(StopEntity*)addStopEntity:(Stop*)stop forTripEntity:(TripEntity*)tripEntity
{
   StopEntity* aStopEntity  = 
   (StopEntity*)[NSEntityDescription 
                 insertNewObjectForEntityForName:@"StopEntity"
                 inManagedObjectContext:self.context];
   
   aStopEntity.name = stop.name;
   aStopEntity.details = stop.details;
   aStopEntity.number = [NSNumber numberWithInt:stop.number];
   aStopEntity.latitude = [NSNumber numberWithDouble:stop.location.latitude];
   aStopEntity.longitude = [NSNumber numberWithDouble:stop.location.longitude];
   aStopEntity.photoIdString = stop.photoID;
   aStopEntity.photoSourceURLString = [stop.photoSourceURL absoluteString];
   aStopEntity.photoURLString = [stop.photoURL absoluteString];
   
   aStopEntity.Trip = tripEntity;

   return aStopEntity;
}

-(BOOL)persistEntities
{
   BOOL r = NO;
   
   NSError* error;
   if(![self.context save:&error])
   {
      NSLog(@"Error saving trip:%@", [error localizedDescription]);
   }
   else
   {
      [self fetchTrips];
      [self initializeTrips];

      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:HAS_PERSISTED_TRIPS];
      
      [[NSUserDefaults standardUserDefaults] synchronize];
      [NSUserDefaults resetStandardUserDefaults];
      
      r = YES;
   }
   
   self.hasTrips = r;
   
   return r;
}

-(BOOL)fetchTrips
{
	// Create a basic fetch request
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"TripEntity" inManagedObjectContext:self.context]];
	
	// Add a sort descriptor
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"number" ascending:YES selector:nil];
	NSArray *descriptors = [NSArray arrayWithObject:sortDescriptor];
	[fetchRequest setSortDescriptors:descriptors];
	[sortDescriptor release];
	
	// Init the fetched results controller
	NSError *error;
	self.results = 
   [[NSFetchedResultsController alloc] 
    initWithFetchRequest:fetchRequest 
    managedObjectContext:self.context 
    sectionNameKeyPath:nil cacheName:@"Root"];
   
	self.results.delegate = self;
	
   if (![[self results] performFetch:&error])	
      NSLog(@"Error: %@", [error localizedDescription]);
   
	[self.results release];
	[fetchRequest release];
   
   ///////////test
   if (!self.results.fetchedObjects.count) 
	{
		NSLog(@"Database has no trips at this time");
		return YES;
	}
	
	NSLog(@"trips:");
	for (TripEntity* trip in self.results.fetchedObjects)
   {
		NSLog(@"%@ : %d", trip.name, [trip.Stops count]);
      for(StopEntity* stop in trip.Stops)
         NSLog(@"%@",stop.name);
   }
   /////////////
   
   return YES;
}

-(BOOL)initializeTrips
{
   self.trips = [NSMutableArray array]; 
   
   for (TripEntity* tripEntity in self.results.fetchedObjects)
   {
      Trip* trip = 
      [Trip 
       initWithName:tripEntity.name 
       details:tripEntity.details 
       stops:[tripEntity.Stops count] 
       number:[tripEntity.number intValue]];

      for(StopEntity* stopEntity in tripEntity.Stops)
      {
         Stop* stop =
         [Stop 
          initWithName:stopEntity.name 
          details:stopEntity.details
          photoURL:[NSURL URLWithString:stopEntity.photoURLString]
          photoSourceURL:[NSURL URLWithString:stopEntity.photoSourceURLString]
          photoID:stopEntity.photoIdString
          latitude:[stopEntity.latitude floatValue]
          longitude:[stopEntity.longitude floatValue]];
         
         stop.trip = trip;
         
         [trip.stops addObject:stop];
      }
      
      [self.trips addObject:trip];
   }
   
   return YES;
}

////////////////////////////////////////////////////////
//initialize the database with the passed array of trips
-(void)initializeDatabaseWith:(NSArray *)flickrTrips
{
   [self resetDatabase];
   [self initializeDatabase];
   
   for(Trip* trip in flickrTrips)
   {
      TripEntity* tripEntity = [self addTripEntity:trip];
      
      for(Stop* stop in trip.stops)
         [self addStopEntity:stop forTripEntity:tripEntity];
   }
   
   [self persistEntities];
   
   //test
   //[self fetchTrips];
}

- (void)applicationWillResignActive:(UIApplication *)application 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   */
   
   flickrDelegate = flickrRequest.delegate;
   flickrSession = flickrRequest.sessionInfo;
}

- (void)applicationDidEnterBackground:(UIApplication *)application 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);
   /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
   */
}

- (void)applicationWillEnterForeground:(UIApplication *)application 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);
   /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
   flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:flickrContext];
   flickrRequest.requestTimeoutInterval = 60.0;
   flickrRequest.sessionInfo = flickrSession;
   flickrRequest.delegate = flickrDelegate;
}

- (void)applicationDidBecomeActive:(UIApplication *)application 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   */
}

- (void)applicationWillTerminate:(UIApplication *)application 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}


@end

