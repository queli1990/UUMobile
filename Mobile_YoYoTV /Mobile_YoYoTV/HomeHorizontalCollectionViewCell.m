//
//  HomeHorizontalCollectionViewCell.m
//  Mobile_YoYoTV
//
//  Created by li que on 2017/12/14.
//  Copyright © 2017年 li que. All rights reserved.
//

#import "HomeHorizontalCollectionViewCell.h"

@implementation HomeHorizontalCollectionViewCell

- (instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.sumImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height-5-17)];
        self.vipImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _vipImgView.image = [UIImage imageNamed:@"VIP.png"];
        [_sumImageView addSubview:_vipImgView];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_sumImageView.frame)+5, frame.size.width, 17)];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = UIColorFromRGB(0x808080, 1.0);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:12.0];
        
        [self.contentView addSubview:_sumImageView];
        [self.contentView addSubview:_titleLabel];
    }
    return self;
}

- (void)setModel:(HomeModel *)model {
    _model = model;
    _titleLabel.text = model.name;
    if (model.pay) {
        self.vipImgView.hidden = NO;
    } else {
        self.vipImgView.hidden = YES;
    }
    [self.sumImageView sd_setImageWithURL:[NSURL URLWithString:model.landscape_poster_s] placeholderImage:[UIImage imageNamed:@"placeholder_16_9"]];
}








@end
