import Foundation
import Capacitor
import UIKit


func generateUserAgent() -> String {
    // Retrieve the current iOS Version
    let iosVersion = UIDevice.current.systemVersion
    
    // Define a basic user-agent format for Safari on iPhone
    let baseUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/%@ Mobile/15E148 Safari/604.1"
    
    // Extract the major version of iOS as that is used in the Safari part of the UA
    // For a more precise version match, you may want to use the full iosVersion string
    let majorVersion = iosVersion.split(separator: ".").first ?? "13"  // Default to `13` if not able to get major version.
    
    // Format the user-agent string, replacing placeholders with the actual versions
    let formattedUserAgent = String(format: baseUserAgent, iosVersion, majorVersion as CVarArg)
    
    print("requested UA gen: " + formattedUserAgent)

    return formattedUserAgent
}

class WebviewOverlay: UIViewController, WKUIDelegate, WKNavigationDelegate {

    var webview: WKWebView?
    var plugin: WebviewControllerPlugin!
    var configuration: WKWebViewConfiguration!

    var closeFullscreenButton: UIButton!
    var topSafeArea: CGFloat!

    var currentDecisionHandler: ((WKNavigationResponsePolicy) -> Void)? = nil

    var openNewWindow: Bool = false

    var currentUrl: URL?

    var loadUrlCall: CAPPluginCall?

    init(_ plugin: WebviewControllerPlugin, configuration: WKWebViewConfiguration) {
        super.init(nibName: "WebviewController", bundle: nil)
        self.plugin = plugin
        self.configuration = configuration
    }

    deinit {
        self.webview?.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.webview = WKWebView(frame: .zero, configuration: self.configuration)
        self.webview?.customUserAgent = generateUserAgent()
        self.webview?.uiDelegate = self
        self.webview?.navigationDelegate = self
        self.webview?.allowsLinkPreview = true
        

        view = self.webview
        view.isHidden = plugin.hidden
        view.backgroundColor = .white;
        self.webview?.scrollView.bounces = false
        self.webview?.allowsBackForwardNavigationGestures = true;

        self.webview?.isOpaque = false

//        let button = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 60, y: 20, width: 40, height: 40))
//        let image = UIImage(named: "icon", in: Bundle(for: NSClassFromString("WebviewControllerPlugin")!), compatibleWith: nil)
//        button.setImage(image, for: .normal)
//        button.isHidden = true;
//        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
//        button.adjustsImageWhenHighlighted = false
//        button.layer.cornerRadius = 0.5 * button.bounds.size.width
//        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
//
//        let blur = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.regular))
//        blur.frame = button.bounds
//        blur.layer.cornerRadius = 0.5 * button.bounds.size.width
//        blur.clipsToBounds = true
//        blur.isUserInteractionEnabled = false
//        button.insertSubview(blur, at: 0)
//        button.bringSubviewToFront(button.imageView!)
//
//        self.closeFullscreenButton = button
//        view.addSubview(self.closeFullscreenButton)

        self.webview?.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }

    override func viewDidLayoutSubviews() {
        self.topSafeArea = view.safeAreaInsets.top
//        self.closeFullscreenButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: self.topSafeArea + 20, width: 40, height: 40)
    }

    @objc func buttonAction(sender: UIButton!) {
        plugin.toggleFullscreen()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        currentUrl = webView.url
        view.isHidden = plugin.hidden
        if (plugin.hidden) {
            plugin.notifyListeners("updateSnapshot", data: [:])
        }
        if (self.loadUrlCall != nil) {
            self.loadUrlCall?.resolve()
            self.loadUrlCall = nil
        }
        plugin.notifyListeners("page loaded", data: [:])

//        // Remove tap highlight
//        let script = "function addStyleString(str) {" +
//            "var node = document.createElement('style');" +
//            "node.innerHTML = str;" +
//            "document.body.appendChild(node);" +
//            "}" +
//        "addStyleString('html, body {-webkit-tap-highlight-color: transparent;}');"
//        webView.evaluateJavaScript(script)
//        print("attempting to set webview!")
//        webView.evaluateJavaScript("localStorage.setItem('test', true);")
    }

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            if (plugin.hasListeners("navigation")) {
                self.openNewWindow = true
            }
            self.loadUrl(url)
        }
        return nil
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url

        // Check if the URL has a specific scheme you want to handle (e.g., "myscheme")
        if let scheme = url?.scheme, scheme == "capacitor" {
            // Handle the URL with your custom logic
            handleCustomScheme(url: url)
            decisionHandler(.cancel) // Cancel the navigation for this scheme

            // TODO: Copy the localStorage of this (the overlay) into the localStorage of the WKWebView that hosts the app
            // Can get the WKWebView that hosts the app like so:
            // self.plugin.bridge?.webView (WKWebview)
            
            return
        }
        
        if let scheme = url?.scheme, scheme == "com.powerschool.portal" {
            // Handle the URL with your custom logic
            handleCustomScheme(url: url)
            decisionHandler(.cancel) // Cancel the navigation for this scheme. This should hopefully prevent PS Mobile from opening.
            return
        }
        
        // Continue with the default behavior for other schemes
        decisionHandler(.allow)
    }

    func handleCustomScheme(url: URL?) {
        // Implement your custom handling logic for the specific scheme
        if let urlString = url?.absoluteString {
            print("Handling custom scheme: \(urlString)")
            print("checking for listeners...");
            print(plugin.hasListeners("navigation"))
            print("checked! going to notify anyways")
            plugin.notifyListeners("navigation", data: [
                "url": urlString
            ])
            self.plugin.notifyListeners("navigation", data: [
                "url": urlString
            ], retainUntilConsumed: true);
            
        } else {
            print("unable to convert URL properly. bye!");
            print(url);
            print(url?.absoluteString);
        }
    }


    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.clearDecisionHandler()
    }

    func clearDecisionHandler() {
        if (self.currentDecisionHandler != nil) {
            self.currentDecisionHandler!(.allow)
            self.currentDecisionHandler = nil
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if (self.currentDecisionHandler != nil) {
            self.clearDecisionHandler()
        }
        // Nah.
//        if (plugin.hasListeners("navigation")) {
//            self.currentDecisionHandler = decisionHandler
//            print("notifying listeners of response with url: " + (navigationResponse.response.url?.absoluteString ?? ""))
//            plugin.notifyListeners("navigation", data: [
//                "url": navigationResponse.response.url?.absoluteString ?? "",
//                "newWindow": self.openNewWindow,
//                "sameHost": currentUrl?.host == navigationResponse.response.url?.host
//            ])
//            self.openNewWindow = false
//        }
//        else {
            decisionHandler(.allow)
            return
//        }
    }


    public func loadUrl(_ url: URL) {
 
            self.webview?.load(URLRequest(url: url))
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "estimatedProgress") {
            plugin.notifyListeners("progress", data: ["value":self.webview?.estimatedProgress ?? 1])
        }
    }

}

@objc(WebviewControllerPlugin)
public class WebviewControllerPlugin: CAPPlugin {

    var width: CGFloat!
    var height: CGFloat!
    var x: CGFloat!
    var y: CGFloat!

    var hidden: Bool = false

    var fullscreen: Bool = false

    var webviewOverlay: WebviewOverlay!

    private let implementation = WebviewController();
    
    /**
     * Capacitor Plugin load
     */
    override public func load() {}
    
    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.resolve([
            "value": implementation.echo(value)
        ])
    }

    @objc func loadURL(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            let webConfiguration = WKWebViewConfiguration()
            webConfiguration.allowsInlineMediaPlayback = true
            webConfiguration.mediaTypesRequiringUserActionForPlayback = []
//                webConfiguration.applicationNameForUserAgent = "VC Browser (iOS)/v2-redesign Mobile/15E148 Version/15.0" // Use this to bypass google's "Secure Browsers Policy" thing
            if let websiteDataStore = self.bridge?.webView?.configuration.websiteDataStore {
                webConfiguration.websiteDataStore = websiteDataStore // How.
            } else {
                print("WAS NOT ABLE TO GET WEBSITE DATA STORE. DO NOT CONTINUE!")
                webConfiguration.websiteDataStore = WKWebsiteDataStore.default()
            }
            // Content controller
//            let javascript = call.getString("javascript") ?? ""
//            if !javascript.isEmpty {
//                var injectionTime: WKUserScriptInjectionTime!
//                switch call.getInt("injectionTime") {
//                case 0:
//                    injectionTime = .atDocumentStart
//                case 1:
//                    injectionTime = .atDocumentEnd
//                default:
//                    injectionTime = .atDocumentStart
//                }
//                let contentController = WKUserContentController()
//                let script = WKUserScript(source: javascript, injectionTime: injectionTime, forMainFrameOnly: true)
//                contentController.addUserScript(script)
//                webConfiguration.userContentController = contentController
//            }

            self.webviewOverlay = WebviewOverlay(self, configuration: webConfiguration)

            guard let urlString = call.getString("url") else {
                call.reject("Must provide a URL to open")
                return
            }

            if let url = URL(string: urlString),
               let encodedURLString = url.absoluteString.data(using: .utf8)?.base64EncodedString() {
                let updatedURLString = "https://vc-assist.github.io/auth.html?url=\(encodedURLString)"
                if let updatedURL = URL(string: urlString) {
                    self.hidden = false

                    self.width = CGFloat(call.getFloat("width") ?? 0)
                    self.height = CGFloat(call.getFloat("height") ?? 0)
                    self.x = CGFloat(call.getFloat("x") ?? 0)
                    self.y = CGFloat(call.getFloat("y") ?? 0)

                    self.webviewOverlay.view.isHidden = true
                    self.bridge?.viewController?.addChild(self.webviewOverlay)
                    self.bridge?.viewController?.view.addSubview(self.webviewOverlay.view)
                    self.webviewOverlay.view.frame = CGRect(x: self.x, y: self.y, width: self.width, height: self.height)
                    self.webviewOverlay.didMove(toParent: self.bridge?.viewController)
                    print("loading url...")
                    print(updatedURL);
                    self.webviewOverlay.loadUrl(updatedURL);
                    if (!self.fullscreen){
                        print("is not in fs, toggling...")
                        self.toggleFullscreen();
                    } else {
                        print("is in full screen on initial load! this should be fine, hopefully!");
                        self.toggleFullscreen();
                        self.toggleFullscreen();
//                        // TODO: Show an Error box!
//                        let errorMessage = "VCAssistNative Error: iOS Webview will not be shown due to fullscreen on initial load. Please report this error to the developers. "
//                        let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
//                        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
//                        alertController.addAction(okAction)
//
//                        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
//                            topViewController.present(alertController, animated: true, completion: nil)
//                        }
//
//                        call.reject(errorMessage);
                    }
                } else {
                    call.reject("Failed to create updated URL")
                }
            } else {
                call.reject("Failed to create URL from the provided string")
            }
        }
    }


    @objc func close(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if (self.webviewOverlay != nil) {
                self.webviewOverlay.view.removeFromSuperview()
                self.webviewOverlay.removeFromParent()
                self.webviewOverlay = nil
                self.hidden = false
            }
        }
    }
    
    @objc func closeWindow(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if (self.webviewOverlay != nil) {
                print("got closeWindow request, closing!")
                self.webviewOverlay.view.removeFromSuperview()
                self.webviewOverlay.removeFromParent()
                self.webviewOverlay = nil
                self.hidden = false
            }
        }
    }

    @objc func getSnapshot(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if (self.webviewOverlay != nil) {
                if (self.webviewOverlay.webview != nil) {
                    let offset: CGPoint = (self.webviewOverlay.webview?.scrollView.contentOffset)!
                    self.webviewOverlay.webview?.scrollView.setContentOffset(offset, animated: false)

                    self.webviewOverlay.webview?.takeSnapshot(with: nil) {image, error in
                        if let image = image {
                            guard let jpeg = image.jpegData(compressionQuality: 1) else {
                                return
                            }
                            let base64String = jpeg.base64EncodedString()
                            call.resolve(["src": base64String])
                        } else {
                            call.resolve(["src": ""])
                        }
                    }
                }
                else {
                    call.resolve(["src": ""])
                }
            }
            else {
                call.resolve(["src": ""])
            }
        }
    }

    @objc func updateDimensions(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.width = CGFloat(call.getFloat("width") ?? 0)
            self.height = CGFloat(call.getFloat("height") ?? 0)
            self.x = CGFloat(call.getFloat("x") ?? 0)
            self.y = CGFloat(call.getFloat("y") ?? 0)

            if (!self.fullscreen) {
                let rect = CGRect(x: self.x, y: self.y, width: self.width, height: self.height)
                self.webviewOverlay.view.frame = rect
            }
            else {
                let width = UIScreen.main.bounds.width
                let height = UIScreen.main.bounds.height
                let rect = CGRect(x: 0, y: 0, width: width, height: height)
                self.webviewOverlay.view.frame = rect
            }
//
//            if (self.webviewOverlay.topSafeArea != nil && self.webviewOverlay.closeFullscreenButton != nil) {
//                self.webviewOverlay.closeFullscreenButton.frame = CGRect(x: UIScreen.main.bounds.width - 60, y: self.webviewOverlay.topSafeArea + 20, width: 40, height: 40)
//            }
            
            if (self.hidden) {
                self.notifyListeners("updateSnapshot", data: [:])
            }
            call.resolve()
        }
    }

    @objc func show(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.hidden = false
            if (self.webviewOverlay != nil) {
                self.webviewOverlay.view.isHidden = false
            }
            call.resolve()
        }
    }

    @objc func hide(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.hidden = true
            if (self.webviewOverlay != nil) {
                self.webviewOverlay.view.isHidden = true
            }
            call.resolve()
        }
    }

    @objc func evaluateJavaScript(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let javascript = call.getString("javascript") else {
                call.reject("Must provide javascript string")
                return
            }
            if (self.webviewOverlay != nil) {
                if (self.webviewOverlay.webview != nil) {
                    func eval(completionHandler: @escaping (_ response: String?) -> Void) {
                        self.webviewOverlay.webview?.evaluateJavaScript(String(javascript)) { (value, error) in
                            if error != nil {
                                call.reject(error?.localizedDescription ?? "unknown error")
                            }
                            else if let valueName = value as? String {
                                completionHandler(valueName)
                            }
                        }
                    }

                    eval(completionHandler: { response in
                        call.resolve(["result": response as Any])
                    })
                }
                else {
                    call.resolve(["result": ""])
                }
            }
            else {
                call.resolve(["result": ""])
            }
        }
    }

    @objc func toggleFullscreen(_ call: CAPPluginCall? = nil) {
        DispatchQueue.main.async {
            if (self.webviewOverlay != nil) {
                if (self.fullscreen) {
                    let rect = CGRect(x: self.x, y: self.y, width: self.width, height: self.height)
                    self.webviewOverlay.view.frame = rect
                    self.fullscreen = false
//                    self.webviewOverlay.closeFullscreenButton.isHidden = true
                }
                else {
                    let width = UIScreen.main.bounds.width
                    let height = UIScreen.main.bounds.height
                    let rect = CGRect(x: 0, y: 0, width: width, height: height)
                    self.webviewOverlay.view.frame = rect
                    self.fullscreen = true
//                    self.webviewOverlay.closeFullscreenButton.isHidden = false
                }
                if (call != nil) {
                    call!.resolve()
                }
            }
        }
    }

    @objc func goBack(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if (self.webviewOverlay != nil) {
                self.webviewOverlay.webview?.goBack()
                call.resolve()
            }
        }
    }

    @objc func goForward(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if (self.webviewOverlay != nil) {
                self.webviewOverlay.webview?.goForward()
                call.resolve()
            }
        }
    }

    @objc func reload(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if (self.webviewOverlay != nil) {
                self.webviewOverlay.webview?.reload()
                call.resolve()
            }
        }
    }

    @objc func loadUrl_legacy(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if (self.webviewOverlay != nil) {
                let url = call.getString("url") ?? ""
                self.webviewOverlay.loadUrlCall = call
                self.webviewOverlay.loadUrl(URL(string: url)!)
            }
        }
    }

    @objc func handleNavigationEvent(_ call: CAPPluginCall) {
        if (self.webviewOverlay != nil && self.webviewOverlay.currentDecisionHandler != nil) {
            if (call.getBool("allow") ?? true) {
                self.webviewOverlay.currentDecisionHandler!(.allow)
            }
            else {
                self.webviewOverlay.currentDecisionHandler!(.cancel)
                self.notifyListeners("page loaded", data: [:])
            }
            self.webviewOverlay.currentDecisionHandler = nil
            call.resolve()
        }
    }
}

