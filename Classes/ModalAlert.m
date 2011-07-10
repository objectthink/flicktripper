/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

/*
 Thanks to Kevin Ballard for suggesting the UITextField as subview approach
 All credit to Kenny TM. Mistakes are mine. 
 To Do: Ensure that only one runs at a time -- is that possible?
 */

#import "ModalAlert.h"
#import <stdarg.h>

#define TEXT_FIELD_TAG	9999

@interface ModalAlertDelegate : NSObject <UIAlertViewDelegate, UITextFieldDelegate> 
{
	CFRunLoopRef currentLoop;
	NSString *text;
	NSUInteger index;
}
@property (assign) NSUInteger index;
@property (retain) NSString *text;
@end

@implementation ModalAlertDelegate
@synthesize index;
@synthesize text;

-(id) initWithRunLoop: (CFRunLoopRef)runLoop 
{
	if ((self = [super init])) currentLoop = runLoop;
	return self;
}

-(void)finishPrompt:(id)o
{
	CFRunLoopStop(currentLoop);   
}

// User pressed button. Retrieve results
-(void)alertView:(UIAlertView*)aView clickedButtonAtIndex:(NSInteger)anIndex 
{
	UITextField *tf = (UITextField *)[aView viewWithTag:TEXT_FIELD_TAG];
	if (tf) self.text = tf.text;
	self.index = anIndex;
   
   [aView resignFirstResponder];
   
   // give the keyboard a chance to go away...
	[self performSelector:@selector(finishPrompt:) withObject:nil afterDelay: 0.9f];

	//CFRunLoopStop(currentLoop);
}

- (BOOL) isLandscape
{
	return ([UIDevice currentDevice].orientation == 
           UIDeviceOrientationLandscapeLeft) || ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight);
}

// Move alert into place to allow keyboard to appear
- (void) moveAlert: (UIAlertView *) alertView
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.25f];
	if (![self isLandscape])
		alertView.center = CGPointMake(160.0f, 180.0f);
	else 
		alertView.center = CGPointMake(240.0f, 90.0f);
	[UIView commitAnimations];
	
	[[alertView viewWithTag:TEXT_FIELD_TAG] becomeFirstResponder];
}

- (void) dealloc
{
	self.text = nil;
	[super dealloc];
}

@end

@implementation ModalAlert

+ (NSUInteger) ask: (NSString *) question withCancel: (NSString *) cancelButtonTitle withButtons: (NSArray *) buttons
{
	CFRunLoopRef currentLoop = CFRunLoopGetCurrent();
	
	// Create Alert
	ModalAlertDelegate *madelegate = [[ModalAlertDelegate alloc] initWithRunLoop:currentLoop];
   
	UIAlertView *alertView = 
   [[UIAlertView alloc] 
    initWithTitle:question 
    message:nil 
    delegate:madelegate 
    cancelButtonTitle:cancelButtonTitle 
    otherButtonTitles:nil];
	
   for (NSString *buttonTitle in buttons) 
      [alertView addButtonWithTitle:buttonTitle];
	
   [alertView show];
	
	// Wait for response
	CFRunLoopRun();
	
	// Retrieve answer
	NSUInteger answer = madelegate.index;
   
	[alertView release];
	[madelegate release];
	return answer;
}

+ (void) say: (id)formatstring,...
{
	va_list arglist;
	va_start(arglist, formatstring);
	id statement = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
	va_end(arglist);
	[ModalAlert ask:statement withCancel:@"Ok" withButtons:nil];
	[statement release];
}

+ (BOOL) ask: (id)formatstring,...
{
	va_list arglist;
	va_start(arglist, formatstring);
	id statement = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
	va_end(arglist);
	BOOL answer = ([ModalAlert ask:statement withCancel:nil withButtons:[NSArray arrayWithObjects:@"Yes", @"No", nil]] == 0);
	[statement release];
	return answer;
}

+ (BOOL) confirm: (id)formatstring,...
{
	va_list arglist;
	va_start(arglist, formatstring);
	id statement = [[NSString alloc] initWithFormat:formatstring arguments:arglist];
	va_end(arglist);
	BOOL answer = [ModalAlert ask:statement withCancel:@"Cancel" withButtons:[NSArray arrayWithObject:@"OK"]];
	[statement release];
	return	answer;
}

CGRect lastBounds;

+(NSString *) textQueryWith: (NSString *)question prompt: (NSString *)prompt button1: (NSString *)button1 button2:(NSString *) button2
{
	// Create alert
	CFRunLoopRef currentLoop = CFRunLoopGetCurrent();
	ModalAlertDelegate *madelegate = [[ModalAlertDelegate alloc] initWithRunLoop:currentLoop];
	
   UIAlertView *alertView = 
   [[UIAlertView alloc] initWithTitle:question message:@"\n" delegate:madelegate cancelButtonTitle:button1 otherButtonTitles:button2, nil];

	// Build text field
	UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 260.0f, 30.0f)];
	tf.borderStyle = UITextBorderStyleRoundedRect;
	tf.tag = TEXT_FIELD_TAG;
	tf.placeholder = prompt;
	tf.clearButtonMode = UITextFieldViewModeWhileEditing;
	tf.keyboardType = UIKeyboardTypeAlphabet;
	tf.keyboardAppearance = UIKeyboardAppearanceAlert;
	tf.autocapitalizationType = UITextAutocapitalizationTypeSentences;
	tf.autocorrectionType = UITextAutocorrectionTypeDefault;
	tf.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

	// Show alert and wait for it to finish displaying
	[alertView show];
	//while (CGRectEqualToRect(alertView.bounds, CGRectZero));
   
   //2010-10-24 20:43:02.320 iTripSimpleJournal[8825:207] 284.000000 140.000000  0.000000 0.000000

   NSLog(@"%f %f  %f %f",
         alertView.bounds.size.width,
         alertView.bounds.size.height,
         alertView.bounds.origin.x,
         alertView.bounds.origin.y
         );
   
   if(!(CGRectEqualToRect(alertView.bounds, CGRectZero)))
      lastBounds = alertView.bounds;
	
	// Find the center for the text field and add it
	CGRect bounds = alertView.bounds;
   
   if(CGRectEqualToRect(bounds, CGRectZero))
      bounds = lastBounds;
   
   bounds = CGRectMake(0.0f, 0.0f, 284.0f, 140.0f);
   
	tf.center = CGPointMake(bounds.size.width / 2.0f, bounds.size.height / 2.0f - 10.0f);
	[alertView addSubview:tf];
	[tf release];
	
	// Set the field to first responder and move it into place
	[madelegate performSelector:@selector(moveAlert:) withObject:alertView afterDelay: 0.9f];
	
	// Start the run loop
	CFRunLoopRun();
	
	// Retrieve the user choices
	NSUInteger index = madelegate.index;
	NSString *answer = [[madelegate.text copy] autorelease];
	if (index == 0) answer = nil; // assumes cancel in position 0

	[alertView release];
	[madelegate release];
	return answer;
}

+ (NSString *) ask: (NSString *) question withTextPrompt: (NSString *) prompt
{
	return [ModalAlert textQueryWith:question prompt:prompt button1:@"Cancel" button2:@"OK"];
}
@end

