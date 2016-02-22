//
//  LogViewController.m
//  Insider
//
//  Created by Alexandru Maimescu on 2/22/16.
//  Copyright © 2016 Alex Maimescu. All rights reserved.
//

#import "LogViewController.h"
#import "AppDelegate.h"

@interface LogViewController ()

@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@end

@implementation LogViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.logTextView.text = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveNotification:)
                                                 name:kLogMessageNotificationKey
                                               object:nil];
}

- (void)didReceiveNotification:(NSNotification *)notification
{
    self.logTextView.text = [NSString stringWithFormat:@"%@\n%@", self.logTextView.text, notification.object];
}

@end
