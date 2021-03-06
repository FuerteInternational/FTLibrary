//
//  FTFacebookViewController.m
//  FTLibrary
//
//  Created by Ondrej Rafaj on 31/10/2011.
//  Copyright (c) 2011 Fuerte International. All rights reserved.
//

#import "FTFacebookViewController.h"
#import "ASIDownloadCache.h"
#import "FTSystem.h"
#import "FTAppDelegate.h"
#import "UIView+Layout.h"
#import "UIColor+Tools.h"
#import "UIAlertView+Tools.h"


@implementation FTFacebookViewController

@synthesize delegate;
@synthesize facebookAppId;
@synthesize useGridView;
@synthesize download;
@synthesize controllerName;


#pragma mark Creating elements

- (void)createLoadingIndicator {
	UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[ai startAnimating];
	CGRect r = ai.bounds;
	r.size.width += 10;
	UIView *v = [[UIView alloc] initWithFrame:r];
	[v addSubview:ai];
	[ai release];
	UIBarButtonItem *loading = [[UIBarButtonItem alloc] initWithCustomView:v];
	[v release];
	[self.navigationItem setRightBarButtonItem:loading animated:YES];
	[loading release];
}

- (void)createReloadButton {
	UIBarButtonItem *reload = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(didPressReloadButton:)];
	[self.navigationItem setRightBarButtonItem:reload];
	[reload release];
}

- (void)createTableView {
	if (!useGridView) [super createTableView];
	else {
		grid = [[AQGridView alloc] initWithFrame:CGRectMake(0, 0, 320, [self.view height])];
		[grid setDelegate:self];
		[grid setDataSource:self];
		[self.view addSubview:grid];
	}
}

#pragma mark Facebook stuff

- (Facebook *)facebook {
	FTAppDelegate *ad = [FTAppDelegate delegate];
	[ad.share setUpFacebookWithAppID:facebookAppId permissions:FTShareFacebookPermissionOffLine | FTShareFacebookPermissionRead andDelegate:self];	
	return ad.share.facebook;
}

- (void)authorizeWithOfflineAccess:(BOOL)offlineAccess {
	//NSString *offline = @"offline_access";
	//if (offlineAccess) offline = nil;
	[[self facebook] authorize:[NSArray arrayWithObjects:
								@"publish_stream",
								@"read_stream",
								@"read_friendlists",
								@"read_insights",
								@"user_birthday",
								@"friends_birthday",
								@"user_about_me",
								@"friends_about_me",
								@"user_photos",
								@"friends_photos",
								@"user_videos",
								@"friends_videos",
								@"offline_access",
								nil]];
}

- (void)authorize {
	[self authorizeWithOfflineAccess:NO];
}

- (void)authorizeWithOfflineRequestAccess {
//	FTAppDelegate *ad = [FTAppDelegate delegate];
//	if (![ad.share canUseOfflineAccess]) {
//		NSString *tl = FTLangGet(@"Facebook permissions");
//		NSString *ms = FTLangGet(@"Would you like to grant extended Facebook permissions to this app so you don't have to re-login again?");
//		NSString *ok = FTLangGet(@"YES");
//		NSString *cn = FTLangGet(@"NO");
//		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:tl message:ms delegate:self cancelButtonTitle:cn otherButtonTitles:ok, nil];
//		[alert show];
//		[alert release];
//	}
//	else 
	[self authorizeWithOfflineAccess:YES];
}

- (FTShareFacebookData *)facebookShareData {
	FTShareFacebookData *d = [[FTShareFacebookData alloc] init];
	[d setHttpType:FTShareFacebookHttpTypeGet];
	[d setType:FTShareFacebookRequestTypeFriends];
	return d;
}

#pragma mark Alert view permissions delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[self authorizeWithOfflineAccess:YES];
	}
	else {
		[self authorizeWithOfflineAccess:NO];
	}
}

#pragma mark Connection & Downloading stuff

- (void)downloadDataFromUrl:(NSString *)url {
	Facebook *fb = [self facebook];
	if (![fb isSessionValid]) {
		[self authorizeWithOfflineRequestAccess];
	}
	else {
		[download release];
		download = [[FTDownload alloc] initWithPath:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		[download setDelegate:self];
		[download cachingEnabled:YES];
		[download startDownload];
	}
}

- (void)noInternetConnection {
	
}

- (void)startDownloadingDataForCurrentPage {
	
}

#pragma mark Download delegate methods

- (void)downloadFinishedWithResult:(NSString *)result {
	
}

- (void)downloadDataPercentageChanged:(CGFloat)percentage forObject:(FTDownload *)object {
	if (object == download) {
        //[self.progressView setProgress:(percentage / 100)];
		NSLog(@"Download in %f percent", percentage);
    }
}

- (void)downloadStatusChanged:(FTDownloadStatus)downloadStatus forObject:(FTDownload *)object {
    if (object == download) {
		if (downloadStatus != FTDownloadStatusActive) {
			
        }
        if (downloadStatus == FTDownloadStatusSuccessful) {
            NSString *s = [object.downloadRequest responseString];
            [self downloadFinishedWithResult:s];
			[self createReloadButton];
        }
        else if (downloadStatus == FTDownloadStatusFailed) {
            [UIAlertView showMessage:FTLangGet(@"Error downloading file") withTitle:FTLangGet(@"Error")];
			[self createReloadButton];
        }
    }
}

#pragma mark Layout

- (void)doLayoutSubviews {
	[super doLayoutSubviews];
	if ([FTSystem isPhoneIdiom]) {
		if (isLandscape) {
			[table setWidth:480];
			[grid setWidth:480];
		}
		else {
			[table setWidth:320];
			[grid setWidth:320];
		}
	}
}

#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self.view setBackgroundColor:[UIColor colorWithHexString:@"F2F2F2"]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startDelayedReloadData) name:kFTAppDelegateDidOpenAppWithUrl object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[table setBackgroundColor:[UIColor clearColor]];
	[grid setBackgroundColor:[UIColor clearColor]];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	UIView *v;
	if (!useGridView) v = table;
	else v = grid;
	[v setAutoresizingMask:UIViewAutoresizingNone];
	CGRect r = self.view.bounds;
	if (searchBar) {
		r.origin.y += [searchBar height];
		r.size.height -= 44;
	}
	[v setFrame:r];
	[v setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
	if (useGridView) [grid reloadData];
	
	if ([data count] <= 0) {
		[self startDownloadingDataForCurrentPage];
		[self createLoadingIndicator];
	}
}

#pragma mark Loading data

- (void)reloadData {
	if (!useGridView) [table reloadData];
	else [grid reloadData];
}

- (void)startDelayedReloadData {
	[NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(reloadData) userInfo:nil repeats:NO];
}

- (void)didPressReloadButton:(UIBarButtonItem *)sender {
	[self createLoadingIndicator];
	[self reloadData];
}

#pragma mark Saving status methods

- (NSString *)keyForController {
	return [NSString stringWithFormat:@"FTFacebookViewControllerKeyFor%@", controllerName];
}

- (void)saveOffset:(CGPoint)offset {
	[[NSUserDefaults standardUserDefaults] setValue:NSStringFromCGPoint(offset) forKey:[self keyForController]];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:[[self keyForController] stringByAppendingString:@"Date"]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (CGPoint)lastOffset {
	NSString *p = [[NSUserDefaults standardUserDefaults] valueForKey:[self keyForController]];
	if (!p || ([p length] < 5)) return CGPointZero;
	else {
		return CGPointFromString(p);
	}
}

#pragma mark Grid view delegate & data source methods

- (NSUInteger)numberOfItemsInGridView:(AQGridView *)gridView {
	return [data count];
}

- (CGSize)portraitGridCellSizeForGridView:(AQGridView *)gridView {
	return CGSizeMake(150, 150);
}

- (void)configureGridCell:(FTGridViewCell *)cell atIndex:(NSInteger)index forGridView:(AQGridView *)gridView {
	[cell.contentView setBackgroundColor:[UIColor randomColor]];
}

- (AQGridViewCell *)gridView:(AQGridView *)gridView cellForItemAtIndex:(NSUInteger)index {
	static NSString *ci = @"FBAQGridViewCell";
	FTGridViewCell *cell = (FTGridViewCell *)[gridView dequeueReusableCellWithIdentifier:ci];
	if (!cell) {
		cell = [[[FTGridViewCell alloc] initWithFrame:CGRectMake(0, 0, 150, 150) reuseIdentifier:ci] autorelease];
	}
	[cell.imageView setImage:nil];
	[self configureGridCell:cell atIndex:index forGridView:grid];
	return cell;
}

- (void)gridView:(AQGridView *)gridView didSelectItemAtIndex:(NSUInteger)index {
	[gridView deselectItemAtIndex:index animated:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	NSLog(@"View did scroll: %@", NSStringFromCGPoint(scrollView.contentOffset));
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	[self saveOffset:scrollView.contentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (!decelerate) [self saveOffset:scrollView.contentOffset];
}

#pragma mark Memory management

- (void)dealloc {
	[_facebook release];
	[facebookAppId release];
	[download release];
	[searchBar release];
	[controllerName release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


@end
