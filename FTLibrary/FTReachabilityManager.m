//
//  FTReachabilityManager.h
//	FTLibrary
//
//  Created by Baldoph Pourprix on 29/11/2011.
//  Copyright (c) 2011 Fuerte International. All rights reserved.
//

#import "FTReachabilityManager.h"
#import "FTError.h"

NSString * const FTReachabilityStateDidChangeNotification = @"FTReachabilityStateDidChangeNotification";
NSString * const FTReachabilityNetworkDidChangeNotification = @"FTReachabilityNetworkDidChangeNotification";

@interface FTReachabilityManager ()
void reachabilityDidChange(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags,void *info);
@end

@implementation FTReachabilityManager

@synthesize reachabilityState = _reachabilityState;
@synthesize networkType = _networkType;

#pragma mark - Object lifecycle

- (id)initWithHost:(NSString *)reachabilityHost
{
    self = [super init];
    if (self) {
        _reachabilityRef = SCNetworkReachabilityCreateWithName(NULL,[reachabilityHost UTF8String]);
        if(_reachabilityRef != NULL) {
            // the ref is created successfully
            SCNetworkReachabilityContext context;
            context.info = (void *) self;
            context.release = NULL;
            context.retain = NULL;
            context.copyDescription = NULL;
            context.version = 0;
            
            SCNetworkReachabilitySetCallback(_reachabilityRef, &reachabilityDidChange, &context);
            SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetMain(), kCFRunLoopCommonModes);
			
			_queuedTask = [NSMutableArray new];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityStateDidChange:) name:FTReachabilityStateDidChangeNotification object:nil];
		}
	}
    return self;
}

- (void)_setReachabilityState:(FTReachabilityState)state
{
	@synchronized(_reachabilityState) {
		[self willChangeValueForKey:@"reachabilityState"];
		[_reachabilityState release];
		_reachabilityState = [[NSNumber numberWithInt:state] retain];
		[self didChangeValueForKey:@"reachabilityState"];
		[[NSNotificationCenter defaultCenter] postNotificationName:FTReachabilityStateDidChangeNotification object:self];
	}
}

- (void)_setNetworkType:(FTReachabilityNetworkType)netType
{
	@synchronized (_networkType) {
		[self willChangeValueForKey:@"networkType"];
		[_networkType release];
		_networkType = [[NSNumber numberWithInt:netType] retain];
		[self didChangeValueForKey:@"networkType"];
		[[NSNotificationCenter defaultCenter] postNotificationName:FTReachabilityNetworkDidChangeNotification object:self];
	}
}

- (void) dealloc
{	
    if (_reachabilityRef != NULL) {
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, (CFRunLoopRef)[NSRunLoop mainRunLoop], (CFStringRef)[[NSRunLoop mainRunLoop] currentMode]);
        CFRelease(_reachabilityRef);
    }
	[_queuedTask release];
	[super dealloc];
}

// reachability callback implementation
void reachabilityDidChange(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags,void *info)
{
	FTReachabilityManager *theTarget = (FTReachabilityManager *)info;
    FTReachabilityState newState = FTReachabilityStateUnknown;
    
	FTReachabilityNetworkType netType = FTReachabilityNetworkTypeUnknown;
    if ((flags & kSCNetworkReachabilityFlagsReachable) > 0 ) {
        newState = FTReachabilityStateYes;
		
		if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
			netType = FTReachabilityNetworkTypeWifi;
		
		if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
			netType = FTReachabilityNetworkTypeCarrier;
	}
    else {
        newState = FTReachabilityStateNo;
		netType = FTReachabilityNetworkTypeUnknown;
	}
	if (netType != [theTarget.networkType intValue]) {
		[theTarget _setNetworkType:netType];
	}
	if (newState != [theTarget.reachabilityState intValue]) {
		[theTarget _setReachabilityState:newState];
	}
}

#pragma mark - Other Methods

- (void)performConnectionNeededTask:(void (^)(void))block failureBlock:(void (^)(FTError *error))failureBlock
{
	NSInteger reachabilityState = [self.reachabilityState intValue];
	FTError *error = [FTError errorWithTitle:@"No Internet Connection" andDescription:@"Your device appears to be offline."];
	if (reachabilityState == FTReachabilityStateYes) {
		block();
	}
	else if (reachabilityState == FTReachabilityStateNo) {
		if (failureBlock) failureBlock(error);
	}
	else {
		
		void (^waitBlock)(void) = ^(void) {
			int state;
			do {
				sleep(0.5);
				state = [self.reachabilityState intValue];
			} while (state == FTReachabilityStateUnknown);
			
			if (state == FTReachabilityStateYes) {
				dispatch_async(dispatch_get_main_queue(), block);
			}
			else {
				dispatch_async(dispatch_get_main_queue(), ^{
					if (failureBlock) failureBlock(error);
				});
			}
		};
		
		@synchronized (_queuedTask) {
			[_queuedTask addObject:[[waitBlock copy] autorelease]];
		}		
	}
}

- (void)reachabilityStateDidChange:(NSNotification *)notification
{
	NSArray *tasks;
	@synchronized (_queuedTask) {
		tasks = [_queuedTask copy];
		[_queuedTask removeAllObjects];
	}
	for (void (^waitBlock)(void) in tasks) {
		waitBlock();
	}
	[tasks release];
}

@end
