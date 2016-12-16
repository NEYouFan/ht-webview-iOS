//
//  HTWebViewProgressView.h
//
//  Created by gaoqiang xu on 3/25/15.
//  Copyright (c) 2015 gaoqiang xu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTWebViewProgressViewProtocol.h"
@import WebKit;

@interface HTWebViewProgressView : UIView
<HTWebViewProgressViewProtocol>
@property (nonatomic) float progress;

@property (readonly, nonatomic) UIView *progressBarView;
@property (nonatomic) NSTimeInterval barAnimationDuration;// default 0.5
@property (nonatomic) NSTimeInterval fadeAnimationDuration;// default 0.27
/**
 *  进度条的颜色
 */
@property (copy, nonatomic) UIColor *progressBarColor;

@end
