package com.lqr471814.capacitor.webviewcontroller;

import android.util.Log;

public class WebviewController {

    public String echo(String value) {
        Log.i("Echo", value);
        return value;
    }
}
