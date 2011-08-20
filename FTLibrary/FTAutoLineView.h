//
//  FTAutoLineView.h
//  FTLibrary
//
//  Created by Ondrej Rafaj on 02/05/2011.
//  Copyright 2011 Fuerte International. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FTView.h"


@interface FTAutoLineView : FTView {
    
	BOOL enableSideSpace;
	
}

@property (nonatomic) BOOL enableSideSpace;


- (void)layoutElements;


@end
