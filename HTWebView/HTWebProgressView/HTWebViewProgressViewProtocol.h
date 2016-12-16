//
//  HTWebViewProgressViewProtocol.h
//
//  Created by gaoqiang xu on 3/25/15.
//  Copyright (c) 2015 gaoqiang xu. All rights reserved.
//

@protocol HTWebViewProgressViewProtocol <NSObject>

@required
- (void)setProgress:(float)progress animated:(BOOL)animated;

@end

