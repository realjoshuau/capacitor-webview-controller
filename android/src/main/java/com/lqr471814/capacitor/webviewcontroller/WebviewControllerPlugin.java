package com.lqr471814.capacitor.webviewcontroller;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
import android.view.ViewGroup;
import android.view.View;

@CapacitorPlugin(name = "WebviewController")
public class WebviewControllerPlugin extends Plugin {
    private WebView webview;

    @Override
    public void load() {
        super.load();
    }

    private void ensureWebView() {
        if (webview != null) {
            return;
        }
        webview = new WebView(this.getContext());

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
            ensureWebView();
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
