//
//  PlayerViewController.m
//  Mobile_YoYoTV
//
//  Created by li que on 2017/5/3.
//  Copyright © 2017年 li que. All rights reserved.
//

#import "PlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Masonry/Masonry.h>
#import "ZFPlayer.h"
#import "PlayerRequest.h"
#import "PlayVCContentView.h"
#import "StorageHelper.h"
//#import "HomeCollectionViewCell.h"
#import "PlayerRecommendCollectionViewCell.h"
#import "PlayerCollectionReusableView.h"
#import "HomeFootCollectionReusableView.h"
#import "Mobile_YoYoTV-Swift.h"
#import "LoginViewController.h"
#import "NSString+encrypto.h"
#import "PlayerUserRequest.h"
@import SpotX;


@interface PlayerViewController ()<ZFPlayerDelegate,selectedIndexDelegate,UICollectionViewDelegate,UICollectionViewDataSource,SpotXAdDelegate>
@property (nonatomic,strong) SpotXView *ad;
/** 播放器View的父视图*/
@property (strong, nonatomic) UIView *playerFatherView;
@property (strong, nonatomic) ZFPlayerView *playerView;
@property (strong, nonatomic) ZFPlayerControlView *controlView;
/** 离开页面时候是否在播放 */
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, strong) ZFPlayerModel *playerModel;
@property (nonatomic, strong) UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;

@property (nonatomic,strong) NSArray *vimeoResponseArray;
@property (nonatomic,strong) NSDictionary *vimeoResponseDic;
@property (nonatomic) NSInteger currentIndex;
@property (nonatomic,strong) PlayVCContentView *videoInfoView;
@property (nonatomic,strong) NSArray *storageArray;
@property (nonatomic,strong) UIView *relatedView;
@property (nonatomic,strong) NSDictionary *playHistory;
@property (nonatomic) BOOL isCollected;
@property (nonatomic) BOOL isFromBtnClick;
@property (nonatomic,strong) UICollectionView *collectionView;
/*用来做中间变量，给collectionView的headerView中影片信息部分传值*/
@property (nonatomic,strong) PlayerRequest *VimeoRequest;
@property (nonatomic) CGFloat sectionOneHeight;
@property (nonatomic,copy) NSString *beginTime;
@end

@implementation PlayerViewController

- (void)dealloc {
    NSLog(@"%@释放了",self.class);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // pop回来时候是否自动播放
    if (self.navigationController.viewControllers.count == 2 && self.playerView && self.isPlaying) {
        self.isPlaying = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}

/**请求用户相关信息：是否收藏和播放记录**/
- (void) requestData {
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"userInfo"];
    BOOL isLogin = userInfo;
    if (!isLogin) {
        [self requestVimeoData];
        return;
    }
    [SVProgressHUD showWithStatus:@"loading"];
    [[PlayerUserRequest new] requestUserVideoInfoWithID:[NSString stringWithFormat:@"%@",self.model.ID] andBlock:^(PlayerUserRequest *responseData) {
        self.isCollected = responseData.isCollected;
        self.playHistory = responseData.playHistory;
    } andFilureBlock:^(PlayerUserRequest *responseData) {
        [ShowToast showToastWithString:@"获取用户播放记录失败" withBackgroundColor:[UIColor orangeColor] withTextFont:14];
    }];
    [self requestVimeoData];
}
/**请求viemeo接口**/
- (void) requestVimeoData {
    PlayerRequest *request = [PlayerRequest new];
    request.genre_id = self.model.genre_id;
    request.ID = self.model.ID;
    request.vimeo_id = self.model.vimeo_id;
    request.vimeo_token = self.model.vimeo_token;
    request.regexName = self.model.name;
    [request requestVimeoPlayurl:^(PlayerRequest *responseData) {
        PlayerRequest *vimeoRequest = responseData;
        
        PlayerRequest *relatedRequest = [[PlayerRequest alloc] init];
        relatedRequest.ID = self.model.ID;
        [relatedRequest requestRelatedData:nil andBlock:^(PlayerRequest *responseData) {
            _controlView.fullScreenBtn.userInteractionEnabled = YES;
            if (responseData.responseData.count > 0) {
                self.storageArray = responseData.responseData;
            }
            
            self.VimeoRequest = vimeoRequest;
            PlayerCollectionReusableView *headView = [PlayerCollectionReusableView new];
            headView.model = self.model;
            headView.selectedIndex = _currentIndex;
            [headView dealResponseData:self.VimeoRequest];
            self.sectionOneHeight = headView.headerInfoHeight;
            self.vimeoResponseDic = headView.vimeoResponseDic;
            self.vimeoResponseArray = headView.vimeoResponseArray;
            
            BOOL isHaveInitCollectionView = false;
            for ( UIView *view in self.view.subviews ) {
                NSString *className = NSStringFromClass([view class]);
                if ([className isEqualToString:@"UICollectionView"]) {
                    isHaveInitCollectionView = true;
                    break;
                }
            }
            isHaveInitCollectionView ? [_collectionView reloadData] : [self initCollectionView];
            [self setNewModel];
            [SVProgressHUD dismiss];
        } andFailureBlock:^(PlayerRequest *responseData) {
            
        }];
    } andFailureBlock:^(PlayerRequest *responseData) {
        [SVProgressHUD showWithStatus:@"请检查网络"];
        [SVProgressHUD dismissWithDelay:2];
    }];
}

/**设置播放的model**/
/**当前只考虑默认进入页面，即index=0时，如果user选集的话另做考虑**/
- (void) setNewModel {
    BOOL isPay = ([[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP"] boolValue] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP499"] boolValue] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP199"] boolValue] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP299"] boolValue]);
    if (!isPay) {
        [_ad show]; // 加载广告
        [_playerView.player pause];
    }
    if (self.vimeoResponseDic) {
        //将当前剧集的所有url从大到小排列
        NSMutableArray *arr = [self dealUrlWidthWithFiles:self.vimeoResponseDic[@"files"] andDownload:self.vimeoResponseDic[@"download"]];
        self.playerModel.title            = _vimeoResponseDic[@"name"];
        self.playerModel.videoURL         = [NSURL URLWithString:arr.lastObject[@"link"]];
        //判断是否已经播放过
        if ([_playHistory isKindOfClass:[NSDictionary class]]) {
            NSString *playedTimeStr = _playHistory[@"playbackProgress"];
            self.playerModel.seekTime = [playedTimeStr integerValue];
            _playHistory = nil;
        }
        [self.playerView resetToPlayNewVideo:self.playerModel];
    }
    if (self.vimeoResponseArray) {
        if ([_playHistory isKindOfClass:[NSDictionary class]]) {
            NSInteger historyIndex = [_playHistory[@"episodes"] integerValue];
            _currentIndex = historyIndex;
        }
        NSDictionary *currendDic = self.vimeoResponseArray[(int)_currentIndex];
        //将当前剧集的所有url从大到小排列
        NSMutableArray *arr = [self dealUrlWidthWithFiles:currendDic[@"files"] andDownload:currendDic[@"download"]];
        self.playerModel.title            = currendDic[@"name"];
        self.playerModel.videoURL         = [NSURL URLWithString:[arr lastObject][@"link"]];
        [self.playerView resetToPlayNewVideo:self.playerModel];
    }
}

/**当点中某一集的时候的代理方法**/
- (void)selectedButton:(UIButton *)btn {
#pragma mark 播放记录
    [self postPlayRecord];
    
    NSInteger index = btn.tag - 1000;
    if (index == _currentIndex) return;
    btn.selected = YES;
    _currentIndex = index;
//    _isFromBtnClick = YES;
    [self setNewModel];
}
/**加载广告**/
- (void) loadNextAd {
    _ad = [[SpotXView alloc] initWithFrame:self.view.bounds];
    _ad.delegate = self;
    _ad.channelID = @"85394";
    
    [_ad startLoading];
}

- (void) presentViewController:(UIViewController *)viewControllerToPresent {
    [self presentViewController:viewControllerToPresent animated:YES completion:nil];
}

- (void)adClosed {
    [self removeSpotView];
}

- (void) adSkipped {
    [self removeSpotView];
}

- (void) removeSpotView {
    [_playerView.player play];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self loadNextAd]; //加载广告资源
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [SpotX initializeWithApiKey:nil category:@"IAB1" section:@"Fiction" domain:@"com.spotxchange.demo" url:@""];
    [self loadNextAd];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.currentIndex = 0;
    self.ID ? [self requestModel] : [self requestData];
    [self setupPlayer];
    
    self.playerView.hasPreviewView = YES;
    
    StorageHelper *instance = [StorageHelper sharedSingleClass];
    self.storageArray = instance.storageArray;
    self.beginTime = [self getCurrentTime];
}

- (NSString *) getCurrentTime{
    //获取当前时间
    NSDate *now = [NSDate date];
    //创建日期格式
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];// 创建一个时间格式化对象
    [dateFormatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"]; //设定时间的格式
    return [dateFormatter stringFromDate:now];
}

- (void) setupPlayer {
    self.playerFatherView = [[UIView alloc] init];
    [self.view addSubview:self.playerFatherView];
    [self.playerFatherView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(0);
        make.leading.trailing.mas_equalTo(0);
        // 这里宽高比16：9,可自定义宽高比
        make.height.mas_equalTo(self.playerFatherView.mas_width).multipliedBy(9.0f/16.0f);
    }];
    // 自动播放，默认不自动播放
    //[self.playerView autoPlayTheVideo];
}

// 返回值要必须为NO
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    // 这里设置横竖屏不同颜色的statusbar
    // if (ZFPlayerShared.isLandscape) {
    //    return UIStatusBarStyleDefault;
    // }
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
//    return ZFPlayerShared.isStatusBarHidden;
    return NO;
}

#pragma mark - ZFPlayerDelegate

- (void)zf_playerBackAction {
    [self popToLastPage];
}

- (void) popToLastPage {
    [[PushHelper new] popController:self WithNavigationController:self.navigationController andSetTabBarHidden:_isHideTabbar];
    [self postPlayRecord];
}
//上传播放记录
//postActive(userIP,albumID,name,playedTime,beginTime,endTime);
- (void) postUserData {
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *albumId = [NSString stringWithFormat:@"%@",self.model.ID];
    if (self.playerView.player.currentTime.value) {
        int watchTime = (int)self.playerView.player.currentTime.value/self.playerView.player.currentTime.timescale*1000;
        NSString *isCollection = [NSString stringWithFormat:@"%i",self.isCollected];
        NSString *endTime = [self getCurrentTime];
        
        [[PlayerUserRequest new] postPlayTimeWithVersion:version albumId:albumId albumTitle:self.model.name watchTime:watchTime isCollection:isCollection startTime:self.beginTime endTime:endTime];
    }
    self.beginTime = [self getCurrentTime]; //清空上一次的开始时间
}

- (void) postPlayRecord {
    [self postUserData];
    
    if (self.playerView.player.currentItem == nil) return;
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"userInfo"];
    BOOL isLogin = userInfo;
    if (!isLogin) {
        return;
    }
    NSLog(@"%lld",self.playerView.player.currentTime.value/self.playerView.player.currentTime.timescale);
//    NSLog(@"currentTime.value---%lld",self.playerView.player.currentTime.value);
//    NSLog(@"currentTime.timescale---%d",self.playerView.player.currentTime.timescale);
    CGFloat watchTime = self.playerView.player.currentTime.value/self.playerView.player.currentTime.timescale;

    [[PlayerUserRequest new] postUserRecoreWithTitle:self.model.name albumID:self.model.ID albumImg:self.model.landscape_poster_s currentIndex:_currentIndex watchedTime:watchTime pay:self.model.pay];
}

//- (void)zf_playerDownload:(NSString *)url {
//    // 此处是截取的下载地址，可以自己根据服务器的视频名称来赋值
//    NSString *name = [url lastPathComponent];
//    [[ZFDownloadManager sharedDownloadManager] downFileUrl:url filename:name fileimage:nil];
//    // 设置最多同时下载个数（默认是3）
//    [ZFDownloadManager sharedDownloadManager].maxCount = 4;
//}

- (void)zf_playerControlViewWillShow:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    //    self.backBtn.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.backBtn.alpha = 0;
    }];
}

- (void)zf_playerControlViewWillHidden:(UIView *)controlView isFullscreen:(BOOL)fullscreen {
    //    self.backBtn.hidden = fullscreen;
    [UIView animateWithDuration:0.25 animations:^{
        self.backBtn.alpha = !fullscreen;
    }];
}

#pragma mark - Getter

- (ZFPlayerModel *) playerModel {
    if (!_playerModel) {
        _playerModel                  = [[ZFPlayerModel alloc] init];
        _playerModel.title            = @"";
        _playerModel.videoURL         = [NSURL URLWithString:@""];
        _playerModel.placeholderImage = [UIImage imageNamed:@"loading_bgView1"];
        _playerModel.fatherView       = self.playerFatherView;
        //        _playerModel.resolutionDic = @{@"高清" : self.videoURL.absoluteString,
        //                                       @"标清" : self.videoURL.absoluteString};
    }
    return _playerModel;
}

- (ZFPlayerView *)playerView {
    if (!_playerView) {
        _playerView = [[ZFPlayerView alloc] init];
        
        self.controlView = [[ZFPlayerControlView alloc] init];
        _controlView.fullScreenBtn.userInteractionEnabled = NO;
        /*****************************************************************************************
         *    指定控制层(可自定义)
         *    ZFPlayerControlView *controlView = [[ZFPlayerControlView alloc] init];
         *    设置控制层和播放模型
         *    控制层传nil，默认使用ZFPlayerControlView(如自定义可传自定义的控制层)
         *    等效于 [_playerView playerModel:self.playerModel];
         ******************************************************************************************/
        [_playerView playerControlView:_controlView playerModel:self.playerModel];
        
        // 设置代理
        _playerView.delegate = self;
        
        //（可选设置）可以设置视频的填充模式，内部设置默认（ZFPlayerLayerGravityResizeAspect：等比例填充，直到一个维度到达区域边界）
        // _playerView.playerLayerGravity = ZFPlayerLayerGravityResize;
        
        // 打开下载功能（默认没有这个功能）
//        _playerView.hasDownload    = YES;
        
        // 打开预览图
        _playerView.hasPreviewView = YES;
    }
    return _playerView;
}

#pragma mark - Action

- (IBAction)backClick {
    [self popToLastPage];
}

- (IBAction)playNewVideo:(UIButton *)sender {
    self.playerModel.title            = @"这是新播放的视频";
    self.playerModel.videoURL         = [NSURL URLWithString:@"http://baobab.wdjcdn.com/1456665467509qingshu.mp4"];
    // 设置网络封面图
    self.playerModel.placeholderImageURLString = @"http://img.wdjimg.com/image/video/447f973848167ee5e44b67c8d4df9839_0_0.jpeg";
    // 从xx秒开始播放视频
    // self.playerModel.seekTime         = 15;
    [self.playerView resetToPlayNewVideo:self.playerModel];
}

- (void) initCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat padding = 5;
    CGFloat itemWidth = (ScreenWidth-4*padding)/3.0;
    CGFloat itemHeight = itemWidth * (158.0/113.0)+20;    layout.itemSize    = CGSizeMake(itemWidth, itemHeight); // 设置cell的宽高
    layout.minimumLineSpacing = 5.0;
    layout.minimumInteritemSpacing = 5.0;
    layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, ScreenWidth*9/16, ScreenWidth, ScreenHeight-ScreenWidth*9/16 - 10) collectionViewLayout:layout];
    [_collectionView registerClass:[PlayerRecommendCollectionViewCell class] forCellWithReuseIdentifier:@"PlayerRecommendCollectionViewCell"];
    [_collectionView registerClass:[PlayerCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PlayerCollectionReusableView"];
    [_collectionView registerClass:[HomeFootCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"HomeFootCollectionReusableView"];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor whiteColor];
    [_relatedView addSubview:_collectionView];
    [self.view addSubview:_collectionView];
}

#pragma mark UIColltionViewDelegate
//有多少个分区
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

//每个分区下有多少个cell
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.storageArray.count;
}

//每个cell是什么
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PlayerRecommendCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PlayerRecommendCollectionViewCell" forIndexPath:indexPath];
    cell.model = self.storageArray[indexPath.row];
    return cell;
}

//头视图和尾视图
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        PlayerCollectionReusableView *headView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PlayerCollectionReusableView" forIndexPath:indexPath];
        headView.model = self.model;
        headView.selectedIndex = _currentIndex;
        [headView dealResponseData:self.VimeoRequest];
        self.sectionOneHeight = headView.headerInfoHeight;
        self.vimeoResponseDic = headView.vimeoResponseDic;
        self.vimeoResponseArray = headView.vimeoResponseArray;
        headView.delegate = self;
        //判断是否已经收藏
        headView.videoInfoView.collectionBtn.selected = self.isCollected;
        //添加收藏按钮的点击事件
        [headView.videoInfoView.collectionBtn addTarget:self action:@selector(collection:) forControlEvents:UIControlEventTouchUpInside];
        return headView;
    } else {
        HomeFootCollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"HomeFootCollectionReusableView" forIndexPath:indexPath];
        return footerView;
    }
}

//collectionView头视图的高度
- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    CGFloat gap = 10;
    return CGSizeMake(0, _sectionOneHeight + gap);
}

//点中cell的相应事件
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _playHistory = nil;
#pragma mark 播放记录
    [self postPlayRecord];
    
    HomeModel *model = self.storageArray[indexPath.row];
    BOOL isPay = ([[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP"] boolValue] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP499"] boolValue] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP199"] boolValue] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"com.uu.VIP299"] boolValue]);
    if (!isPay && model.pay) {
        NSDictionary *dic = [[NSUserDefaults standardUserDefaults] objectForKey:@"userInfo"];
        BOOL isLogin = dic;
        if (isLogin) {
            PurchaseViewController *vc = [PurchaseViewController new];
            vc.isHideTab = YES;
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            LoginViewController *vc = [LoginViewController new];
            vc.isHide = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
        [_playerView pause];
        return;
    }
    
    self.model = model;
    [_relatedView removeFromSuperview];
    [_videoInfoView removeFromSuperview];
    _vimeoResponseDic = nil;
    _vimeoResponseArray = nil;
    self.currentIndex = 0;
    [self requestData];
}

- (void) requestModel {
    [SVProgressHUD showWithStatus:@"loading"];
    NSString *url = [NSString stringWithFormat:@"http://cdn.100uu.tv/albums/%@/?format=json&platform=apple-tv",self.ID];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [SVProgressHUD dismiss];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        self.model = [HomeModel modelWithDictionary:dic];
        [self requestData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [SVProgressHUD showWithStatus:@"请检查网络"];
    }];
}

- (void) collection:(UIButton *)btn {
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:@"userInfo"];
    BOOL isLogin = userInfo;
    if (isLogin) {
        if (btn.selected) {
            [self deleteCollection:btn];
        } else { //应该收藏
            [self postAlbum:btn];
        }
    } else {
        [_playerView pause];
        LoginViewController *vc = [LoginViewController new];
        vc.isHide = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void) deleteCollection:(UIButton *)btn {
    [[PlayerUserRequest new] cancleCollectionWithID:self.model.ID andBlock:^(PlayerUserRequest *responseData) {
        if ([responseData.status isEqualToString:@"2"] || [responseData.status isEqualToString:@"3"]) {
            [ShowToast showToastWithString:@"已取消收藏" withBackgroundColor:[UIColor orangeColor] withTextFont:14];
            btn.selected = NO;
        } else {
            [ShowToast showToastWithString:@"取消收藏失败" withBackgroundColor:[UIColor orangeColor] withTextFont:14];
        }
    } andFilureBlock:^(PlayerUserRequest *responseData) {
        [ShowToast showToastWithString:@"取消收藏网络出现问题" withBackgroundColor:[UIColor orangeColor] withTextFont:14];
    }];
}

- (void) postAlbum:(UIButton *)btn {
    [[PlayerUserRequest new] collectionWithID:self.model.ID title:self.model.name image:self.model.landscape_poster_s pay:self.model.pay andBlock:^(PlayerUserRequest *responseData) {
        if ([responseData.status isEqualToString:@"3"] || [responseData.status isEqualToString:@"2"]) {
            btn.selected = YES;
            [ShowToast showToastWithString:@"收藏成功" withBackgroundColor:[UIColor orangeColor] withTextFont:14];
        } else {
            [ShowToast showToastWithString:@"收藏失败，请重新登录" withBackgroundColor:[UIColor orangeColor] withTextFont:14];
        }
    } andFilureBlock:^(PlayerUserRequest *responseData) {
        [ShowToast showToastWithString:@"收藏网络发生错误" withBackgroundColor:[UIColor orangeColor] withTextFont:14];
    }];
}
//将剧集排序
- (NSMutableArray *) dealUrlWidthWithFiles:(NSArray *)filesArray andDownload:(NSArray *)downloadsArray {
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:0];
    for (int i = 0; i<filesArray.count; i++) {
        PlayerModel *model = filesArray[i];
        [tempArray addObject:model];
    }
    for (int i = 0; i<downloadsArray.count; i++) {
        PlayerModel *model = downloadsArray[i];
        [tempArray addObject:model];
    }
    [tempArray sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2)
     {
         //此处的规则含义为：若前一元素比后一元素小，则返回降序（即后一元素在前，为从大到小排列）
         if ([obj1[@"size"] integerValue] < [obj2[@"size"] integerValue]){
             return NSOrderedDescending;
         } else {
             return NSOrderedAscending;
         }
     }];
    return tempArray;
}

- (NSArray *)storageArray {
    if (_storageArray == nil) {
        _storageArray = [NSArray array];
    }
    return _storageArray;
}



@end
