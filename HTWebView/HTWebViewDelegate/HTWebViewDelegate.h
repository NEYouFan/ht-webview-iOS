//
//  HTWebViewDelegate.h
//  Pods
//
//  Created by Wayne Wei on 15/9/6.
//
//

#import <UIKit/UIkit.h>
#import "WebViewJavascriptBridge.h"

#ifdef  WKWEBVIEW_SUPPORT_ENABLED
#import "WKWebViewJavascriptBridge.h"
#endif

//该宏定义是由 WKWebViewJavascriptBridge.h 文件引入，故不方便改为统一的宏格式
//即通过是否启用 WKWEBVIEW_SUPPORT_ENABLED 宏可以启用 supportsWKWebKit 宏
#ifdef supportsWKWebKit

#import <WebKit/WebKit.h>

#endif

@protocol HTWebViewProgressViewProtocol;

#ifdef supportsWKWebKit
@interface HTWebViewDelegate : NSObject <UIWebViewDelegate, WKNavigationDelegate, WKUIDelegate>

#else
@interface HTWebViewDelegate : NSObject <UIWebViewDelegate>

#endif

/**
 *  工厂方法，返回HTWebViewDelegate对象，支持设置自定义UIWebViewDelegate/启用JavascriptBridge/Web页加载进度显示/页面滑动返回
 *
 *  @param webView           UIWebView控件对象，用户负责维护其生命周期，即delegate对其为弱引用
 *  @param webviewDelegate   用户自行的实现了UIWebViewDelegate协议的对象
 *  @param bridgeEnabled     是否启用JavascriptBridge
 *  @param defaultHandler    对Javascript调用消息的默认响应block
 *  @param progressEnabled   是否启用web页加载进度显示
 *  @param progressView      用户自定义进度条，若progressEnabled为YES,则不能传入nil。
 *  @param navigationEnabled 是否启动滑动返回上一浏览页面功能；需注意，启用同时webView对象的scalesPageToFit属性会为设置为YES。非整屏宽度的webView暂不支持。
 *
 *  @return HTWebViewDelegate类型对象，需用户维护其生命周期
 */
+ (instancetype)delegateForWebView:(UIWebView*)webView
                   webviewDelegate:(id<UIWebViewDelegate>)webviewDelegate
            enableJavascriptBridge:(BOOL)bridgeEnabled
      withJavascriptDefaultHandler:(WVJBHandler)defaultHandler
                    enableProgress:(BOOL)progressEnabled
                  withProgressView:(UIView <HTWebViewProgressViewProtocol>*)progressView
           enableGestureNavigation:(BOOL)navigationEnabled;



/**
 *  获取HTWebViewDelegate对象持有的WebViewJavascriptBridge对象，可通过该对象进行JavaScript与Navitve的通信机制
 *
 *  @return WebViewJavascriptBridge类型对象，用户不需要维护其生命周期
 */
- (WebViewJavascriptBridge*)javascriptBridge;


#ifdef supportsWKWebKit
+ (instancetype)delegateForWKWebView:(WKWebView*)wkWebView
                     webviewDelegate:(id<WKNavigationDelegate>)webviewDelegate
              enableJavascriptBridge:(BOOL)bridgeEnabled
        withJavascriptDefaultHandler:(WVJBHandler)defaultHandler
                      enableProgress:(BOOL)progressEnabled
                    withProgressView:(UIView <HTWebViewProgressViewProtocol>*)progressView
             enableGestureNavigation:(BOOL)navigationEnabled;

- (WKWebViewJavascriptBridge*)javascriptBridgeForWKWebView;
#endif

@end
