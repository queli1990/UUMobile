//
//  HomeViewController.m
//  Mobile_YoYoTV
//
//  Created by li que on 2017/5/3.
//  Copyright © 2017年 li que. All rights reserved.
//

#import "HomeViewController.h"

#import "HomeHeadCollectionReusableView.h"
#import "HomeHead_title_CollectionReusableView.h"
#import "HomeFootCollectionReusableView.h"
#import "HomeHorizontalCollectionViewCell.h"
#import "ListViewController.h"
#import "HomeRequest.h"
#import "PlayerViewController.h"
#import "StorageHelper.h"
#import "Mobile_YoYoTV-Swift.h"
#import "LoginViewController.h"


@interface HomeViewController () <UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,HomeCirculationScrollViewDelegate,UIScrollViewDelegate>
@property (nonatomic,strong) NSArray *storageArray;
@property (nonatomic,strong) NSArray *headArray;
@property (nonatomic,strong) NSMutableArray *contentArray;
@property (nonatomic,strong) NSMutableArray *titleArray;
@property (nonatomic,strong) UICollectionView *collectionView;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SearchHistory"];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController setNavigationBarHidden:YES];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self requestDataWithDictionary:nil];
}

- (void) requestDataWithDictionary:(NSDictionary *)dic {
    [SVProgressHUD showWithStatus:@"loading"];
    HomeRequest *requet = [[HomeRequest alloc] init];
    requet.currentIndex = self.currentIndex;
    [requet requestData:dic andBlock:^(HomeRequest *responseData) {
        self.headArray = responseData.responseHeadArray.count > 6 ? [responseData.responseHeadArray subarrayWithRange:NSMakeRange(0, 6)] : responseData.responseHeadArray;
        self.storageArray = responseData.responseHeadArray;//存储推荐列表的数组，以防详情页面没有推荐内容
        self.contentArray = responseData.responseDataArray;
        self.titleArray = responseData.titleArray;
        [self addStorageHelper];
        if (self.contentArray.count > 0) {
            [self initCollectionView];
        } else {
            if (_currentIndex) {
                NoResultView *noResultView = [[NoResultView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight-49)];
                [self.view addSubview:noResultView];
            }
        }
        [SVProgressHUD dismiss];
    } andFailureBlock:^(HomeRequest *responseData) {
        [SVProgressHUD showWithStatus:@"请检查网络"];
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
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight-20-44-49) collectionViewLayout:layout];
    [_collectionView registerClass:[HomeHorizontalCollectionViewCell class] forCellWithReuseIdentifier:@"HomeHorizontalCollectionViewCell"];
    [_collectionView registerClass:[HomeHeadCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HomeHeadCollectionReusableView"];
    [_collectionView registerClass:[HomeHead_title_CollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HomeHead_title_CollectionReusableView"];
    [_collectionView registerClass:[HomeFootCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"HomeFootCollectionReusableView"];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_collectionView];
}

#pragma mark - collectionView代理方法
//多少个分区
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.contentArray.count;
}

//每个分区有多少cell
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([_contentArray[section] count] > 6) {
        return 6;
    } else {
        return [_contentArray[section] count];
    }
}

//每个cell是什么
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HomeModel *model = _contentArray[indexPath.section][indexPath.row];
    HomeHorizontalCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HomeHorizontalCollectionViewCell" forIndexPath:indexPath];
    cell.model = model;
    return cell;
}

//头尾视图
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        if (indexPath.section == 0) {
            HomeHeadCollectionReusableView *headView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HomeHeadCollectionReusableView" forIndexPath:indexPath];
            [headView detailArray:self.headArray];
            headView.delegate = self;
            headView.titleLabel.text = _titleArray[indexPath.section][@"name"];
            UIFont *font = [UIFont fontWithName:@"Arial" size:18.0];
            headView.titleLabel.font = font;
            CGSize labelSize = [headView.titleLabel.text sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
            headView.titleLabel.frame = CGRectMake(10, 5+10, labelSize.width, 20);
            headView.moreLabel.frame = CGRectMake(ScreenWidth-15-8-5-40, 5+5, 40, 20);
            headView.categoryBtn.tag = indexPath.section;
            [headView.categoryBtn addTarget:self action:@selector(pushCategoryVC:) forControlEvents:UIControlEventTouchUpInside];
            return headView;
        }
        HomeHead_title_CollectionReusableView *headView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HomeHead_title_CollectionReusableView" forIndexPath:indexPath];
        headView.titleLabel.text = _titleArray[indexPath.section][@"name"];
        UIFont *font = [UIFont fontWithName:@"Arial" size:18.0];
        headView.titleLabel.font = font;
        CGSize labelSize = [headView.titleLabel.text sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
        headView.titleLabel.frame = CGRectMake(10, 10+10, labelSize.width, 20);
        headView.moreLabel.frame = CGRectMake(ScreenWidth-15-8-5-40, 10+10, 40, 20);
        headView.categoryBtn.tag = indexPath.section;
        [headView.categoryBtn addTarget:self action:@selector(pushCategoryVC:) forControlEvents:UIControlEventTouchUpInside];
        return headView;
    }else {
        HomeFootCollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"HomeFootCollectionReusableView" forIndexPath:indexPath];
        return footerView;
    }
}

- (void) pushCategoryVC:(UIButton *)btn {
    NSNumber *currentID = _titleArray[btn.tag][@"id"];
    NSNumber *currentGenreID = _titleArray[btn.tag][@"genre_id"];
    NSLog(@"点中的分类的id------%@---geneid:%@",currentID,currentGenreID);
    ListViewController *vc = [[ListViewController alloc] init];
    vc.ID = currentGenreID;
    vc.titleName = [btn.subviews[0] text];
    [[PushHelper new] pushController:vc withOldController:self.navigationController andSetTabBarHidden:YES];
}

//collectionView头视图的高度
- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGSizeMake(0, ScreenWidth*210/375+30+5);
    } else {
        return CGSizeMake(0, 40);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    HomeModel *model = _contentArray[indexPath.section][indexPath.row];
    [self pushWithPay:model];
}

//滚动视图的代理方法
- (void) didSecectedHomeCirculationScrollViewAnIndex:(NSInteger)currentpage{
    HomeModel *model = _headArray[currentpage];
    [self pushWithPay:model];
}

- (void) pushWithPay:(HomeModel *)model {
    BOOL isPay = ([[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP199"] boolValue] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP199"] boolValue] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP199"] boolValue]);
    
    if (!isPay && model.pay) {
        NSDictionary *dic = [[NSUserDefaults standardUserDefaults] objectForKey:@"userInfo"];
        BOOL isLogin = dic;
        if (isLogin) {
            PurchaseViewController *vc = [PurchaseViewController new];
            vc.isHideTab = NO;
            [[PushHelper new] pushController:vc withOldController:self.navigationController andSetTabBarHidden:YES];
        } else {
            LoginViewController *vc = [LoginViewController new];
            vc.isHide = NO;
            [[PushHelper new] pushController:vc withOldController:self.navigationController andSetTabBarHidden:YES];
        }
    } else {
        PlayerViewController *vc = [[PlayerViewController alloc] init];
        vc.model = model;
        vc.isHideTabbar = NO;
        [[PushHelper new] pushController:vc withOldController:self.navigationController andSetTabBarHidden:YES];
    }
}

- (void) addStorageHelper {
    StorageHelper *sharedInstance = [StorageHelper sharedSingleClass];
    sharedInstance.storageArray = self.storageArray;
}


//- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
//    NSLog(@"结束-----%f",scrollView.contentOffset.y);
//    [NSObject cancelPreviousPerformRequestsWithTarget:self];
//}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    NSLog(@"滑动-----%f",scrollView.contentOffset.y);
    if ([self.showNavDelegate respondsToSelector:@selector(didShowNav:)]) {
        [self.showNavDelegate didShowNav:scrollView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
