//
//  SDViewController.m
//  Silent Mobile Disco
//
//

#import "SDViewController.h"

#import "SDHostGameViewController.h"
#import "SDJoinGameViewController.h"

@interface SDViewController ()

@end

@implementation SDViewController


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
    SDHostGameViewController *vc = [[SDHostGameViewController alloc] initWithNibName:@"SDHostGameViewController" bundle:[NSBundle mainBundle]];
    
    // Initialize Navigation Controller
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    // Present Navigation Controller
    [self presentViewController:nc animated:YES completion:nil];
}

- (IBAction)joinGame:(id)sender {
    // Initialize Join Game View Controller
    SDJoinGameViewController *vc = [[SDJoinGameViewController alloc] initWithStyle:UITableViewStylePlain];
    
    // Initialize Navigation Controller
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    // Present Navigation Controller
    [self presentViewController:nc animated:YES completion:nil];
}

@end
