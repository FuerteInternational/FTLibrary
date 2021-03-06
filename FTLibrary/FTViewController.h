//
//  FTViewController.h
//  FTLibrary
//
//  Created by Ondrej Rafaj on 28/06/2011.
//  Copyright 2011 Fuerte International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FTTableViewCell.h"
#import "FTProgressView.h"


@interface FTViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FTProgressViewDelegate> {
    
	UITableView *table;
	
	NSArray *data;
	
	UIImageView *backgroundView;
	
	BOOL isLandscape;
	
	FTProgressView *loadingProgressView;
	
	UIView *debugLabel;
    
    BOOL compareDesign;
    
    UIImageView *compareDesignView;
	
}

@property (nonatomic, retain) UITableView *table;

@property (nonatomic, retain) NSArray *data;

@property (nonatomic, retain) UIImageView *backgroundView;

@property (nonatomic) BOOL isLandscape;

@property (nonatomic, retain) FTProgressView *loadingProgressView;

@property (nonatomic, assign, getter=isCompareDesign) BOOL compareDesign;

@property (nonatomic, retain) IBOutlet UIImageView *compareDesignView;


// Initialization
- (void)initializingSequence;

// Layout
- (CGRect)fullscreenRect;

// Miscellaneous
- (void)setTitleWithNoTranslation:(NSString *)title;

// Layout & style
- (void)setBackgroundWithImageName:(NSString *)imageName;
- (void)doLayoutSubviews;
- (void)createAllElements;

// Table views
- (void)createTableViewWithStyle:(UITableViewStyle)style andAddToTheMainView:(BOOL)addToView;
- (void)createTableViewWithStyle:(UITableViewStyle)style;
- (void)createTableView;

- (void)configureCell:(FTTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView;

// Loading progress view
- (void)enableLoadingProgressViewInWindowWithTitle:(NSString *)title withAnimationStyle:(FTProgressViewAnimation)animation showWhileExecuting:(SEL)method onTarget:(id)target withObject:(id)object animated:(BOOL)animated;
- (void)enableLoadingProgressViewInWindowWithTitle:(NSString *)title andAnimationStyle:(FTProgressViewAnimation)animation;
- (void)enableLoadingProgressViewWithTitle:(NSString *)title withAnimationStyle:(FTProgressViewAnimation)animation showWhileExecuting:(SEL)method onTarget:(id)target withObject:(id)object animated:(BOOL)animated;
- (void)enableLoadingProgressViewWithTitle:(NSString *)title andAnimationStyle:(FTProgressViewAnimation)animation;
- (void)enableLoadingProgressViewWithTitle:(NSString *)title withAnimationStyle:(FTProgressViewAnimation)animation andCustomView:(UIView *)view;
- (void)disableLoadingProgressView;

- (BOOL)checkForConnectionWithMessage;


@end
