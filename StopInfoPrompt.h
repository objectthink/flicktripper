//
//  StopInfoPrompt.h
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 9/18/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface StopInfoPrompt : UIAlertView
{
   UITextField* stopNameField;
   UITextView*  stopDetailsField;
}

@property (nonatomic, retain) UITextField* stopNameField;
@property (nonatomic, retain) UITextView*  stopDetailsField;

@property (readonly) NSString* stopName;
@property (readonly) NSString* stopDetails;

- (id)initWithTitle:(NSString *)title 
   message:(NSString *)message 
   delegate:(id)delegate 
   cancelButtonTitle:(NSString *)cancelButtonTitle 
   okButtonTitle:(NSString *)okButtonTitle;

@end
