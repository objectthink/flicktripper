//
//  RootViewController.m
//  test
//
//  Created by stephen eshelman on 7/25/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "RootViewController.h"
#import "DetailViewController.h"
#import "testAppDelegate.h"
#import "UIImageInfoViewController.h"
#import "UserInfoController.h"
#import "ModalAlert.h"
#import "TDBadgedCell.h"

#define BARBUTTON(TITLE, SELECTOR) 	[[[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR] autorelease]
#define SYSBARBUTTON(ITEM, SELECTOR) [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:ITEM target:self action:SELECTOR] autorelease]
#define MAINLABEL	((UILabel *)self.navigationItem.titleView)

NSCondition* condition;
BOOL done = NO;

///////////////////////////////////////////////////////////////////////////////
//Show a basic, unadorned message box
void MessageBox(NSString* title, NSString* message)
{
   UIAlertView *av = 
   [[[UIAlertView alloc] 
     initWithTitle:title 
     message:message 
     delegate:nil 
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil] 
    autorelease];
	
   [av show];
}
///////////////////////////////////////////////////////////////////////////////
void ShowActivity(UIViewController* controller, BOOL show)
{
   if(show)
   {
      UIActivityIndicatorView *activityIndicator = 
      [[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)] autorelease];
      
      UIBarButtonItem * barButton = 
      [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
      
      // Set to Left or Right
      [[controller navigationItem] setLeftBarButtonItem:barButton];
      
      [barButton release];
      [activityIndicator startAnimating];
   }
   else
   {
      UIActivityIndicatorView *activityIndicator = 
      (UIActivityIndicatorView*)[[[controller navigationItem]leftBarButtonItem] customView];

      [[controller navigationItem] setLeftBarButtonItem:nil];
      [activityIndicator stopAnimating];
      //[activityIndicator release];

      //UIBarButtonItem * barButton = 
      //[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:controller action:@selector(doit)];

      //[[controller navigationItem] setLeftBarButtonItem:barButton];
      //[barButton release];
   }
}

@implementation RootViewController

@synthesize trips;
@synthesize app;

///////////////////////////////////////////////////////////////////////////////
//SHOW BUSY ALERT
-(void)ShowBusy:(BOOL)showing
{
   if(showing)
   {
      [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
      
      busyAlert = 
      [[[UIAlertView alloc]
        initWithTitle:@"Searching flickr" 
        message:nil 
        delegate:nil 
        cancelButtonTitle:nil 
        otherButtonTitles:nil] autorelease];
      
      [busyAlert show];
      
      UIActivityIndicatorView* aiv =
      [[UIActivityIndicatorView alloc]
       initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
      
      aiv.center = CGPointMake(busyAlert.bounds.size.width/2.0f, busyAlert.bounds.size.height - 40.0f);
      
      [aiv startAnimating];
      
      [busyAlert addSubview:aiv];
      [aiv release];
   }
   else 
   {
      if (busyAlert != nil) 
      {
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
         [busyAlert dismissWithClickedButtonIndex:0 animated:NO];
         busyAlert = nil;
      }
   }
}

///////////////////////////////////////////////////////////////////////////////
//OFFlickrAPIRequestDelegate
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
   TripJournalSession* session = request.sessionInfo;
   
   switch (session.requestType) 
   {
      case TRIPS:
         [self OnDoRequestTypeTrips:request didCompleteWithResponse:response];
         break;
      case FROB:
         [self OnDoRequestTypeFrob:request didCompleteWithResponse:response];
         break;
      case AUTH:
         [self OnDoRequestTypeAuth:request didCompleteWithResponse:response];
         break;
      case TAGS:
         [self OnDoRequestTypeTags:request didCompleteWithResponse:response];
         break;
      case IMAGES:
         [self OnDoRequestTypeImages:request didCompleteWithResponse:response];
         break;
      case IMAGEINFO:
         [self OnDoRequestTypeImageInfo:request didCompleteWithResponse:response];
         break;
      case DELETE:
         NSLog(@"ABOUT TO DELETE");

         Trip* trip = session.tag;
         if( [trip.stops count] > 0)
         {
            [trip.stops removeLastObject];
            
            if([trip.stops count] > 0)
            {
               Stop* stop = [trip.stops lastObject];
            
               [app.flickrRequest 
                callAPIMethodWithPOST:@"flickr.photos.delete" 
                arguments:[NSDictionary dictionaryWithObjectsAndKeys:stop.photoID,@"photo_id",nil]
                ];   
            }
            else 
            {
               int row = [trips indexOfObject:trip];
               NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:0];
               
               [trips removeObject:trip];

               [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

               MessageBox(nil, @"Trip successfully deleted from flickr!");
            }
         }
         break;
      default:
         break;
   }
}
///////////////////////////////////////////////////////////////////////////////
//flickrAPIRequest:didFailWithError
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didFailWithError:(NSError *)error
{
   TripJournalSession* session = request.sessionInfo;
   
   NSInteger errorCode = [error code];
   
   switch (session.requestType) 
   {
      case FROB:
         break;
      case AUTH:
         break;
      case TAGS:
         if(errorCode == 98)
         {
            MessageBox(@"Authorization",@"You flickr authorization has expired, please authorize again...");
            
            app.flickrContext.authToken = nil;
            
            //UPDATE THESE TO #DEFINE OR SOMETHING ELSE
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"flickrAuthToken"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"flickrAuthNsid"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"flickrAuthUsername"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"flickrAuthFullname"];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            [NSUserDefaults resetStandardUserDefaults];

            [self getTrips];
         }
         break;
      case IMAGES:
         break;
      case IMAGEINFO:
         break;
      default:
         MessageBox(@"didFailWithError", [error localizedDescription]);
         break;
   }
}
///////////////////////////////////////////////////////////////////////////////
//flickrAPIRequest:imageUploadSentBytes:totalBytes
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request imageUploadSentBytes:(NSUInteger)sent totalBytes:(NSUInteger)total
{
}
/////////////////////////////////////////////////////////////////////////////
//OnDoRequestTypeFrob
//Handle flickr frob response
-(void)OnDoRequestTypeFrob:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
   NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, request.sessionInfo, response);   
   
   [self OnAuthorizeWithResponse:response];
}
///////////////////////////////////////////////////////////////////////////////
//OnAuthorizeWithResponse:
//Login flickr with response frob to perform authorization
-(void)OnAuthorizeWithResponse:(NSDictionary*)response
{
   ////////////////////////////////////////////////////////////////////////////
   //STORE FROB TO USE LATER WHEN REQUESTING AUTH TOKEN
   [response retain];
   
   TripJournalSession* session = app.flickrRequest.sessionInfo;
   session.tag = response;
   
   UIImageInfoViewController* cc = 
   [[UIImageInfoViewController alloc]initWithNibName:@"ImageInfoController" bundle:nil];
   
   cc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
   
   NSURL *loginURL = 
   [app.flickrContext loginURLFromFrobDictionary:response requestedPermission:OFFlickrDeletePermission];
   
   NSURLRequest* ur = [NSURLRequest requestWithURL:loginURL];
   
   cc.theUrlRequest = ur;
   
   [self presentModalViewController:cc animated:YES]; 
   [cc release];
}
///////////////////////////////////////////////////////////////////////////////
//OnDoRequestTypeAuth
//Handle flickr get token response
-(void)OnDoRequestTypeAuth:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
   NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, request.sessionInfo, response);
   
   NSString* token = [[response valueForKeyPath:@"auth.token"]textContent];
   NSDictionary* user = [response valueForKeyPath:@"auth.user"];
   
   NSString* nsid = [user valueForKey:@"nsid"];
   NSString* fullname = [user valueForKey:@"fullname"];
   NSString* username = [user valueForKey:@"username"];
   
   NSLog(@"%@ %@ %@",nsid, fullname, username);
   
   if (![token length]) 
   {
      app.flickrContext.authToken = nil;
      
      //UPDATE THESE TO #DEFINE OR SOMETHING ELSE
      [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"flickrAuthToken"];
      [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"flickrAuthNsid"];
      [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"flickrAuthUsername"];
      [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"flickrAuthFullname"];

      [[NSUserDefaults standardUserDefaults] synchronize];
      [NSUserDefaults resetStandardUserDefaults];
   }
   else 
   {
      app.flickrContext.authToken = token;
      
      [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"flickrAuthToken"];
      [[NSUserDefaults standardUserDefaults] setObject:nsid forKey:@"flickrAuthNsid"];
      [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"flickrAuthUsername"];
      [[NSUserDefaults standardUserDefaults] setObject:fullname forKey:@"flickrAuthFullname"];
      
      [[NSUserDefaults standardUserDefaults] synchronize];
      [NSUserDefaults resetStandardUserDefaults];
      
      //self.title = [NSString stringWithFormat:@"%@ Trips", username]; 
      
      //SEARCH FOR TRIPS AGAIN NOW THAT WE HAVE AUTH
      [self getTrips];
   } 
   
   ////////////////////////////////////////////////////////////////////////////
   //TODO - CHECK THE TOKEN SOMEWHERE ELSE - TEST
   //[self CheckToken];
}
///////////////////////////////////////////////////////////////////////////////
//ONDOREQUESTTYPETAGS
//get a list of trips tags for the user from flickr
-(void)OnDoRequestTypeTags:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
   TripJournalSession* session = request.sessionInfo;

   NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, request.sessionInfo, response); 
   
   NSString* stat = [response valueForKey:@"stat"];
   if( [stat isEqualToString:@"ok"] )
   {
      NSArray* tags = [response valueForKeyPath:@"who.tags.tag"];
      
      if (tags != nil) 
      {
         //NSLog([NSString stringWithFormat:@"%d",[tags count]]);
         
         for(NSDictionary* d in tags)
         {
            //NSLog(@"%@",[d objectForKey:@"_text"]);   
            
            NSString* tag = [d objectForKey:@"_text"];
            
            if( [tag hasPrefix:@"iSimpleTripJournal:tripid="] )
            {
               NSLog(@"***%@", tag);
               [session.tripids addObject:tag];
            }
         }
         
         //////////////////////////////////////////////////////////////////////
         //START OFF THE SEARCH FOR TRIP INFO
         [self getTripInfo:session];
      }
   }      
}
///////////////////////////////////////////////////////////////////////////////
//ONDOREQUESTTYPETAGS
//get a list of trips tags for the user from flickr
-(void)OnDoRequestTypeTrips:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
   TripJournalSession* session = request.sessionInfo;
   
   NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, request.sessionInfo, response); 
   
   NSString* stat = [response valueForKey:@"stat"];
   if( [stat isEqualToString:@"ok"] )
   {
      NSArray* tags = [response valueForKeyPath:@"values.value"];
      
      if (tags != nil) 
      {
         //NSLog([NSString stringWithFormat:@"%d",[tags count]]);
         
         for(NSDictionary* d in tags)
         {
            NSString* tag = [d objectForKey:@"_text"];
            
            NSString* aTripId =
            [NSString stringWithFormat:@"isimpletripjournal:tripid=%@",tag];
            
            [session.tripids addObject:aTripId];            
         }
         
         //////////////////////////////////////////////////////////////////////
         //START OFF THE SEARCH FOR TRIP INFO
         [self getTripInfo:session];
      }
   }      
}
///////////////////////////////////////////////////////////////////////////////
//getTripInfo:
-(void)getTripInfo:(TripJournalSession*)session
{
   session.requestType = IMAGES;
   
   session.index++;
   if(session.index < [session.tripids count])
   {
      //UPDATE THE LIST
      [self.tableView reloadData];

      //IF THIS IS THE FIRST TRIP WE FETCHED
      if(session.index == 0)
      {
         ShowActivity(self, YES);
         self.tableView.allowsSelection = NO;
      }
      
      session.trip = nil;
      
      NSLog(@"%@",
         [NSString stringWithFormat:@"Searching me for %@",[session.tripids objectAtIndex:session.index]]);
             
      NSString* tripid = 
      [session.tripids objectAtIndex:session.index];
      
      [app.flickrRequest 
       callAPIMethodWithGET:@"flickr.photos.search" 
       arguments:[NSDictionary dictionaryWithObjectsAndKeys:
         tripid                ,@"tags",
         @"date-posted-asc"    ,@"sort",
         @"me"                 ,@"user_id",
         nil]
       ];         
   }
   else
   {
      ShowActivity(self, NO);
      
      //WE ARE DONE NOW UPDATE THE TABLWVIEW
      [self.tableView reloadData];
      
      self.navigationItem.rightBarButtonItem.enabled = YES;
      
      self.tableView.allowsSelection = YES;
   }
}
///////////////////////////////////////////////////////////////////////////////
//getPhotoInfo
-(void)getPhotoInfo:(TripJournalSession*)session
{
   session.requestType = IMAGEINFO;
   
   session.photoIndex++;
   if(session.photoIndex < [session.photos count])
   {
      NSDictionary* photo = [session.photos objectAtIndex:session.photoIndex];
      NSString* photoId = [photo objectForKey:@"id"];
      
      [app.flickrRequest 
       callAPIMethodWithGET:@"flickr.photos.getInfo" 
       arguments:[NSDictionary dictionaryWithObjectsAndKeys:photoId,@"photo_id",nil]
       ];               
   }
   else 
   {
      //[session.photos release];
      //session.photos = nil;
      session.photoIndex = -1;
      
      [self getTripInfo:session];
   }   
}
///////////////////////////////////////////////////////////////////////////////
//OnDoRequestTypeImages
-(void)OnDoRequestTypeImages:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
   TripJournalSession* session = request.sessionInfo;

   NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, request.sessionInfo, response);
   
   NSString* stat = [response valueForKey:@"stat"];
   if( [stat isEqualToString:@"ok"] )
   {
      NSDictionary* photoDict = [response objectForKey:@"photos"];
      NSArray* photos = [photoDict objectForKey:@"photo"];  
      
      NSLog(@"Found %d images",[photos count]);
      
      session.photos = photos;
      
      [self getPhotoInfo:session];
      
      //GET THE FIRST PHOTO - EXAMPLE
      //NSDictionary* onePhoto =
      //[[response valueForKeyPath:@"photos.photo"]objectAtIndex:0];
      //NSLog(@"%@",[[flickrContext photoSourceURLFromDictionary:onePhoto size:OFFlickrMediumSize] absoluteString]);
      
      /////////////////////////////////////////////////////////////////////////
      //TODO NEED TO COME UP WITH HOW TO PICK ONE IMAGE HERE INSTEAD OF
      //ADDING THEM ALL TO images AS THERE COULD BE A LOT
      //or(NSDictionary* aPhoto in photos)
      //{
         ///////////////////////////////////////////////////////
         //COMPARE TO URL STRINGS RETURNED FROM OF
         //NSURL *photoURL = [app.flickrContext photoSourceURLFromDictionary:aPhoto size:OFFlickrSmallSize];
         //NSURL *photoSourcePage = [app.flickrContext photoWebPageURLFromDictionary:aPhoto];
         //NSLog( @"%@",[photoURL absoluteString] );
         //NSLog( @"%@",[photoSourcePage absoluteString] );
      //}
   }
}
///////////////////////////////////////////////////////////////////////////////
//OnDoRequestTypeImageInfo
-(void)OnDoRequestTypeImageInfo:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
   TripJournalSession* session = request.sessionInfo;

   NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, request.sessionInfo, response);
   
   NSString* stop       = [NSString stringWithFormat:@"stop number %d"        , session.photoIndex];
   NSString* stopDetails= [NSString stringWithFormat:@"stop number %d details", session.photoIndex];
   NSString* tripName   = [NSString stringWithFormat:@"trip number %d"        , session.index];
   NSString* tripDetails= [NSString stringWithFormat:@"trip details %d"       , session.index];
   int number = -1;
   float lat = 0.0f;
   float lon = 0.0f;
   
   ///////////////////////////////////////////////////////////////////////////
   //ITEREATE OVER TAGS AND FIND THE TRIP NAME AND STOP 
   NSArray* tags = [response valueForKeyPath:@"photo.tags.tag"];
   for(NSDictionary* d in tags)
   {
      NSLog(@"%@",[d objectForKey:@"raw"]);   
      
      NSString* tag = [d objectForKey:@"raw"];
      
      if( [tag hasPrefix:@"iSimpleTripJournal:tripname="] )
      {
         NSLog(@"***%@", [tag substringFromIndex:28]); 
         tripName = [tag substringFromIndex:28];
      }
      
      if( [tag hasPrefix:@"iSimpleTripJournal:tripdetails="] )
      {
         NSLog(@"***%@", [tag substringFromIndex:31]); 
         tripDetails = [tag substringFromIndex:31];
      }

      if( [tag hasPrefix:@"iSimpleTripJournal:stop="] )
      {
         NSLog(@"*****%@", [tag substringFromIndex:24]); 
         stop = [tag substringFromIndex:24];
      }
      
      if( [tag hasPrefix:@"iSimpleTripJournal:stopdetails="] )
      {
         NSLog(@"*****%@", [tag substringFromIndex:31]); 
         stopDetails = [tag substringFromIndex:31];
      }

      if( [tag hasPrefix:@"iSimpleTripJournal:tripid="] )
      {
         NSLog(@"***%@", [tag substringFromIndex:26]); 
         number = [[tag substringFromIndex:26]intValue ];
      }

      if( [tag hasPrefix:@"geo:lat="] )
      {
         NSLog(@"***%@", [tag substringFromIndex:8]); 
         lat = [[tag substringFromIndex:8]floatValue ];
      }

      if( [tag hasPrefix:@"geo:lon="] )
      {
         NSLog(@"***%@", [tag substringFromIndex:8]); 
         lon = [[tag substringFromIndex:8]floatValue ];
      }
   }      
   
   ////////////////////////////////////////////////////////////////////////////
   //COLLECT TRIP NAME AND STORE IN TRIP
   if(session.trip == nil)
   {
      int numberOfStops = [session.photos count];
      
      session.trip = 
      [Trip initWithName:tripName details:tripDetails stops:numberOfStops number:number];
      
      [trips addObject:session.trip];
   }
   
   ///////////////////////////////////////////////////////////////////////////////
   //MAKE SURE WE GET THE FIRST STOP - IT WAS THE ONE THAT
   //CAUSED US TO CREATE THE TRIP ABOVE
   if(session.trip != nil)
   {
      NSDictionary* photo = [session.photos objectAtIndex:session.photoIndex];
      NSString* photoID = [photo objectForKey:@"id"];
      
      NSURL* photoURL = 
      [app.flickrContext photoSourceURLFromDictionary:photo size:OFFlickrSmallSize];
      NSURL* photoSourcePage = 
      [app.flickrContext photoWebPageURLFromDictionary:photo];

      ////////////////////////////////////////////////////////////////////////////
      //ADD STOPS INFO
      [session.trip.stops addObject:
       [Stop 
        initWithName:stop 
        details:stopDetails
        photoURL:photoURL
        photoSourceURL:photoSourcePage
        photoID:photoID
        latitude:lat
        longitude:lon
        ]];
      
      Stop* aStop = [session.trip.stops lastObject];
      aStop.trip = session.trip;
      aStop.uploaded = YES;
   }
   
   ////////////////////////////////////////////////////////////////////////////
   //GET THE NEXT PHOTO INFO
   [self getPhotoInfo:session];
}

#pragma mark -
#pragma mark View lifecycle
- (void)viewDidLoad 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [super viewDidLoad];
   
   [self.navigationController setToolbarHidden:NO animated:YES];   

   
   /////////////////////////////////////////////////////////////////
   //CREATE A MULTI-LINE LABEL FOR THE MAVIGATION ITEM TITLEVIEW
   NSString* username = 		
   [[NSUserDefaults standardUserDefaults] objectForKey:@"flickrAuthUsername"];

   UILabel* aLabel1 = [[[UILabel alloc] initWithFrame:CGRectMake(0, 20, 100, 20)] autorelease];
   
   [aLabel1 setFont:[UIFont fontWithName:@"Helvetica" size:18.0f]];
   [aLabel1 setText:@"My Trips"];
   
   aLabel1.backgroundColor = [UIColor clearColor];
   aLabel1.shadowColor = [UIColor whiteColor];
   aLabel1.shadowOffset = CGSizeMake(1.0, 1.0);
   aLabel1.textAlignment = UITextAlignmentCenter;

    
   UILabel* aLabel2 = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)] autorelease];
   
   [aLabel2 setFont:[UIFont fontWithName:@"Helvetica" size:14.0f]];
   [aLabel2 setText:username];
   
   aLabel2.backgroundColor = [UIColor clearColor];
   aLabel2.shadowColor = [UIColor whiteColor];
   aLabel2.shadowOffset = CGSizeMake(1.0, 1.0);
   aLabel2.textAlignment = UITextAlignmentCenter;

   UIView* myTitleView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 100, 40)];
   [myTitleView addSubview:aLabel1];
   [myTitleView addSubview:aLabel2];
   
   self.navigationItem.titleView = myTitleView;
   /////////////////////////////////////////////////////////////////
   
   //UIBarButtonItem* test = 
   //[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(doit)];
   
   //UIButton* infoButon = [UIButton buttonWithType:UIButtonTypeInfoLight];
   
   //[infoButon addTarget:self action:@selector(doit:) forControlEvents:UIControlEventTouchUpInside];
   //infoButon.tag = 7;
   
   //UIBarButtonItem* toolbarItem1 =    
   //[[[UIBarButtonItem alloc]
   //  initWithCustomView:infoButon]autorelease];
   
   //UIBarButtonItem* toolbarItem2 = 
   //[[UIBarButtonItem alloc]
   //initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(doit:)];
   //toolbarItem2.tag = 77;

   //[self setToolbarItems:[NSArray arrayWithObjects:toolbarItem1,nil]];

   //[test release];
   
   ////////////////////////////////////////////////////////////////////////////
   //SET THE FLICKR REQUEST DELEGATE
   app = (testAppDelegate*)[[UIApplication sharedApplication] delegate];
   app.flickrRequest.delegate = self;
   
   self.title = @"Trips";
   self.navigationItem.title = @"Trips";
   
   //GET TRIPS
   [self getTrips];
          
   [self setBarButtonItems];

   // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
///////////////////////////////////////////////////////////////////////////////
//TOOLBAR HANDLER
-(void)doit:(id)sender
{
   switch([sender tag])
   {
      case 7:
      {
         UserInfoController* controller = 
         [[UserInfoController alloc] initWithNibName:@"UserInfoController" bundle:nil];
         
         [self.navigationController pushViewController:controller animated:YES];
         
         [controller release];
      }
         break;
      case 77:
         [self getTrips];
         break;
   }
}
///////////////////////////////////////////////////////////////////////////////
//GET TRIPS
-(void)getTrips
{
   NSString* token = 		
   [[NSUserDefaults standardUserDefaults] objectForKey:@"flickrAuthToken"];
   
   if(![token length])
      [self RequestFrob];
   else
   {
      app.flickrContext.authToken = token;
      [self getTripsFromFlickr];
   }
}
///////////////////////////////////////////////////////////////////////////////
//GET TRIPS FROM FLICKR
-(void)getTripsFromFlickr
{
   self.trips = [NSMutableArray array];

   //NSString* username = 		
   //[[NSUserDefaults standardUserDefaults] objectForKey:@"flickrAuthUsername"];
   
   //self.title = [NSString stringWithFormat:@"%@ Trips", username];
      
   app.flickrRequest.sessionInfo = [TripJournalSession sessionWithRequestType:TAGS];
   
   TripJournalSession* session = app.flickrRequest.sessionInfo;

   NSString* nsid = 		
   [[NSUserDefaults standardUserDefaults] objectForKey:@"flickrAuthNsid"];

   switch(session.requestType)
   {
      case TRIPS:
         [app.flickrRequest 
          callAPIMethodWithGET:@"flickr.machinetags.getValues" 
          arguments:[NSDictionary dictionaryWithObjectsAndKeys:@"isimpletripjournal",@"namespace",@"tripid",@"predicate",nil]
          ];            
         break;
      case TAGS:
         [app.flickrRequest 
          callAPIMethodWithGET:@"flickr.tags.getListUser" 
          arguments:[NSDictionary dictionaryWithObjectsAndKeys:nsid,@"user_id",nil]
          ];            
         break;
      default:
         NSLog(@"SWITCH SKIPPED");
         break;
   }

}
///////////////////////////////////////////////////////////////////////////////
//GET TRIPS FROM FLICKR - TEST
-(void)getTripsFromFlickrX
{
   self.trips = [NSMutableArray array];
   
   NSString* username = 		
   [[NSUserDefaults standardUserDefaults] objectForKey:@"flickrAuthUsername"];
   
   //self.title = [NSString stringWithFormat:@"%@ Trips", username];
   
   Trip* trip;
   
   trip = [Trip initWithName:@"My trip to Cozumel" details:@"some details about my trip" stops:3];
   [trips addObject:trip];
   [trip.stops addObject:[Stop initWithName:@"Coconuts" details:@"Stopped for margarita's"]];
   [trip.stops addObject:[Stop initWithName:@"Mezcalito's" details:@"Yummy tacos"]];
   [trip.stops addObject:[Stop initWithName:@"Ernestos" details:@"the best fajitas on the island"]];
   
   trip = [Trip initWithName:@"Aruba was great!" details:@"fun in Aruba" stops:1];
   [trips addObject:trip];
   [trip.stops addObject:[Stop initWithName:@"Bunker Bar" details:@"Free drinks!"]];
   
   trip = [Trip initWithName:@"Somewhere name" details:@"Some details" stops:3];
   [trips addObject:trip];
   [trip.stops addObject:[Stop initWithName:@"here" details:@"Stopped here"]];
   [trip.stops addObject:[Stop initWithName:@"there" details:@"Stopped there"]];
   [trip.stops addObject:[Stop initWithName:@"everywhere" details:@"ate everywhere"]];      
}
///////////////////////////////////////////////////////////////////////////////
//Request the frob from Flickr
-(void)RequestFrob
{
   app.flickrRequest.sessionInfo = [TripJournalSession sessionWithRequestType:FROB];
   
   [app.flickrRequest 
    callAPIMethodWithGET:@"flickr.auth.getFrob" 
    arguments:nil];         
}
///////////////////////////////////////////////////////////////////////////////
//VIEW WILL APPEAR
- (void)viewWillAppear:(BOOL)animated 
{
   [super viewWillAppear:animated];
   
   [self.tableView reloadData];
   
   TripJournalSession* session = app.flickrRequest.sessionInfo;
   
   switch (session.requestType) 
   {
      case FROB:
         if (session.tag != nil) 
         {
            //MessageBox(@"FROB", @"FROB");
            NSDictionary* frobResponse = session.tag;
            session.requestType = AUTH;
            NSString* frob = [[frobResponse valueForKeyPath:@"frob"]textContent];
            
            [app.flickrRequest 
             callAPIMethodWithGET:@"flickr.auth.getToken" 
             arguments:[NSDictionary dictionaryWithObjectsAndKeys:frob,@"frob", nil]];            
         }
         break;
      default:
         break;
   }
}
///////////////////////////////////////////////////////////////////////////////
//VIEW DID APPEAR
- (void)viewDidAppear:(BOOL)animated 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [super viewDidAppear:animated];
   
   ////////////////////////////////////////////////////////////////////////////
   //SET THE FLICKR REQUEST DELEGATE
   app = (testAppDelegate*)[[UIApplication sharedApplication] delegate];
   app.flickrRequest.delegate = self;   
}
///////////////////////////////////////////////////////////////////////////////
//VIEW DID APPEAR
- (void)viewWillDisappear:(BOOL)animated 
{
   [super viewWillDisappear:animated];
}
///////////////////////////////////////////////////////////////////////////////
//VIEW DID APPEAR
- (void)viewDidDisappear:(BOOL)animated 
{
   [super viewDidDisappear:animated];
}

/*
 // Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 */

-(int)determineNextTripId
{
   int nextTripId = 1;
   for(Trip* trip in trips)
   {
      if(trip.number > nextTripId)
         nextTripId = trip.number;
   }
   
   return nextTripId+1;
}

-(void)addTrip:(id)sender
{
   Trip* trip;
   
   NSString* name    = [ModalAlert ask:@"Enter trip name"    withTextPrompt:@"Trip Name"]; 
   if(name == nil)
      return;
   
   NSString* details = [ModalAlert ask:@"Enter trip details" withTextPrompt:@"Trip Details"];
   if(details == nil)
      details = @" ";
   
   trip = [Trip initWithName:name details:details stops:0 number:[self determineNextTripId]]; 
   
   [trips addObject:trip];
   
   [self.tableView reloadData];
}

- (void) setBarButtonItems
{
   if(self.navigationItem.rightBarButtonItem == nil)
   {
      self.navigationItem.rightBarButtonItem = SYSBARBUTTON(UIBarButtonSystemItemAdd, @selector(addTrip:));  
      self.navigationItem.rightBarButtonItem.enabled = NO;
   }
   
   //if(self.navigationItem.leftBarButtonItem == nil)
   //{
   //   self.navigationItem.leftBarButtonItem = SYSBARBUTTON(UIBarButtonSystemItemAdd, @selector(addTrip:));         
   //}
	
	//if (self.tableView.isEditing)
	//	self.navigationItem.rightBarButtonItem = SYSBARBUTTON(UIBarButtonSystemItemDone, @selector(leaveEditMode));
	//else
	//	self.navigationItem.rightBarButtonItem = 
    //     self.trips.count ? SYSBARBUTTON(UIBarButtonSystemItemEdit, @selector(enterEditMode)) : nil;
}

-(void)enterEditMode
{
   self.navigationItem.leftBarButtonItem.enabled = NO;
   
   [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
   [self.tableView setEditing:YES animated:YES];
   [self setBarButtonItems];
}

-(void)leaveEditMode
{
   self.navigationItem.leftBarButtonItem.enabled = YES;
   
   [self.tableView setEditing:NO animated:YES];
   [self setBarButtonItems];
}

#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
   return 1;
}

//- (void)
//   tableView:(UITableView *)aTableView 
//   commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
//   forRowAtIndexPath:(NSIndexPath *)indexPath 
//{
   //MessageBox(@"tableView:commitEditingStyle:forRowAtIndexPath", @"called");
//}

///////////////////////////////////////////////////////////////////////////////
// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
   return self.trips.count;
}
///////////////////////////////////////////////////////////////////////////////
// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
   static NSString *CellIdentifier = @"Cell";
      
   TDBadgedCell* cell = (TDBadgedCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
   if (cell == nil) 
   {
      cell = 
      [[[TDBadgedCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
       
      //cell.textLabel.text = [[contents objectAtIndex:indexPath.row] objectForKey:@"title"];
      //cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
       
      //cell.detailTextLabel.text = [[contents objectAtIndex:indexPath.row] objectForKey:@"detail"];
      //cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
       
      //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
       
      //if (indexPath.row == 1)
      //   cell.badgeColor = [UIColor colorWithRed:1.000 green:0.397 blue:0.419 alpha:1.000];
       
      //if (indexPath.row == 2)
      //   cell.badgeColor = [UIColor colorWithWhite:0.783 alpha:1.000];
       
      //return cell;
    }
    
	// Configure the cell.
   Trip* trip;
   trip = [trips objectAtIndex:indexPath.row];
   
   NSString* badge = [[NSString alloc] initWithFormat:@"%d",[trip.stops count]];
   cell.badgeNumber = badge; 
   [badge release];

   cell.textLabel.text = trip.name;
   cell.detailTextLabel.text = trip.details;
   
   cell.detailTextLabel.textColor = [UIColor blackColor];
   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
   cell.editingAccessoryType = UITableViewCellAccessoryNone;
   
   //IMAGE USED TO IDENTIFY TRIP - COULD BE A STOP IMAGE SET AS DEFAULT
   //if( [trip.stops count] > 0 )
   //{
   //   Stop* stop = [trip.stops objectAtIndex:0];
   //   
   //   if(stop.image != nil)
   //      cell.imageView.image = stop.image;
   //}
   
   //cell.imageView.image = 
   //[UIImage imageNamed:@"simpletripjournal512x512.png"];

   return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

///////////////////////////////////////
//DELETE THE SELECTED TRIP
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    if (editingStyle == UITableViewCellEditingStyleDelete) 
    {
       if([ModalAlert ask:@"Deleting this trip will remove all stops and photos from flickr..."])
       {           
          Trip* trip = [trips objectAtIndex:[indexPath row]];

          //DELETE THE ROW FROM THE DATA SOURCE
          //[trip.stops removeObjectAtIndex:indexPath.row];
             
          ///////////////////////////////////////////////
          //SEND DELETE REQUEST
          TripJournalSession* session = [TripJournalSession sessionWithRequestType:DELETE];
          app.flickrRequest.sessionInfo = session;
          session.tag = trip;

          Stop* stop = [trip.stops lastObject];
                    
          [app.flickrRequest 
           callAPIMethodWithPOST:@"flickr.photos.delete" 
           arguments:[NSDictionary dictionaryWithObjectsAndKeys:stop.photoID,@"photo_id",nil]];
       }

       //[trips removeObjectAtIndex:[indexPath row]];

       // Delete the row from the data source.
       //[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) 
    {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
   //TDBadgedCell* cell = (TDBadgedCell*)[self.tableView cellForRowAtIndexPath:indexPath];
   
   /////////////////////////////////////////////
   //UIActivityIndicatorView *activityIndicator = 
   //[[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)] autorelease];
   
   //[activityIndicator startAnimating];
   
   //cell.accessoryView = activityIndicator;
   //[cell setNeedsDisplay];
   //[self.tableView setNeedsDisplay];
   //ShowActivity(self, YES);
   /////////////////////////////////////////////
   
   DetailViewController*
   detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
   //detailViewController.tag = cell;
   
   // ...
   // Pass the selected object to the new view controller.
   detailViewController.trip = [trips objectAtIndex:indexPath.row];
   
   [self.navigationController pushViewController:detailViewController animated:YES];
   [detailViewController release];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning 
{
   // Releases the view if it doesn't have a superview.
   [super didReceiveMemoryWarning];
    
   NSLog(@"%s", __PRETTY_FUNCTION__);
   
   //[ModalAlert say:@"RootViewController Memory Warning!"];
   // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
   // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
   // For example: self.myOutlet = nil;
   
   NSLog(@"%s", __PRETTY_FUNCTION__);

   //[ModalAlert say:@"RootViewController viewDidUnload"];
   
   [self.trips removeAllObjects];
   self.trips = nil;
}

- (void)dealloc 
{
   [super dealloc];
   
   NSLog(@"%s", __PRETTY_FUNCTION__);
}
@end

