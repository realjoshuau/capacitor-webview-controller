package com.lqr471814.capacitor.webviewcontroller;

import com.getcapacitor.Bridge;
import com.getcapacitor.JSObject;
import com.getcapacitor.Logger;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import android.net.Uri;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
import android.view.ViewGroup;
import android.view.View;

import java.util.Map;
import java.util.Objects;

@CapacitorPlugin(name = "WebviewController")
public class WebviewControllerPlugin extends Plugin {
    private WebView webview;

    @Override
    public void load() {
        super.load();
    }

    private void closeWebView() {
        ViewGroup rootGroup = ((ViewGroup) getBridge().getWebView().getParent());
        int count = rootGroup.getChildCount();
        if (count > 1) {
            rootGroup.removeView(webview);
            webview.destroyDrawingCache();
            webview.destroy();
            webview = null;
        }
    }

    @PluginMethod
    public void loadURL(PluginCall call) {
        String url = call.getString("url");
        if (url == null) {
            call.reject(("Must provide a url to load."));
            return;
        }

        getActivity().runOnUiThread(() -> {
            if (webview != null) {
                return;
            }
            webview = new WebView(this.getContext());

            ViewGroup.LayoutParams params = new ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            );
            webview.setLayoutParams(params);
            webview.requestLayout();
            ((ViewGroup) getBridge().getWebView().getParent()).addView(webview);

            WebSettings settings = webview.getSettings();
            settings.setUserAgentString(System.getProperty("http.agent"));
            settings.setJavaScriptEnabled(true);
            settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
            settings.setDomStorageEnabled(true);

            webview.setWebViewClient(new WebViewClient() {
                public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {
                    if (Objects.equals(request.getUrl().getAuthority(), "local-capacitor")) {
                        Uri.Builder newUri = request.getUrl().buildUpon();
                        newUri.authority("localhost");
                        Uri uri = newUri.build();

                        WebResourceRequest finalRequest = request;
                        request = new WebResourceRequest() {
                            @Override
                            public Uri getUrl() {
                                return uri;
                            }

                            @Override
                            public boolean isForMainFrame() {
                                return finalRequest.isForMainFrame();
                            }

                            @Override
                            public boolean isRedirect() {
                                return finalRequest.isRedirect();
                            }

                            @Override
                            public boolean hasGesture() {
                                return finalRequest.hasGesture();
                            }

                            @Override
                            public String getMethod() {
                                return finalRequest.getMethod();
                            }

                            @Override
                            public Map<String, String> getRequestHeaders() {
                                return finalRequest.getRequestHeaders();
                            }
                        };
                    }

                    WebResourceResponse response = bridge.getLocalServer().shouldInterceptRequest(request);
                    if (response == null) {
                        Logger.info("Skipping interception.");
                        return super.shouldInterceptRequest(view, request);
                    }

                    return response;
                }

                @Override
                public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                    String url = request.getUrl().toString();
                    boolean abort = false;

                    // shouldInterceptRequest doesn't intercept "localhost" for some reason
                    // so instead we load a different unique URL, then intercept it, to get around it.
                    if (Objects.equals(request.getUrl().getAuthority(), "localhost")) {
                        Uri.Builder redirectUri = request.getUrl().buildUpon();
                        redirectUri.authority("local-capacitor");
                        webview.stopLoading();
                        webview.loadUrl(redirectUri.build().toString());
                        abort = true;
                    }

                    Logger.info("URL LOADING REQUEST " + url);
                    if (!hasListeners("navigation")) {
                        return abort;
                    }
                    Logger.info("NOTIFY " + url);
                    JSObject event = new JSObject();
                    event.put("url", url);
                    notifyListeners("navigation", event);
                    return abort;
                }

                @Override
                public void onPageFinished(WebView view, String url) {
                    super.onPageFinished(view, url);
                    JSObject event = new JSObject();
                    event.put("url", url);
                    notifyListeners("page loaded", event);
                }
            });
            webview.loadUrl(url);

            call.resolve();
        });
    }

    @PluginMethod
    public void closeWindow(PluginCall call) {
        if (webview == null) {
            call.reject("Must initialize webview first.");
            return;
        }
        getActivity().runOnUiThread(() -> {
            closeWebView();
            call.resolve();
        });
    }

    @PluginMethod
    public void evaluateJavascript(PluginCall call) {
        String javascript = call.getString("javascript");
        if (javascript == null || javascript.isEmpty()) {
            call.reject("Must provide javascript string.");
            return;
        }
        if (webview == null) {
            call.reject("Must initialize webview first.");
            return;
        }
        getActivity().runOnUiThread(() -> webview.evaluateJavascript(
            javascript,
            result -> {
                JSObject obj = new JSObject();
                obj.put("result", result);
                call.resolve(obj);
            }
        ));
        call.resolve();
    }

    @PluginMethod
    public void show(PluginCall call) {
        if (webview == null) {
            call.reject("Must initialize webview first.");
            return;
        }
        getActivity().runOnUiThread(() -> {
            webview.setVisibility(View.VISIBLE);
            call.resolve();
        });
    }

    @PluginMethod
    public void hide(PluginCall call) {
        if (webview == null) {
            call.reject("Must initialize webview first.");
            return;
        }
        getActivity().runOnUiThread(() -> {
            webview.setVisibility(View.INVISIBLE);
            call.resolve();
        });
    }
}
