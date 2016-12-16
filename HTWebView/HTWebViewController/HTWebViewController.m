//
//  HTWebViewController.m
//  Pods
//
//  Created by netease on 15/8/31.
//
//

#import "HTWebViewController.h"
#import "HTLog.h"
#import "UIViewController+HTRouterUtils.h"
#import "UIImage+ImageWithColor.h"

@interface HTWebViewController ()

@property (nonatomic, readwrite, strong)UIWebView* webView;
@property (nonatomic, strong)UIBarButtonItem* defaultCloseButton;
@property (nonatomic, strong)UIBarButtonItem* defaultBackButton;
@property (nonatomic, strong)UIBarButtonItem* spacerButton;
@property (nonatomic, strong)UIBarButtonItem* leftMarginButton;

@end

@implementation HTWebViewController

- (instancetype)init{
    if (self = [super init]) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _webView = [[UIWebView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:_webView];

    //导航栏配置
    [self configNavigationBar];
}

- (void)configNavigationBar
{
    //如果未提供自定义返回按钮和关闭按钮，则提供默认按钮，尽量引导用户自行定制
    if (!self.backButton) {
       
        _defaultBackButton = [[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonClicked:)];
        self.backButton = _defaultBackButton;
    }
    
    if (!self.closeButton) {
        _defaultCloseButton = [[UIBarButtonItem alloc]initWithTitle:@"关闭" style:UIBarButtonItemStyleDone target:self action:@selector(closeButtonClicked:)];
        
        self.closeButton = _defaultCloseButton;
    }
    
    self.spacerButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    self.spacerButton.width = self.buttonItemsSpace;
    
    self.leftMarginButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    self.leftMarginButton.width = self.buttonItemsLeftMargin;

    self.navigationItem.leftBarButtonItems = @[self.leftMarginButton, self.backButton];
}

- (UIBarButtonItem*)barButtonWithNormalImage:(NSString*)normal highlightedImage:(NSString*)highlighted selector:(SEL)sel
{
    UIImage* normalImage = [UIImage imageNamed:normal];
    UIImage* highlightedImage = [UIImage imageNamed:highlighted];
    
    CGRect frame = CGRectMake(0, 0, normalImage.size.width, normalImage.size.height);
    UIButton* button = [[UIButton alloc]initWithFrame:frame];
    
    [button setBackgroundImage:normalImage forState:UIControlStateNormal];
    [button setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    
    [button addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem* barButton = [[UIBarButtonItem alloc]initWithCustomView:button];
    
    return barButton;
}

- (void)closeButtonClicked:(id)sender
{    
    [self ht_back];
}

- (void)backButtonClicked:(id)sender
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
        self.navigationItem.leftBarButtonItems = @[self.leftMarginButton, self.backButton, self.spacerButton,self.closeButton];
    } else {
        [self ht_back];
    }
}

- (SEL)closeButtonResponderSelector
{
    return @selector(closeButtonClicked:);
}

- (SEL)backButtonResponderSelector
{
    return @selector(backButtonClicked:);
}

- (NSString*)webTitle
{
    return [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

@end
