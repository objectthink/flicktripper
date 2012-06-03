//
//  EditViewController.m
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 6/3/12.
//  Copyright (c) 2012 blue sky computing. All rights reserved.
//

#import "EditViewController.h"

#define SYSBARBUTTON(ITEM, SELECTOR) [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:ITEM target:self action:SELECTOR] autorelease]

@interface EditViewController ()

@end

@implementation EditViewController

@synthesize tripComposite;
@synthesize name;

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
   
   /////////CREATE THE SEGMENTED BAR
   
   //////////////////////////////////////////////////////////////////////
   //CREATE SEGMENTED NAME/DETAILS CONTROL
	UISegmentedControl* segmentedControl = 
   [[UISegmentedControl alloc] initWithItems:
    [NSArray arrayWithObjects:@"Name", @"Details", nil ]];
   
	[segmentedControl 
    addTarget:self 
    action:@selector(segmentAction:) 
    forControlEvents:UIControlEventValueChanged];
   
	segmentedControl.frame = CGRectMake(0, 0, 90, 30);
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	  
	self.navigationItem.titleView = segmentedControl;
   [segmentedControl release];
   /////////////////////////////////
   
   /////////////////////////////////
   //ADD THE SAVE BUTTON
   self.navigationItem.rightBarButtonItem  = 
   SYSBARBUTTON(UIBarButtonSystemItemSave, @selector(save:));  
}
/////////////////////////////////////////////////////////////////////////////
//SEGMENT ACTION
//Handle requests to show next/previous stop
- (IBAction)segmentAction:(id)sender
{
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
   switch (segmentedControl.selectedSegmentIndex) 
   {
      case 0: //Name
         name.text = tripComposite.name;
         break;
         
      case 1: //Details
         name.text = tripComposite.details;
         break;
         
      default:
         break;
   }
}
///////////////////////////////////////////////////////////////////////////////
//save:
-(void)save:(id)sender
{
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
