//
//  StopInfoPrompt.m
//  iTripSimpleJournal
//
//  Created by stephen eshelman on 9/18/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "StopInfoPrompt.h"


@implementation StopInfoPrompt
@synthesize stopNameField;
@synthesize stopDetailsField;
@synthesize stopName;
@synthesize stopDetails;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okayButtonTitle
{
   
   if (
       (self = 
       [super 
        initWithTitle:title 
        message:message 
        delegate:delegate 
        cancelButtonTitle:cancelButtonTitle 
        otherButtonTitles:okayButtonTitle, nil]))
   {
      stopNameField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 45.0, 260.0, 25.0)]; 
      [stopNameField setBackgroundColor:[UIColor whiteColor]]; 

      [self addSubview:stopNameField];
      
      stopDetailsField = [[UITextView alloc] initWithFrame:CGRectMake(12.0, 75.0, 260.0, 25.0)];
      [self addSubview:stopDetailsField];
      
      CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, 130.0); 
      [self setTransform:translate];
   }
   return self;
}
- (void)show
{
   [stopNameField becomeFirstResponder];
   [super show];
}
- (NSString*)stopName
{
   return stopNameField.text;
}
- (NSString*) stopDetails
{
   return stopDetailsField.text;
}
- (void)dealloc
{
   [stopNameField release];
   [stopDetailsField release];
   
   [super dealloc];
}
@end
