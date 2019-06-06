#import "CobaltNetworkStatusPlugin.h"
#import <Cobalt/PubSub.h>

@implementation CobaltNetworkStatusPlugin

- (instancetype) init {
    if (self = [super init]) {
        _networkReachability = [[NetworkChangeReceiver alloc] initWithDelegate: self];
        _listeningControllers = [NSHashTable hashTableWithOptions: NSPointerFunctionsWeakMemory];
    }

    return self;
}

- (void)onMessageFromWebView:(WebViewType)webView
          inCobaltController:(nonnull CobaltViewController *)viewController
                  withAction:(nonnull NSString *)action
                        data:(nullable NSDictionary *)data
          andCallbackChannel:(nullable NSString *)callbackChannel{
    
    if ([action isEqualToString: @"getStatus"]) {
        NSDictionary * status = @{@"status": [self getStatus]};
        
        [[PubSub sharedInstance] publishMessage:status
                                      toChannel:callbackChannel];

    }
    else if ([action isEqualToString: @"startStatusMonitoring"]) {
        [self startStatusMonitoring: viewController];
        
    }
    else if ([action isEqualToString: @"stopStatusMonitoring"]) {
        [self stopStatusMonitoring: viewController];
    }
    else {
        NSLog(@"CobaltNetworkStatusPlugin onMessageWithCobaltController:andData: unknown action %@", action);
    }

}

- (NSString *) getStatus {
    return [_networkReachability getStatus];
}

- (void) onNetworkStatusChanged: (NSString *) status {
    if ([_listeningControllers anyObject] != nil) {
        NSDictionary * message = @{
            kJSType: kJSTypePlugin,
            kJSPluginName: @"CobaltNetworkStatusPlugin",
            kJSAction: @"onStatusChanged",
            kJSData: @{ @"status": status }
        };
        
        for (CobaltViewController * viewController in _listeningControllers) {
            if (viewController != nil) {
                [viewController sendMessage: message];
            }
        }
    }
    else {
        [_networkReachability stopNotifier];
    }
}

- (void) startStatusMonitoring: (CobaltViewController *) viewController {
    if (![_listeningControllers containsObject: viewController]) {
        if ([_listeningControllers anyObject] == nil) {
            [_networkReachability startNotifier];
        }
        
        [_listeningControllers addObject: viewController];
    }
}

- (void) stopStatusMonitoring: (CobaltViewController *) viewController {
    if ([_listeningControllers containsObject: viewController]) {
        [_listeningControllers removeObject: viewController];
        
        if ([_listeningControllers anyObject] == nil) {
            [_networkReachability stopNotifier];
        }
    }
}

@end
