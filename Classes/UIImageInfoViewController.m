//
//  UIImageInfoViewController.m
//
//  Created by stephen eshelman on 5/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UIImageInfoViewController.h"
#import "ModalAlert.h"

@implementation UIImageInfoViewController

@synthesize theWebView;
@synthesize theUrlRequest;
@synthesize theBackButton;

-(void)webViewDidStartLoad:(UIWebView*)webView
{
   [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
   //self.theBackButton.enabled = NO;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
   //self.theBackButton.enabled = YES;
   [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
   if([error code] == -999)
      return;
   
   [ModalAlert say:[error localizedDescription]];
}

-(void)viewDidLoad
{
   [theWebView loadRequest:theUrlRequest];
}

-(IBAction)OnBack:(id)sender
{
   //[[self parentViewController]dismissModalViewControllerAnimated:YES];
   [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
   [self dismissModalViewControllerAnimated:YES];
   
}

-(void)dealloc
{
   [theWebView release];
   [theUrlRequest release];
   
   [super dealloc];
}
@end
