//
//  PlayRecordTableViewCell.h
//  Mobile_YoYoTV
//
//  Created by li que on 2017/11/24.
//  Copyright © 2017年 li que. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HomeModel.h"

@interface PlayRecordTableViewCell : UITableViewCell

@property (nonatomic,strong) UIImageView *sumImageView;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UILabel *timeLabel;
@property (nonatomic,strong) HomeModel *model;
@property (nonatomic,strong) UIImageView *vipImgView;

@end
