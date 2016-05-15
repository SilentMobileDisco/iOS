//
//  SDJoinGameViewController.m
//  Silent Mobile Disco
//
//

#import "SDJoinGameViewController.h"
#import "SDDiscoViewController.h"
#import "SDDiscoModel.h"
#import <arpa/inet.h>
#import "GStreamerBackend.h"


@interface SDJoinGameViewController () <NSNetServiceDelegate, NSNetServiceBrowserDelegate> {
    
}

@property (strong, nonatomic) NSMutableArray *services;

@property (strong, nonatomic) NSNetServiceBrowser *serviceBrowser;
@property (strong, nonatomic) SDDiscoModel *selectedDisco;

@end

@implementation SDJoinGameViewController

static NSString *ServiceCell = @"ServiceCell";

#pragma mark -
#pragma mark Initialization
- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    
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
    
    // Start Browsing
    [self startBrowsing];
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
#pragma mark Table View Data Source Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.models ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.models count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ServiceCell];
    
    if (!cell) {
        // Initialize Table View Cell
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ServiceCell];
    }
    
    SDDiscoModel *disco = [self.models objectAtIndex:[indexPath row]];

    // Configure Cell
    [cell.textLabel setText:[disco name]];
    [cell.detailTextLabel setText:[disco uri]];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark -
#pragma mark Table View Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Left empty because all logic is handled in prepareSegue:sender:
}

#pragma mark -
#pragma mark Net Service Browser Delegate Methods
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)serviceBrowser {
    [self stopBrowsing];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser didNotSearch:(NSDictionary *)userInfo {
    [self stopBrowsing];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    // Resolve Service
    [self.services addObject:service];
    
    [service setDelegate:self];
    [service resolveWithTimeout:30.0];
    
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)serviceBrowser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    // If a service is removed, loop through and remove the relevant service
    // For now, using model name suffices, but IP and port should also be compared.
    for (SDDiscoModel *model in self.models) {
        if ([[model name] isEqualToString:[service name]]) {
            [self.models removeObject:model];
        }
    }
    
    [self.services removeObject:service];
    
    if(!moreComing) {
        // Update Table View
        [self.tableView reloadData];
    }
}

#pragma mark -
#pragma mark Net Service Delegate Methods
- (void)netService:(NSNetService *)service didNotResolve:(NSDictionary *)errorDict {
    [service setDelegate:nil];
}

- (void)netServiceDidResolveAddress:(NSNetService *)service {
    SDDiscoModel *disco = [self createDiscoModelFromService:service];
    
    [self.models addObject:disco];
    [self.tableView reloadData];

    
    NSLog(@"Did Discover Disco: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);
    
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
    // Stop Browsing Services
    [self stopBrowsing];
    
    // Dismiss View Controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Helper Methods
- (void)startBrowsing {
    if (self.services) {
        [self.services removeAllObjects];
    } else {
        self.services = [[NSMutableArray alloc] init];
    }
    
    if (self.models) {
        [self.models removeAllObjects];
    } else {
        self.models = [[NSMutableArray alloc] init];
    }
    
    // Initialize Service Browser
    self.serviceBrowser = [[NSNetServiceBrowser alloc] init];
    
    // Configure Service Browser
    [self.serviceBrowser setDelegate:self];
    [self.serviceBrowser searchForServicesOfType:@"_silentmobiledisco._udp." inDomain:@"local."];
}

- (void)stopBrowsing {
    if (self.serviceBrowser) {
        [self.serviceBrowser stop];
        [self.serviceBrowser setDelegate:nil];
        [self setServiceBrowser:nil];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selectedDisco = [self.models objectAtIndex:indexPath.row];

    if ([segue.destinationViewController respondsToSelector:@selector(setDisco:)]) {
        [segue.destinationViewController performSelector:@selector(setDisco:)
                                              withObject:self.selectedDisco];
    }

}

- (SDDiscoModel *)createDiscoModelFromService:(NSNetService *)service {
    char addressBuffer[INET6_ADDRSTRLEN];
    for (NSData *data in [service addresses])
    {
        memset(addressBuffer, 0, INET6_ADDRSTRLEN);
        
        typedef union {
            struct sockaddr sa;
            struct sockaddr_in ipv4;
            struct sockaddr_in6 ipv6;
        } ip_socket_address;
        
        ip_socket_address *socketAddress = (ip_socket_address *)[data bytes];
        
        if (socketAddress && (socketAddress->sa.sa_family == AF_INET))
        {
            const char *addressStr = inet_ntop(
                                               socketAddress->sa.sa_family,
                                               (socketAddress->sa.sa_family == AF_INET ? (void *)&(socketAddress->ipv4.sin_addr) : (void *)&(socketAddress->ipv6.sin6_addr)),
                                               addressBuffer,
                                               sizeof(addressBuffer));
            
            int port = ntohs(socketAddress->sa.sa_family == AF_INET ? socketAddress->ipv4.sin_port : socketAddress->ipv6.sin6_port);
            
            if (addressStr && port)
            {
                SDDiscoModel* model = [[SDDiscoModel alloc] initWithName:service.name ip:[NSString stringWithUTF8String:addressStr] port:[NSString stringWithFormat:@"%d", port]];
                return model;
            }
        }
        
    }
    return NULL;

}


@end
