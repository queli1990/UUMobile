//
//  ListViewController.m
//  Mobile_YoYoTV
//
//  Created by li que on 2017/5/22.
//  Copyright © 2017年 li que. All rights reserved.
//

#import "ListViewController.h"
#import "ListRequest.h"
#import "NavView.h"
#import "HomeHorizontalCollectionViewCell.h"
#import "PlayerViewController.h"
#import "Mobile_YoYoTV-Swift.h"
#import "LoginViewController.h"

@interface ListViewController () <UICollectionViewDelegate,UICollectionViewDataSource>
@property (nonatomic,strong) NSMutableArray *contentArray;
@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic) int requestPage;
@property (nonatomic) BOOL isFromPulling;
@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _requestPage = 1;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController setNavigationBarHidden:YES];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self setupNav];
    [self initCollectionView];
    [self requestData:_requestPage];
}

- (void) requestData:(int) page {
    [SVProgressHUD showWithStatus:@"loading"];
    ListRequest *request = [ListRequest new];
    request.ID = self.ID;
    request.currentPage = page;
    [request requestData:nil andBlock:^(ListRequest *responseData) {
        //NSLog(@"%@success",NSStringFromClass([self class]));
        if (responseData.responseData.count > 0) {
            if (_isFromPulling) {
                [self.contentArray removeAllObjects];
            }
            [self.contentArray addObjectsFromArray:responseData.responseData];
            [self.collectionView reloadData];
            _isFromPulling = NO;
            [self.collectionView.mj_footer endRefreshing];
            [self.collectionView.mj_header endRefreshing];
            if (responseData.totalCount == self.contentArray.count ) {
                self.collectionView.mj_footer.hidden = YES;
            } else {
                self.collectionView.mj_footer.hidden = NO;
            }
        } else {
            NoResultView *noResultView = [[NoResultView alloc] initWithFrame:CGRectMake(0, 64, ScreenWidth, ScreenHeight)];
            [self.view addSubview:noResultView];
        }
        [SVProgressHUD dismiss];
    } andFailureBlock:^(ListRequest *responseData) {
        //NSLog(@"%@fail",NSStringFromClass([self class]));
        [SVProgressHUD showWithStatus:@"请检查网络"];
        [self.collectionView.mj_footer endRefreshing];
        [self.collectionView.mj_header endRefreshing];
    }];
}

- (void) initCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat padding = 10;
    CGFloat itemWidth = (ScreenWidth-3*padding)/2.0;
    CGFloat itemHeight = itemWidth * (99.0/169.0)+22;
    layout.itemSize    = CGSizeMake(itemWidth, itemHeight); // 设置cell的宽高
    layout.minimumLineSpacing = 10.0;
    layout.minimumInteritemSpacing = 10.0;
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 64, ScreenWidth, ScreenHeight-64) collectionViewLayout:layout];
    [_collectionView registerClass:[HomeHorizontalCollectionViewCell class] forCellWithReuseIdentifier:@"HomeHorizontalCollectionViewCell"];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor whiteColor];
    //下拉刷新
    _collectionView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        _isFromPulling = YES;
        _requestPage = 1;
        [self requestData:_requestPage];
    }];
    //加载更多
    self.collectionView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        _requestPage += 1;
        [self requestData:_requestPage];
    }];
    
    [self.view addSubview:_collectionView];
}

#pragma mark UIColltionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.contentArray.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    HomeModel *model = self.contentArray[indexPath.row];
    BOOL isPay = ([[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP"] boolValue] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP499"] boolValue] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP199"] boolValue] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP299"] boolValue]);
    if (!isPay && model.pay) {
//        NSDictionary *dic = [[NSUserDefaults standardUserDefaults] objectForKey:@"userInfo"];
//        BOOL isLogin = dic;
//        if (isLogin) {
//            PurchaseViewController *vc = [PurchaseViewController new];
//            vc.isHideTab = YES;
//            [[PushHelper new] pushController:vc withOldController:self.navigationController andSetTabBarHidden:YES];
//        } else {
//            LoginViewController *vc = [LoginViewController new];
//            vc.isHide = YES;
//            [[PushHelper new] pushController:vc withOldController:self.navigationController andSetTabBarHidden:YES];
//        }
        PurchaseViewController *vc = [PurchaseViewController new];
        vc.isHideTab = NO;
        [[PushHelper new] pushController:vc withOldController:self.navigationController andSetTabBarHidden:YES];
    } else {
        PlayerViewController *vc = [[PlayerViewController alloc] init];
        vc.isHideTabbar = YES;
        vc.model = model;
        [[PushHelper new] pushController:vc withOldController:self.navigationController andSetTabBarHidden:YES];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HomeHorizontalCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HomeHorizontalCollectionViewCell" forIndexPath:indexPath];
    cell.model = self.contentArray[indexPath.row];
    return cell;
}

- (void) setupNav {
    NavView *nav = [[NavView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 64)];
    nav.titleLabel.text = self.titleName;
    [nav.backBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:nav];
}

- (void) backBtnClick:(UIButton *)btn {
    [[PushHelper new] popController:self WithNavigationController:self.navigationController andSetTabBarHidden:NO];
}

- (NSMutableArray *)contentArray {
    if (_contentArray == nil) {
        _contentArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _contentArray;
}






@end
