//
//  StopViewController.h
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 7/26/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "testAppDelegate.h"
#import "Trip.h"


@interface StopViewController : UIViewController <
CLLocationManagerDelegate, 
MKMapViewDelegate,
OFFlickrAPIRequestDelegate,
UIActionSheetDelegate>
{
   testAppDelegate* app;

   Stop* stop;
   
   IBOutlet MKMapView* mapView;
   IBOutlet UIButton*  imageButton;
   IBOutlet UILabel*   stopDetails;
   IBOutlet UILabel*   stopName;
   
   UIBarButtonItem* gotoFlickrPageButton;
   
   BOOL showingAll;
   
   UILabel* stopNameLabel;
   
   UISegmentedControl* segmentedControl;
}
@property (retain) Stop*     stop;
@property (assign) UIButton* imageButton;
@property (assign) UILabel*  stopDetails;
@property (assign) UILabel*  stopName;
@property (assign) testAppDelegate* app;
@property (retain) UILabel* stopNameLabel;
@property (retain) UISegmentedControl* segmentedControl;

//OFFlickrAPIRequestDelegate
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didCompleteWithResponse:(NSDictionary *)response;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request didFailWithError:(NSError *)error;
- (void)flickrAPIRequest:(OFFlickrAPIRequest *)request imageUploadSentBytes:(NSUInteger)sent totalBytes:(NSUInteger)total;

-(IBAction) imageTouched;

-(void)toolbarHandler:(id)sender;
-(void)OnShowInfo;
-(void)OnSaveToCameraRoll;
-(void)OnPromptWhereTo;

//CLLocationManagerDelegate
-(void)locationManager:(CLLocationManager *)manager 
    didUpdateToLocation:(CLLocation *)newLocation 
           fromLocation:(CLLocation *)oldLocation;

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;

//MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views;
@end

@interface MyUIViewController : UIViewController
@end


