//
//  EditViewController.h
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 6/3/12.
//  Copyright (c) 2012 blue sky computing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Trip.h"
@interface EditViewController : UIViewController

@property (nonatomic, assign) id <TripComposite> tripComposite;

@property (nonatomic, retain) IBOutlet UITextView* name;

@end
