package com.lqr471814.capacitor.webviewcontroller;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
import android.view.View;
import android.content.Context;

@CapacitorPlugin(name = "WebviewController")
public class WebviewControllerPlugin extends Plugin {
    private Webview webview;

    @Override
    public void load() {
        super.load();
    }

    private void ensureWebView() {
        if (webview != null) {
            return;
        }
        webview = new WebView(context);

        ((ViewGroup) getBridge().getWebView().getParent()).addView(webview);

        WebSettings settings = webview.getSettings();
        settings.setAllowContentAccess(true);
        settings.setJavaScriptEnabled(true);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
        settings.setDomStorageEnabled(true);

        webview.setWebViewClient(new WebViewClient());
    }

    private void closeWebView() {
        ViewGroup rootGroup = ((ViewGroup) getBridge().getWebView().getParent());
        int count = rootGroup.getChildCount();
        if (count > 1) {
            rootGroup.removeView(webView);
            webView.destroyDrawingCache();
            webView.destroy();
            webView = null;
        }
    }

    @PluginMethod
    public void loadURL(PluginCall call) {
        String url = call.getString("url");
        getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                ensureWebView();
                webview.loadUrl(url);
                call.success();
            }
        });
    }

    @PluginMethod
    public void closeWindow(PluginCall call) {
        if (webview == null) {
            call.error("Must initialize webview first.");
            return;
        }
        getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                closeWebView();
                call.success();
            }
        });
    }

    @PluginMethod
    public void evaluateJavascript(PluginCall call) {
        if (javascript.isEmpty()) {
            call.error("Must provide javascript string.");
            return;
        }
        if (webview == null) {
            call.error("Must initialize webview first.");
            return;
        }
        getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                webview.evaluateJavascript(
                    call.getString("javascript"),
                    new ValueCallback<String>() {
                        @Override
                        public void onReceiveValue(String result) {
                            JSObject obj = new JSObject();
                            obj.put("result", result);
                            call.resolve(obj);
                        }
                    }
                );
            }
        })
        call.success();
    }

    @PluginMethod
    public void show(PluginCall call) {
        if (webview == null) {
            call.error("Must initialize webview first.");
            return;
        }
        getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                webView.setVisibility(View.VISIBLE);
                call.success();
            }
        });
    }

    @PluginMethod
    public void hide() {
        if (webview == null) {
            call.error("Must initialize webview first.");
            return;
        }
        getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                webView.setVisibility(View.INVISIBLE);
                call.success();
            }
        });
    }
}
