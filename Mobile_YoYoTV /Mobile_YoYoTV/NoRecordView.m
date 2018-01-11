//
//  NoRecordView.m
//  Mobile_YoYoTV
//
//  Created by li que on 2018/1/11.
//  Copyright © 2018年 li que. All rights reserved.
//

#import "NoRecordView.h"

@implementation NoRecordView

- (instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        CGFloat gap = 20;
        CGFloat labelHeight = 20;
        CGFloat imgHeight = 85;
        CGFloat originalHeight = (ScreenHeight-64-gap-labelHeight-imgHeight)/2;
        
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake((ScreenWidth-123)/2, originalHeight, 123, imgHeight)];
        imgView.image = [UIImage imageNamed:@"noRecord"];
        
        UILabel *alertLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(imgView.frame)+gap, ScreenWidth, 20)];
        alertLabel.textColor = UIColorFromRGB(0xFFBE7D, 1.0);
        alertLabel.text = @"暂未播放，快播放你喜欢的影片吧";
        alertLabel.textAlignment = NSTextAlignmentCenter;
        alertLabel.font = [UIFont systemFontOfSize:14.0];
        
        [self addSubview:imgView];
        [self addSubview:alertLabel];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
