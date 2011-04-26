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

#define BARBUTTON(TITLE, SELECTOR) 	[[[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR] autorelease]
#define SYSBARBUTTON(ITEM, SELECTOR) [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:ITEM target:self action:SELECTOR] autorelease]
#define MAINLABEL	((UILabel *)self.navigationItem.titleView)

@implementation DetailViewController

@synthesize trip;
@synthesize app;
@synthesize tag;
@synthesize isUploadingWaiting;

#pragma mark -
#pragma mark CLLocationManager
///////////////////////////////////////////////////////////////////////
//locationManager:didUpdateToLocation:fromLocation
//store the current location to be used in the new stop
-(void)locationManager:(CLLocationManager *)manager 
   didUpdateToLocation:(CLLocation *)newLocation 
          fromLocation:(CLLocation *)oldLocation
{
   NSLog(@"%@",newLocation);
   
   //HOW OLD IS THIS READING?
   NSTimeInterval t =
   [[newLocation timestamp]timeIntervalSinceNow];
   
   if(t < -180) return;
   
   currentLocation = [newLocation coordinate];
}
////////////////////////////////////////////////////////////////////////
//locationManager:didFailWithError
//there was an error getting the current location
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
   [ModalAlert say:[error localizedDescription]];
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
      
      //ADD THESE PROPERTIES BY HAND FOR NOW
      stop.image = [self resizeImage:image];
      stop.location = currentLocation;
      stop.mapPoint = [[MapPoint alloc] initWithCoordinate:stop.location title:stop.name];
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
         uploadWaiting.enabled = trip.needsUploading;
      }
   }
}

-(void)flickrAPIRequest:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
   NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, request.sessionInfo, response);   
   
   TripJournalSession* session = app.flickrRequest.sessionInfo;
   
   switch (session.requestType) 
   {
      case UPLOAD:
         [self.tableView reloadData];
         
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
         ShowActivity(self, NO);

         TripJournalSession* session = app.flickrRequest.sessionInfo;

         Stop* aStop =  (Stop*)session.tag;

         NSArray* urls = [response valueForKeyPath:@"photo.urls.url"];
         
         aStop.photoSourceURL = [NSURL URLWithString:[[urls objectAtIndex:0]objectForKey:@"_text"]];
         aStop.photoID               = [response valueForKeyPath:@"photo.id"];
                  
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
         break;
      }
      case LOCATION:
      {
         Stop* aStop =  (Stop*)session.tag;

         aStop.uploaded = YES;
         
         //CHECK FOR MORE DELAYED UPLOADS
         for (Stop* aStop in trip.stops) 
         {
            if(!aStop.uploaded)
            {
               [self Upload:nil withStop:aStop];
               return;
            }
         }         
         MessageBox(nil, @"Photo uploaded to flickr successfully!");

         //UPDATE THE TOOLBAR
         uploadWaiting.enabled = trip.needsUploading;

         break;
      }
      case DELETE:
         MessageBox(nil, @"Stop deleted from flickr successfully!");
         break;
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
         [trip.stops removeLastObject];
         
         ///////////////////////////////////////
         //STOP THE LOCATION MANAGER
         app.locationManager.delegate = nil;
         [app.locationManager stopUpdatingLocation];

         [uploadProgressActionSheet dismissWithClickedButtonIndex:0 animated:YES];
         
         ShowActivity(self, NO);
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

//- (void)navigationController:(UINavigationController *)navigationController 
//   willShowViewController:(UIViewController *)viewController 
//   animated:(BOOL)animated
//{
//}
//- (void)navigationController:(UINavigationController *)navigationController 
//   didShowViewController:(UIViewController *)viewController 
//   animated:(BOOL)animated
//{   
//}

#pragma mark -
#pragma mark View lifecycle

//- (void)viewWillAppear:(BOOL)animated 
//{
//   [super viewWillAppear:animated];
//}

//-(void)viewDidAppear:(BOOL)animated 
//{
//   [super viewDidAppear:animated];
//}

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
   
   self.title = @"Stops";

   /////////////////////////////////////////////////////////////////
   //CREATE A LABEL FOR THE MAVIGATION ITEM TITLEVIEW
   UILabel* aLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 30)];
   
   [aLabel setFont:[UIFont fontWithName:@"Helvetica" size:18.0f]];
   [aLabel setText:trip.name];
   
   aLabel.backgroundColor = [UIColor clearColor];
   aLabel.shadowColor = [UIColor whiteColor];
   aLabel.shadowOffset = CGSizeMake(1.0, 1.0);
   aLabel.textAlignment = UITextAlignmentCenter;
   
   self.navigationItem.titleView = aLabel;
   /////////////////////////////////////////////////////////////////

   ////////////////////////////////////////////////////////////////////////////
   //SET THE FLICKR REQUEST DELEGATE
   app = (testAppDelegate*)[[UIApplication sharedApplication] delegate];
   app.flickrRequest.delegate = self;
   
   //SET THE LOCATION MANAGER DELEGATE
   //app.locationManager.delegate = self;

   [self setBarButtonItems];

   //UIBarButtonItem* test = 
   //[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(doit:)];
   //test.tag = 7;
   
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
   
   //[uploadWaitingButton addTarget:self action:@selector(doit:) forControlEvents:UIControlEventTouchUpInside];
   //uploadWaitingButton.tag = 7;

   //uploadWaiting =    
   //[[UIBarButtonItem alloc]
   // initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
   //   target:self 
   //   action:@selector(doit:)];
   
   [uploadWaitingButton addTarget:self 
                           action:@selector(doit:) 
                 forControlEvents:UIControlEventTouchUpInside];
   
   uploadWaitingButton.tag = 77;
   
   uploadWaiting =    
   [[UIBarButtonItem alloc]
     initWithCustomView:uploadWaitingButton];
   
   uploadWaiting.enabled = trip.needsUploading;
   
   //uploadWaiting.tag = 77;
   
   
   UIBarButtonItem* playTrip =    
   [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(doit:)];
   playTrip.tag = 777;

   [self setToolbarItems:[NSArray arrayWithObjects:playTrip,spaceItem,uploadWaiting,nil]];
   
   //[test release];
   [playTrip release];
   [uploadWaiting release];
   
   // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
         
         for (Stop* aStop in trip.stops) 
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
               [stop.image release];
            }
            
            [view setContentSize:CGSizeMake([self.trip.stops count]*frame.size.width, frame.size.height)];
            [view setPagingEnabled:YES];
            
            controller.view = view;
            
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
      self.navigationItem.rightBarButtonItem = SYSBARBUTTON(UIBarButtonSystemItemCamera, @selector(addStop:));         
   }
}
///////////////////////////////////////////////////////////////////////////////
//addStop:
-(void)addStop:(id)sender
{
   TripJournalSession* session = [TripJournalSession sessionWithRequestType:PREUPLOAD];
      
   ///////////////////////////////////////////////////////
   //START THE LOCATION MANAGER
   //MUST MAKE SURE THIS DELEGATE IS NIL BEFORE LEAVING
   //THIS VIEW - MAY NEED A CLEANUP METHOD
   app.locationManager.delegate = self;
   [app.locationManager startUpdatingLocation];

   app.flickrRequest.sessionInfo = session;
   
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
   TripJournalSession* session = app.flickrRequest.sessionInfo;
   
   session.requestType = UPLOAD;
   
   //the stop we are working with
   session.tag = stop;
   
   ShowActivity(self, YES);
  
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
   
   ///////////////////////////////////////////////////////////////
   //NEED TO FIND THE RIGHT PLACE TO CREATE THE NEW STOP AND
   //ADD IT TO THE TRIP
   //Stop* stop = [Stop initWithName:@"new stop" details:@"new stop details"];
   //stop.image = image;
   //[self.trip.stops addObject:stop];
   
   //[UIApplication sharedApplication].idleTimerDisabled = YES;
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

//   TripJournalSession* session = app.flickrRequest.sessionInfo;
//
//   if(session != nil)
//   {
//      if(session.requestType != PREUPLOAD)
//      {         
//         if([ModalAlert confirm:@"You have stops that have not been uploaded that will be lost.  Upload now?"])
//         {
//            for (Stop* aStop in trip.stops) 
//            {
//               if(!aStop.uploaded)
//               {
//                  [self Upload:nil withStop:aStop];
//                  return;
//               }
//            }      
//         }
//      }
//   }
}
   
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


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
         Stop* stop = [trip.stops objectAtIndex:indexPath.row];
         NSString* photoId = [[stop.photoID copy]autorelease];
         
         BOOL uploaded = stop.uploaded;
         
         //DELETE THE ROW FROM THE DATA SOURCE
         [trip.stops removeObjectAtIndex:indexPath.row];

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
      }
   }   
   else if (editingStyle == UITableViewCellEditingStyleInsert) 
   {
      //NOT DOING THIS
      
      // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
   }   
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
   return [trip.stops count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
   Stop* stop = [trip.stops objectAtIndex:indexPath.row];

   cell.textLabel.text = stop.name;
   
   if(stop.details != nil)
   cell.detailTextLabel.text = stop.details; 
   
   cell.detailTextLabel.textColor = [UIColor blackColor];
   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
   cell.editingAccessoryType = UITableViewCellAccessoryNone;
   
   //FETCH THE STOP IMAGE - MAY NEED TO STORE THIS FOR THE DETAILS VIEW
   UIImage* image;
   if(stop.image == nil)
   {
      NSData *imageData = [NSData dataWithContentsOfURL:stop.photoURL];
      image = [UIImage imageWithData:imageData];
      
      stop.image = image;
   }
   else
   {
      image = stop.image;
   }
   
   //STOP IMAGE
   cell.imageView.image = image;
   
   return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

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
   // Navigation logic may go here. Create and push another view controller.
   StopViewController* stopViewController = 
   [[[StopViewController alloc] initWithNibName:@"StopViewController" bundle:nil] autorelease];
   
   stopViewController.stop = [trip.stops objectAtIndex:indexPath.row];
   
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
   //[trip release];
   trip = nil;
   
   [super dealloc];   
}


@end

