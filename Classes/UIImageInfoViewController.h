//
//  UIImageInfoViewController.h
//
//  Created by stephen eshelman on 5/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface UIImageInfoViewController : UIViewController <UIWebViewDelegate> /* Specify a superclass (eg: NSObject or NSView) */ 
{
   IBOutlet UIWebView* theWebView;
   NSURLRequest* theUrlRequest;
   IBOutlet UIBarButtonItem* theBackButton;
}

@property (nonatomic, retain) UIWebView *theWebView;
@property (nonatomic, retain) NSURLRequest* theUrlRequest;
@property (assign) UIBarButtonItem* theBackButton;

-(IBAction)OnBack:(id)sender;
@end
