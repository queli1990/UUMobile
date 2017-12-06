//
//  MainCollectionTableViewCell.m
//  Mobile_YoYoTV
//
//  Created by li que on 2017/11/30.
//  Copyright © 2017年 li que. All rights reserved.
//

#import "MainCollectionTableViewCell.h"

@implementation MainCollectionTableViewCell

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        //height = 90
        CGFloat horGap = 16.0;//水平间隙
        CGFloat verGap = 6.0;//竖直间隙
        CGFloat leftGap = 15.0;//默认的最左端的间距
        CGFloat totalHeight = 90.0;//总高
        
        self.sumImageView = [[UIImageView alloc] initWithFrame:CGRectMake(leftGap, (totalHeight-72)/2, 125, 72)];
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_sumImageView.frame)+horGap, (totalHeight-18*2-verGap)/2, ScreenWidth-CGRectGetMaxX(_sumImageView.frame)-horGap-leftGap, 18)];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        _titleLabel.textColor = UIColorFromRGB(0x4A4A4A, 1.0);
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(_titleLabel.frame.origin.x, CGRectGetMaxY(_titleLabel.frame)+verGap, _titleLabel.frame.size.width, 18)];
        _timeLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _timeLabel.textColor = UIColorFromRGB(0x9B9B9B, 1.0);
        self.vipImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _vipImgView.image = [UIImage imageNamed:@"VIP"];
        [_sumImageView addSubview:_vipImgView];
        
        UILabel *line = [[UILabel alloc] initWithFrame:CGRectMake(leftGap, 89, ScreenWidth-2*leftGap, 1)];
        line.backgroundColor = UIColorFromRGB(0xE6E6E6, 1.0);
        
        [self.contentView addSubview:_sumImageView];
        [self.contentView addSubview:_titleLabel];
        [self.contentView addSubview:_timeLabel];
        [self.contentView addSubview:line];
    }
    return self;
}

- (void)setModel:(CollectionModel *)model {
    _model = model;
    _titleLabel.text = model.albumTitle;
    _timeLabel.text = @"";
    if (model.pay) {
        self.vipImgView.hidden = NO;
    } else {
        self.vipImgView.hidden = YES;
    }
    [self.sumImageView sd_setImageWithURL:[NSURL URLWithString:model.albumImg] placeholderImage:[UIImage imageNamed:@"placeholder_16_9"]];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
