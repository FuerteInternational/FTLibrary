//
//  FTDragAndDropCanvasView.m
//  DDrop
//
//  Created by Ondrej Rafaj on 03/04/2011.
//  Copyright 2011 Fuerte International. All rights reserved.
//

#import "FTDragAndDropCanvasView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+Layout.h"


#define degreesToRadians(__ANGLE__) (M_PI * (__ANGLE__) / 180.0)
#define radiansToDegrees(__ANGLE__) (180.0 * (__ANGLE__) / M_PI)

#define kFTDragAndDropCanvasViewMinScale            0.15f * interfaceRotationFactor
#define kFTDragAndDropCanvasViewMaxScale            1.0f * interfaceRotationFactor
#define kFTDragAndDropCanvasViewSpeed               0.75f


@interface FTDragAndDropCanvasView (Private)

- (void)activateElement:(FTDragAndDropView *)element;
- (void)deleteElement:(FTDragAndDropView *)element;
- (void)configureElement:(FTDragAndDropView *)element;
- (void)didEditElement:(FTDragAndDropView *)element;

@end


@implementation FTDragAndDropCanvasView

@synthesize backgroundImageView;
@synthesize delegate;


#pragma mark Object lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		
		animatedLayout = NO;
		elements = [[NSMutableArray alloc] init];
		
		self.backgroundColor = [UIColor clearColor];
		
		backgroundImageView = [[UIImageView alloc] init];
		[self addSubview:backgroundImageView];
		
		stickersContainerView = [[UIView alloc] init];
		stickersContainerView.clipsToBounds = YES;
		[self addSubview:stickersContainerView];	
		
		UIImage *deleteImage = [UIImage imageNamed:@"DD_canvas-delete.png"];
		UIImage *highlightedDeleteImage = [UIImage imageNamed:@"DD_canvas-delet-highlighted.png"];
		deleteImageView = [[UIImageView alloc] initWithImage:deleteImage highlightedImage:highlightedDeleteImage];
		deleteImageView.hidden = YES;
		[stickersContainerView addSubview:deleteImageView];
    }
    return self;
}

- (void)dealloc {
    [elements release];
    [backgroundImageView release];
	[stickersContainerView release];
	[deleteImagePath release];
	[deleteImageView release];
    [super dealloc];
}

#pragma mark View lifecycle

- (void)layoutSubviews
{	
	if (self.bounds.size.height / self.bounds.size.width < 1) {
		//landscape
		interfaceRotationFactor = 1;
		[backgroundImageView setFrame:CGRectIntegral(backgroundImageRectLandscape)];
		[stickersContainerView setFrame:CGRectIntegral(backgroundImageRectLandscape)];
	}
	else {
		//portrait
		interfaceRotationFactor = backgroundImageRectPortrait.size.width / backgroundImageRectLandscape.size.width;
		[backgroundImageView setFrame:CGRectIntegral(backgroundImageRectPortrait)];
		[stickersContainerView setFrame:CGRectIntegral(backgroundImageRectPortrait)];
	}
	
	[deleteImageView centerInSuperView];
	[deleteImageView positionAtX:30];
	
	[deleteImagePath release];
	deleteImagePath = [[UIBezierPath bezierPathWithOvalInRect:[stickersContainerView convertRect:deleteImageView.frame toView:self]] retain];
		
	if (animatedLayout) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.6];
	}
	for (FTDragAndDropView *element in elements) {
		element.center = CGPointMake(element.positionX * interfaceRotationFactor, element.positionY * interfaceRotationFactor);
		CGAffineTransform rotation = CGAffineTransformMakeRotation(element.rotationValue);
		CGAffineTransform scaling = CGAffineTransformMakeScale(element.scaleValue * interfaceRotationFactor, element.scaleValue * interfaceRotationFactor);
		element.transform = CGAffineTransformConcat(rotation, scaling);
	}
	if (animatedLayout) {
		animatedLayout = NO;
		[UIView commitAnimations];
	}
}

#pragma mark Class level methods

- (UIImage *)imageWithSize:(CGSize)desiredSize andLogo:(UIImage *)logo
{
	CGSize imageSizePoints = backgroundImageView.image.size;
	
	//pixels 
	CGSize imageSize = CGSizeMake(imageSizePoints.width * backgroundImageView.image.scale, imageSizePoints.height * backgroundImageView.image.scale);
	
	CGFloat horizontalRatio = desiredSize.width / imageSize.width;
    CGFloat verticalRatio = desiredSize.height /imageSize.height;
    CGFloat ratio = MAX(horizontalRatio, verticalRatio);
	
    CGSize newImageSize = CGSizeMake(roundf(imageSize.width * ratio), roundf(imageSize.height * ratio));
	
	UIGraphicsBeginImageContextWithOptions(newImageSize, YES, 0.0);
	CGContextRef context = UIGraphicsGetCurrentContext();	
	
	[backgroundImageView.image drawInRect:CGRectMake(0, 0, newImageSize.width, newImageSize.height)];
	
	//the reference size is in landscape
	CGFloat horizontalRatio2 = newImageSize.width / 1024;
    CGFloat verticalRatio2 = newImageSize.height / 748;
    CGFloat newScaling = MAX(horizontalRatio2, verticalRatio2);
	
	for (FTDragAndDropView *element in elements) {
		CGPoint newCenter = CGPointMake(ceilf(element.positionX * newScaling), ceilf(element.positionY * newScaling));
		CGContextSaveGState(context);
		CGContextTranslateCTM(context, newCenter.x, newCenter.y);
		CGFloat scaleValue = element.scaleValue * newScaling;
		CGContextScaleCTM(context, scaleValue, scaleValue);
		CGFloat rotationValue = element.rotationValue;
		CGContextRotateCTM(context, rotationValue);
		
		UIImage *imageToDraw = element.imageView.image;
		[imageToDraw drawAtPoint:CGPointMake(-roundf((imageToDraw.size.width / 2)), -roundf((imageToDraw.size.height / 2)))];
		
		CGContextRestoreGState(context);
	}
	
	if (logo) {
 		int margin = MAX(newImageSize.width * 2.f / 100.f, newImageSize.height * 2.f / 100.f);
		CGSize logoSizePixels = CGSizeMake(logo.scale * logo.size.width, logo.scale * logo.size.height);
		int logoMaxSize = MAX(newImageSize.width * 20.f / 100.f, newImageSize.height * 20.f / 100.f);
		
		CGFloat ratio1 = logoMaxSize / logoSizePixels.height;
		CGFloat ratio2 = logoMaxSize / logoSizePixels.width;
		CGFloat logoRatio =  MIN(ratio1, ratio2);
		CGSize logoFinalSize = CGSizeMake(roundf(logoSizePixels.width * logoRatio), roundf(logoSizePixels.height * logoRatio));
		
		CGRect logoRect = CGRectMake(newImageSize.width - logoFinalSize.width - margin, 
									 newImageSize.height - logoFinalSize.height - margin,
									 logoFinalSize.width, logoFinalSize.height);
		[logo drawInRect:logoRect];
	}
	
	UIImage *returnedImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	//CGContextRelease(context);
	
	return returnedImage;
}

- (UIImage *)imageWithSize:(CGSize)desiredSize
{
	return [self imageWithSize:desiredSize andLogo:nil];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
	[backgroundImageView setImage:backgroundImage];
	CGSize imageSize = backgroundImage.size;
	//landscape
	CGFloat horizontalRatio = 1024 / imageSize.width;
    CGFloat verticalRatio = 748 / imageSize.height;
    CGFloat ratio = MIN(horizontalRatio, verticalRatio);
    CGSize newImageSize = CGSizeMake(imageSize.width * ratio, imageSize.height * ratio);
    backgroundImageRectLandscape = CGRectMake((1024 - newImageSize.width)/2, (748 - newImageSize.height)/2, newImageSize.width, newImageSize.height);
	backgroundImageRectLandscape = CGRectIntegral(backgroundImageRectLandscape);

	//portrait
	horizontalRatio = 768 / imageSize.width;
    verticalRatio = 1024 / imageSize.height;
    ratio = MIN(horizontalRatio, verticalRatio);
    newImageSize = CGSizeMake(imageSize.width * ratio, imageSize.height * ratio);
    backgroundImageRectPortrait = CGRectMake((768 - newImageSize.width)/2, (1024 - newImageSize.height)/2, newImageSize.width, newImageSize.height);
	backgroundImageRectPortrait = CGRectIntegral(backgroundImageRectPortrait);
	
	[self setNeedsLayout];
}

#pragma mark Animations

- (void)randomizeElementPosition:(FTDragAndDropView *)element animated:(BOOL)animated {
	CGPoint p = element.center;
	UIView *workingView = self.backgroundImageView;
	
	if (animated) [UIView beginAnimations:nil context:nil];
	
	// Rotation
	int degrees = ((arc4random() % 60) - 30);
	CGFloat rotation = degreesToRadians(degrees);
	element.transform = CGAffineTransformRotate(element.transform, rotation);
	element.rotationValue += rotation;
	
	// Scale
	int max = 70.0f;
	CGFloat min = (kFTDragAndDropCanvasViewMinScale * max);
	CGFloat scale = (((float)(arc4random() % (int)(max - min)) + min) / max);
	NSLog(@"New scale: %f", scale);
	if (scale < kFTDragAndDropCanvasViewMinScale) scale = kFTDragAndDropCanvasViewMinScale;
	element.transform = CGAffineTransformScale(element.transform, scale, scale);
	element.scaleValue = scale;
	
    // Position
	CGSize maxSize = CGSizeMake((workingView.size.width - element.size.width), (workingView.size.height - element.size.height));
    p = CGPointMake(((rand()% (int)maxSize.width) + (element.size.width / 2)), ((rand()% (int)maxSize.height) + (element.size.height / 2)));
    /*
    max = (int)([workingView width] - (2 * [element width]));
	NSLog(@"Max value (x): %d", max);
	p.x = ((arc4random() % max) + [element width]);
	if (p.x < 0 || p.x > [workingView width]) p.x = workingView.bounds.size.width / 2;
	max = (int)([workingView height] - (2 * [element height]));
	NSLog(@"Max value (y): %d", max);
	p.y = ((arc4random() % max) + [element height]);
	if (p.y < 0 || p.y > [workingView height]) p.y = workingView.bounds.size.height / 2;
	//*/
    
    
    NSLog(@"New random center: %@", NSStringFromCGPoint(p));
	element.positionX = p.x;
	element.positionY = p.y;
	[element setCenter:p];
	
	if (animated) [UIView commitAnimations];
	[self didEditElement:element];
}

#pragma mark Add/Remove Elements

- (void)addElementWithData:(NSDictionary *)data reversed:(BOOL)reversed
{
    FTDragAndDropView *element = [[FTDragAndDropView alloc] initWithImageData:data reversed:reversed];
    [self configureElement:element];
    [element release];
}

- (void)addElementWithData:(NSDictionary *)data
{
    [self addElementWithData:data reversed:NO];
}

- (void)addElementWithPath:(NSString *)imagePath withRandomPosition:(BOOL)randomPosition reversed:(BOOL)reversed
{
    FTDragAndDropView *element = [[FTDragAndDropView alloc] initWithImagePath:imagePath reversed:reversed];
	element.positionX = (self.bounds.size.width / 2);
	element.positionY = (self.bounds.size.height / 2);
    [self configureElement:element];
	[self randomizeElementPosition:element animated:YES];
	if ([delegate respondsToSelector:@selector(createdElement:withData:)]) {
		[delegate createdElement:element withData:element.elementData];
	}
	[self didEditElement:element];
    
    [element release];
}

- (void)addElementWithPath:(NSString *)imagePath reversed:(BOOL)reversed
{
    FTDragAndDropView *element = [[FTDragAndDropView alloc] initWithImagePath:imagePath reversed:reversed];

	if ([delegate respondsToSelector:@selector(createdElement:withData:)]) {
		[delegate createdElement:element withData:element.elementData];
	}

    [self configureElement:element];

	element.positionX = element.center.x / interfaceRotationFactor;
	element.positionY = element.center.y / interfaceRotationFactor;

	[self didEditElement:element];

    [element release];
}

- (void)addElementWithPath:(NSString *)imagePath
{
    [self addElementWithPath:imagePath reversed:NO];
}

- (void)addElementWithImage:(UIImage *)image {
	FTDragAndDropView *element = [[FTDragAndDropView alloc] initWithImage:image];
	element.positionX = self.bounds.size.width / 2;
	element.positionY = self.bounds.size.height / 2;
	if ([delegate respondsToSelector:@selector(createdElement:withData:)]) {
		[delegate createdElement:element withData:element.elementData];
	}
	[self didEditElement:element];
    [self configureElement:element];
    [element release];
}

- (void)configureElement:(FTDragAndDropView *)element
{
	if (!element) return;
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapElement:)];
    [tap2 setNumberOfTapsRequired:2];
    [tap2 setNumberOfTouchesRequired:1];
    [element addGestureRecognizer:tap2];
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapElement:)];
    [tap1 requireGestureRecognizerToFail:tap2];
    [tap2 release];
    [tap1 setNumberOfTapsRequired:1];
    [tap1 setNumberOfTouchesRequired:1];
    [element addGestureRecognizer:tap1];
    [tap1 release];
    
    UIRotationGestureRecognizer *rot = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateView:)];
    [rot setDelegate:self];
    [element addGestureRecognizer:rot];
    [rot release];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveView:)];
    [rot setDelegate:self];
    [pan setMinimumNumberOfTouches:1];
    [pan setMaximumNumberOfTouches:1];
    [element addGestureRecognizer:pan];
    [pan release];
	
	UILongPressGestureRecognizer *longTouch = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongTouch:)];
	[longTouch setDelegate:self];
	longTouch.minimumPressDuration = 1;
	[element addGestureRecognizer:longTouch];
	[longTouch release];
	
    UIPinchGestureRecognizer *pin = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(resizeView:)];
    [rot setDelegate:self];
    [element addGestureRecognizer:pin];
    [pin release];
    
    [elements addObject:element];

    [stickersContainerView addSubview:element];

	[element centerInSuperView];
    //[self activateElement:element];
}

- (void)deleteElement:(FTDragAndDropView *)element
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(removeElementToDelete)];
    [element setAlpha:0];
    [UIView commitAnimations];
}

- (void)highlightActiveElement
{
    [UIView beginAnimations:nil context:nil];
    for (FTDragAndDropView *e in elements) {
        if (e != activeElement) {
            [e setAlpha:1.0f];
        }
    }
    [activeElement setAlpha:0.85f];
    [UIView commitAnimations];
}

- (void)layoutElements:(BOOL)animated
{
	animatedLayout = animated;
	[self setNeedsLayout];
}

- (void)finishRemovingElements {
	for (FTDragAndDropView *e in elements) {
        [e removeFromSuperview];
    }
}

- (void)removeAllElements {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(finishRemovingElements)];
    for (FTDragAndDropView *e in elements) {
        [e setAlpha:0];
    }
    [UIView commitAnimations];
	[elements removeAllObjects];
}

#pragma mark Use Elements

- (void)activateElement:(FTDragAndDropView *)element
{
    if (element != activeElement) {
        activeElement = element;
        [self highlightActiveElement];
    }
}

- (void)disableActiveElement
{
    if (activeElement) {
		[UIView beginAnimations:nil context:nil];
        [activeElement setAlpha:1];
		[UIView commitAnimations];
		
        activeElement = nil;
    }
}

- (void)removeElementToDelete
{
    if (elementToDelete) {
        [elementToDelete removeFromSuperview];
		if ([delegate respondsToSelector:@selector(deleteElement:withData:)]) {
			[delegate deleteElement:elementToDelete withData:[elementToDelete getInfo]];
		}
		[elements removeObject:elementToDelete];
        elementToDelete = nil;
    }
}

- (void)didEditElement:(FTDragAndDropView *)element {
	[self disableActiveElement];
    if ([delegate respondsToSelector:@selector(finishedEditingElement:withData:)]) {
        [delegate finishedEditingElement:element withData:[element getInfo]];
    }
}

#pragma mark Gesture delegate methods

- (void)handleTap:(UITapGestureRecognizer *)tap {
    if (tap.view != activeElement) [self activateElement:(FTDragAndDropView *)tap.view];
    else [self disableActiveElement];
}

- (void)handleLongTouch:(UILongPressGestureRecognizer *)tap {
	FTDragAndDropView *v = (FTDragAndDropView *)tap.view;
	[self activateElement:v];
	if (tap.state == UIGestureRecognizerStateBegan) {
		[deleteImageView setAlpha:0];
		[deleteImageView setHidden:NO];
		
		[UIView beginAnimations:nil context:nil];
		[deleteImageView setAlpha:1];
		[UIView commitAnimations];			
		
		[stickersContainerView bringSubviewToFront:deleteImageView];
		
		[stickersContainerView bringSubviewToFront:v];
	}
	else if (tap.state == UIGestureRecognizerStateEnded) {
		if (!v.isDragged) [deleteImageView setHidden:YES];
		deleteImageView.highlighted = NO;
		[self disableActiveElement];
	}
}

- (void)didTapElement:(UITapGestureRecognizer *)recognizer {
    
}

- (void)didDoubleTapElement:(UITapGestureRecognizer *)recognizer {
    FTDragAndDropView *v = (FTDragAndDropView *)recognizer.view;
    [stickersContainerView bringSubviewToFront:v];
	[elements removeObject:v];
	[elements addObject:v];
    if ([delegate respondsToSelector:@selector(sentElementToTheFront:withData:)]) {
		NSMutableArray *arr = [NSMutableArray array];
		for (FTDragAndDropView *v in elements) {
			[arr addObject:[v getInfo]];
		}
		[delegate sentElementToTheFront:v withData:arr];
	}
}

static CGFloat tempRotation = 0;

- (void)rotateView:(UIRotationGestureRecognizer *)recognizer {
    FTDragAndDropView *v = (FTDragAndDropView *)recognizer.view;
	[self activateElement:v];
	
	if([(UIRotationGestureRecognizer*)recognizer state] == UIGestureRecognizerStateEnded) {
		tempRotation = 0;
		v.rotationValue += [recognizer rotation];
		[self didEditElement:v];
		return;
	}
	CGFloat rotation = 0.0 - (tempRotation - [recognizer rotation]);
	v.transform = CGAffineTransformRotate(v.transform, rotation);
	
	tempRotation = [recognizer rotation];
}

- (void)moveView:(UIPanGestureRecognizer *)recognizer {

	FTDragAndDropView *v = (FTDragAndDropView *)recognizer.view;

    [self activateElement:v];

	if([recognizer state] == UIGestureRecognizerStateBegan) {

		v.dragged = YES;
	}

	CGPoint translatedPoint = [recognizer translationInView: stickersContainerView];
    
    //NSLog(@"point: %@, VPX: %f, View: %@, IRF: %f", NSStringFromCGPoint(translatedPoint), v.positionX, NSStringFromCGRect(v.frame), interfaceRotationFactor);

	translatedPoint = CGPointMake(v.positionX * interfaceRotationFactor + translatedPoint.x, v.positionY * interfaceRotationFactor + translatedPoint.y);

	//NSLog(@"Computed point: %@", NSStringFromCGPoint(translatedPoint));

	CGRect newElementFrame;
	newElementFrame.size = v.bounds.size;
	newElementFrame.origin = CGPointMake(translatedPoint.x - newElementFrame.size.width / 2, translatedPoint.y - newElementFrame.size.height / 2);
	CGRect minimumInsideRectangle = CGRectInset(newElementFrame, 0.2 * newElementFrame.size.width, 0.2 * newElementFrame.size.height);

	if (!CGRectIsNull(CGRectIntersection(minimumInsideRectangle, stickersContainerView.bounds))) {
		[v setCenter:translatedPoint];
	}
	
	CGPoint locationInSelf = [recognizer locationInView:self];
	BOOL shouldDelete = NO;
	
	if (!deleteImageView.hidden && [deleteImagePath containsPoint:locationInSelf]) {
		deleteImageView.highlighted = YES;
		shouldDelete = YES;
	}
	else {
		deleteImageView.highlighted = NO;		
	}
	
	if ([recognizer state] == UIGestureRecognizerStateEnded) {
		v.positionX = [v center].x / interfaceRotationFactor;
		v.positionY = [v center].y / interfaceRotationFactor;
		[self didEditElement:v];
		deleteImageView.hidden = YES;
		deleteImageView.highlighted = NO;

		v.dragged = NO;
		if (shouldDelete) {
			elementToDelete = v;
			[self deleteElement:v];
		}
		else {
			NSInteger viewHierachyIndex = [elements indexOfObject:v];
			[stickersContainerView insertSubview:v atIndex:viewHierachyIndex]; 
		}

		[self disableActiveElement];
	}
}

- (void)resizeView:(UIPinchGestureRecognizer *)recognizer    {
	FTDragAndDropView *v = (FTDragAndDropView *)recognizer.view;
	[self activateElement:v];
	
	CGFloat currentScale = [[v.layer valueForKeyPath:@"transform.scale"] floatValue];
	if ([recognizer state] == UIGestureRecognizerStateBegan || [recognizer state] == UIGestureRecognizerStateChanged) {
		CGFloat newScale = 1 -  (v.scaleValue * interfaceRotationFactor - [recognizer scale]) * (kFTDragAndDropCanvasViewSpeed);
		newScale = MIN(newScale, kFTDragAndDropCanvasViewMaxScale / currentScale);   
		newScale = MAX(newScale, kFTDragAndDropCanvasViewMinScale / currentScale);
		CGAffineTransform savedTransform = v.transform;
		CGFloat actualScale = [[v.layer valueForKeyPath:@"transform.scale.x"] floatValue];
		
		v.transform = CGAffineTransformScale([v transform], newScale, newScale);
		if ([[v.layer valueForKeyPath:@"transform.scale.x"] floatValue] < kFTDragAndDropCanvasViewMinScale)
		{
			CGFloat scaleToMinimum = kFTDragAndDropCanvasViewMinScale / actualScale;
			v.transform = CGAffineTransformScale(savedTransform, scaleToMinimum, scaleToMinimum);
		}
		else if ([[v.layer valueForKeyPath:@"transform.scale.x"] floatValue] > kFTDragAndDropCanvasViewMaxScale)
		{
			CGFloat scaleToMaximum = kFTDragAndDropCanvasViewMaxScale / actualScale;
			v.transform = CGAffineTransformScale(savedTransform, scaleToMaximum, scaleToMaximum);
		}
		
		v.scaleValue = [recognizer scale] / interfaceRotationFactor;
	}
	if([recognizer state] == UIGestureRecognizerStateEnded) {
		currentScale = [[v.layer valueForKeyPath:@"transform.scale.x"] floatValue];
		v.scaleValue = currentScale / interfaceRotationFactor;
		[self didEditElement:v];
		[self disableActiveElement];
	}
}

#pragma mark Gestur Recognizer delegate method

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
