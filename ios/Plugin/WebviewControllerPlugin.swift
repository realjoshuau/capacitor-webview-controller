import UIKit
import Capacitor
import WebKit

@objc(WebViewControllerPlugin)
public class WebViewControllerPlugin: CAPPlugin, WKNavigationDelegate {

    var customWebView: WKWebView?
    
    // Declaring Notification Names
    enum NotificationName: String {
        case willNavigate = "navigation"
        case didFinishLoad = "page loaded"
        case didClose = "closed"
    }

    @objc func loadURL(_ call: CAPPluginCall) {
        
        print("Loading webview....");
        
        let urlString = call.getString("url") ?? "https://google.com"
        let userAgent = call.getString("userAgent") ?? ""

        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.applicationNameForUserAgent = userAgent

        customWebView = WKWebView(frame: UIScreen.main.bounds, configuration: webViewConfiguration)
        customWebView?.navigationDelegate = self

        DispatchQueue.main.async {
            if let url = URL(string: urlString) {
                self.customWebView?.load(URLRequest(url: url))
                NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationName.willNavigate.rawValue), object: url)
            }

            if let customWebView = self.customWebView, let viewController = self.bridge?.viewController {
                viewController.view.addSubview(customWebView)
            }

            call.resolve()
        }
        
        call.resolve();
    }

    @objc func closeWindow(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.customWebView?.removeFromSuperview()
            self.customWebView = nil
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationName.didClose.rawValue), object: nil)
        }

        call.resolve()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationName.didFinishLoad.rawValue), object: webView.url)
    }

    @objc func evaluateJavaScript(_ call: CAPPluginCall) {
        let javascript = call.getString("javascript") ?? ""

        customWebView?.evaluateJavaScript(javascript, completionHandler: { result, error in
            if let error = error {
                call.reject("Failed to evaluate JavaScript", "ERR_EVALUATE_JS", error)
            } else {
                call.resolve([
                    "result": String(describing: result!)
                ])
            }
        })
    }

    @objc func show(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.customWebView?.isHidden = false
        }

        call.resolve()
    }

    @objc func hide(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.customWebView?.isHidden = true
        }
        
        call.resolve()
    }
}
