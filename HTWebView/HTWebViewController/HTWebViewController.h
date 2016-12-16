//
//  HTWebViewController.h
//  Pods
//
//  Created by Wayne Wei on 15/8/31.
//  Copyright (c) 2015年 HT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTWebViewDelegate.h"

@interface HTWebViewController : UIViewController <UIWebViewDelegate>
/**
 *  UIWebView对象，其frame与controller.view.frame一致
 */
@property (nonatomic, readonly, strong)UIWebView* webView;
/**
 *  WebViewDelegate组件
 */
@property (nonatomic, strong)HTWebViewDelegate* webViewDelegate;
/**
 *  导航栏显示的关闭按钮。可用户自行定制并传入(在 viewDidLoad 方法被调用之前设置起效)，否则提供默认文本显示的关闭按钮。
 *  关联的响应方法为 closeButtonResponderSelector返回值；显示规则为默认情况不显示，若[webView canGoBack]为YES，则在用户点击返回按钮后出现在返回按钮右边；响应表现为点击后则直接返回前一controlelr
 */
@property (nonatomic, strong)UIBarButtonItem* closeButton;
/**
 *  导航栏显示的返回按钮。可用户自行定制并传入(在 viewDidLoad 方法被调用之前设置起效)，否则提供默认文本显示的返回按钮。
 *  关联的响应方法为 backButtonResponderSelector返回值；显示规则为默认情况均显示;响应表现为[webView canGoBack]为NO，则点击后返回前一controller，否则后退至上一次浏览的web页面
 */
@property (nonatomic, strong)UIBarButtonItem* backButton;

/**
 *  返回按钮和关闭按钮同时存在时，二者之间距，单位为point
 */
@property (nonatomic, assign)CGFloat buttonItemsSpace;
/**
 *  返回按钮左边边距，单位为point
 */
@property (nonatomic, assign)CGFloat buttonItemsLeftMargin;

/**
 *  点击关闭按钮的响应方法，用户需自行关联到定制的关闭按钮上
 *
 *  @return selector
 */
- (SEL)closeButtonResponderSelector;
/**
 *  点击返回按钮的响应方法，用户需自行关联到定制的返回按钮上
 *
 *  @return selector
 */
- (SEL)backButtonResponderSelector;
/**
 *  获取当前显示web页的标题
 *
 *  @return web页标题
 */
- (NSString*)webTitle;
@end