//
//  MTViewController.m
//  Four in a Row
//
//  Created by Bart Jacobs on 11/04/13.
//  Copyright (c) 2013 Mobile Tuts. All rights reserved.
//

#import "MTViewController.h"

#import "MTHostGameViewController.h"
#import "MTJoinGameViewController.h"

@interface MTViewController ()

@end

@implementation MTViewController

#pragma mark -
#pragma mark Initialization
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
    }
    
    return self;
}

#pragma mark -
#pragma mark View Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup View
    [self setupView];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark View Methods
- (void)setupView {
    
}

- (void)updateView {
    
}

#pragma mark -
#pragma mark Actions
- (IBAction)hostGame:(id)sender {
    // Initialize Host Game View Controller
    MTHostGameViewController *vc = [[MTHostGameViewController alloc] initWithNibName:@"MTHostGameViewController" bundle:[NSBundle mainBundle]];
    
    // Initialize Navigation Controller
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    // Present Navigation Controller
    [self presentViewController:nc animated:YES completion:nil];
}

- (IBAction)joinGame:(id)sender {
    // Initialize Join Game View Controller
    MTJoinGameViewController *vc = [[MTJoinGameViewController alloc] initWithStyle:UITableViewStylePlain];
    
    // Initialize Navigation Controller
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    // Present Navigation Controller
    [self presentViewController:nc animated:YES completion:nil];
}

@end
