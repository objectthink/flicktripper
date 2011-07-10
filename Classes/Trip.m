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

+(Trip*)initWithName:(NSString *)name details:(NSString *)details stops:(int)stopsCount
{
   Trip* aTrip = [[Trip alloc] init];
   
   aTrip.name = name;
   aTrip.details = details;
   aTrip.stops = [[[NSMutableArray alloc] initWithCapacity:stopsCount] autorelease];
   
   return [aTrip autorelease];
}

+(Trip*)initWithName:(NSString *)name details:(NSString *)details stops:(int)stopsCount number:(int)number
{
   Trip* aTrip = [[Trip alloc] init];
   
   aTrip.name = name;
   aTrip.details = details;
   aTrip.stops = [[[NSMutableArray alloc] initWithCapacity:stopsCount] autorelease];
   aTrip.number = number;
   
   return [aTrip autorelease];
}

///////////////////////////////////////////////////////////////////////////////
//REMOVE STOP
-(void) removeStop:(Stop*)stop
{
   [self.stops removeObject:stop];
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
   [stops release];
   stops = nil;

   [super dealloc];
}
@end

@implementation Stop
@synthesize trip;
@synthesize name;
@synthesize details;
@synthesize photoURL;
@synthesize photoThumbURL;
@synthesize photoSourceURL;
@synthesize photoID;
@synthesize number;
@synthesize image;
@synthesize thumb;
@synthesize location;
@synthesize mapPoint;
@synthesize uploaded;

-(NSInteger)index
{
   return [self.trip.stops indexOfObject:self];
}

- (void)dealloc
{
   NSLog(@"%s", __PRETTY_FUNCTION__);

   [name release];
   [details release];
   [photoURL release];
   [photoID release];
   [photoSourceURL release];
   [photoThumbURL release];
   [image release];
   [thumb release];
   [mapPoint release];
   
   trip = nil;
      
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
   
   //NSLog(@"photoURL:%@",[photoURL absoluteString]);
   
   CLLocationCoordinate2D aLocation = {lat,lon};
   aStop.location = aLocation;
   
   aStop.mapPoint = [[MapPoint alloc] initWithCoordinate:aStop.location title:aStop.name];
   
   aStop.uploaded = NO;
   
   return [aStop autorelease];
}

+(Stop*)
initWithName:(NSString *)name 
details:(NSString *)details
photoURL:(NSURL*) photoURL
photoThumbURL:(NSURL*) photoThumbURL
photoSourceURL:(NSURL*)photoSourceURL
photoID:(NSString*) photoID
latitude:(float)lat
longitude:(float)lon
trip:(Trip*)trip
uploaded:(BOOL)uploaded
{
   Stop* aStop = [[Stop alloc] init];
   
   aStop.name = name;
   aStop.details = details;
   aStop.photoURL = photoURL;
   aStop.photoThumbURL = photoThumbURL;
   aStop.photoSourceURL = photoSourceURL;
   aStop.photoID = photoID;
   aStop.trip = trip;
   aStop.uploaded = uploaded;
   
   //NSLog(@"photoURL:%@",[photoURL absoluteString]);
   
   CLLocationCoordinate2D aLocation = {lat,lon};
   aStop.location = aLocation;
   
   aStop.mapPoint = [[MapPoint alloc] initWithCoordinate:aStop.location title:aStop.name];
      
   return [aStop autorelease];
}

@end

