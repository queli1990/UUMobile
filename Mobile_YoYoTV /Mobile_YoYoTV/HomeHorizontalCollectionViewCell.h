//
//  HomeHorizontalCollectionViewCell.h
//  Mobile_YoYoTV
//
//  Created by li que on 2017/12/14.
//  Copyright © 2017年 li que. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HomeModel.h"

@interface HomeHorizontalCollectionViewCell : UICollectionViewCell

@property (nonatomic,strong) UIImageView *sumImageView;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) HomeModel *model;
@property (nonatomic,strong) UIImageView *vipImgView;

@end
