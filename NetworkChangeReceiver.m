#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>

#import <CoreFoundation/CoreFoundation.h>

#import "NetworkChangeReceiver.h"

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void * info) {
    NSCAssert(info != nil, @"info is nil in ReachabilityCallback");
    NSCAssert([(__bridge NSObject *) info isKindOfClass: [NetworkChangeReceiver class]], @"info is wrong class in ReachabilityCallback");

    NetworkChangeReceiver * receiverObject = (__bridge NetworkChangeReceiver *) info;
    [receiverObject onNetworkStatusChanged: [NetworkChangeReceiver networkStatusForFlags: flags]];
}

@implementation NetworkChangeReceiver

- (instancetype) init {
    self = [super init];

    struct sockaddr_in zeroAddress; // Create a socket address on which we will check the connectivity
    bzero(&zeroAddress, sizeof(zeroAddress)); // Fill address with zeros
    zeroAddress.sin_len = sizeof(zeroAddress); // Set address length
    zeroAddress.sin_family = AF_INET; // Set address family to Internet

    _reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *) &zeroAddress);
    NSAssert(_reachabilityRef != nil, @"_reachabilityRef is nil");

    return self;
}

- (instancetype) initWithDelegate: (id) delegate {
    self = [self init];

    [self setDelegate: delegate];

	return self;
}

- (void) setDelegate: (id) delegate {
    NSAssert([delegate respondsToSelector: @selector(onNetworkStatusChanged:)], @"NetworkChangeReceiver setDelegate: delegate does not contain a onNetworkStatusChanged method");

    _delegate = delegate;
}

+ (NSString *) networkStatusForFlags: (SCNetworkReachabilityFlags) flags {
    BOOL networkReachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
    BOOL networkIsWWAN = (flags & kSCNetworkReachabilityFlagsIsWWAN) != 0;
    BOOL connectionEstablished = (flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0;
    BOOL connectionOnDemand = (flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0;
    BOOL connectionOnTraffic = (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0;
    BOOL interventionRequired = (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0;

    // Default status is "none"
    NSString * returnValue = @"none";

    // If the network is reachable
	if (networkReachable) {
        // If the connection has already been established or can be made without intervention
        if (connectionEstablished || ((connectionOnDemand || connectionOnTraffic) && !interventionRequired)) {
            // If the connection is over a mobile network
            if (networkIsWWAN) {
                returnValue = @"mobile";
            }
            // Otherwise we assume it is over Wifi
            else {
			    returnValue = @"wifi";
            }
    	}
    }

	return returnValue;
}

- (NSString *) getStatus {
	NSAssert(_reachabilityRef != nil, @"getStatus called with nil SCNetworkReachabilityRef");

    // Return "unknown" in case of error while retrieving the connection status
	NSString * returnValue = @"unknown";
	SCNetworkReachabilityFlags flags;

	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
		returnValue = [NetworkChangeReceiver networkStatusForFlags: flags];
	}

	return returnValue;
}

- (void) onNetworkStatusChanged: (NSString *) status {
    // Call the listener's onNetworkStatus callback
    [_delegate onNetworkStatusChanged: status];
}

- (void) startNotifier {
    SCNetworkReachabilityContext context = {0, (__bridge void *) self, nil, nil, nil};

    if (SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context)) {
        SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

- (void) stopNotifier {
    if (_reachabilityRef != nil) {
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

- (void) dealloc {
    [self stopNotifier];

    if (_reachabilityRef != nil) {
        CFRelease(_reachabilityRef);
    }
}

@end
