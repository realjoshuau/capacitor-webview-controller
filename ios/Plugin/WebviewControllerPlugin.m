#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>
#import <WebKit/WebKit.h>

CAP_PLUGIN(WebViewControllerPlugin, "WebViewController",
   CAP_PLUGIN_METHOD(loadURL, CAPPluginReturnPromise);
   CAP_PLUGIN_METHOD(closeWindow, CAPPluginReturnPromise);
   CAP_PLUGIN_METHOD(evaluateJavaScript, CAPPluginReturnPromise);
   CAP_PLUGIN_METHOD(show, CAPPluginReturnNone);
   CAP_PLUGIN_METHOD(hide, CAPPluginReturnNone);
   CAP_PLUGIN_METHOD(addListener, CAPPluginReturnCallback);
   CAP_PLUGIN_METHOD(removeListener, CAPPluginReturnNone);
);