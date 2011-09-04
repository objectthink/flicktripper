//
//  DetailViewController.h
//  test
//
//  Created by stephen eshelman on 7/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <ObjectiveFlickr.h>
#import "Trip.h"
#import "TripJournalSession.h"
#import "testAppDelegate.h"


@interface DetailViewController : UITableViewController <
OFFlickrAPIRequestDelegate,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate,
UIActionSheetDelegate,
CLLocationManagerDelegate,
UITableViewDataSource>
{
   Trip* trip;
   
   testAppDelegate* app;
   
   UIProgressView* progressView;
   UIActionSheet* uploadProgressActionSheet;
   
   CLLocationCoordinate2D currentLocation;
   
   BOOL isUploadingWaiting;
   
   UIBarButtonItem* uploadWaiting;
   
   id tag;
}
@property (assign) BOOL backRequested;
@property (assign) Trip* trip;
@property (assign) testAppDelegate* app;
@property (assign) id tag;
@property (assign) BOOL isUploadingWaiting;

-(void)goBack;
-(void)doit:(id)sender;
-(void)setBarButtonItems;
-(void)getStopInfo:(UIImage*)image;
-(void)getPhotoInfo:(NSDictionary *)response;
-(void)Upload:(UIImage*) image withStop:(Stop*)stop;

//CLLocationManagerDelegate
-(void)locationManager:(CLLocationManager *)manager 
   didUpdateToLocation:(CLLocation *)newLocation 
          fromLocation:(CLLocation *)oldLocation;

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

//OFFlickrAPIRequestDelegate
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didFailWithError:(NSError *)error;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request imageUploadSentBytes:(NSUInteger)sent totalBytes:(NSUInteger)total;

//UINavigationControllerDelegate
//- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
//- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
@end
