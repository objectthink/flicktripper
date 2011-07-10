//
//  StopViewController.m
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 7/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "StopViewController.h"
#import "RootViewController.h"
#import "UIImageInfoViewController.h"
#import "ModalAlert.h"
#import "MBProgressHUD.h"

#define SYSBARBUTTON(ITEM, SELECTOR) [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:ITEM target:self action:SELECTOR] autorelease]

///////////////////////////////////////////////////////////////////////////////
//MyUIViewController - implementation
@implementation MyUIViewController
///////////////////////////////////////////////////////////////////////////////
//The viw was touched - test only
-(void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event 
{
   [self dismissModalViewControllerAnimated:YES];
}
@end

@implementation StopViewController
@synthesize stop;
@synthesize imageButton;
@synthesize stopDetails;
@synthesize stopName;
@synthesize app;
@synthesize stopNameLabel;
@synthesize segmentedControl;

#pragma mark -
#pragma mark OFFlickrAPIRequestDelegate
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response
{
   NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, request.sessionInfo, response);   
   
   TripJournalSession* session = app.flickrRequest.sessionInfo;
   
   switch (session.requestType) 
   {
      case UPLOAD:
         break;
      case IMAGEINFO:
         break;
      case LOCATION:
         break;
      case DELETE:
         MessageBox(nil, @"Stop deleted from flickr successfully!");
         break;
      default:
         break;
   }   
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didFailWithError:(NSError *)error
{
   MessageBox(@"didFailWithError", [error localizedDescription]);
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request imageUploadSentBytes:(NSUInteger)sent totalBytes:(NSUInteger)total
{
   
}

/////////////////////////////////////////////////////////////////////////////////
//UPDATE WITH STOP
//Update the stop view with the passed stop
-(void)UpdateWithStop:(Stop*)aStop
{
   //////////////////////////////////////////////////////////////////////////////
   //IS THE IMAGE AVAILABLE? EVENTUALLY THIS WILL HAPPEN IN ANOTHER THREAD
   //FETCH THE STOP IMAGE - MAY NEED TO STORE THIS FOR THE DETAILS VIEW
   if(aStop.thumb == nil)
   {
      //CONSIDER DOING THIS IN ANOTHER THREAD
      //UIImage* image;
      
      //NSData *imageData = [NSData dataWithContentsOfURL:aStop.photoURL];
      //image = [UIImage imageWithData:imageData];
      
      dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
      dispatch_async(queue, 
      ^{
         UIImage* image;
         NSData *imageData = [NSData dataWithContentsOfURL:stop.photoThumbURL];
         image = [UIImage imageWithData:imageData];
                        
         if(imageData == nil)
            image = [UIImage imageNamed:@"icon.png"];
                        
            aStop.thumb = image;
                        
            dispatch_sync(dispatch_get_main_queue(), 
               ^{
                  [self.imageButton setBackgroundImage:aStop.thumb forState:UIControlStateNormal];
               });
            });  

      
      //aStop.image = image;
   }
   else
      [self.imageButton setBackgroundImage:aStop.thumb forState:UIControlStateNormal];
   
   //////////////////////////////////////////////////////////////////////////////
   //SETUP PHOTO ON BUTTON
   self.title = aStop.name;
   self.stopDetails.text = aStop.details;
   self.stopName.text = aStop.name;
   
   self.imageButton.imageView.contentMode = UIViewContentModeScaleAspectFit;   
   
   //[self.imageButton setBackgroundImage:aStop.image forState:UIControlStateNormal];
   
   //TELL THE MAPVIEW TO SHOW THE CURRENT LOCATION
   //[mapView setShowsUserLocation:YES];
   
   [mapView addAnnotation:aStop.mapPoint];
   [mapView setCenterCoordinate:aStop.mapPoint.coordinate];
   
   gotoFlickrPageButton.enabled = stop.photoSourceURL != nil;
   
   //UPDATE THE VIEW CONTROLLER TITLE
   [stopNameLabel setText:aStop.name];
   
   ///////////////////////////////////////////////////////////////////////////
   //DISABLE THE SEGMENT CONTROLS AS APPROPRIATE
   //NSInteger currentStopIndex = [stop.trip.stops indexOfObject:aStop];
   NSInteger currentStopIndex = [aStop index];
   [self.segmentedControl setEnabled:(currentStopIndex > 0) forSegmentAtIndex:0];
   [self.segmentedControl setEnabled:(currentStopIndex < [stop.trip.stops count] -1) forSegmentAtIndex:1];   
}

#pragma mark -
#pragma mark MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)senderMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   return nil;
}

- (void)mapView:(MKMapView *)senderMapView didAddAnnotationViews:(NSArray *)views
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   /////////////////////////////////////////////////////
   //SET THE REGION BASED ON THE FIRST VIEW - THIS SHOULD PROBABLY
   //BE CHANGED TO THE VIEW FOR THIS STOP OR THE VIEW IN THE MIDDLE
   //OF THE LIST OF VIEWS
   //MKAnnotationView* av = [views objectAtIndex:0];
   //id<MKAnnotation>  mp = [av annotation];
   
   MKCoordinateRegion region = 
   MKCoordinateRegionMakeWithDistance([stop.mapPoint coordinate], 250, 250);
   
   [senderMapView setRegion:region animated:YES];
   
   /////////////////////////////////////////////////////
   //FIND THE VIEW FOR THIS STOP AND MAKE IT PURPLE
   for(MKPinAnnotationView* av in views)
   {
      id<MKAnnotation> mp = [av annotation];
      
      if(mp == stop.mapPoint)
         av.pinColor = MKPinAnnotationColorPurple;
      else
         av.pinColor = MKPinAnnotationColorRed;
      
      ////////////////////////////////////////////////////
      //SIZE IMAGE FOR ANNOTATION
      UIImage* stopImage = [stop.trip findStopWithMapPoint:mp].image;
      
      UIGraphicsBeginImageContext(CGSizeMake(32, 32));
      [stopImage drawInRect:CGRectMake(0.0f, 0.0f, 32, 32)];
      UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
		
      av.leftCalloutAccessoryView = [[[UIImageView alloc] initWithImage:img] autorelease];      
   }
}

#pragma mark -
#pragma mark CLLocationManager
-(void)locationManager:(CLLocationManager *)manager 
   didUpdateToLocation:(CLLocation *)newLocation 
          fromLocation:(CLLocation *)oldLocation
{
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{   
}

#pragma mark -
#pragma mark StopViewController

-(IBAction) imageTouched
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   //MyUIViewController* c = [[[MyUIViewController alloc]init] autorelease];
   
   //do we have the image?
   //////////////////////////////////////////////////////////////////////////////
   //IS THE IMAGE AVAILABLE? EVENTUALLY THIS WILL HAPPEN IN ANOTHER THREAD
   //FETCH THE STOP IMAGE - MAY NEED TO STORE THIS FOR THE DETAILS VIEW
//   if(stop.image == nil)
//   {
//      dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
//      dispatch_async(queue, 
//                     ^{
//                        UIImage* image;
//                        NSData *imageData = [NSData dataWithContentsOfURL:stop.photoURL];
//                        image = [UIImage imageWithData:imageData];
//                        
//                        if(imageData == nil)
//                           image = [UIImage imageNamed:@"icon.png"];
//                        
//                        stop.image = image;
//                        
//                        dispatch_sync(dispatch_get_main_queue(), 
//                                      ^{
//                                         //c.view = [[[UIImageView alloc]initWithImage:stop.image]autorelease];                                         
//                                      });
//                     });  
//   }
   //else
      //c.view = [[[UIImageView alloc]initWithImage:stop.image]autorelease];

   MyUIViewController* c = [[[MyUIViewController alloc]init] autorelease];

   c.view = [[[UIImageView alloc]initWithImage:stop.image]autorelease];

   if(stop.image == nil)
   {
      //ShowActivity(self, YES);
//      UIImage* image;
//      NSData *imageData = [NSData dataWithContentsOfURL:stop.photoURL];
//      image = [UIImage imageWithData:imageData];
//
//      stop.image = image;
      //ShowActivity(self, NO);
      
      // No need to retain (just a local variable)
      //MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
      MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:c.view animated:YES];
      hud.labelText = @"Loading";
      
      dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), 
                     ^{
                        // Do a taks in the background
                        UIImage* image;
                        NSData *imageData = [NSData dataWithContentsOfURL:stop.photoURL];
                        image = [UIImage imageWithData:imageData];
                        
                        stop.image = image;
                        // Hide the HUD in the main tread 
                        dispatch_async(dispatch_get_main_queue(), 
                                       ^{
                                          UIImageView* iv = (UIImageView*)c.view;
                                          
                                          iv.image = image;
                                          
                                          [MBProgressHUD hideHUDForView:c.view animated:YES];
                                       });
                     });

   }
   
   //MyUIViewController* c = [[[MyUIViewController alloc]init] autorelease];
   
   //c.view = [[[UIImageView alloc]initWithImage:stop.image]autorelease];
   c.view.userInteractionEnabled = YES;
   c.view.contentMode = UIViewContentModeScaleAspectFit;
   c.view.backgroundColor = [UIColor blackColor];
   
   c.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
      
   [self presentModalViewController:c animated:YES];  
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

-(void)mapType:(UISegmentedControl*)sender
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   switch(sender.selectedSegmentIndex)
   {
      case 0:
         mapView.mapType = MKMapTypeStandard;
         break;
      case 1:
         mapView.mapType = MKMapTypeSatellite;
         break;
      case 2:
         mapView.mapType = MKMapTypeHybrid;
         break;
   }
}

-(void)viewDidLoadX
{
   NSLog(@"%s", __PRETTY_FUNCTION__);
   
   [super viewDidLoad];
   
   [self.navigationController popToRootViewControllerAnimated:YES];
}

//////////////////////////////////////////////////////////////////////////////
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
   NSLog(@"%s", __PRETTY_FUNCTION__);
   
   [super viewDidLoad];
   
   //make sure the stop and trip are still valid
   if((self.stop == nil) || (self.stop.trip == nil) )
   {
      MessageBox(@"Memory problem!", @"There was a memory problem.  Reopening trips.");
      [self.navigationController popToRootViewControllerAnimated:YES];
      return;
   }

   /////////////////////////////////////////////////////////////////////
   //SET THE APP PROPERTY
   app = (testAppDelegate*)[[UIApplication sharedApplication] delegate];
   
   //if(self.navigationItem.rightBarButtonItem == nil)
   //{
   //   self.navigationItem.rightBarButtonItem = SYSBARBUTTON(UIBarButtonSystemItemAdd, @selector(toolbarHandler:));  
   //   self.navigationItem.rightBarButtonItem.enabled = NO;
   //}
   
   //////////////////////////////////////////////////////////////////////
   //CREATE SEGMENTED UP DOWN CONTROL 
	segmentedControl = 
   [[UISegmentedControl alloc] initWithItems:
    [NSArray arrayWithObjects:
     [UIImage imageNamed:@"up.png"],
     [UIImage imageNamed:@"down.png"],
     nil]];
   
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
   
	segmentedControl.frame = CGRectMake(0, 0, 90, 30);
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	
	//defaultTintColor = [segmentedControl.tintColor retain];	// keep track of this for later
   
	UIBarButtonItem *segmentBarItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
   [segmentedControl release];
   
	self.navigationItem.rightBarButtonItem = segmentBarItem;
   [segmentBarItem release];
   /////////////////////////////////////////////////////////////////
   
   /////////////////////////////////////////////////////////////////
   //CREATE A MULTI-LINE LABEL FOR THE MAVIGATION ITEM TITLEVIEW
   Trip* trip = self.stop.trip;
   
   UILabel* aLabel1 = [[[UILabel alloc] initWithFrame:CGRectMake(0, 20, 150, 20)] autorelease];
   
   [aLabel1 setFont:[UIFont fontWithName:@"Helvetica" size:18.0f]];
   [aLabel1 setText:stop.name];
   [aLabel1 setTextColor:[UIColor whiteColor]];
   
   aLabel1.backgroundColor = [UIColor clearColor];
   aLabel1.shadowColor = [UIColor blackColor];
   aLabel1.shadowOffset = CGSizeMake(1.0, 1.0);
   aLabel1.textAlignment = UITextAlignmentCenter;
   
   self.stopNameLabel = aLabel1;
   
   UILabel* aLabel2 = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 20)] autorelease];
   
   [aLabel2 setFont:[UIFont fontWithName:@"Helvetica" size:14.0f]];
   [aLabel2 setText:trip.name];
   
   aLabel2.backgroundColor = [UIColor clearColor];
   aLabel2.shadowColor = [UIColor whiteColor];
   aLabel2.shadowOffset = CGSizeMake(1.0, 1.0);
   aLabel2.textAlignment = UITextAlignmentCenter;
   
   UIView* myTitleView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 150, 40)];
   [myTitleView addSubview:aLabel1];
   [myTitleView addSubview:aLabel2];
   
   self.navigationItem.titleView = myTitleView;
   /////////////////////////////////////////////////////////////////
   
   //////////////////////////////////////////////////////////////////////////////
   //SETUP TOOLBAR
   gotoFlickrPageButton =    
   [[[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
    target:self 
    action:@selector(toolbarHandler:)] autorelease];
   
   gotoFlickrPageButton.enabled = stop.photoSourceURL != nil;
   gotoFlickrPageButton.tag = 77;

   NSArray* items = [NSArray arrayWithObjects:@"Map", @"Satellite", @"Hybrid",nil];
   UISegmentedControl* sc = [[[UISegmentedControl alloc] initWithItems:items] autorelease];
   sc.segmentedControlStyle = UISegmentedControlStyleBar;
   sc.selectedSegmentIndex = 0;
   [sc addTarget:self action:@selector(mapType:) forControlEvents:UIControlEventValueChanged];
      
   UIBarButtonItem* mapToolbarItem =    
   [[[UIBarButtonItem alloc]
     initWithCustomView:sc]autorelease];
   
   UIBarButtonItem* allToolbarItem =    
   [[[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
     target:self 
     action:@selector(toolbarHandler:)] autorelease];

   allToolbarItem.tag = 778;
   
   UIBarButtonItem* spaceItem =    
   [[[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace 
     target:self 
     action:@selector(toolbarHandler:)] autorelease];
   
   spaceItem.width = 30;

   [self setToolbarItems:[NSArray arrayWithObjects:gotoFlickrPageButton,spaceItem,mapToolbarItem,spaceItem, allToolbarItem, nil]];
   
   //SET THE MAPVIEW AND LOCATIONMANAGER DELEGATES TO SELF
   mapView.delegate = self;
   mapView.layer.cornerRadius = 10.0;
   
   imageButton.layer.cornerRadius = 10.0;
   
   stopDetails.layer.cornerRadius = 10.0;
   stopDetails.backgroundColor = [UIColor lightGrayColor];
   
   stopName.layer.cornerRadius = 10.0;
   stopName.backgroundColor = [UIColor lightGrayColor];
   
   showingAll = NO;
   
   [self UpdateWithStop:stop];
}
/////////////////////////////////////////////////////////////////////////////
//SEGMENT ACTION
//Handle requests to show next/previous stop
- (IBAction)segmentAction:(id)sender
{
	UISegmentedControl *segmentedControlSender = (UISegmentedControl *)sender;
   Trip* currentTrip = self.stop.trip;
   
   NSUInteger currentStopIndex = [currentTrip.stops indexOfObject:self.stop];
   NSInteger  nextStopIndex = 0;
   
	NSLog(@"Segment clicked: %d, %d", 
         segmentedControlSender.selectedSegmentIndex, currentStopIndex);

   
   //////////////////////////////////////////////////////////////////////////
   //REMOVE THE CURRENT STOP PIN FROM THE MAP
   [mapView removeAnnotation:self.stop.mapPoint];

   switch (segmentedControl.selectedSegmentIndex) 
   {
      case 0:            //PREVIOUS
         nextStopIndex = currentStopIndex - 1;
         
         if(nextStopIndex > -1)
         {
            self.stop = [currentTrip.stops objectAtIndex:nextStopIndex];
            [self UpdateWithStop:self.stop];
         }
         break;
         
      case 1:            //NEXT
         nextStopIndex = currentStopIndex + 1;
         
         if(nextStopIndex < [currentTrip.stops count])
         {
            self.stop = [currentTrip.stops objectAtIndex:nextStopIndex];
            [self UpdateWithStop:self.stop];
         }
         break;

      default:
         break;
   }
}
//////////////////////////////////////////////////////////////////////////////
//TOOLBAR HANDLER
-(void)toolbarHandler:(id)sender
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   UIBarButtonItem* button = sender;   
   switch ((int)button.tag) 
   {
      case 778:
         if([ModalAlert ask:@"Deleting this stop will remove the photo from flickr..."])
         { 
            NSString* photoId = [[stop.photoID copy]autorelease];
            Trip* currentTrip = self.stop.trip;
            
            //WERE ABOUT TO DELETE THE CURRENT STOP
            //SET STOP TO ANOTHER INDEX AND UPDATE VIEW
            NSUInteger currentStopIndex = [currentTrip.stops indexOfObject:stop];
            
            
            //REMOVE STOP FROM TRIP LIST OF STOPS
            [self.stop.trip removeStop:self.stop];
            
            if(currentStopIndex == [stop.trip.stops count])
               currentStopIndex -= 1;
                              
            self.stop = [stop.trip.stops objectAtIndex:currentStopIndex];

            [self UpdateWithStop:self.stop];
            ////////////////////////////////////////
            
            BOOL uploaded = stop.uploaded;
               
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
         break;
      case 77:
         //SHOW THE FLICKR PAGE
         [self OnShowInfo];
         break;
      case 777:
      {
         if(showingAll)
         {
            showingAll = NO;
            
            NSMutableArray* points = [[NSMutableArray alloc]init];
            
            NSLog(@"stop retainCount %d", [stop retainCount]);

            for(Stop* aStop in stop.trip.stops)
            {
               [points addObject:aStop.mapPoint];
            }
            
            [mapView removeAnnotations:points];
            
            [mapView addAnnotation:stop.mapPoint];
            
            NSLog(@"stop retainCount %d", [stop retainCount]);
                  
            [points release];
            
            NSLog(@"stop retainCount %d", [stop retainCount]);
         }
         else
         {
            showingAll = YES;
            
            NSLog(@"stop retainCount %d", [stop retainCount]);
            [mapView removeAnnotation:stop.mapPoint];
         
            NSMutableArray* points = [[NSMutableArray alloc]init];
            
            for(Stop* aStop in stop.trip.stops)
            {
               [points addObject:aStop.mapPoint];
            }
         
            NSLog(@"stop retainCount %d", [stop retainCount]);

            [mapView addAnnotations:points];
            
            NSLog(@"stop retainCount %d", [stop retainCount]);
            
            [points release];
            
            NSLog(@"stop retainCount %d", [stop retainCount]);
         }
         break;
      }
      default:
         break;
   }
}
///////////////////////////////////////////////////////////////////////////////
//OnShowInfo
//Called when the info button on the image view is tapped
//Show the Flickr web page that the chosen image is on
-(void)OnShowInfo
{
   UIImageInfoViewController* cc = 
   [[[UIImageInfoViewController alloc]initWithNibName:@"ImageInfoController" bundle:nil] autorelease];
   
   cc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
   
   NSURLRequest* ur = [NSURLRequest requestWithURL:stop.photoSourceURL];
   
   cc.theUrlRequest = ur;
   
   [self presentModalViewController:cc animated:YES]; 
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   // Releases the view if it doesn't have a superview.
   [super didReceiveMemoryWarning];
       
   //[ModalAlert say:@"Memory Warning!"];

   // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [super viewDidUnload];
   
   // Release any retained subviews of the main view.
   // e.g. self.myOutlet = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
   NSLog(@"%s", __PRETTY_FUNCTION__);
   [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated
{
   NSLog(@"%s", __PRETTY_FUNCTION__);
   [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
   NSLog(@"%s", __PRETTY_FUNCTION__);
   [super viewWillDisappear:animated];
}

- (void)dealloc 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   mapView.delegate = nil;
   [mapView release];
   
   //[imageButton release];
   //[stopDetails release];
   //[stopName release];
   
   [stop release];
   
   [super dealloc];
}
@end
