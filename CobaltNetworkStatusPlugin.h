#import <Cobalt/CobaltAbstractPlugin.h>
#import "NetworkChangeReceiver.h"

@interface CobaltNetworkStatusPlugin: CobaltAbstractPlugin {
    NetworkChangeReceiver * _networkReachability;
    NSHashTable * _listeningControllers;
}

- (instancetype) init;
- (void) onNetworkStatusChanged: (NSString *) status;

@end