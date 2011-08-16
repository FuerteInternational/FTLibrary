//
//  FTSystemKillSwitch.m
//  FTLibrary
//
//  Created by Ondrej Rafaj on 29/06/2011.
//  Copyright 2011 Fuerte International. All rights reserved.
//

#import "FTSystemKillSwitch.h"
#import "FTDataJson.h"
#import "FTAppDelegate.h"
#import "UIView+Layout.h"
#import "FTSystem.h"

#define kFTSystemKillSwitchHash                 @"FTSystemKillSwitchHash"
#define kFTSystemKillSwitchVersions             @"FTSystemKillSwitchVersions"

#define kFTSystemKillSwitchAbortNotification    @"FTSystemKillSwitchAbortNotification"
#define kFTSystemKillSwitchIsApplicationLocked  @"FTSystemKillSwitchIsApplicationLocked"

#define kFTSystemKillSwitchAlertTag             862


@implementation FTSystemKillSwitchMessage

@synthesize title;
@synthesize message;
@synthesize web;
@synthesize appStore;


- (void)dealloc {
    
    [title release];
    [message release];
    [web release];
    [appStore release];
    [super dealloc];
}

@end

@interface FTSystemKillSwitch(Private)
-(void)foreGroundResult;
@end

@implementation FTSystemKillSwitch

@synthesize url;
@synthesize appWindow;
@synthesize blockerShadow;
@synthesize hash;
@synthesize versions;
@synthesize message;
@synthesize isDebugActive;
@synthesize isApplicationLocked;
@synthesize delegate;



#pragma mark getter setter;

- (NSString *)hash {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kFTSystemKillSwitchHash];
}

- (void)setHash:(NSString *)aHash {
     [[NSUserDefaults standardUserDefaults] setObject:aHash forKey:kFTSystemKillSwitchHash];
}

- (FTSystemKillSwitchVersions)versions {
    
    NSDictionary *resutls = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kFTSystemKillSwitchVersions];
    FTSystemKillSwitchVersions ver;
    ver.live = [[resutls objectForKey:@"live"] floatValue];
    ver.minimum = [[resutls objectForKey:@"minimum"] floatValue];
    ver.staging = [[resutls objectForKey:@"staging"] floatValue];
    
    return ver;
}

- (void)setVersions:(FTSystemKillSwitchVersions)someVersions {
    NSDictionary *ver = [NSDictionary 
                         dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithFloat:someVersions.live], [NSNumber numberWithFloat:someVersions.minimum], [NSNumber numberWithFloat:someVersions.staging], nil] 
                         forKeys:[NSArray arrayWithObjects:@"live", @"minimum", @"staging", nil]];
    [[NSUserDefaults standardUserDefaults] setObject:ver forKey:kFTSystemKillSwitchVersions];
}

+ (BOOL)isApplicationLocked {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFTSystemKillSwitchIsApplicationLocked];
}

- (BOOL)isApplicationLocked {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFTSystemKillSwitchIsApplicationLocked];
}

- (void)setIsApplicationLocked:(BOOL)isAnApplicationLocked {
    [[NSUserDefaults standardUserDefaults] setBool:isAnApplicationLocked forKey:kFTSystemKillSwitchIsApplicationLocked]; 
}


+ (NSInteger)alertViewTag {
    return kFTSystemKillSwitchAlertTag;
}

#pragma mark get data

- (void)getData {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    

    BOOL internetAvailable = [FTSystem isInternetAvailable];
    
    message = [[FTSystemKillSwitchMessage alloc] init];
    if (!internetAvailable) {
        if (self.isApplicationLocked) {
            message.title = @"Application locked";
            message.message = @"Internet Connetion is required in order to unlock the application";
            message.web = nil;
            message.appStore = [NSURL URLWithString:@"http://www.wellbakedapp.com"];            
        }
    }
    else {
        NSString *type = (isDebugActive)? @"staging" : @"live";
        NSString *request = [NSString stringWithFormat:@"%@-%@.json", url, type]; //http://new.fuerteint.com/_files/calpol_testing/killswitch/live.json
        NSDictionary *dictionaryData = [FTDataJson jsonDataFromUrl:request];
        
        if (isDebugActive) {
            versions.staging = [[dictionaryData objectForKey:@"version"] floatValue];
            versions.live = 0.0;
        }
        else {
            versions.live = [[dictionaryData objectForKey:@"version"] floatValue];
            versions.staging = 0.0;
        }
        
        NSDictionary *data = [dictionaryData objectForKey:@"data"];
        versions.minimum = [[data objectForKey:@"minversion"] floatValue];
        
        message.title = [data objectForKey:@"title"];
        message.message = [data objectForKey:@"message"];
        message.web = [NSURL URLWithString:[data objectForKey:@"web"]];
        message.appStore = [NSURL URLWithString:[data objectForKey:@"appstore"]];
    
    }
    [self performSelectorOnMainThread:@selector(foreGroundResult) withObject:nil waitUntilDone:NO];
    
    [pool drain];
    
}

- (void)foreGroundResult {
    static UIView *alertView;
    static UIView *shadow;
    if (!shadow) {
        shadow = [[UIView alloc] initWithFrame:appWindow.bounds];
        [shadow setBackgroundColor:[UIColor blackColor]];
        [shadow setAlpha:blockerShadow];
    }
    
    for (UIView *view in appWindow.subviews) {
        if ([view isEqual:alertView]) {
            [view removeFromSuperview];
            NSLog(@"alertView found and removed");
        }
    }
    
    //check version
    
    if (versions.current < versions.minimum || versions.minimum == 0) {
        //remove other alertView
        
        [self setIsApplicationLocked:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:kFTSystemKillSwitchAbortNotification object:nil];
        if (self.delegate && [self.delegate respondsToSelector:@selector(killSwitchDidFinish)]) {
            [self.delegate killSwitchDidFinish];
        }
        alertView = nil;
        //show view on window
        if(appWindow) {
            [shadow setHidden:NO];
            [appWindow addSubview:shadow];
            
            if ([[self delegate] respondsToSelector:@selector(viewForAppKillSwitchWithMessage:)]) {
                alertView = [[self delegate] viewForAppKillSwitchWithMessage:message];
            }
            else {
                float w = appWindow.bounds.size.width - 40;
                float h =  appWindow.bounds.size.height - 40;
                alertView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, w, h)];
                [alertView autorelease];
            }
            
            [alertView setTag:kFTSystemKillSwitchAlertTag];
            [appWindow addSubview:alertView];
            [alertView centerInSuperView];
                
        }
    }
    else {
        [self setIsApplicationLocked:NO];
        [shadow setHidden:YES];
        
    }
}


#pragma mark Initialization

- (id)initWithAppURL:(NSString *)aUrl {
	self = [super init];
	if (self) {
        url = [aUrl retain];
        isDebugActive = NO;
#ifdef DEBUG
        isDebugActive = YES;
#endif
		appWindow = [FTAppDelegate window];
		blockerShadow = 0.6;
        
        
	}
	return self;
}

- (void)killSwitchApp {
    versions.current = [FTSystemKillSwitch currentAppVersion];
    [self performSelectorInBackground:@selector(getData) withObject:nil];
}

#pragma mark Settings

+ (float)currentAppVersion {
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    float versionFloat = [version floatValue];
    return  versionFloat;
}

+ (void)setCurrentAppVersion:(float)current {
    FTSystemKillSwitch *ks = [[FTSystemKillSwitch alloc] init];
    FTSystemKillSwitchVersions ver = [ks versions];
    
    
	ver.current = current;
    [ks setVersions:ver];
    [ks release];
}

+ (NSInteger)remoteAllowedAppVersion {
	return 1;
}


#pragma mark Memory management

- (void)dealloc {
    
    [url release];
    [appWindow release];
    [hash release];
    delegate = nil;
	[super dealloc];
}

@end
