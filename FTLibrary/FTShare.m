//
//  FTShare.m
//  IKEA_settings
//
//  Created by cescofry on 28/09/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FTShare.h"

@implementation FTShare

@synthesize facebook = _facebook;
@synthesize twitter = _twitter;
@synthesize twitterDelegate = _twitterDelegate;
@synthesize facebookDelegate = _facebookDelegate;
@synthesize mailDelegate = _mailDelegate;

@synthesize referencedController = _referencedController;

static NSDictionary *_twitterParams;
static NSMutableDictionary *_facebookParams;

- (id)initWithReferencedController:(id)controller
{
    self = [super init];
    if (self) {
        // Initialization code here.
        [self setReferencedController:controller];
        _twitterParams = nil;
        _facebookParams = nil;
        
        //FTShareFBDidLoginNotification
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(fbDidLogin) name:@"FTShareFBDidLoginNotification" object:nil];
        [notificationCenter addObserver:self selector:@selector(fbDidNotLogin:) name:@"FTShareFBDidNotLoginNotification" object:nil];
    }
    
    return self;
}
- (void)dealloc {
    [_facebook release], _facebook = nil;
    [_twitter release], _twitter = nil;
    _twitterDelegate = nil;
    _facebookDelegate = nil;
    _mailDelegate = nil;
    _referencedController = nil;
    [super dealloc];
}

#pragma mark --
#pragma mark Twitter

// setting up twitter engine
- (void)setUpTwitterWithConsumerKey:(NSString *)consumerKey secret:(NSString *)secret appID:(NSString *)appID andDelegate:(id<FTShareTwitterDelegate>)delegate {
    _twitter = [[SA_OAuthTwitterEngine alloc] initOAuthWithDelegate:self];
    self.twitterDelegate = delegate;
    self.twitter.consumerKey = consumerKey;  
    self.twitter.consumerSecret = secret;
    //APP id not set yet
}

- (void)shareViaTwitter:(NSDictionary *)data {
    _twitterParams = nil;
    _twitterParams = data;
    if(![self.twitter isAuthorized]){  
        UIViewController *controller = [SA_OAuthTwitterController controllerToEnterCredentialsWithTwitterEngine:self.twitter delegate:self];  
        
        if (controller && self.referencedController){  
            [(UIViewController *)self.referencedController presentModalViewController:controller animated:YES];
        }
    }
    else {
        [self.twitter sendUpdate:[_twitterParams objectForKey:@"message"]];
    }
}

#pragma mark SA_OAuthTwitterEngineDelegate 

- (void) storeCachedTwitterOAuthData: (NSString *) data forUsername: (NSString *) username {  
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];  
    
    [defaults setObject: data forKey: @"twitterAuthData"];  
    [defaults synchronize];  
}

- (void)clearCachedTwitterOAuthData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];  
    
    [defaults setObject: nil forKey: @"twitterAuthData"];  
    [defaults synchronize];     
}

- (NSString *) cachedTwitterOAuthDataForUsername: (NSString *) username {  
    return [[NSUserDefaults standardUserDefaults] objectForKey: @"twitterAuthData"];  
}

#pragma mark TwitterEngineDelegate  
- (void) requestSucceeded: (NSString *) requestIdentifier {  
    NSLog(@"Request %@ succeeded", requestIdentifier); 
    if ([self.twitterDelegate respondsToSelector:@selector(twitterDidPostSuccesfully:error:)]) {
        [self.twitterDelegate twitterDidPostSuccesfully:YES error:nil];
    }
}  

- (void) requestFailed: (NSString *) requestIdentifier withError: (NSError *) error {  
    NSLog(@"Request %@ failed with error: %@", requestIdentifier, error);
    if ([self.twitterDelegate respondsToSelector:@selector(twitterDidPostSuccesfully:error:)]) {
        [self.twitterDelegate twitterDidPostSuccesfully:NO error:error];
    }
}

#pragma mark Twitter login

- (void)OAuthTwitterController:(SA_OAuthTwitterController *)controller authenticatedWithUsername:(NSString *)username {
    if ([self.twitterDelegate respondsToSelector:@selector(twitterDidLoginSuccesfully:error:)]) {
        [self.twitterDelegate twitterDidLoginSuccesfully:YES error:nil];
    }
    [self shareViaTwitter:_twitterParams];
}

- (void)OAuthTwitterControllerFailed:(SA_OAuthTwitterController *)controller {
    NSError *error = [NSError errorWithDomain:@"com.fuerteint.FTShare" code:400 userInfo:[NSDictionary dictionaryWithObject:@"Couldn't share with twitter" forKey:@"description"]];
    if ([self.twitterDelegate respondsToSelector:@selector(twitterDidLoginSuccesfully:error:)]) {
        [self.twitterDelegate twitterDidLoginSuccesfully:NO error:error];
    }
}



#pragma mark --
#pragma mark Facebook

- (void)setUpFacebookWithAppID:(NSString *)appID andDelegate:(id<FTShareFacebookDelegate>)delegate {
    _facebook = [[Facebook alloc] initWithAppId:appID andDelegate:self];
    self.facebookDelegate = delegate;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:appID forKey:@"FTShareFBAppID"];
    [defaults synchronize];
    
	if ([defaults objectForKey:@"FBAccessTokenKey"] 
        && [defaults objectForKey:@"FBExpirationDateKey"]) {
        self.facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        self.facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
	}
}

- (void)shareViaFacebook:(NSDictionary *)data {
    _facebookParams = [data mutableCopy];
    if (![self.facebook isSessionValid]) {
        [self.facebook authorize:[NSArray arrayWithObjects:@"publish_stream", @"read_stream", @"offline_access", nil]];
    }
    else {
        [self.facebook dialog:@"feed" andParams:_facebookParams andDelegate:self];
    }
}

#pragma mark Facebook dialog

- (void)dialogDidComplete:(FBDialog *)dialog {
	if (self.facebookDelegate && [self.facebookDelegate respondsToSelector:@selector(facebookDidPostSuccesfully:error:)]) {
        [self.facebookDelegate facebookDidPostSuccesfully:YES error:nil];
    }
}
- (void)dialogDidNotComplete:(FBDialog *)dialog {
    NSDictionary *dict = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects:@"Couldn't post with facebook", nil]
                                                     forKeys:[NSArray arrayWithObjects:@"description", nil]];
    NSError *error= [NSError errorWithDomain:@"com.fuerte.FTShare" code:400 userInfo:dict];
    if (self.facebookDelegate && [self.facebookDelegate respondsToSelector:@selector(facebookDidPostSuccesfully:error:)]) {
        [self.facebookDelegate facebookDidPostSuccesfully:NO error:error];
    }
}

#pragma mark Facebook login

- (void)fbDidLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[self.facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
	
    if (self.facebookDelegate && [self.facebookDelegate respondsToSelector:@selector(facebookDidLoginSuccesfully:error:)]) {
        [self.facebookDelegate facebookDidLoginSuccesfully:YES error:nil];
    }
    
    if (_facebookParams) {
        [self.facebook dialog:@"feed" andParams:_facebookParams andDelegate:self];
    }
    
}

-(void)fbDidNotLogin:(BOOL)cancelled {
    NSDictionary *dict = [NSDictionary dictionaryWithObjects: [NSArray arrayWithObjects:@"Couldn't login with facebook", [NSNumber numberWithBool:cancelled], nil]
                                                     forKeys:[NSArray arrayWithObjects:@"description", @"cancelled", nil]];
    NSError *error= [NSError errorWithDomain:@"com.fuerte.FTShare" code:400 userInfo:dict];
    if (self.facebookDelegate && [self.facebookDelegate respondsToSelector:@selector(facebookDidLoginSuccesfully:error:)]) {
        [self.facebookDelegate facebookDidLoginSuccesfully:NO error:error];
    }
}

#pragma mark --
#pragma mark notification


@end