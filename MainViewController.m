//
//  MainViewController.m
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "RootViewController.h"
#import "UserInfoController.h"
#import "ModalAlert.h"

@implementation MainViewController

-(IBAction)MyTrips:(id)sender
{
   NSLog(@"MyTrips clicked");
   
   RootViewController*
   rootViewController = 
   [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:nil];
   
   [self.navigationController pushViewController:rootViewController animated:YES];
   [rootViewController release];
}
-(IBAction)OtherTrips:(id)sender
{
   [ModalAlert say:@"Coming Soon!"];
}
-(IBAction)UploadWaiting:(id)sender
{
   [ModalAlert say:@"Coming Soon!"];
}

 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad 
{
   [super viewDidLoad];
   
   /////////////////////////////////////////////////////////////////
   //CREATE A LABEL FOR THE MAVIGATION ITEM TITLEVIEW
   UILabel* aLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 30)];
   
   [aLabel setFont:[UIFont fontWithName:@"Helvetica" size:24.0f]];
   [aLabel setText:@"flicktripper"];
   [aLabel setTextColor:[UIColor whiteColor]];
   
   aLabel.backgroundColor = [UIColor clearColor];
   aLabel.shadowColor = [UIColor blackColor];
   aLabel.shadowOffset = CGSizeMake(1.0, 1.0);
   aLabel.textAlignment = UITextAlignmentCenter;
   
   self.navigationItem.titleView = aLabel;
   [aLabel release];
   /////////////////////////////////////////////////////////////////

   self.title = @"Main";
   
   [self.navigationController setToolbarHidden:NO animated:YES];   
   
   //UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
   UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
   infoButton.frame = CGRectMake(20, 20, 20, 20);
   [infoButton setBackgroundImage:
    [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"gear" ofType:@"png"]] 
                            forState:UIControlStateNormal];
   
   [infoButton addTarget:self action:@selector(doit:) forControlEvents:UIControlEventTouchUpInside];
   infoButton.tag = 7;
   
   UIBarButtonItem* infoToolbarItem =    
   [[[UIBarButtonItem alloc]
     initWithCustomView:infoButton]autorelease];
   
   [self setToolbarItems:[NSArray arrayWithObjects:infoToolbarItem,nil]];
}
///////////////////////////////////////////////////////////////////////////////
//TOOLBAR HANDLER
-(void)doit:(UIButton*)sender
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
   }
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

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc 
{
    [super dealloc];
}
@end
