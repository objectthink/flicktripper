//
//  testAppDelegate.m
//  test
//
//  Created by stephen eshelman on 7/25/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "testAppDelegate.h"
#import "RootViewController.h"
#import "TripEntity.h"

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

   //initialize the database
   [self initializeDatabase];
   
   return YES;
}

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
   
   //TRY TO SAVE SOMETHING
   TripEntity* aTrip  = 
   (TripEntity*)[NSEntityDescription 
                 insertNewObjectForEntityForName:@"TripEntity"
                 inManagedObjectContext:self.context];
   
   aTrip.name = @"my trip name";
   aTrip.details = @"some details";
   aTrip.number = [NSNumber numberWithInt:77];

   if(![self.context save:&error])
      NSLog(@"Error saving trip:%@", [error localizedDescription]);
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

