//
//  EditViewController.m
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 6/3/12.
//  Copyright (c) 2012 blue sky computing. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "EditViewController.h"
#import "TripJournalSession.h"
#import "RootViewController.h"
#import "MBProgressHUD.h"

#define SYSBARBUTTON(ITEM, SELECTOR) [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:ITEM target:self action:SELECTOR] autorelease]

@interface EditViewController ()

@end

@implementation EditViewController

@synthesize tripComposite;
@synthesize name;
@synthesize theName;
@synthesize theDetails;
@synthesize segmentedControl;

#pragma mark OFFlickrAPIRequestDelegate
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request 
 didCompleteWithResponse:(NSDictionary *)response
{      
   if([self.tripComposite isKindOfClass:[Trip class]])
   {
      [self setPhotoTagsWithTrip:(Trip*)tripComposite];
   }
   else
   {
      [MBProgressHUD hideHUDForView:self.view animated:YES];
   }
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didFailWithError:(NSError *)error
{
   [MBProgressHUD hideHUDForView:self.view animated:YES];

   MessageBox(@"flickr Error", [error localizedDescription]);
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request imageUploadSentBytes:(NSUInteger)sent totalBytes:(NSUInteger)total
{
}

int tripUpdateIndex = -1;
-(void)setPhotoTagsWithTrip:(Trip*)trip
{
   tripUpdateIndex++;
   if(tripUpdateIndex < [trip.stops count])
   {
      Stop* stop = [trip.stops objectAtIndex:tripUpdateIndex];
      [self setPhotoTagsWithStop:stop];
   }
   else
   {
      [MBProgressHUD hideHUDForView:self.view animated:YES];
   }
}

-(void)setPhotoTagsWithStop:(Stop*)stop
{
   ////////////////////////////////////////////////////////////////////////////
   //SET THE FLICKR REQUEST DELEGATE
   testAppDelegate* app = (testAppDelegate*)[[UIApplication sharedApplication] delegate];
   app.flickrRequest.delegate = self;
   
   TripJournalSession* session = 
   [TripJournalSession sessionWithRequestType:SETTAGS];
   
   app.flickrRequest.sessionInfo = session;
   
   NSString* tags = [[stop tags] autorelease]; 
   
   [app.flickrRequest 
    callAPIMethodWithPOST:@"flickr.photos.setTags" 
    arguments:
    [NSDictionary 
     dictionaryWithObjectsAndKeys:
     stop.photoID,@"photo_id",
     tags,@"tags",
     nil]
    ];  
}
///////////////////////////////////////////////////////////////////////////////
//getPhotoInfo of the last uploaded image
//query flickr for phtoto info in order to get the flickr photo page 
-(void)setPhotoTags
{   
   tripUpdateIndex = -1;
   if([self.tripComposite isKindOfClass:[Stop class]])
      [self setPhotoTagsWithStop:(Stop*)tripComposite];
   else
      [self setPhotoTagsWithTrip:(Trip*)tripComposite];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   // Do any additional setup after loading the view from its nib.
   
   name.text = [tripComposite name];
   
   self.theDetails = [tripComposite details];
   self.theName = [tripComposite name];
   
   //////////////////////////////////////////////////////////////////////
   //text box radius
   name.layer.cornerRadius = 10.0;
   
   /////////CREATE THE SEGMENTED BAR
   
   //////////////////////////////////////////////////////////////////////
   //CREATE SEGMENTED NAME/DETAILS CONTROL
	self.segmentedControl = 
   [[UISegmentedControl alloc] initWithItems:
    [NSArray arrayWithObjects:@"Name", @"Details", nil ]];
   
	[self.segmentedControl 
    addTarget:self 
    action:@selector(segmentAction:) 
    forControlEvents:UIControlEventValueChanged];
   
	self.segmentedControl.frame = CGRectMake(0, 0, 90, 30);
	self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	self.segmentedControl.selectedSegmentIndex = 0;
   
	self.navigationItem.titleView = self.segmentedControl;
   [self.segmentedControl release];
   /////////////////////////////////
   
   /////////////////////////////////
   //ADD THE SAVE BUTTON
   self.navigationItem.rightBarButtonItem  = 
   SYSBARBUTTON(UIBarButtonSystemItemSave, @selector(save:));  
   
   [name becomeFirstResponder];
}
/////////////////////////////////////////////////////////////////////////////
//SEGMENT ACTION
//Handle requests to show next/previous stop
- (IBAction)segmentAction:(id)sender
{
   switch (self.segmentedControl.selectedSegmentIndex) 
   {
      case 0: //Name
         self.theDetails = [NSString stringWithString:name.text];
         name.text = self.theName;
         break;
         
      case 1: //Details
         self.theName = [NSString stringWithString:name.text];
         name.text = self.theDetails;
         break;
         
      default:
         break;
   }
}
///////////////////////////////////////////////////////////////////////////////
//save:
-(void)save:(id)sender
{
   [self.name resignFirstResponder];
   
   MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
   hud.labelText = @"Updating flickr tags";   

   //GET THE FIELD THAT IS ON THE SCREEN
   switch (self.segmentedControl.selectedSegmentIndex) 
   {
      case 0: //Name
         self.theName = [NSString stringWithString:name.text];
         break;
         
      case 1: //Details
         self.theDetails = [NSString stringWithString:name.text];
         break;
   }

   [tripComposite setDetails:self.theDetails];
   [tripComposite setName:self.theName];
   
   [self setPhotoTags];
   
   //[self.navigationController popViewControllerAnimated:YES];   
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
