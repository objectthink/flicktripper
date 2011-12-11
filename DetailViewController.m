//
//  DetailViewController.m
//  test
//
//  Created by stephen eshelman on 7/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "StopViewController.h"
#import "RootViewController.h"
#import "ModalAlert.h"
#import <dispatch/dispatch.h>
#import <Foundation/NSLock.h>

#define BARBUTTON(TITLE, SELECTOR) 	 [[[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR] autorelease]
#define SYSBARBUTTON(ITEM, SELECTOR) [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:ITEM target:self action:SELECTOR] autorelease]
#define MAINLABEL	((UILabel *)self.navigationItem.titleView)

@implementation DetailViewController

@synthesize trip;
@synthesize app;
@synthesize tag;
@synthesize isUploadingWaiting;
@synthesize backRequested;

////////////////////////////////////////////////////////////////////////////////
//Attempt the free up memory before capturing a new stop
-(void)relinquishTripImages
{   
   [trip relinquishImages];
}

#pragma mark -
#pragma mark CLLocationManage
NSInteger useLocation = 0;
////////////////////////////////////////////////////////////////////////////////
//locationManager:didUpdateToLocation:fromLocation
//store the current location to be used in the new stop
-(void)locationManager:(CLLocationManager *)manager 
   didUpdateToLocation:(CLLocation *)newLocation 
          fromLocation:(CLLocation *)oldLocation
{
   NSLog(@"%@ time:%f",newLocation,[[newLocation timestamp]timeIntervalSinceNow]);
   
//   currentLocation = [newLocation coordinate];
//
//   //HOW OLD IS THIS READING?
//   NSTimeInterval t =
//   [[newLocation timestamp]timeIntervalSinceNow];
//   
//   if(t < -120) 
//   {
//      NSLog(@"SKIPPING LOCATION READING");
//      return;
//   }
//   
//   //if((useLocation%3)==1)
//   
//   if(true)
//   {
//      currentLocation = [newLocation coordinate];
//   
//      //WEVE GOT A LOCATION SO STOP UPDATES
//      [app.locationManager stopUpdatingLocation];
//   }
   
   currentLocation = [newLocation coordinate];

   // test that the horizontal accuracy does not indicate an invalid measurement
   if (newLocation.horizontalAccuracy < 0) return;
   // test the age of the location measurement to determine if the measurement is cached
   // in most cases you will not want to rely on cached measurements
   NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
   if (locationAge > 5.0) return;

   //WEVE GOT A LOCATION SO STOP UPDATES
   [app.locationManager stopUpdatingLocation];
}

BOOL userInformedOfDisabledLocationServices = NO;
////////////////////////////////////////////////////////////////////////
//locationManager:didFailWithError
//there was an error getting the current location
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
   NSLog(@"%s %@", __PRETTY_FUNCTION__, error);   

   //[ModalAlert say:[error localizedDescription]];
   
   if ([error domain] == kCLErrorDomain) 
   {
      // We handle CoreLocation-related errors here
      switch ([error code]) 
      {
            // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
            // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
         case kCLErrorDenied:
            // USER HAS DISALLOWED LOCATION SERVICES FOR ISIMPLE TRIP JOURNAL
            //STOP UPDATING LOCATION
            [app.locationManager stopUpdatingLocation];
            break;
         case kCLErrorLocationUnknown:
            break;
         default:
            break;
      }
   } 
   else 
   {
      // We handle all non-CoreLocation errors here
   }
}

-(UIImage*)resizeImage:(UIImage*)image
{
   UIImage* newImage;
   
   CGFloat w;
   CGFloat h;
   
   if(image.size.width > image.size.height)
   {
      w=640;
      h=480;
   }
   else
   {
      w=480;
      h=640;
   }
   
   ////////////////////////////////////////////////////////////////////////////
   //RESIZE THE IMAGE TO 480x640 FOR UPLOAD TO FLICKR
   //TODO GIVE THE USER THE OPTION TO UPLOAD THE FULL SIZE IMAGE
   CGSize newSize = {w,h};
   
   UIGraphicsBeginImageContext( newSize );// a CGSize that has the size you want
   [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
   
   //image is the original UIImage
   newImage = UIGraphicsGetImageFromCurrentImageContext();
   UIGraphicsEndImageContext();
   ////////////////////////////////////////////////////////////////////////////
   
   return newImage;
}

#pragma mark -
#pragma mark DetailViewController
-(void)getStopInfo:(UIImage*)image
{
   TripJournalSession* session = app.flickrRequest.sessionInfo;
      
   session.requestType = UPLOAD;
      
   NSString* stopName    = [ModalAlert ask:@"Enter stop name"    withTextPrompt:@"Stop Name"];
   
   if(stopName == nil)
   {
      //STOP THE LOCATION MANAGER
      app.locationManager.delegate = nil;
      [app.locationManager stopUpdatingLocation];
      
      return;
   }
   
   NSString* stopDetails = [ModalAlert ask:@"Enter stop details" withTextPrompt:@"Stop Details"];
   
   ////////////////////////////////////////////////////////////////////
   //DONT BOTHER UNLESS WE GET A NAME
   if( stopName!=nil )
   {
      if(stopDetails == nil)
         stopDetails = @" ";
      
      Stop* stop = [Stop initWithName:stopName details:stopDetails];
      
      //ADD THESE PROPERTIES BY HAND AS WE DON'T HAVE ALL OF THE
      //STOP DATA YET
      stop.image = [self resizeImage:image];
      stop.location = currentLocation;
      stop.mapPoint = [MapPoint withCoordinate:stop.location title:stop.name];
      stop.trip = self.trip;
      
      [self.trip.stops addObject:stop];
      
      if (![[NSUserDefaults standardUserDefaults] boolForKey:DELAY_UPLOAD_KEY])
         [self Upload:image withStop:(Stop*)stop];
      else 
      {
         //STOP THE LOCATION MANAGER
         app.locationManager.delegate = nil;
         [app.locationManager stopUpdatingLocation];
         
         [self.tableView reloadData];
         
         //UPDATE THE TOOLBAR
         uploadWaiting.enabled = self.trip.needsUploading;
      }
   }
}

-(int)determineNextStopNumber
{
   int nextStopNumber = 1;
   for(Stop* stop in trip.stops)
   {
      if(stop.number > nextStopNumber)
         nextStopNumber = stop.number;
   }
   
   return nextStopNumber+1;
}

-(void)flickrAPIRequest:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
   NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, request.sessionInfo, response);   
   
   TripJournalSession* session = app.flickrRequest.sessionInfo;
   
   switch (session.requestType) 
   {
      case UPLOAD:
         //[self.tableView reloadData];
         
         //STOP THE LOCATION MANAGER
         app.locationManager.delegate = nil;
         
         [app.locationManager stopUpdatingLocation];
         
         [response retain];
         
         [self getPhotoInfo:response];
         break;
      case IMAGEINFO:
      {
         [response retain];
         
         [uploadProgressActionSheet dismissWithClickedButtonIndex:0 animated:YES];
         //ShowActivity(self, NO);

         TripJournalSession* session = app.flickrRequest.sessionInfo;

         Stop* aStop =  (Stop*)session.tag;

         NSArray* urls = [response valueForKeyPath:@"photo.urls.url"];
         
         aStop.photoSourceURL = [NSURL URLWithString:[[urls objectAtIndex:0]objectForKey:@"_text"]];
         aStop.photoID        = [response valueForKeyPath:@"photo.id"];
         aStop.photoURL       = 
         [app.flickrContext photoSourceURLFromDictionary:[response valueForKey:@"photo"] size:OFFlickrSmallSize];
         aStop.photoThumbURL  = 
         [app.flickrContext photoSourceURLFromDictionary:[response valueForKey:@"photo"] size:OFFlickrSmallSquareSize];
                  
         
         aStop.number = [self determineNextStopNumber];
         
         ////////////////////////////////////////////////////////////////////////////
         //GET DATES
         NSDictionary* dates = [response valueForKeyPath:@"photo.dates"];
         NSString* taken = [dates objectForKey:@"taken"];

         aStop.taken = taken;         

         ////////////////////////////////////////////////
         //SET LOCATION
         session.requestType = LOCATION;
         
         NSString* latS = [NSString stringWithFormat:@"%f",aStop.location.latitude];
         NSString* lonS = [NSString stringWithFormat:@"%f",aStop.location.longitude];
         
         [app.flickrRequest 
          callAPIMethodWithPOST:@"flickr.photos.geo.setLocation" 
          arguments:[NSDictionary dictionaryWithObjectsAndKeys:
                     latS,@"lat",
                     lonS,@"lon",
                     aStop.photoID, @"photo_id",nil]];         
         
         //wait til we have the photo urls to repaint the list
         [self.tableView reloadData];

         break;
      }
      case LOCATION:
      {
         Stop* aStop =  (Stop*)session.tag;

         aStop.uploaded = YES;
         
         //force new thumb to be fetch the next time the list is updated
         //[aStop.thumb release];
         aStop.thumb = nil;
         
         //CHECK FOR MORE DELAYED UPLOADS
         for (Stop* aStop in self.trip.stops) 
         {
            if(!aStop.uploaded)
            {
               [self Upload:nil withStop:aStop];
               return;
            }
         }
         
         MessageBox(nil, @"Photo uploaded to flickr successfully!");
                  
         //UPDATE THE TOOLBAR
         uploadWaiting.enabled = self.trip.needsUploading;
         
         //UPDATE THE STOP LIST
         [self.tableView reloadData];

         if(backRequested == YES)
         {
            [self performSelector:@selector(goBack) withObject:nil afterDelay:1.0];

            //[self goBack];
         }

         break;
      }
      case DELETE:
         MessageBox(nil, @"Stop deleted from flickr successfully!");
         //UPDATE THE TOOLBAR
         uploadWaiting.enabled = self.trip.needsUploading;
         break;
      default:
         break;
   }   
}

-(void)flickrAPIRequest:(OFFlickrAPIRequest *)request didFailWithError:(NSError *)error
{
   TripJournalSession* session = app.flickrRequest.sessionInfo;

   MessageBox(@"didFailWithError", [error localizedDescription]);
   
   switch(session.requestType)
   {
      case UPLOAD:
         ////////////////////////////////////////
         //REMOVE THE STOP THAT FAILED UPLOAD
         [self.trip.stops removeLastObject];
         
         ///////////////////////////////////////
         //STOP THE LOCATION MANAGER
         app.locationManager.delegate = nil;
         [app.locationManager stopUpdatingLocation];

         [uploadProgressActionSheet dismissWithClickedButtonIndex:0 animated:YES];
         
         //ShowActivity(self, NO);
         break;
      case DELETE:
         break;
      case LOCATION:
         break;
      default:
         NSLog(@"SWITCH SKIPPED");
         break;
   }
}

-(void)flickrAPIRequest:(OFFlickrAPIRequest *)request imageUploadSentBytes:(NSUInteger)sent totalBytes:(NSUInteger)total
{
   
   float fSent = sent;
   float fTotal = total;
   
   [progressView setProgress: (fSent/fTotal)];
   
   if(sent==total)
      uploadProgressActionSheet.title = @"Waiting for flickr...\n\n\n";
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewWillAppear:(BOOL)animated 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [super viewWillAppear:animated];
   
   
   //make sure the stop and trip are still valid
   if(self.trip == nil)
   {
      MessageBox(@"Memory problem!", @"There was a memory problem.  Reopening trips.");
      [self.navigationController popToRootViewControllerAnimated:YES];
      return;
   }
   
   [self.tableView reloadData];
}

-(void)viewDidAppear:(BOOL)animated 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [super viewDidAppear:animated];
}

///////////////////////////////////////////////////////////////////////////////
//getPhotoInfo of the last uploaded image
//query flickr for phtoto info in order to get the flickr photo page 
-(void)getPhotoInfo:(NSDictionary *)response
{
   TripJournalSession* session = app.flickrRequest.sessionInfo;

   session.requestType = IMAGEINFO;
   
   NSString* photoId = [response valueForKeyPath:@"photoid._text"];
      
   [app.flickrRequest 
    callAPIMethodWithGET:@"flickr.photos.getInfo" 
    arguments:[NSDictionary dictionaryWithObjectsAndKeys:photoId,@"photo_id",nil]
   ];  
   
   [response release];
}
///////////////////////////////////////////////////////////////////////////////
//viewDidLoad
//set up the tool bar and create the location manager
- (void)viewDidLoad 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [super viewDidLoad];
   
   //make sure the stop and trip are still valid
   if((self.trip == nil) || (self.trip.name == nil) )
   {
      MessageBox(@"Memory problem!", @"There was a memory problem.  Reopening trips.");
      [self.navigationController popToRootViewControllerAnimated:YES];
      return;
   }

   self.title = @"Stops";

   /////////////////////////////////////////////////////////////////
   //CREATE A LABEL FOR THE MAVIGATION ITEM TITLEVIEW
   UILabel* aLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 30)];
   
   [aLabel setFont:[UIFont fontWithName:@"Helvetica" size:18.0f]];
   [aLabel setText:self.trip.name];
   [aLabel setTextColor:[UIColor whiteColor]];
   
   aLabel.backgroundColor = [UIColor clearColor];
   aLabel.shadowColor = [UIColor blackColor];
   aLabel.shadowOffset = CGSizeMake(1.0, 1.0);
   aLabel.textAlignment = UITextAlignmentCenter;
   
   self.navigationItem.titleView = aLabel;
   [aLabel release];
   /////////////////////////////////////////////////////////////////

   ////////////////////////////////////////////////////////////////////////////
   //SET THE FLICKR REQUEST DELEGATE
   app = (testAppDelegate*)[[UIApplication sharedApplication] delegate];
   app.flickrRequest.delegate = self;
   
   //SET THE LOCATION MANAGER DELEGATE
   //app.locationManager.delegate = self;

   [self setBarButtonItems];

   UIBarButtonItem* spaceItem =    
   [[[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace 
     target:self 
     action:@selector(toolbarHandler:)] autorelease];
   
   spaceItem.width = 20;
   
   UIButton* uploadWaitingButton = 
   [UIButton buttonWithType:UIButtonTypeRoundedRect];
   
   uploadWaitingButton.frame = CGRectMake(20, 20, 40, 30);
   [uploadWaitingButton setBackgroundImage:
    [UIImage imageNamed:@"upload.png"] forState:UIControlStateNormal];
   
   [uploadWaitingButton addTarget:self 
                           action:@selector(doit:) 
                 forControlEvents:UIControlEventTouchUpInside];
   
   uploadWaitingButton.tag = 77;
   
   uploadWaiting =    
   [[UIBarButtonItem alloc]
     initWithCustomView:uploadWaitingButton];
   
   uploadWaiting.enabled = self.trip.needsUploading;
   
   UIBarButtonItem* playTrip =    
   [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(doit:)];
   playTrip.tag = 777;

   [self setToolbarItems:[NSArray arrayWithObjects:playTrip,spaceItem,uploadWaiting,nil]];
   
   [playTrip release];
   [uploadWaiting release];
}

-(void)doit:(id)sender
{
   UIBarButtonItem* button = sender;   
   switch ((int)button.tag) {
      case 7:
      {
         // Solicit text response
         NSString *answer = [ModalAlert ask:@"What is your name?" withTextPrompt:@"Name"];
         
         // Show result based on answer
         if (answer)
            [ModalAlert say:@"Nice to meet you, %@.", answer];
         else
            [ModalAlert say:@"You can stay anonymous"];
         
         // Ask a Yes/No question and respond
         if ([ModalAlert ask:@"Are you feeling well%@?", answer ? [NSString stringWithFormat:@", %@", answer] : @", anonymous person"])
            [ModalAlert say:@"Glad to hear it."];
         else
            [ModalAlert say:@"Sorry to hear it."];
      }
         break;
      case 77:
         //MessageBox(@"upload waiting", @"upload waiting");
         
         for (Stop* aStop in self.trip.stops) 
         {
            if(!aStop.uploaded)
            {
               [self Upload:nil withStop:aStop];
               return;
            }
         }
         break;
      case 777:
         //[ModalAlert say:@"Play Trip!"];
         {
            UIViewController* controller =
            [[UIViewController alloc] init];
            
            controller.title = 
            [NSString stringWithFormat:@"Stops(%d)", [self.trip.stops count]];
            
            CGRect frame = [[UIScreen mainScreen]applicationFrame];
            
            UIScrollView* view =
            [[UIScrollView alloc] initWithFrame:frame];
                        
            frame.origin.y = 0;
            frame.origin.x -= frame.size.width;
            
            for(Stop* stop in self.trip.stops)
            {
               UIImageView* iv;
               
               frame.origin.x += frame.size.width;

               if(stop.image == nil)
               {
                  NSData *imageData = [NSData dataWithContentsOfURL:stop.photoURL];
                  UIImage* image = [UIImage imageWithData:imageData];
                  
                  stop.image = image;
               }

               iv = [[UIImageView alloc]initWithFrame:frame];
               iv.image = stop.image;
               [view addSubview:iv];
               [iv release];
            }
            
            [view setContentSize:CGSizeMake([self.trip.stops count]*frame.size.width, frame.size.height)];
            [view setPagingEnabled:YES];
            
            controller.view = view;
            [view release];
            
            // ...
            // Pass the selected object to the new view controller.
            [self.navigationController pushViewController:controller animated:YES];
            [controller release];
         }
         break;
      default:
         break;
   }
}

- (void) setBarButtonItems
{
   if(self.navigationItem.rightBarButtonItem == nil)
   {
      self.navigationItem.rightBarButtonItem  = SYSBARBUTTON(UIBarButtonSystemItemCamera, @selector(addStop:));  
      self.navigationItem.leftBarButtonItem   = BARBUTTON   (@"Trips", @selector(back:));
   }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//go back to the root view controller
-(void)goBack
{
   [self.navigationController popViewControllerAnimated:YES];   
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//check for un-uploaded stops
-(void)back:(id)sender
{
   if(trip.needsUploading==YES)
   {
      if([ModalAlert ask:@"You have stops that have not been uploaded that will be lost.  Upload now?"])
      {
         Stop* stop=nil;
         for (Stop* aStop in trip.stops) 
         {
            if(!aStop.uploaded)
            {
               stop = aStop;
               break;
            }
         }
         
         self.backRequested = YES;
         [self Upload:nil withStop:stop];
      }
      else
         [self goBack];
   }
   else
      [self goBack];
}
///////////////////////////////////////////////////////////////////////////////
//addStop:
-(void)addStop:(id)sender
{
   TripJournalSession* session = [TripJournalSession sessionWithRequestType:PREUPLOAD];

   //clecn up images
   [self relinquishTripImages];
   
   //////////////////////////////////////////////////////
   //SET THE SESSION IN FLICKR REQUEST
   app.flickrRequest.sessionInfo = session;

   ///////////////////////////////////////////////////////
   //START THE LOCATION MANAGER
   //MUST MAKE SURE THIS DELEGATE IS NIL BEFORE LEAVING
   //THIS VIEW - MAY NEED A CLEANUP METHOD
   app.locationManager.delegate = self;
   [app.locationManager startUpdatingLocation];
   
   //////////////////////////////////////////////////////
   //START WITH NO CURRENT LOCATION SO THAT A PREVIOUS
   //LOCATION DOES NOT LEAK INTO A SUBSEQUENT STOP
   currentLocation.latitude = 0;
   currentLocation.longitude = 0;
   
   UIImagePickerController* picker = [[UIImagePickerController alloc] init];
   
   if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) 
      picker.sourceType = UIImagePickerControllerSourceTypeCamera;
   
   picker.delegate = self;
   picker.allowsEditing = YES;
   
   [self presentModalViewController:picker animated:YES];
   
   [picker release];
}
///////////////////////////////////////////////////////////////////////////////
//Upload:withStop
- (void)Upload:(UIImage *)image withStop:(Stop*)stop
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   TripJournalSession* session = app.flickrRequest.sessionInfo;
   
   session.requestType = UPLOAD;
   
   //the stop we are working with
   session.tag = stop;
   
   //ShowActivity(self, YES);
  
   UIImage* newImage;
   
   if(image == nil)
      newImage = stop.image;
   else
      if([[NSUserDefaults standardUserDefaults]boolForKey:UPLOAD_FULLSIZE_KEY])
      {
         newImage = image;
      }
      else
      {
         newImage = [self resizeImage:image];
      }
   
   ////////////////////////////////////////////////////////////////////////////
   //UPLOAD IMAGE
   NSData *JPEGData = UIImageJPEGRepresentation(newImage, 1.0);
            
   //////////////////////////////////////////////////////////////////////
   //SETTAGS - CREATE IGUESS TAG, VALUE HAS SURROUNDING DOUBLE QUOTES
      
   NSString* tags = 
   [[NSString alloc]initWithFormat:
    @"iSimpleTripJournal:tripid=%d iSimpleTripJournal:tripname=\"%@\" iSimpleTripJournal:tripdetails=\"%@\" iSimpleTripJournal:stop=\"%@\" iSimpleTripJournal:stopdetails=\"%@\" geo:lat=%f geo:lon=%f geotagged" , 
    self.trip.number, 
    self.trip.name, 
    self.trip.details, 
    stop.name, 
    stop.details,
    stop.location.latitude,
    stop.location.longitude
    ];

   //CHECK FOR PUBLIC OR NOT
   NSString* isPublic;
   if([[NSUserDefaults standardUserDefaults]boolForKey:UPLOAD_PUBLIC_KEY])
      isPublic = [[[NSString alloc] initWithString:@"1"]autorelease];
   else
      isPublic = [[[NSString alloc] initWithString:@"0"]autorelease];

   [app.flickrRequest 
    uploadImageStream:[NSInputStream inputStreamWithData:JPEGData] 
    suggestedFilename:@"iSimpleTripJournal" 
    MIMEType:@"image/jpeg" 
    arguments:[NSDictionary dictionaryWithObjectsAndKeys:
      isPublic                       ,@"is_public",
      self.trip.name                 ,@"title",
      stop.name                      ,@"description",
      @"1"                           ,@"safety_level",
      tags                           ,@"tags",
      nil]
    ];
      
   [tags release];
   
   uploadProgressActionSheet = 
   [[[UIActionSheet alloc] 
     initWithTitle:[NSString stringWithFormat:@"Uploading image.\n%@\n\n",stop.name] 
     delegate:self
     cancelButtonTitle:nil 
     destructiveButtonTitle: nil 
     otherButtonTitles: nil] 
    autorelease];
   
   progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0.0f, 50.0f, 220.0f, 90.0f)];
   [progressView setProgressViewStyle: UIProgressViewStyleDefault];
   [uploadProgressActionSheet addSubview:progressView];
   [progressView release];
	
   [progressView setProgress:(0.0f)];
   [uploadProgressActionSheet showFromToolbar:self.navigationController.toolbar];
   
   progressView.center = CGPointMake(uploadProgressActionSheet.center.x, progressView.center.y);	
}   

///////////////////////////////////////////////////////////////////////////////
//UIImagePicker delegate interface
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
   TripJournalSession* session = app.flickrRequest.sessionInfo;

   session.requestType = NONE;
   
   //STOP THE LOCATION MANAGER
   app.locationManager.delegate = nil;
   [app.locationManager stopUpdatingLocation];
   
   [self dismissModalViewControllerAnimated:YES];
}
///////////////////////////////////////////////////////////////////////////////
//imagePickerController:didFInishPickingMediaWithInfo:
#ifndef __IPHONE_3_0
- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
   UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];

#else
- (void)imagePickerController:(UIImagePickerController *)picker 
didFinishPickingImage:(UIImage *)image 
editingInfo:(NSDictionary *)editingInfo
{
#endif
   TripJournalSession* session = app.flickrRequest.sessionInfo;

   [image retain];
   
   session.tag = image;
   
   [self dismissModalViewControllerAnimated:YES];
      
   /////////////////////////////////////////////////////////////////////////
   // we schedule this call in run loop because we want to dismiss the modal view first
   [self performSelector:@selector(getStopInfo:) withObject:image afterDelay:0.5];
   //[self performSelector:@selector(Upload:) withObject:image afterDelay:0.5];
}

- (void)viewWillDisappear:(BOOL)animated 
{   
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [super viewWillDisappear:animated];
}
   
////////////////////////////////////////////////////////////////
//VIEW DID DISAPPEAR
- (void)viewDidDisappear:(BOOL)animated 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}
////////////////////////////////////////////////////////////////
//DELETE A STOP
- (void)
tableView:(UITableView *)aTableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath 
{
   if (editingStyle == UITableViewCellEditingStyleDelete) 
   {
      if([ModalAlert ask:@"Deleting this stop will remove the photo from flickr..."])
      { 
         Stop* stop = [self.trip.stops objectAtIndex:indexPath.row];
         NSString* photoId = [[stop.photoID copy]autorelease];
         
         BOOL uploaded = stop.uploaded;
         
         //DELETE THE ROW FROM THE DATA SOURCE
         [self.trip.stops removeObjectAtIndex:indexPath.row];

         // Delete the row from the data source
         [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
         
         if(uploaded)
         {
            ///////////////////////////////////////////////
            //SEND DELETE REQUEST
            TripJournalSession* session = [TripJournalSession sessionWithRequestType:DELETE];
            app.flickrRequest.sessionInfo = session;
         
            [app.flickrRequest 
             callAPIMethodWithPOST:@"flickr.photos.delete" 
             arguments:[NSDictionary dictionaryWithObjectsAndKeys:photoId,@"photo_id",nil]
             ];
         }
         else
            //UPDATE THE TOOLBAR
            uploadWaiting.enabled = self.trip.needsUploading;
      }
   }   
   else if (editingStyle == UITableViewCellEditingStyleInsert) 
   {
      //NOT DOING THIS
      
      // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
   }   
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
   // Return the number of rows in the section.
   return [self.trip.stops count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
   return 74;
}

#define LABEL_TAKEN 7
#define LABEL_TITLE 77
#define LABEL_DETAILS 777

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
   static NSString *CellIdentifier = @"Cell";
    
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
   if (cell == nil) 
   {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
      
      //add date taken label
      UILabel* takenLabel = 
      [[[UILabel alloc] 
        initWithFrame:CGRectMake(84.0, 54.0, 200.0, 18.0)] autorelease];
      
      takenLabel.tag = LABEL_TAKEN;
      takenLabel.font = [UIFont systemFontOfSize:12.0];
      takenLabel.textAlignment = UITextAlignmentRight;
      takenLabel.textColor = [UIColor darkGrayColor];
      takenLabel.backgroundColor = [UIColor clearColor];
      //takenLabel.autoresizingMask = 
      //UIViewAutoresizingFlexibleLeftMargin |
      //UIViewAutoresizingFlexibleHeight;
      
      [cell.contentView addSubview:takenLabel];
      //////////////////////////////////////////////////////////////////////////
      
      //add title label
      UILabel* mainLabel = 
      [[[UILabel alloc] 
        initWithFrame:CGRectMake(84.0, 5.0, 220.0, 15.0)] autorelease];
      
      mainLabel.tag = LABEL_TITLE;
      mainLabel.font = [UIFont boldSystemFontOfSize:15];
//      mainLabel.font = [UIFont systemFontOfSize:15.0];
      mainLabel.textAlignment = UITextAlignmentLeft;
      mainLabel.textColor = [UIColor blackColor];
      mainLabel.backgroundColor = [UIColor clearColor];
//    mainLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
//    UIViewAutoresizingFlexibleHeight;
      [cell.contentView addSubview:mainLabel];
      //////////////////////////////////////////////////////////////////////////
      
      //add details label
//      UILabel* secondLabel = 
//      [[[UILabel alloc] 
//        initWithFrame:CGRectMake(84.0, 25.0, 195.0, 30.0)] autorelease];
      
      UITextView* secondLabel =
      [[[UITextView alloc] 
        initWithFrame:CGRectMake(84.0, 15.0, 195.0, 36.0)]autorelease];
      
      secondLabel.editable = NO;
      secondLabel.userInteractionEnabled = NO;
      
      secondLabel.tag = LABEL_DETAILS;
      secondLabel.font = [UIFont systemFontOfSize:12.0];
      secondLabel.textAlignment = UITextAlignmentLeft;
      secondLabel.textColor = [UIColor darkGrayColor];
      secondLabel.backgroundColor = [UIColor clearColor];
      
//      secondLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
//      UIViewAutoresizingFlexibleHeight;
      [cell.contentView addSubview:secondLabel];
      //////////////////////////////////////////////////////////////////////////
   }
       
   // Configure the cell...
   Stop* stop = [self.trip.stops objectAtIndex:indexPath.row];

//   cell.textLabel.text = stop.name;
//   
//   if(stop.details != nil)
//      cell.detailTextLabel.text = stop.details; 
//   
//   cell.detailTextLabel.textColor = [UIColor blackColor];

   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
   cell.editingAccessoryType = UITableViewCellAccessoryNone;
   
   UILabel* titleLabel = (UILabel*)   [cell.contentView viewWithTag:LABEL_TITLE];
   titleLabel.text = stop.name;
   
   UILabel* detailsLabel = (UILabel*) [cell.contentView viewWithTag:LABEL_DETAILS];
   detailsLabel.text = stop.details;
   
   UILabel* takenLabel = (UILabel *)  [cell.contentView viewWithTag:LABEL_TAKEN];
   takenLabel.text = stop.taken;
      
   if(stop.thumb == nil)
   {
      dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
      dispatch_async(queue, 
                     ^{
                        UIImage* image;

                        if(stop.photoThumbURL == nil)
                        {
                           image = [UIImage imageNamed:@"needs_uploading.png"];
                        }
                        else
                        {
                           NSData *imageData = [NSData dataWithContentsOfURL:stop.photoThumbURL];
                           image = [UIImage imageWithData:imageData];
                        
                           if(imageData == nil)
                              image = [UIImage imageNamed:@"icon.png"];
                        }
                        
                        stop.thumb = image;
                        
                        dispatch_sync(dispatch_get_main_queue(), 
                                      ^{
                                         cell.imageView.image = stop.thumb;
                                         [cell setNeedsLayout];
                                      });
                     });  
   }
   else
   {
      cell.imageView.image = stop.thumb;
   }

   return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
   // Navigation logic may go here. Create and push another view controller.
   StopViewController* stopViewController = 
   [[[StopViewController alloc] initWithNibName:@"StopViewController" bundle:nil] autorelease];
   
   stopViewController.stop = [self.trip.stops objectAtIndex:indexPath.row];
   
   // ...
   // Pass the selected object to the new view controller.
   [self.navigationController pushViewController:stopViewController animated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning 
{
   // Releases the view if it doesn't have a superview.
   [super didReceiveMemoryWarning];
    
   NSLog(@"%s", __PRETTY_FUNCTION__);

   //[ModalAlert say:@"DetailViewController Memory Warning!"];
   
   // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
   [super viewDidUnload];
   
   // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
   // For example: self.myOutlet = nil;
   
   //[ModalAlert say:@"DetailViewController viewDidUnload!"];

   //for(Stop* stop in trip.stops)
   //{
   //   stop.image = nil;
   //}
   
   NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)dealloc 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);
   
//   NSLog(@"trip retainCount=%d", [self.trip retainCount]);
//   [self.trip release];
//   NSLog(@"trip retainCount=%d", [self.trip retainCount]);
   
   //trip = nil;
   
   [super dealloc];   
}


@end

