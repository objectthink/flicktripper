//
//  Trip.h
//  test
//
//  Created by stephen eshelman on 7/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MapPoint : NSObject <MKAnnotation>
{
	NSString *title;
	CLLocationCoordinate2D coordinate;
}

+(id)withCoordinate:(CLLocationCoordinate2D)c title:(NSString *)t;
-(id)initWithCoordinate:(CLLocationCoordinate2D)c title:(NSString *)t;

@property (nonatomic      ) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;

@end

@class Stop;
@interface Trip : NSObject 
{
   NSString* name;
   NSString* details;
   int number;
   
   NSMutableArray* stops;
}

-(void)dealloc;

+(Trip*)initWithName:(NSString*)name details:(NSString*)details stops:(int)stops;
+(Trip*)initWithName:(NSString*)name details:(NSString*)details stops:(int)stops number:(int)number;

-(Stop*)findStopWithMapPoint:(MapPoint*)mapPoint;
-(void) removeStop:(Stop*)stop;

@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* details;
@property (retain)          NSMutableArray* stops;
@property (assign)          int number;
@property (assign, getter=getNeedsUploading) BOOL needsUploading;

@end

@interface Stop : NSObject
{
   Trip* trip;
   
   MapPoint* mapPoint;
   
   NSString* name;
   NSString* details;
   int number;
   
   UIImage* image;         //used for stop page
   UIImage* thumb;         //thumbnail used on details view
   
   NSURL* photoURL;        //big image
   NSURL* photoThumbURL;   //thumb url
   
   NSURL* photoSourceURL;
   
   NSString* photoID;
   
   CLLocationCoordinate2D location;
   
   BOOL uploaded;
}

-(void)dealloc;
-(NSInteger)index;

+(Stop*)initWithName:(NSString*)name details:(NSString*)details;

+(Stop*)initWithName:(NSString*)name 
   details:(NSString *)details 
   photoURL:(NSURL*) photoURL 
   photoSourceURL:(NSURL*)photoSourceURL;

+(Stop*)initWithName:(NSString*)name 
   details:(NSString *)details 
   photoURL:(NSURL*) photoURL 
   photoSourceURL:(NSURL*)photoSourceURL
   photoID:(NSString*) photoID
   latitude:(float) lat
   longitude:(float) lon;

+(Stop*)initWithName:(NSString*)name 
             details:(NSString *)details 
            photoURL:(NSURL*) photoURL 
       photoThumbURL:(NSURL*) photoURL 
      photoSourceURL:(NSURL*)photoSourceURL
             photoID:(NSString*) photoID
            latitude:(float) lat
           longitude:(float) lon
                trip:(Trip*)trip
            uploaded:(BOOL)uploaded;

@property (assign) Trip* trip;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* details;
@property (retain) NSURL* photoURL;
@property (retain) NSURL* photoThumbURL;
@property (retain) NSURL* photoSourceURL;
@property (nonatomic, copy) NSString* photoID;
@property (assign) int number;
@property (retain) UIImage* image;
@property (retain) UIImage* thumb;
@property (assign) CLLocationCoordinate2D location;
@property (retain) MapPoint* mapPoint;
@property (assign) BOOL uploaded;
@end

