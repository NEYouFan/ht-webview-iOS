//
//  HTWebViewProgress.h
//
//  Created by gaoqiang xu on 3/25/15.
//  Copyright (c) 2015 gaoqiang xu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTWebViewProgressViewProtocol.h"

@interface HTWebViewProgress : NSObject
<UIWebViewDelegate>

@property (readonly, nonatomic) CGFloat progress;
/**
 *  进度条
 */
@property (strong, nonatomic) UIView <HTWebViewProgressViewProtocol> *progressView;
/**
 *  转发WebViewDelegate
 */
@property (weak, nonatomic) id <UIWebViewDelegate> proxyDelegate;

@end
