//
//  RootViewController.h
//  test
//
//  Created by stephen eshelman on 7/25/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ObjectiveFlickr.h>
#import "testAppDelegate.h"
#import "TripJournalSession.h"

//SOME USEFUL FUNCTIONS - MAY MOVE THESE TO THE APP DELEGATE SOURCE FILE
void MessageBox(NSString* title, NSString* message);
void ShowActivity(UIViewController* controller, BOOL show);

@interface RootViewController : UITableViewController <OFFlickrAPIRequestDelegate>
{   
   NSMutableArray* trips;
   testAppDelegate* app;
   
   UIAlertView* busyAlert;
}

-(void)setBarButtonItems;

///////////////////////////////////////////////////////////////////////////////
//OFFlickrAPIRequestDelegate
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didFailWithError:(NSError *)error;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request imageUploadSentBytes:(NSUInteger)sent totalBytes:(NSUInteger)total;

-(void)OnAuthorizeWithResponse:(NSDictionary*)response;
-(void)OnDoRequestTypeFrob:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response;
-(void)OnDoRequestTypeAuth:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response;
-(void)OnDoRequestTypeTags:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response;
-(void)OnDoRequestTypeTrips:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response;
-(void)OnDoRequestTypeImages:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response;
-(void)OnDoRequestTypeImageInfo:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response;

-(void)ShowBusy:(BOOL)showing;
-(void)doit:(id)sender;
-(void)getTrips;
-(void)getTripInfo:(TripJournalSession *)session;
-(void)getPhotoInfo:(TripJournalSession*)session;
-(void)getTripsFromFlickr;
-(void)RequestFrob;

@property (retain) NSMutableArray* trips;
@property (assign) testAppDelegate* app;

@end
