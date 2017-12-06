//
//  PushHelper.m
//  Mobile_YoYoTV
//
//  Created by li que on 2017/11/15.
//  Copyright © 2017年 li que. All rights reserved.
//

#import "PushHelper.h"

@implementation PushHelper

- (void) pushController:(UIViewController *)newController withOldController:(UINavigationController *)oldController andSetTabBarHidden:(BOOL)hidden{
    [oldController pushViewController:newController animated:YES];
    [[oldController rdv_tabBarController] setTabBarHidden:hidden animated:YES];
}

- (void) popController:(UIViewController *)oldController WithNavigationController:(UINavigationController *)navigationController andSetTabBarHidden:(BOOL)hidden{
    [navigationController popViewControllerAnimated:YES];
    [[oldController rdv_tabBarController] setTabBarHidden:hidden animated:YES];
}


@end
