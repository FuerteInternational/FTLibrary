//
//  CPCoreTextView.h
//  FTLibrary
//
//  Created by Francesco Freezone <cescofry@gmail.com> on 20/07/2011.
//  Copyright 2011 Fuerte International. All rights reserved.
//

//     Special markers:
//     _default: It is the default applied to the whole text. Markups is not needed on the text
//     _page: Divide the text in pages. Respond to markup <_page/>
//     _bullet: define styles for bullets. Respond to Markups <bullets />
//     _image: define style for images. Respond to markup <_image>imageNameOnBundle.extension</_image>
//     _link: define style for links. Respond to markup <_link>link_target|link name</_link>
 

#import <UIKit/UIKit.h>
#import "FTCoreTextStyle.h"
#import <CoreText/CoreText.h>

@protocol FTCoreTextViewDelegate;
@interface FTCoreTextView : UIView {
    NSString *_text;
    @private
	NSMutableDictionary *_styles;
    NSMutableArray		*_markers;
    FTCoreTextStyle		*_defaultStyle;
    NSMutableString		*_processedString;
    CGPathRef			_path;
    CGContextRef        _context;
    CTFramesetterRef	_framesetter;
	BOOL				_changesMade;
    NSMutableDictionary *_URLs;
    NSMutableDictionary *_images;
    id<FTCoreTextViewDelegate> _delegate;
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSMutableArray *markers;
@property (nonatomic, retain) FTCoreTextStyle *defaultStyle;
@property (nonatomic, retain) NSMutableString *processedString;
@property (nonatomic, assign) CGPathRef path;
@property (nonatomic, assign) CGContextRef context;
@property (nonatomic, retain) NSMutableDictionary *uRLs;
@property (nonatomic, retain) NSMutableDictionary *images;
@property (nonatomic, assign) id<FTCoreTextViewDelegate> delegate;


- (id)initWithFrame:(CGRect)frame;

- (void)setStyles:(NSDictionary *)styles __deprecated;


- (void)addStyle:(FTCoreTextStyle *)style;
- (void)addStyles:(NSArray *)styles;

- (NSArray *)stylesArray;

+ (NSString *)stripTagsforString:(NSString *)string;
+ (NSArray *)pagesFromText:(NSString *)string;

- (CGSize)suggestedSizeConstrainedToSize:(CGSize)size;
- (void)fitToSuggestedHeight;

@end

@protocol FTCoreTextViewDelegate <NSObject>
@optional
- (void)touchedData:(NSDictionary *)data inCoreTextView:(FTCoreTextView *)textView;

@end
