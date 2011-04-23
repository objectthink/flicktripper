//
//  Trip.m
//  test
//
//  Created by stephen eshelman on 7/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Trip.h"

@implementation MapPoint
@synthesize coordinate, title;

- (id)initWithCoordinate:(CLLocationCoordinate2D)c title:(NSString *)t
{
	self = [super init];
	coordinate = c;
	[self setTitle:t];
	
	return [self autorelease];
}

- (void)dealloc
{
	[title release];
	[super dealloc];
}
@end

@implementation Trip
@synthesize name;
@synthesize details;
@synthesize stops;
@synthesize number;
@dynamic needsUploading;

-(BOOL)getNeedsUploading
{
    for (Stop* stop in stops) 
    {
        if(!stop.uploaded)
            return YES;
    }
    return NO;
}

+(Trip*)initWithName:(NSString *)name details:(NSString *)details stops:(int)stops
{
   Trip* aTrip = [[Trip alloc] init];
   
   aTrip.name = name;
   aTrip.details = details;
   aTrip.stops = [[NSMutableArray alloc] initWithCapacity:stops];
   
   return [aTrip autorelease];
}

+(Trip*)initWithName:(NSString *)name details:(NSString *)details stops:(int)stops number:(int)number
{
   Trip* aTrip = [[Trip alloc] init];
   
   aTrip.name = name;
   aTrip.details = details;
   aTrip.stops = [[NSMutableArray alloc] initWithCapacity:stops];
   aTrip.number = number;
   
   return [aTrip autorelease];
}

///////////////////////////////////////////////////////////////////////////////
//findStopWithMapPoint
//return the Stop with the passed mapPoint
-(Stop*)findStopWithMapPoint:(MapPoint*)mapPoint
{
   for(Stop* stop in stops)
   {
      if (stop.mapPoint == mapPoint) 
         return stop;
   }
   
   return nil;
}

- (void)dealloc
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [name release];
   [details release];
   
   [stops removeAllObjects];
   stops = nil;

   [super dealloc];
}
@end

@implementation Stop
@synthesize trip;
@synthesize name;
@synthesize details;
@synthesize photoURL;
@synthesize photoSourceURL;
@synthesize photoID;
@synthesize number;
@synthesize image;
@synthesize location;
@synthesize mapPoint;
@synthesize uploaded;

- (void)dealloc
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [name release];
   [details release];
   [photoURL release];
   [photoID release];
   [photoSourceURL release];
   [image release];
   [mapPoint release];
      
   [super dealloc];
}

+(Stop*)initWithName:(NSString *)name details:(NSString *)details
{
   Stop* aStop = [[Stop alloc] init];
   
   aStop.name = name;
   aStop.details = details;
   
   aStop.uploaded = NO;
   
   return [aStop autorelease];
}

+(Stop*)
initWithName:(NSString *)name 
details:(NSString *)details
photoURL:(NSURL*) photoURL
photoSourceURL:(NSURL*)photoSourceURL
{
   Stop* aStop = [[Stop alloc] init];
   
   aStop.name = name;
   aStop.details = details;
   aStop.photoURL = photoURL;
   aStop.photoSourceURL = photoSourceURL;
   
   aStop.uploaded = NO;

   return [aStop autorelease];
}

+(Stop*)
initWithName:(NSString *)name 
details:(NSString *)details
photoURL:(NSURL*) photoURL
photoSourceURL:(NSURL*)photoSourceURL
photoID:(NSString*) photoID
latitude:(float)lat
longitude:(float)lon
{
   Stop* aStop = [[Stop alloc] init];
   
   aStop.name = name;
   aStop.details = details;
   aStop.photoURL = photoURL;
   aStop.photoSourceURL = photoSourceURL;
   aStop.photoID = photoID;
   
   CLLocationCoordinate2D aLocation = {lat,lon};
   aStop.location = aLocation;
   
   aStop.mapPoint = [[MapPoint alloc] initWithCoordinate:aStop.location title:aStop.name];
   
   aStop.uploaded = NO;
   
   return [aStop autorelease];
}

@end

