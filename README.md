HTWebView
---

HTWebView 是一套对 WebView 进行功能扩展的解决方案。

![](images/demo.gif)

特性
---
* 集成[WebViewJavascriptBridge](https://github.com/marcuswestin/WebViewJavascriptBridge)提供的JavaScript与Navitve的通信机制
* 与页面导航管理[HTUniversalRouter](...)结合使用，支持到Native页面的跳转
* 支持页面加载进度条的显示
* 网页滑动后退
* 支持页面滑动(右滑)后退
* 提供具备基本功能的WebView Controller

用法
---


####创建UIWebView
```
/*创建UIWebView*/
UIWebView* myWebView = [[UIWebView alloc]init];

/*ViewContrller遵循UIWebViewDelegate*/
MyViewContrller: UIViewController <UIWebViewDelegate>


```

####创建进度条，MyProcessView需要遵循HTWebViewProgressViewProtocol
```
/*自定义进度条，需要遵循HTWebViewProgressViewProtocol*/
MyProcessView : UIView <HTWebViewProgressViewProtocol>

MyProcessView* processView = [[MyProcessView alloc]init];
```

####创建HTWebViewDelegate

```
/*根据需要配置HTWebViewDelegate*/
HTWebViewDelegate* webViewDelegate = 
[HTWebViewDelegate delegateForWebView:_webView 
	webviewDelegate:self 
	enableJavascriptBridge:YES 
	withJavascriptDefaultHandler:^(id data, WVJBResponseCallback responseCallback) {
	        HTDemoLogDebug(@"ObjC received message from JS: %@", data);
	        responseCallback(@"Response for message from ObjC");
	    } 
    enableProgress:YES 
    withProgressView:_gradView 
    enableGestureNavigation:YES];
```

####获取WebViewJavascriptBridge，做JavaScript与Objective-C的通信
```    				
WebViewJavascriptBridge* bridge = [webViewDelegate javascriptBridge]; 

[bridge send:@"A string sent from ObjC before Webview has loaded." responseCallback:^(id responseData) {
        NSLog(@"objc got response! %@", responseData);
    }];

```


安装
---
###	CocoaPods

1. `pod 'HTWebView' , :git=>'https://g.hz.netease.com/HTIOSUI/HTWebView.git'`
2. `pod install`或`pod update`
3. \#import "HTWebView.h"
	
系统要求
---

该项目最低支持`iOS 7.0`和`Xcode 7.0`

许可证
---

HTWebView，详情见LICENSE文件。
