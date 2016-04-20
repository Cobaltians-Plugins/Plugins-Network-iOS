#import "CobaltNetworkStatusPlugin.h"

@implementation CobaltNetworkStatusPlugin

- (instancetype) init {
    if (self = [super init]) {
        _networkReachability = [[NetworkChangeReceiver alloc] initWithDelegate: self];
        _listeningControllers = [NSHashTable hashTableWithOptions: NSPointerFunctionsWeakMemory];
    }

    return self;
}

- (void) onMessageFromCobaltController: (CobaltViewController *) viewController
                               andData: (NSDictionary *) data {
    [self onMessageWithCobaltController: viewController
                                andData: data];
}

- (void) onMessageFromWebLayerWithCobaltController: (CobaltViewController *) viewController
                                           andData: (NSDictionary *) data {
    [self onMessageWithCobaltController: viewController
                                andData: data];
}

- (void) onMessageWithCobaltController: (CobaltViewController *) viewController
                               andData: (NSDictionary *) data {
    NSString * callback = [data objectForKey: kJSCallback];
    NSString * action = [data objectForKey: kJSAction];

    if (action != nil) {
        if ([action isEqualToString: @"getStatus"]) {
            NSDictionary * status = @{@"status": [self getStatus]};

            [viewController sendCallback: callback
                                withData: status];
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
    else {
        NSLog(@"CobaltNetworkStatusPlugin onMessageWithCobaltController:andData: action is nil");
    }
}

- (NSString *) getStatus {
    return [_networkReachability getStatus];
}

- (void) onNetworkStatusChanged: (NSString *) status {
    if ([_listeningControllers anyObject] != nil) {
        NSDictionary * message = @{
            kJSType: kJSTypePlugin,
            kJSPluginName: @"networkStatus",
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
