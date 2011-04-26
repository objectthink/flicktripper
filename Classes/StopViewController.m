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

/////////////////////////////////////////////////////////////////////////////////
//UPDATE WITH STOP
//Update the stop view with the passed stop
-(void)UpdateWithStop:(Stop*)aStop
{
   //////////////////////////////////////////////////////////////////////////////
   //IS THE IMAGE AVAILABLE? EVENTUALLY THIS WILL HAPPEN IN ANOTHER THREAD
   //FETCH THE STOP IMAGE - MAY NEED TO STORE THIS FOR THE DETAILS VIEW
   UIImage* image;
   if(aStop.image == nil)
   {
      NSData *imageData = [NSData dataWithContentsOfURL:aStop.photoURL];
      image = [UIImage imageWithData:imageData];
      
      aStop.image = image;
   }
   else
   {
      image = aStop.image;
   }

   //////////////////////////////////////////////////////////////////////////////
   //SETUP PHOTO ON BUTTON
   self.title = aStop.name;
   self.stopDetails.text = aStop.details;
   self.stopName.text = aStop.name;
   
   self.imageButton.imageView.contentMode = UIViewContentModeScaleAspectFit;   
   [self.imageButton setBackgroundImage:aStop.image forState:UIControlStateNormal];
   
   //TELL THE MAPVIEW TO SHOW THE CURRENT LOCATION
   //[mapView setShowsUserLocation:YES];
   
   [mapView addAnnotation:aStop.mapPoint];
   [mapView setCenterCoordinate:aStop.mapPoint.coordinate];
   
   gotoFlickrPageButton.enabled = stop.photoSourceURL != nil;
   
   //UPDATE THE VIEW CONTROLLER TITLE
   [stopNameLabel setText:aStop.name];
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

   MyUIViewController* c = [[[MyUIViewController alloc]init] autorelease];
   
   c.view = [[[UIImageView alloc]initWithImage:stop.image]autorelease];
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
//////////////////////////////////////////////////////////////////////////////
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [super viewDidLoad];
   
   //SET THE APP PROPERTY
   app = (testAppDelegate*)[[UIApplication sharedApplication] delegate];
   
   //if(self.navigationItem.rightBarButtonItem == nil)
   //{
   //   self.navigationItem.rightBarButtonItem = SYSBARBUTTON(UIBarButtonSystemItemAdd, @selector(toolbarHandler:));  
   //   self.navigationItem.rightBarButtonItem.enabled = NO;
   //}
   
   //////////////////////////////////////////////////////////////////////
   //ADD 
	UISegmentedControl *segmentedControl = 
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
   
   aLabel1.backgroundColor = [UIColor clearColor];
   aLabel1.shadowColor = [UIColor whiteColor];
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
   //SETUP PHOTO ON BUTTON
   self.title = stop.name;
   self.stopDetails.text = stop.details;
   self.stopName.text = stop.name;
   
   self.imageButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
   
   [self.imageButton setBackgroundImage:stop.image forState:UIControlStateNormal];
   
   //////////////////////////////////////////////////////////////////////////////
   //SETUP TOOLBAR
   gotoFlickrPageButton =    
   [[[UIBarButtonItem alloc]
    initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
    target:self 
    action:@selector(toolbarHandler:)] autorelease];
   
   gotoFlickrPageButton.enabled = stop.photoSourceURL != nil;
   
   NSArray* items = [NSArray arrayWithObjects:@"Map", @"Satellite", @"Hybrid",nil];
   UISegmentedControl* sc = [[[UISegmentedControl alloc] initWithItems:items] autorelease];
   sc.segmentedControlStyle = UISegmentedControlStyleBar;
   sc.selectedSegmentIndex = 0;
   [sc addTarget:self action:@selector(mapType:) forControlEvents:UIControlEventValueChanged];
   
   gotoFlickrPageButton.tag = 77;
   
   UIBarButtonItem* toolbarItem2 =    
   [[[UIBarButtonItem alloc]
     initWithCustomView:sc]autorelease];
   
   UIBarButtonItem* toolbarItem3 =    
   [[[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
     target:self 
     action:@selector(toolbarHandler:)] autorelease];

   toolbarItem3.tag = 777;
   
   UIBarButtonItem* spaceItem =    
   [[[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace 
     target:self 
     action:@selector(toolbarHandler:)] autorelease];
   
   spaceItem.width = 30;

   [self setToolbarItems:[NSArray arrayWithObjects:gotoFlickrPageButton,spaceItem,toolbarItem2,spaceItem,toolbarItem3,nil]];
   
   //SET THE MAPVIEW AND LOCATIONMANAGER DELEGATES TO SELF
   mapView.delegate = self;
   mapView.layer.cornerRadius = 10.0;
   //app.locationManager.delegate = self;
   
   imageButton.layer.cornerRadius = 10.0;
   
   stopDetails.layer.cornerRadius = 10.0;
   stopDetails.backgroundColor = [UIColor lightGrayColor];
   
   stopName.layer.cornerRadius = 10.0;
   stopName.backgroundColor = [UIColor lightGrayColor];
   
   //TELL THE MAPVIEW TO SHOW THE CURRENT LOCATION
   //[mapView setShowsUserLocation:YES];
   
   [mapView addAnnotation:stop.mapPoint];
   
   showingAll = NO;
}
/////////////////////////////////////////////////////////////////////////////
//SEGMENT ACTION
//Handle requests to show next/previous stop
- (IBAction)segmentAction:(id)sender
{
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
   Trip* currentTrip = self.stop.trip;
   
   NSUInteger currentStopIndex = [currentTrip.stops indexOfObject:stop];
   NSInteger  nextStopIndex = 0;
   
	NSLog(@"Segment clicked: %d, %d", 
         segmentedControl.selectedSegmentIndex, currentStopIndex);

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
