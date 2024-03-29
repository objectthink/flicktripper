//
//  TripJournalSession.h
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 8/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Trip.h"

typedef enum {
   NONE        = -1,
   IMAGES      = 0,
   TAGS        = 1,
   FROB        = 2,
   AUTH        = 3,
   CHECKAUTH   = 4,
   PREUPLOAD   = 5,
   UPLOAD      = 6,
   SETTAGS     = 7,
   SETTRIPTAGS = 8,
   IMAGESEARCH = 9,
   IMAGEINFO   = 10,
   DELETE      = 11,
   LOCATION    = 12,
   TRIPS       = 13,
   TEST        = 14
}REQUESTTYPE;

@interface TripJournalSession : NSObject
{
   REQUESTTYPE requestType;
   id tag;
   
   int index;
   int photoIndex;
   
   NSMutableArray* tripids;
   NSArray* photos;
   Trip* trip;
   
}
+(TripJournalSession*)sessionWithRequestType:(REQUESTTYPE)requestType;

@property (assign) REQUESTTYPE requestType;
@property (assign) id tag;
@property (retain) NSMutableArray* tripids;
@property (assign) int index;
@property (assign) int photoIndex;
@property (retain) NSArray* photos;
@property (assign) Trip* trip;
@end
