//
//  FTReachabilityManager.h
//	FTLibrary
//
//  Created by Baldoph Pourprix on 29/11/2011.
//  Copyright (c) 2011 Fuerte International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SCNetworkReachability.h> 

/*
 • Monitor reachability status
 • Send notifications to subscribers
 */

extern NSString * const FTReachabilityStateDidChangeNotification;
extern NSString * const FTReachabilityNetworkDidChangeNotification;

typedef enum  {
    FTReachabilityStateUnknown = 0,
    FTReachabilityStateYes,
    FTReachabilityStateNo
} FTReachabilityState;

typedef enum  {
    FTReachabilityNetworkTypeUnknown = 0, 
    FTReachabilityNetworkTypeWifi,
    FTReachabilityNetworkTypeCarrier
} FTReachabilityNetworkType;

@class FTError;

@interface FTReachabilityManager : NSObject {
	
    SCNetworkReachabilityRef	_reachabilityRef;
	NSMutableArray				*_queuedTask;
}

@property (readonly, retain) NSNumber *reachabilityState;
@property (readonly, retain) NSNumber *networkType;

- (id)initWithHost:(NSString *)reachabilityHost;

//if connection status is undefined, wait in background for the connection to be known
//block and failureBlock are always executed on the caller's queue
- (void)performConnectionNeededTask:(void (^)(void))block failureBlock:(void (^)(FTError *error))failureBlock;

@end
