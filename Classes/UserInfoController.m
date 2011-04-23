//
//  UserInfoController.m
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 10/2/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//
#import "testAppDelegate.h"
#import "UserInfoController.h"
#import "ModalAlert.h"


@implementation UserInfoController


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad 
{
   [super viewDidLoad];

   self.title = @"Settings";
   
   // Uncomment the following line to preserve selection between presentations.
   //self.clearsSelectionOnViewWillAppear = NO;
 
   // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
   // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
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
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Return the number of rows in the section.
    //return 2;
   
   switch(section)
   {
      case 0:
         return 1;
         break;
      case 1:
         return 5;
         break;
      default:
         return 0;
         break;
   }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
   //return [NSString stringWithFormat:@"Section Title #%d", section];
   switch(section)
   {
      case 0:
         return [NSString stringWithFormat:@""];
         break;
      case 1:
         return [NSString stringWithString:@"User"];
         break;
   }
   
   return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
   static NSString *CellIdentifier = @"Cell";
    
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
   if (cell == nil) 
   {
      cell = 
      [[[UITableViewCell alloc] 
        initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
   // Configure the cell...
   switch(indexPath.section)
   {
      case 0: //LEGAL
         switch(indexPath.row)
         {
            case 0:
               cell.textLabel.text = @"Legal";
               cell.textLabel.textAlignment = UITextAlignmentCenter;
            default:
               break;
         }
         break;
      case 1: //USER
      {
         UISwitch *mySwitch = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];
         [mySwitch addTarget:self action:@selector(doit:) forControlEvents:UIControlEventValueChanged];
         
         //[cell addSubview:mySwitch];
         cell.accessoryView = mySwitch;
         
         cell.selectionStyle = UITableViewCellSelectionStyleNone;
         switch(indexPath.row)
         {
            case 0:
               cell.textLabel.text = @"flickr Reauthorize";
               
               mySwitch.tag = 7;
               break;
            case 1:
               cell.textLabel.text = @"Upload large photos";
               
               mySwitch.on = 
               [[NSUserDefaults standardUserDefaults] boolForKey:UPLOAD_FULLSIZE_KEY];
               
               mySwitch.tag = 77;
               
               break;
            case 2:
               cell.textLabel.text = @"Make photos public";
               
               mySwitch.on = 
               [[NSUserDefaults standardUserDefaults] boolForKey:UPLOAD_PUBLIC_KEY];
               
               mySwitch.tag = 7777;
               break;
            case 3:
               cell.textLabel.text = @"Delay flickr upload";
               
               mySwitch.on = 
               [[NSUserDefaults standardUserDefaults] boolForKey:DELAY_UPLOAD_KEY];
               
               mySwitch.tag = 77777;
               break;
            case 4:
               cell.textLabel.text = @"iGuess PPT tags";
               
               mySwitch.tag = 777;
               
               break;
         }
      }
      break;
   }
   
   return cell;
}

-(void)doit:(id)sender
{
   UISwitch* aSwitch = (UISwitch*)sender;
   switch(aSwitch.tag)
   {
      case 7:
         if([aSwitch isOn])
         {
            //[ModalAlert say:@"auth ON"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:FLICKR_TOKEN_KEY];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:FLICKR_NSID_KEY];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:FLICKR_USERNAME_KEY];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:FLICKR_FULLNAME_KEY];
                     
            [ModalAlert say:@"The next time you run iSimpleTripJournal you will be asked to reauthorize your flickr account."];
            aSwitch.enabled = NO;
         }
         break;
      case 77:
         if ([aSwitch isOn])
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UPLOAD_FULLSIZE_KEY];
         else 
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:UPLOAD_FULLSIZE_KEY];
         break;
      case 777:
         if([aSwitch isOn])
         {
            [ModalAlert say:@"Set flickr tags used by iGuess Person Place Thing.  Coming!"];
            aSwitch.on = NO;
         }
         break;
      case 7777:
         //if([aSwitch isOn])
         //{
         //   [ModalAlert say:@"Photos uploaded to flickr will be made public and searchable in a future iSimpleTripJournal.  Coming!"];
         //   aSwitch.on = NO;
         //}
         if ([aSwitch isOn])
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UPLOAD_PUBLIC_KEY];
         else 
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:UPLOAD_PUBLIC_KEY];  
         break;
      case 77777:
         if ([aSwitch isOn])
         {
            [ModalAlert say:@"Photos will be queued.  Tap upload button on stop page to upload."];

            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DELAY_UPLOAD_KEY];
         }
         else 
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DELAY_UPLOAD_KEY];
         break;
         break;
   }

   //////////////////////////////////////////////////////////
   //UPDATE THE USER DEFAULTS
   [[NSUserDefaults standardUserDefaults] synchronize];
   [NSUserDefaults resetStandardUserDefaults];
}
          

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
   
   if(indexPath.section == 0) //LEGAL
   {
      UIViewController* controller = [[UIViewController alloc] init];
      
      UITextView* statement = [[UITextView alloc] init];
      
      statement.text = 
@"ObjectiveFlickr Copyright (c) 2006-2009 Lukhnos D. Liu.\n"
"LFWebAPIKit Copyright (c) 2007-2009 Lukhnos D. Liu and Lithoglyph Inc."
"\n\n"
"One test in LFWebAPIKit (Tests/StreamedBodySendingTest) makes use of Google Toolbox for Mac, Copyright (c) 2008"
"Google Inc. Refer to COPYING.txt in the directory for the full text of the Apache License, Version 2.0, under"
"which the said software is licensed."
"Both ObjectiveFlickr and LFWebAPIKit are released under the MIT license, the full text of which is printed here as "
"follows. You can also find the text at: http://www.opensource.org/licenses/mit-license.php "
"Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated "
"documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation "                           
"the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to " 
"permit persons to whom the Software is furnished to do so, subject to the following conditions in this license.  "
"\n\n"
"TDBAGEDCELL - Created by Tim Davies."
"\n\n"      
"It is important when using this class that you credit the author within your credits."
" "      
"THE WORK (TDBADGECELL) IS PROVIDED UNDER THE TERMS OF THIS CREATIVE COMMONS PUBLIC LICENCE (\"CCPL\" OR \"LICENCE\") "
"THE WORK IS PROTECTED BY COPYRIGHT AND/OR OTHER APPLICABLE LAW. ANY USE OF THE WORK OTHER THAN AS AUTHORIZED UNDER THIS "
"LICENCE OR COPYRIGHT LAW IS PROHIBITED. BY EXERCISING ANY RIGHTS TO THE WORK PROVIDED HERE, YOU ACCEPT AND AGR EE TO BE "
"BOUND BY THE TERMS OF THIS LICENCE. THE LICENSOR GRANTS YOU THE RIGHTS CONTAINED HERE IN CONSIDERATION OF YOUR"
"ACCEPTANCE OF SUCH TERMS AND CONDITIONS."
"\n\n"      
"The Licensor hereby grants to You a worldwide, royalty-free, non-exclusive, Licence for use and for the duration of "
"copyright in the Work.  See http://github.com/tmdvs/TDBadgedCell fore more information."      
;      
      statement.editable = NO;
      controller.view = statement;
      
      [statement release];      
   
      //[self presentModalViewController:controller animated:YES];
      [self.navigationController pushViewController:controller animated:YES];
      [controller release];
   }
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc 
{
   [super dealloc];
   
   NSLog(@"%s", __PRETTY_FUNCTION__);
}


@end

