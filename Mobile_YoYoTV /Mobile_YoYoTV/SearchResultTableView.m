//
//  SearchResultTableView.m
//  Mobile_YoYoTV
//
//  Created by li que on 2017/11/24.
//  Copyright © 2017年 li que. All rights reserved.
//

#import "SearchResultTableView.h"
#import "SearchResultRequest.h"

@interface SearchResultTableView() <UITableViewDelegate,UITableViewDataSource>
@property (nonatomic,strong) NSArray *contentArray;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NoResultView *noResultView;
@property (nonatomic) CGFloat height;
@end

@implementation SearchResultTableView

- (instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:_noResultView];
        _noResultView.hidden = YES;
        _height = frame.size.height;
    }
    return self;
}

- (void) requestData {
    SearchResultRequest *request = [[SearchResultRequest alloc] init];
    request.keyword = [self.keyword stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];
    [request requestData:nil andBlock:^(SearchResultRequest *responseData) {
        NSLog(@"success---%@",NSStringFromClass([self class]));
        self.contentArray = responseData.responseData;
        if (_contentArray.count > 0) {
            _noResultView.hidden = YES;
            _tableView.hidden = NO;
            if (_tableView) {
                [_tableView reloadData];
            } else {
                [self initTableView];
            }
        } else {
            _tableView.hidden = YES;
        }
    } andFailureBlock:^(SearchResultRequest *responseData) {
        NSLog(@"fail---%@",NSStringFromClass([self class]));
    }];
}

- (void) initTableView {
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, _height) style:UITableViewStylePlain];
    [_tableView registerClass:[PlayRecordTableViewCell class] forCellReuseIdentifier:@"PlayRecordTableViewCell"];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_tableView];
}

#pragma mark Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.contentArray.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    HomeModel *model = _contentArray[indexPath.row];
    _passHomeModel(model);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PlayRecordTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PlayRecordTableViewCell" forIndexPath:indexPath];
    cell.model = self.contentArray[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (NoResultView *)noResultView {
    if (_noResultView == nil) {
        _noResultView = [[NoResultView alloc] initWithFrame:CGRectMake(0, 64, ScreenWidth, _height)];
    }
    return _noResultView;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
