//
//  SearchResultView.h
//  Mobile_YoYoTV
//
//  Created by li que on 2017/5/25.
//  Copyright © 2017年 li que. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HomeCollectionViewCell.h"

@interface SearchResultView : UIView

typedef void (^callBackSelectedItem)(HomeModel *model);

@property (nonatomic,copy) NSString *keyword;
@property (nonatomic,copy) callBackSelectedItem passHomeModel;

- (void) requestData ;

@end
