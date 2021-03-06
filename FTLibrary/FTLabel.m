//
//  FTLabel.m
//  FTLibrary
//
//  Created by Francesco on 22/07/2011.
//  Copyright 2011 Fuerte International. All rights reserved.
//

#import "FTLabel.h"
#import "UILabel+DynamicHeight.h"
#import "FTCoreTextView.h"
#import "UIView+Layout.h"

@interface FTLabel ()
+ (FTCoreTextAlignement)FTCoreTextAlignementFromUITextAlignment:(UITextAlignment)alignment;
@end
	
@implementation FTLabel

@synthesize leading = _leading;
@synthesize letterSpacing = _letterSpacing;


- (void)rightAnchorToX:(CGFloat)x {
    if (!self.superview) return;
    
    CGRect frame = self.frame;
    frame.origin.x = x - frame.size.width;
    [self setFrame:frame];
}

#pragma Initialization

- (void)doInit {
	[self setBackgroundColor:[UIColor clearColor]];
	[self setLineBreakMode:UILineBreakModeWordWrap];
    [self setLeading:0];
    [self setLetterSpacing:0];
}

- (id)init {
    self = [super init];
    if (self) {
        [self doInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self doInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self doInit];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame font:(UIFont *)font andText:(NSString *)text {
    CGSize textSize = [text sizeWithFont:font constrainedToSize:CGSizeMake(frame.size.width, CGFLOAT_MAX)];
	frame.size.height = textSize.height;
    self = [self initWithFrame:frame];
    if (self) {
        [self doInit];
		[self setNumberOfLines:0];
		[self setFont:font];
		[self setText:text];
    }
    return self;
}

- (void)sizeToFitWidth
{
	CGSize size = [self.text sizeWithFont:self.font constrainedToSize:CGSizeMake(self.bounds.size.width, MAXFLOAT) lineBreakMode:self.lineBreakMode];
	self.size = size;
}

#pragma mark leading setters

- (CGFloat)leading {
    if (_leading > 0) return _leading;
    else return self.font.leading;
}

- (void)setLeading:(CGFloat)leading {
    _leading = leading;
    if (_leading > 0) {
        [self setNeedsDisplay];
    }
}

- (void)setText:(NSString *)text {
    [super setText:text];
    [self setNeedsDisplay];
}

#pragma mark drawrect
///*
- (void)drawRect:(CGRect)rect {
    
    if (_leading > 0) {
           
        FTCoreTextView *ctview = [[FTCoreTextView alloc] initWithFrame:self.bounds];
        
        float leadingDiff = self.leading - self.font.leading;
        
        NSLog(@"LEADING custom : %.1f font: %.1f", self.leading, self.font.leading);
        
        FTCoreTextStyle *defaultS = [[FTCoreTextStyle alloc] init];
        [defaultS setName:@"_default"];
        [defaultS setFont:self.font];
        [defaultS setColor:self.textColor];
        [defaultS setTextAlignment:[FTLabel FTCoreTextAlignementFromUITextAlignment:self.textAlignment]];
        if (leadingDiff > 0)[defaultS setLeading:leadingDiff];
        else [defaultS setMaxLineHeight:self.leading];
        [defaultS setLeading:self.leading];
        [ctview addStyle:defaultS];
        [defaultS release];
        
        FTCoreTextStyle *preStyle = [[FTCoreTextStyle alloc] init];
        [preStyle setName:@"__pre"];
        [preStyle setFont:[UIFont systemFontOfSize:10]];
        [preStyle setColor:[UIColor clearColor]];
        [preStyle setMaxLineHeight:leadingDiff];
        [ctview addStyle:preStyle];
        [preStyle release];
        
        NSString *theText = self.text;
        if (leadingDiff < 0) {
            theText = [NSString stringWithFormat:@"<__pre>\n</__pre>%@", self.text];
        }
        [ctview setText: theText];
        
        [self addSubview:ctview];
    }
    else if (_letterSpacing > 0) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSelectFont (context, [self.font.fontName cStringUsingEncoding:NSASCIIStringEncoding], self.font.pointSize, kCGEncodingMacRoman);
        CGContextSetCharacterSpacing(context, self.letterSpacing);
        CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
        CGAffineTransform myTextTransform = CGAffineTransformScale(CGAffineTransformIdentity, 1.f, -1.f );
        CGContextSetTextMatrix (context, myTextTransform);
        
        // draw 1 but invisbly to get the string length.
        CGPoint p =CGContextGetTextPosition(context);
        float centeredY = (self.font.pointSize + (self.frame.size.height- self.font.pointSize)/2)-2;
        CGContextShowTextAtPoint(context, 0, centeredY, [self.text cStringUsingEncoding:NSASCIIStringEncoding], [self.text length]);
        CGPoint v =CGContextGetTextPosition(context);
        
        // calculate width and draw second one.
        float width = v.x - p.x;
        float centeredX =(self.frame.size.width- width)/2;
        CGContextSetFillColorWithColor(context, [self.textColor CGColor]);
        CGContextShowTextAtPoint(context, centeredX, centeredY, [self.text cStringUsingEncoding:NSASCIIStringEncoding], [self.text length]);
    }
    else {
       [super drawRect:rect]; 
    }
    

    
}
//*/

#pragma mark Memory management

- (void)dealloc {
    [super dealloc];
}


#pragma mark Alignment converter
+ (FTCoreTextAlignement)FTCoreTextAlignementFromUITextAlignment:(UITextAlignment)alignment {
    switch (alignment) {
        case UITextAlignmentLeft:
            return FTCoreTextAlignementLeft;
        case UITextAlignmentCenter: 
            return FTCoreTextAlignementCenter;
        case UITextAlignmentRight: 
            return FTCoreTextAlignementRight;
        default: 
            return FTCoreTextAlignementLeft;
    }
}


@end
