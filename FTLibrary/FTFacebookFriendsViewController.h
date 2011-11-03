//
//  FTFacebookFriendsViewController.h
//  FTLibrary
//
//  Created by Ondrej Rafaj on 31/10/2011.
//  Copyright (c) 2011 Fuerte International. All rights reserved.
//

#import "FTFacebookViewController.h"


@interface FTFacebookFriendsViewController : FTFacebookViewController <UISearchBarDelegate, UIScrollViewDelegate> {
	
	NSMutableDictionary *sections;
	
	BOOL isSearching;
	
	NSMutableArray *searchArray;
	int lastSearchCharCount;
	
}

- (NSDictionary *)dictionaryForFriendAtIndexPath:(NSIndexPath *)indexPath;


@end
