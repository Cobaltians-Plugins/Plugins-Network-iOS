#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

extern NSString * kReachabilityChangedNotification;

@interface NetworkChangeReceiver: NSObject {
    SCNetworkReachabilityRef _reachabilityRef;
    id _delegate;
}

- (instancetype) init;
- (instancetype) initWithDelegate: (id) delegate;
- (void) setDelegate: (id) delegate;
+ (NSString *) networkStatusForFlags: (SCNetworkReachabilityFlags) flags;
- (void) onNetworkStatusChanged: (NSString *) status;
- (void) startNotifier;
- (void) stopNotifier;

- (NSString *) getStatus;

@end
