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
    
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    _reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *) &zeroAddress);
    NSAssert(_reachabilityRef != nil, @"_reachabilityRef is nil");
    
    return self;
}

- (instancetype) initWithDelegate: (id) delegate {
    self = [self init];
    _delegate = delegate;

	return self;
}

- (void) setDelegate: (id) delegate {
    _delegate = delegate;
}

+ (NSString *) networkStatusForFlags: (SCNetworkReachabilityFlags) flags {
	if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
		return @"none";

	NSString * returnValue = @"unknown";

	if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
		returnValue = @"wifi";
	}

	if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
		if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
			returnValue = @"wifi";
		}
	}

	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
		returnValue = @"mobile";
	}

	return returnValue;
}

- (NSString *) getStatus {
	NSAssert(_reachabilityRef != nil, @"getStatus called with nil SCNetworkReachabilityRef");

	NSString * returnValue = @"none";
	SCNetworkReachabilityFlags flags;

	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
		returnValue = [NetworkChangeReceiver networkStatusForFlags: flags];
	}

	return returnValue;
}

- (void) onNetworkStatusChanged: (NSString *) status {
    [_delegate onNetworkStatusChanged: status];
}

- (void) startNotifier {
    SCNetworkReachabilityContext context = {0, (__bridge void *) (self), nil, nil, nil};
    
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
