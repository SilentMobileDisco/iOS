//
//  SDHostGameViewController.m
//  Silent Mobile Disco
//
//

#import "SDHostGameViewController.h"

@interface SDHostGameViewController () <NSNetServiceDelegate>

@property (strong, nonatomic) NSNetService *service;

@end

@implementation SDHostGameViewController

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
    
    // Start Broadcast
    [self startBroadcast];
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
#pragma mark Net Service Delegate Methods
- (void)netServiceDidPublish:(NSNetService *)service {
    NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);
}

- (void)netService:(NSNetService *)service didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", [service domain], [service type], [service name], errorDict);
}


#pragma mark -
#pragma mark View Methods
- (void)setupView {
    // Create Cancel Button
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
}

- (void)updateView {
    
}

#pragma mark -
#pragma mark Actions
- (void)cancel:(id)sender {
    // Cancel Hosting Game
    // TODO
    
    // Dismiss View Controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Helper Methods
- (void)startBroadcast {
    // Initialize GCDAsyncSocket
    
    // Start Listening for Incoming Connections
        // Initialize Service
        self.service = [[NSNetService alloc] initWithDomain:@"local." type:@"_silentdisco._udp." name:@"SilentDiscoServer" port:8554];
        
        // Configure Service
        [self.service setDelegate:self];
        
        // Publish Servibonce
        [self.service publish];
        
}

@end
