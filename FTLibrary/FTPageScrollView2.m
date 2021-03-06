//
//  FTPageScrollView2.m
//  FTLibrary
//
//  Created by Baldoph Pourprix on 16/11/2011.
//  Copyright (c) 2011 Fuerte International. All rights reserved.
//

#import "FTPageScrollView2.h"
#import "UIView+Layout.h"

#define SCROLL_VIEW_WIDTH_FT self.bounds.size.width
#define SCROLL_VIEW_HEIGHT_FT self.bounds.size.height

@interface FTPageView2 : UIView
@property (nonatomic, assign) NSUInteger index;
@end

@implementation FTPageView2
@synthesize index = _index;
- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

@end

@interface FTPageScrollView2 () <UIScrollViewDelegate>

@property (nonatomic, assign) CGSize internalPageSize;

- (void)_updateUIForCurrentHorizontalOffset;
- (FTPageView2 *)_viewForIndex:(NSInteger)index;
- (void)_disposeOfVisibleViewsAndTellDelegate:(BOOL)tellDelegate;
- (NSInteger)_numberOfViewsPerPage;
- (void)_pageDidChange;
@end

@implementation FTPageScrollView2

@synthesize delegate;
@synthesize dataSource = _dataSource;
@synthesize visibleSize = _visibleSize;
@synthesize pageSize = _pageSize;
@synthesize internalPageSize = _internalPageSize;
@synthesize reuseView = _reuseView;

#pragma mark - Others

- (NSInteger)indexOfView:(UIView *)view
{
	for (FTPageView2 *page in _visibleViews) {
		if ([page.subviews objectAtIndex:0] == view) {
			return page.index;
		}
	}
	return NSNotFound;
}

- (UIView *)viewAtIndex:(NSUInteger)index
{
	for (FTPageView2 *page in _visibleViews) {
		if (page.index == index) {
			return [page.subviews objectAtIndex:0];
		}
	}
	return nil;
}

- (NSArray *)visibleViews
{
	NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"index" ascending:YES];
	NSArray *sortedPageViews = [_visibleViews sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
	[descriptor release];
	NSMutableArray *returnedViews = [[NSMutableArray new] autorelease];
	for (FTPageView2 *pageView in sortedPageViews) {
		[returnedViews addObject:pageView.subviews.lastObject];
	}
	return returnedViews;
}

#pragma mark - UI Handling

- (void)reloadData
{
	_numberOfPages = [_dataSource numberOfPagesInPageScrollView:self];
	if (_numberOfPages > 0) {
		self.contentSize = CGSizeMake(_numberOfPages * _internalPageSize.width, _internalPageSize.height);
		[self _disposeOfVisibleViewsAndTellDelegate:NO];
		[self _updateUIForCurrentHorizontalOffset];
	}
}

- (void)reloadPageNumber
{
	NSInteger numberOfPages = [_dataSource numberOfPagesInPageScrollView:self];
	if (numberOfPages != _numberOfPages) {
		_numberOfPages = numberOfPages;
		self.contentSize = CGSizeMake(_numberOfPages * _internalPageSize.width, _internalPageSize.height);
	}
}

- (void)scrollToPageAtIndex:(NSInteger)index animated:(BOOL)animated
{
	if (animated && index != self.selectedIndex) [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	CGFloat xOffset = index * _internalPageSize.width;
	if (index != 0 && self.contentSize.width - xOffset < self.bounds.size.width) {
		xOffset = self.contentSize.width - self.bounds.size.width;
	}
	[self setContentOffset:CGPointMake(xOffset, 0) animated:animated];
}

- (NSInteger)_numberOfViewsPerPage
{
	NSInteger number = self.bounds.size.width / _internalPageSize.width;
	return number + 1;
}

- (FTPageView2 *)_viewForIndex:(NSInteger)index
{
	UIView *finalView = nil;
	
	if (!_dataSourceProvidesViews) {
		UIImageView *reusedImageView = [_reusableViews anyObject];
		if (reusedImageView == nil) {
			reusedImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
			reusedImageView.userInteractionEnabled = YES;
		}
		else {
			[reusedImageView retain];
			[_reusableViews removeObject:reusedImageView];
		}
		UIImage *buttonImage = [_dataSource pageScrollView:self imageForPageAtIndex:index];
		[reusedImageView setImage:buttonImage];
		[reusedImageView sizeToFit];
		finalView = reusedImageView;
	}
	else {
		UIView *reusedView = [_reusableViews anyObject];
		if ([reusedView respondsToSelector:@selector(prepareForReuse)]) {
			[(id <FTReusableView>)reusedView prepareForReuse];
		}
		reusedView = [_dataSource pageScrollView:self viewForPageAtIndex:index reusedView:reusedView];	
		reusedView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		finalView = [reusedView retain];
		[_reusableViews removeObject:reusedView];
	}
	
	FTPageView2 *containerView = [_reusableContainers anyObject];
	if (containerView == nil) {
		containerView = [[FTPageView2 alloc] initWithFrame:CGRectMake(0, 0, _internalPageSize.width, _internalPageSize.height)];
		if (self.pagingEnabled) {
			containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		}
		else {
			containerView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		}
	}
	else {
		[containerView retain];
		[_reusableContainers removeObject:containerView];
	}
	
	[containerView setWidth:_internalPageSize.width];
	[containerView setHeight:_internalPageSize.height];
	
	[containerView positionAtX:index * _internalPageSize.width];
	containerView.index = index;
	[containerView addSubview:finalView];
	[finalView centerInSuperView];
	[finalView release];
	
	return [containerView autorelease];
}

- (void)_updateUIForCurrentHorizontalOffset
{
	CGFloat xOffset = self.contentOffset.x;
	
	CGFloat minVisibleXOffset = xOffset - _visibleHorizontalPadding;
	CGFloat maxVisibleXOffset = minVisibleXOffset + _visibleHorizontalPadding * 2 + SCROLL_VIEW_WIDTH_FT - 1;
	NSInteger minVisibleIndex = minVisibleXOffset / _internalPageSize.width;
	NSInteger maxVisibleIndex = maxVisibleXOffset / _internalPageSize.width;	

	if (minVisibleIndex < 0) minVisibleIndex = 0;
	if (maxVisibleIndex >= _numberOfPages) maxVisibleIndex = _numberOfPages - 1;

	NSMutableSet *newVisibleViews = [NSMutableSet new];
	for (int i = minVisibleIndex; i<= maxVisibleIndex; i++) {
		FTPageView2 *existingView = nil;
		for (FTPageView2 *pageView in _visibleViews) {
			if (pageView.index == i) {
				existingView = pageView;
				break;
			}
		}
		if (existingView) {
			[newVisibleViews addObject:existingView];
			[_visibleViews removeObject:existingView];
		}
		else {
			FTPageView2 *newView = [self _viewForIndex:i];
			[self addSubview:newView];
			[newVisibleViews addObject:newView];
		}
	}
	[self _disposeOfVisibleViewsAndTellDelegate:YES];
	[_visibleViews release];
	_visibleViews = newVisibleViews;
}
			 
- (void)_disposeOfVisibleViewsAndTellDelegate:(BOOL)tellDelegate
{
	BOOL delegateImplementMethod = [_pageScrollViewDelegate respondsToSelector:@selector(pageScrollView:willDiscardView:)];
	
	for (FTPageView2 *pageView in _visibleViews) {
		
		[pageView removeFromSuperview];
		UIView *contentView = pageView.subviews.lastObject;
		if ([contentView respondsToSelector:@selector(willBeDiscarded)]) {
			[(id <FTReusableView>)contentView willBeDiscarded];
		}
		if (tellDelegate && delegateImplementMethod) {
			[_pageScrollViewDelegate pageScrollView:self willDiscardView:contentView];
		}
		if (_reusableViews.count < [self _numberOfViewsPerPage] && _reuseView) {
			[_reusableViews addObject:contentView];
			[_reusableContainers addObject:pageView];
		}
		[contentView removeFromSuperview];
	}
	[_visibleViews removeAllObjects];
}

-(void)_pageDidChange
{
	if ([_pageScrollViewDelegate respondsToSelector:@selector(pageScrollView:didSlideToIndex:)]) {
		[_pageScrollViewDelegate pageScrollView:self didSlideToIndex:[self selectedIndex]];
	}
	if ([_pageScrollViewDelegate respondsToSelector:@selector(pageScrollView:didScrollToView:atIndex:)]) {
		UIView *page = [[self visibleViews] lastObject];
		[_pageScrollViewDelegate pageScrollView:self didScrollToView:page atIndex:[self selectedIndex]];
	}
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint startPoint = [[touches anyObject] locationInView:self];
	_varianceRect = CGRectMake(startPoint.x, startPoint.y, 0, 0);
	
	[super touchesBegan:touches withEvent:event];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint point = [[touches anyObject] locationInView:self];
	CGRect newRect = CGRectMake(point.x, point.y, 0, 0);
	_varianceRect = CGRectUnion(_varianceRect, newRect);
	[super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint point = [[touches anyObject] locationInView:self];
	CGRect newRect = CGRectMake(point.x, point.y, 0, 0);
	_varianceRect = CGRectUnion(_varianceRect, newRect);
	
	if (_varianceRect.size.height < 20 && _varianceRect.size.width < 20) {
		
		for (UIView *v in _visibleViews) {
			if (CGRectContainsPoint(v.frame, point)) {
				if ([_pageScrollViewDelegate respondsToSelector:@selector(pageScrollView:didSelectView:atIndex:)]) {
					[_pageScrollViewDelegate pageScrollView:self didSelectView:v atIndex:v.tag];
				}
				break;
			}
		}
	}
	[super touchesEnded:touches withEvent:event];
}

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		self.pagingEnabled = YES;
		self.showsHorizontalScrollIndicator = NO;
		self.delaysContentTouches = YES;
		self.canCancelContentTouches = YES;
		[super setDelegate:self];
		self.scrollsToTop = NO;
		_reuseView = YES;
		self.visibleSize = frame.size;
		_numberOfPages = -1;
		_dataSourceProvidesViews = NO;
		_reusableViews = [NSMutableSet new];
		_reusableContainers = [NSMutableSet new];
	}
	return self;
}

- (void)setFrame:(CGRect)frame
{
	NSInteger selectedIndex = [self selectedIndex];
	[super setFrame:frame];
	if (self.pagingEnabled) {
		_internalPageSize = self.bounds.size;
	}
	self.contentSize = CGSizeMake(_numberOfPages * _internalPageSize.width, SCROLL_VIEW_HEIGHT_FT);
	[self scrollToPageAtIndex:(selectedIndex < 0) ? 0 : selectedIndex animated:NO];
	[self _updateUIForCurrentHorizontalOffset];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
	if (_numberOfPages == -1 && newSuperview) {
		[self reloadData];
	}
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
	if (newWindow == nil) {
		[self _disposeOfVisibleViewsAndTellDelegate:YES];
	}
}

- (void)setPagingEnabled:(BOOL)pagingEnabled
{
	[super setPagingEnabled:pagingEnabled];
	if (pagingEnabled) {
		_internalPageSize = self.bounds.size;
	}
	else {
		_internalPageSize = _pageSize;
	}
}

- (void)dealloc
{
	[_visibleViews release];
	[_reusableViews release];
	[_reusableContainers release];
	[super dealloc];
}

#pragma mark - Getters

- (NSInteger)selectedIndex
{
    NSInteger index = self.contentOffset.x / _internalPageSize.width;
    if (index < 0) index = 0;
    if (index > _numberOfPages - 1) index = _numberOfPages - 1;
	
    return index;
}

- (UIView *)selectedView
{
	NSInteger index = [self selectedIndex];
	for (FTPageView2 *v in _visibleViews) {
		if (v.index == index) return v.subviews.lastObject;
	}
	return nil;
}

- (id <FTPageScrollView2Delegate>)delegate
{
	return _pageScrollViewDelegate;
}

#pragma mark - Setters

- (void)setVisibleSize:(CGSize)size
{	
	if (size.width > self.frame.size.width) {
		self.clipsToBounds = NO;
	}
	else {
		self.clipsToBounds = YES;
	}

	_visibleSize = size;
	_visibleHorizontalPadding = (size.width - self.frame.size.width) / 2;
}

- (void)setPageSize:(CGSize)pageSize
{
	_pageSize = pageSize;
	if (!self.pagingEnabled) _internalPageSize = pageSize;
}

- (void)setDataSource:(id <FTPageScrollView2DataSource>)d
{
	_dataSource = d;
	if ([_dataSource respondsToSelector:@selector(pageScrollView:viewForPageAtIndex:reusedView:)]) {
		_dataSourceProvidesViews = YES;
	}
	else {
		_dataSourceProvidesViews = NO;
	}
}

- (void)setDelegate:(id<FTPageScrollView2Delegate>)d
{
	_pageScrollViewDelegate = d;
}

#pragma mark - Scroll View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self _updateUIForCurrentHorizontalOffset];
	if ([_pageScrollViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
		[_pageScrollViewDelegate scrollViewDidScroll:self];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self _pageDidChange];
	if ([_pageScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
		[_pageScrollViewDelegate scrollViewDidEndDecelerating:self];
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	if ([_pageScrollViewDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
		[_pageScrollViewDelegate scrollViewWillBeginDragging:scrollView];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) {
		[self _pageDidChange];
	}
	if ([_pageScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
		[_pageScrollViewDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
	}
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
	if ([_pageScrollViewDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
		[_pageScrollViewDelegate scrollViewWillBeginDecelerating:scrollView];
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	if([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}
	if ([_pageScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
		[_pageScrollViewDelegate scrollViewDidEndScrollingAnimation:scrollView];
	}
	[self _pageDidChange];
}

@end