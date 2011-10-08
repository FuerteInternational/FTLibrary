//
//  FTDragDropCropElementView.h
//  Regaine
//
//  Created by Ondrej Rafaj on 11/04/2011.
//  Copyright 2011 Fuerte International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface FTDragDropCropElementView : UIImageView {
    
    CGFloat positionX;
	CGFloat positionY;

}

@property (nonatomic) CGFloat positionX;
@property (nonatomic) CGFloat positionY;


@end
