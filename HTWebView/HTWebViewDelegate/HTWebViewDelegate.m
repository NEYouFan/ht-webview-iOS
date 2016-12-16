//
//  HTWebViewDelegate.m
//  Pods
//
//  Created by Wayne Wei on 15/9/6.
//
//

#import "HTWebViewDelegate.h"
#import "HTWebViewProgress.h"
#import "HTWebViewProgressView.h"
#import <objc/runtime.h>

#if SUPPORT_CONTROLLER_ROUTER
#import "HTControllerRouter.h"
#import "HTControllerRouterLogger.h"
#endif

static NSString *const kWKProgressProperty = @"estimatedProgress";

@interface HTWebViewDelegate ()

#ifdef supportsWKWebKit
@property (nonatomic, weak) WKWebView *wkWebView;
@property (nonatomic, strong) WKWebViewJavascriptBridge *wkBridge;
/*
 * WKWebView可以直接获取大概进度，不需要progressProxy
 * 故delegate本身要向显示控件派发进度事件
 */
@property (nonatomic, strong) UIView <HTWebViewProgressViewProtocol> *progressView;
@property (nonatomic, weak) id<WKNavigationDelegate> managedWKDelegate;
#endif

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, strong) WebViewJavascriptBridge* bridge;
@property (nonatomic, weak) id<UIWebViewDelegate> managedDelegate;
@property (nonatomic, strong) HTWebViewProgress* progressProxy;


#pragma mark Pan Gesture Navigation
@property (nonatomic, assign) BOOL gestureNavigationEnabled;
@property (nonatomic, strong) UIGestureRecognizer* panGesture;
@property (nonatomic, assign) CGFloat panStartX;
@property (nonatomic, strong) NSMutableArray* snapshotStack;
@property (nonatomic, strong) UIImageView* prevSnapshotView;

@end

@implementation HTWebViewDelegate

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

- (void)dealloc
{
#ifdef supportsWKWebKit
    [_wkWebView removeObserver:self forKeyPath:kWKProgressProperty];
#endif
    [_prevSnapshotView removeFromSuperview];
}

+ (instancetype)delegateForWebView:(UIWebView*)webView
                   webviewDelegate:(id<UIWebViewDelegate>)webviewDelegate
            enableJavascriptBridge:(BOOL)bridgeEnabled
      withJavascriptDefaultHandler:(WVJBHandler)defaultHandler
                    enableProgress:(BOOL)progressEnabled
                  withProgressView:(UIView <HTWebViewProgressViewProtocol>*)progressView
           enableGestureNavigation:(BOOL)navigationEnabled;
{
    if (!webView) {
        return nil;
    }

    HTWebViewDelegate *delegate = [[self  alloc]init];
    delegate.webView = webView;
    
    //JSBridge会优先设置自身为WebView之delegate
    //故设置UIWebViewDelegate对象为优先delegate的操作延后
    if (bridgeEnabled) {
        [delegate initJavascriptBridgeWithDefaultHandler:defaultHandler];
    }
    
    if (progressEnabled) {
        NSParameterAssert(progressView);
        [delegate initProgress:webView withProgressView:progressView];
    }
    
    if (navigationEnabled) {
        delegate.gestureNavigationEnabled = YES;
        [delegate initGestureNavigation:webView];
    }
    
    // 将WebView的delegate从JSBridge改为HTWebViewDelegate对象
    webView.delegate = delegate;
    delegate.managedDelegate = webviewDelegate;
    
    return delegate;
}

- (void)initProgress:(UIWebView*)webView withProgressView:(UIView<HTWebViewProgressViewProtocol>*)progressView
{
    self.progressProxy = [[HTWebViewProgress alloc]init];
    self.progressProxy.progressView = progressView;
}

- (void)initJavascriptBridgeWithDefaultHandler:(WVJBHandler)handler
{
    _bridge = [WebViewJavascriptBridge bridgeForWebView:_webView handler:handler];
}

- (WebViewJavascriptBridge*)javascriptBridge
{
    return _bridge;
}



#ifdef supportsWKWebKit
+ (instancetype)delegateForWKWebView:(WKWebView*)wkWebView
                     webviewDelegate:(id<WKNavigationDelegate>)webviewDelegate
              enableJavascriptBridge:(BOOL)bridgeEnabled
        withJavascriptDefaultHandler:(WVJBHandler)defauleHandler
                      enableProgress:(BOOL)progressEnabled
                    withProgressView:(UIView <HTWebViewProgressViewProtocol>*)progressView
             enableGestureNavigation:(BOOL)navigationEnabled;
{
    if (!wkWebView) {
        return nil;
    }
    
    HTWebViewDelegate *delegate = [[HTWebViewDelegate  alloc]init];
    delegate.wkWebView = wkWebView;
    
    //JSBridge会优先设置自身为WKWebView之delegate
    //故设置HTWebViewDelegate对象为WKWebView优先delegate的操作延后，以避免被JSBridge重置
    if (bridgeEnabled) {
        [delegate initJavascriptBridgeForWKWebViewWithDefaultHandler:defaultHandler];
    }
    
    if (progressEnabled) {
        [delegate initProgressForWKWebView:wkWebView withProgressView:progressView];
    }
    
    //    if (navigationEnabled) {
    //        delegate.gestureNavigationEnabled = YES;
    //        [delegate initGestureNavigation:wkWebView];
    //    }
    
    // 将WebView的delegate从JSBridge改为HTWebViewDelegate对象
    wkWebView.navigationDelegate = delegate;
    wkWebView.UIDelegate = delegate;
    
    delegate.managedWKDelegate = webviewDelegate;
    
    return delegate;
}


- (void)initProgressForWKWebView:(WKWebView*)wkWebView withProgressView:(UIView<HTWebViewProgressViewProtocol>*)progressView
{
    self.progressView = progressView;
    
    [wkWebView addObserver:self forKeyPath:kWKProgressProperty options:NSKeyValueObservingOptionNew context:nil];
    
}

- (void)initJavascriptBridgeForWKWebViewWithDefaultHandler:(WVJBHandler)handler
{
    _wkBridge = [WKWebViewJavascriptBridge bridgeForWebView:_wkWebView handler:handler];
}

- (WKWebViewJavascriptBridge*)javascriptBridgeForWKWebView
{
    return _wkBridge;
}

//Observe the estimatedProgress property of WKWebView
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (![keyPath isEqualToString:kWKProgressProperty]) {
        return;
    }
    NSNumber *progress = [change objectForKey: NSKeyValueChangeNewKey];
    [self.progressView setProgress:progress.floatValue animated:YES];
}


#endif

#pragma mark Lua-Javascript Invocation
+ (NSString *)serialize:(id)container {
    if (!container || ![NSJSONSerialization isValidJSONObject:container]){
        return @"";
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:container options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark Router


#if SUPPORT_CONTROLLER_ROUTER
/*!
 *  使用Controller Router来打开Native页面。
 *  app://detail?id=1000&iosopentype=[push|present|pushnavigation|presentnavigation] 不支持url中携带port，username、passward，fragment
 *
 *  如果一个页面是用controller router打开的，那么他的urlparams和params是一样的。
 *  params中会携带上打开这个页面的webview和HTWebViewDelegate实例
 *
 *  @param request 当前浏览器的Request
 *
 *  @return 如果能够打开这个URL，返回YES，否则返回NO
 */
- (BOOL)routerLoadRequest:(NSURLRequest*)request
{
    NSTimeInterval startTime = CACurrentMediaTime();
    
    NSURL *url = request.URL;
    NSDictionary *urlParams = [self paramsFromURL:url];
    HTControllerLaunchMode launchMode = HTControllerLaunchModePushNavigation;
    if ([urlParams objectForKey:@"iosopentype"]){
        NSString *openType = [urlParams objectForKey:@"iosopentype"];
        if ([openType isEqualToString:@"push"]){
            launchMode = HTControllerLaunchModePush;
        } else if ([openType isEqualToString:@"present"]){
            launchMode = HTControllerLaunchModePresent;
        } else if ([openType isEqualToString:@"pushnavigation"]){
            launchMode = HTControllerLaunchModePushNavigation;
        } else if ([openType isEqualToString:@"presentnavigation"]){
            launchMode = HTControllerLaunchModePresentNavigation;
        }
    }
    
    //拼接上除去query的url字符串
    NSString *routeUrlString;
    if (url.host)
        routeUrlString = [NSString stringWithFormat:@"%@://%@%@", url.scheme, url.host, url.path];
    else
        routeUrlString = [NSString stringWithFormat:@"%@://%@", url.scheme, url.path];
    
    HTControllerRouteParam *param = [[HTControllerRouteParam alloc] initWithURL:routeUrlString launchMode:launchMode];
    param.params = urlParams;
    
    UIViewController *vc = [[HTControllerRouter sharedRouter] route:param];
    HTControllerRouterLogInfo(@"spend time:%f", CACurrentMediaTime() - startTime);
    return vc ? NO : YES;
}

- (NSDictionary*)paramsFromURL:(NSURL*)url
{
    NSMutableDictionary *urlParams = [NSMutableDictionary new];
    if (url.query){
        for(NSString* parameter in [url.query componentsSeparatedByString:@"&"]) {
            NSRange range = [parameter rangeOfString:@"="];
            if(range.location!= NSNotFound)
                [urlParams setObject:[[parameter substringFromIndex:range.location+range.length] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[[parameter substringToIndex:range.location] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            else [urlParams setObject:[[NSString alloc] init] forKey:[parameter stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    [urlParams setObject:self forKey:@"webviewdelegate"];
    [urlParams setObject:_webView forKey:@"webview"];
    return urlParams;
}
#endif

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL shouldLoad = YES;
    
    if (_gestureNavigationEnabled) {
        [self webView:webView updateSnapshotAndDisplayWithRequest:request navigationType:navigationType];
    }
    //优先由用户自定义delegate处理，因为_bridge对其不处理的情况默认返回 YES
    //用户自定义的delegate处理
    if ([_managedDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        shouldLoad = [_managedDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
        if (!shouldLoad) {
            return NO;
        }
    }
    
    //javascriptBridge对跳转的拦截
    if ([_bridge respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]){
        shouldLoad = [_bridge webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
        if (!shouldLoad) {
            return NO;
        }
    }
    
    //progressProxy需要根据delegate事件计算大概进度
    if ([_progressProxy respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        shouldLoad = [_progressProxy webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
        if (!shouldLoad){
            return NO;
        }
    }
    
#if SUPPORT_CONTROLLER_ROUTER
    //router
    if (![self routerLoadRequest:request])
        return NO;
#endif
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if ([_managedDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_managedDelegate webViewDidStartLoad:webView];
    }
    
    if ([_bridge respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_bridge webViewDidStartLoad:webView];
    }
    
    if ([_progressProxy respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_progressProxy webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if ([_managedDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_managedDelegate webViewDidFinishLoad:webView];
    }
    
    if ([_bridge respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_bridge webViewDidFinishLoad:webView];
    }
    
    if ([_progressProxy respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_progressProxy webViewDidFinishLoad:webView];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if ([_managedDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [_managedDelegate webView:webView didFailLoadWithError:error];
    }
    
    if (_bridge && [_bridge respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [_bridge webView:webView didFailLoadWithError:error];
    }
    
    if (_progressProxy && [_progressProxy respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [_progressProxy webView:webView didFailLoadWithError:error];
    }
}

#ifdef supportsWKWebKit
+ (SEL)selectorFromOriginalFuncName:(const char *)original
{
    NSString *funcName = [NSString stringWithUTF8String:original];
    NSRange beginRange = [funcName rangeOfString:@"-["];
    NSRange endRange = [funcName rangeOfString:@"]"];
    NSRange selectorRange = NSMakeRange(NSMaxRange(beginRange), endRange.location - NSMaxRange(beginRange));
    NSString *selName = [funcName substringWithRange: selectorRange];
    
    NSArray<NSString*> *splited = [selName componentsSeparatedByString:@" "];
    
    SEL sel = NULL;
    if (splited.count > 1) {
        sel = NSSelectorFromString(splited[1]);
    }
    
    return sel;
}

#pragma mark WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (!webView) {
        return;
    }
    
    SEL sel = [HTWebViewDelegate selectorFromOriginalFuncName:__func__];
    
    //需要为 decisionHandler 传入 WKNavigationActionPolicyAllow 或者 WKNavigationActionPolicyCancel
    //优先由 managedWKDelegate进行处理
    //不然WKBridge内部对其不处理的情况默认为block传入 WKNavigationActionPolicyAllow
    if ([_managedWKDelegate respondsToSelector:sel]) {
        [_managedWKDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
        return;
    }
    if ([_wkBridge respondsToSelector:sel]) {
        [_wkBridge webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
        return;
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    if (!webView) {
        return;
    }
    
    SEL sel = [HTWebViewDelegate selectorFromOriginalFuncName:__func__];
    //需要为 decisionHandler 传入 WKNavigationActionPolicyAllow 或者 WKNavigationActionPolicyCancel
    //优先由 managedWKDelegate进行处理
    //不然WKBridge内部对其不处理的情况默认为block传入 WKNavigationActionPolicyAllow
    if ([_managedWKDelegate respondsToSelector:sel]) {
        [_managedWKDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
        return;
    }
    if ([_wkBridge respondsToSelector:sel]) {
        [_wkBridge webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
        return;
    }
    
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    if (!webView) {
        return;
    }
    
    SEL sel = [HTWebViewDelegate selectorFromOriginalFuncName:__func__];
    
    if ([_managedWKDelegate respondsToSelector:sel]) {
        [_managedWKDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
    
    if ([_wkBridge respondsToSelector:sel]) {
        [_wkBridge webView:webView didStartProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    if (!webView) {
        return;
    }
    
    SEL sel = [HTWebViewDelegate selectorFromOriginalFuncName:__func__];
    
    if ([_managedWKDelegate respondsToSelector:sel]) {
        [_managedWKDelegate webView:webView didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
    
    if ([_wkBridge respondsToSelector:sel]) {
        [_wkBridge webView:webView didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (!webView) {
        return;
    }
    
    SEL sel = [HTWebViewDelegate selectorFromOriginalFuncName:__func__];
    
    if ([_managedWKDelegate respondsToSelector:sel]) {
        [_managedWKDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
    
    if ([_wkBridge respondsToSelector:sel]) {
        [_wkBridge webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
    if (!webView) {
        return;
    }
    
    SEL sel = [HTWebViewDelegate selectorFromOriginalFuncName:__func__];
    
    if ([_managedWKDelegate respondsToSelector:sel]) {
        [_managedWKDelegate webView:webView didCommitNavigation:navigation];
    }
    
    if ([_wkBridge respondsToSelector:sel]) {
        [_wkBridge webView:webView didCommitNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    if (!webView) {
        return;
    }
    
    SEL sel = [HTWebViewDelegate selectorFromOriginalFuncName:__func__];
    
    if ([_managedWKDelegate respondsToSelector:sel]) {
        [_managedWKDelegate webView:webView didFinishNavigation:navigation];
    }
    
    if ([_wkBridge respondsToSelector:sel]) {
        [_wkBridge webView:webView didFinishNavigation:navigation];
    }
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (!webView) {
        return;
    }
    
    SEL sel = [HTWebViewDelegate selectorFromOriginalFuncName:__func__];
    
    if ([_managedWKDelegate respondsToSelector:sel]) {
        [_managedWKDelegate webView:webView didFailNavigation:navigation withError:error];
    }
    
    if ([_wkBridge respondsToSelector:sel]) {
        [_wkBridge webView:webView didFailNavigation:navigation withError:error];
    }
    
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler
{
    if (!webView) {
        return;
    }
    
    SEL sel = [HTWebViewDelegate selectorFromOriginalFuncName:__func__];
    
    if ([_managedWKDelegate respondsToSelector:sel]) {
        [_managedWKDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
        return;
    }
    
    if ([_wkBridge respondsToSelector:sel]) {
        [_wkBridge webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
        return;
    }
    
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

#endif

#pragma mark Pan Gesture Navigation Support

- (void)initGestureNavigation:(UIWebView*)webView
{
    _snapshotStack = [NSMutableArray array];
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHandle:)];
    
    [webView addGestureRecognizer:_panGesture];
    
    [HTWebViewDelegate addShadowToView:webView];
    //强制设置为YES，接口中写明
    webView.scalesPageToFit = YES;
}

- (void)panGestureHandle:(UIPanGestureRecognizer*)sender
{
    if (![self.webView canGoBack] || _snapshotStack.count == 0) {
//FIXME To Do by ww,此处要劫持系统手势后退，大神不推荐，暂不处理
//        if (self.panDelegate && [self.panDelegate respondsToSelector:@selector(DLPanableWebView:panPopGesture:)]) {
//            [self.panDelegate DLPanableWebView:self panPopGesture:sender];
//        }
//
        return;
    }
    
    CGPoint point = [sender translationInView:self.webView];
    if (sender.state == UIGestureRecognizerStateBegan) {
        _panStartX = point.x;
    }
    else if (sender.state == UIGestureRecognizerStateChanged){
        CGFloat deltaX = point.x - _panStartX;
        if (deltaX > 0) {
            assert([_snapshotStack count] > 0);
            
            CGRect rc = self.webView.frame;
            rc.origin.x = deltaX;
            self.webView.frame = rc;
            [self historyView].image = [[_snapshotStack lastObject] objectForKey:@"preview"];
            rc.origin.x = -self.webView.bounds.size.width/2.0f + deltaX/2.0f;
            [self historyView].frame = rc;
        }
    }
    else if (sender.state == UIGestureRecognizerStateEnded){
        CGFloat deltaX = point.x - _panStartX;
        CGFloat duration = .5f;
        if ([self.webView canGoBack]) {
            if (deltaX > self.webView.bounds.size.width/4.0f) {
                [UIView animateWithDuration:(1.0f - deltaX/self.webView.bounds.size.width)*duration animations:^{
                    CGRect rc = self.webView.frame;
                    rc.origin.x = self.webView.bounds.size.width;
                    self.webView.frame = rc;
                    rc.origin.x = 0;
                    [self historyView].frame = rc;
                } completion:^(BOOL finished) {
                    CGRect rc = self.webView.frame;
                    rc.origin.x = 0;
                    self.webView.frame = rc;
                    [self webViewGoBack];
                    
                    //webView下移，等开始加载后重现显示
                    [self.webView.superview insertSubview: self.webView belowSubview:[self historyView]];
                }];
            }
            else{
                [UIView animateWithDuration:(deltaX/self.webView.bounds.size.width)*duration animations:^{
                    CGRect rc = self.webView.frame;
                    rc.origin.x = 0;
                    self.webView.frame = rc;
                    rc.origin.x = -self.webView.bounds.size.width/2.0f;
                    [self historyView].frame = rc;
                } completion:^(BOOL finished) {
                    
                }];
            }
        }
    }
}

- (void)webViewGoBack
{
    [self.webView goBack];
    [self.snapshotStack removeLastObject];
}

- (UIImageView *)historyView{
    if (!_prevSnapshotView) {
        if (self.webView.superview) {
            _prevSnapshotView = [[UIImageView alloc] initWithFrame:self.webView.bounds];
            [self.webView.superview insertSubview:_prevSnapshotView belowSubview:self.webView];
        }
    }
    
    return _prevSnapshotView;
}

- (void)redisplayWebView
{
    assert([[self historyView].superview isEqual:self.webView.superview]);
    
    UIView* superview = self.webView.superview;
    if (![self historyView].image) {
        [superview insertSubview: [self historyView] belowSubview:self.webView];
        return;
    }
    
    [UIView animateWithDuration:0.8f delay:0.3f options:UIViewAnimationOptionCurveEaseIn animations:^{
        [self historyView].alpha = 0.5;
        
    } completion:^(BOOL finished) {
        [superview insertSubview: [self historyView] belowSubview:self.webView];
        
        [self historyView].image = nil;
        [self historyView].alpha = 1;
    }];
}

//FXIME To Do by ww  此部分跟Progress对WebView shouldStartLoad....的处理类似，能否融合？暂未想到合适的办法（由deleggate做各种判定并通知各个组件？接口恐怕会写的很丑陋）
- (void) webView:(UIWebView *)webView updateSnapshotAndDisplayWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    //是否是fragment跳转
    BOOL isFragmentJump = NO;
    if (request.URL.fragment) {
        NSString *nonFragmentURL = [request.URL.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:request.URL.fragment] withString:@""];
        isFragmentJump = [nonFragmentURL isEqualToString:webView.request.URL.absoluteString];
    }
    
    //是否是同一主domain内的加载需求，若非主domain的其他frame加载则不予处理
    BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];
    
    //支持对web页及本地文件的加载处理
    NSString* scheme = [request.URL.scheme lowercaseString];
    BOOL isHTTPOrFile = [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"] || [scheme isEqualToString:@"file"];
    
    if (!isFragmentJump && isHTTPOrFile && isTopLevelNavigation) {
        
        if ((navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeOther) && [[webView.request.URL description] length]) {
            
            if (![[[_snapshotStack lastObject] objectForKey:@"url"] isEqualToString:[webView.request.URL description]]) {
                
                UIImage *curPreview = [HTWebViewDelegate snapshotOfView:webView];
                [_snapshotStack addObject:@{@"preview":curPreview, @"url":[webView.request.URL description]}];
            }
        }
        //手势后退上一次浏览页面时，触发延迟切换为显示WebView以避免页面闪现问题
        if (navigationType == UIWebViewNavigationTypeBackForward && isTopLevelNavigation) {
            [self redisplayWebView];
        }
    }
}

+ (UIImage *)snapshotOfView:(UIView *)view{
    UIGraphicsBeginImageContextWithOptions(view.frame.size, YES, 0.0);
    
    if ([view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    }
    else {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (void)addShadowToView:(UIView *)view{
    CALayer *layer = view.layer;
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:layer.bounds];
    layer.shadowPath = path.CGPath;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOffset = CGSizeZero;
    layer.shadowOpacity = 0.4f;
    layer.shadowRadius = 8.0f;
}

@end
