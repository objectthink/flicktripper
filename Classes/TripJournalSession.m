//
//  TripJournalSession.m
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 8/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TripJournalSession.h"

@implementation TripJournalSession
@synthesize requestType;
@synthesize tag;
@synthesize tripids;
@synthesize index;
@synthesize photoIndex;
@synthesize photos;
@synthesize trip;

+(TripJournalSession*)sessionWithRequestType:(REQUESTTYPE)requestType
{
   TripJournalSession* session =
   [[TripJournalSession alloc] init];
   
   session.requestType = requestType;
   session.tripids = [[NSMutableArray alloc] init];
   session.index = -1;
   session.photoIndex = -1;
   
   //[session retain];
   
   return [session autorelease];
}
@end
