//
//  FTVideoViewController.m
//  FTLibrary
//
//  Created by Ondrej Rafaj on 11/03/2011.
//  Copyright 2011 Fuerte International Ltd. All rights reserved.
//

#import "FTVideoViewController.h"



@implementation FTVideoViewController

@synthesize url = _url;
@synthesize player = _player;
@synthesize delegate = _delegate;
@synthesize shouldRotate = _shouldRotate;

static UIStatusBarStyle originalStatusBarStyle;

#pragma mark MPMoviePlayer notifications

- (void)videoDidStop:(NSNotification *)notification {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerDidStop:)]) {
        [self.delegate videoPlayerDidStop:self];
    }
}


#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
        self.shouldRotate = YES;
    }
    return self;
}

- (id)initWithVideoUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        // Custom initialization
        self.url = url;
    }
    return self;
}

- (id)initWithVideoPath:(NSString *)filePath {
    self = [super init];
    if (self) {
        // Custom initialization
        self.url = [NSURL URLWithString:filePath];
    }
    return self;
}

#pragma mark Memory management

- (void)dealloc {
    [_url release], _url = nil;
    [_player release], _player = nil;
    _delegate = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.player = [[MPMoviePlayerController alloc] initWithContentURL:self.url];
    [self.player.view setFrame:self.view.bounds];
    [self.player setFullscreen:YES];
    [self.player prepareToPlay];
    [self.view addSubview:self.player.view];
    
    //set notifications
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(videoDidStop:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.player];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    originalStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //[self.player play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.player stop];
    [[UIApplication sharedApplication] setStatusBarStyle:originalStatusBarStyle];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.player];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return self.shouldRotate;
}

@end
