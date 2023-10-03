import type { PluginListenerHandle } from "@capacitor/core";
import { BrowserWindow } from "electron";
import type { PageEvent, WebviewControllerPlugin } from "../../src/definitions"
import { EventEmitter } from "node:events"

export class WebviewController extends EventEmitter implements WebviewControllerPlugin {
  window?: BrowserWindow

  private requireWindow(): BrowserWindow {
    if (!this.window) {
      throw new Error("The webview must be opened first.")
    }
    return this.window
  }

  loadURL(options: { url: string, userAgent?: string; }): Promise<void> {
    if (!this.window || this.window.isDestroyed()) {
      this.window = new BrowserWindow({
        autoHideMenuBar: true
      })
    }

    const mainSession = this.window.webContents.session;

    const customCSP = "script-src 'self' 'unsafe-inline' 'unsafe-eval' *; style-src 'self' 'unsafe-inline' *;";
    if (typeof userAgent !== "undefined"){
      session.defaultSession.webRequest.onBeforeSendHeaders((details, callback) => {
        details.requestHeaders['User-Agent'] = userAgent;
        callback({ cancel: false, requestHeaders: details.requestHeaders });
      });
    }
    mainSession.webRequest.onHeadersReceived((details, callback) => {
      const responseHeaders = Object.assign({}, details.responseHeaders, {
        'Content-Security-Policy': customCSP,
      });
      callback({ cancel: false, responseHeaders });
    });

    this.window.loadURL(options.url, 
    return Promise.resolve()
  }
  closeWindow(): Promise<void> {
    this.requireWindow().close()
    this.window = undefined
    return Promise.resolve()
  }

  async evaluateJavaScript(options: { javascript: string; }): Promise<{ result: string; }> {
    const returns = await this.requireWindow().webContents.executeJavaScript(options.javascript)
    return {
      result: JSON.stringify(returns)
    }
  }
  show(): Promise<void> {
    this.requireWindow().show()
    return Promise.resolve()
  }
  hide(): Promise<void> {
    this.requireWindow().hide()
    return Promise.resolve()
  }

  private onNavigate(listener: (args: PageEvent) => void) {
    const win = this.requireWindow()
    const handler = (details: Electron.Event<Electron.WebContentsWillNavigateEventParams>) => {
      const event: PageEvent = {
        url: details.url,
      }
      listener(event)
    }
    win.webContents.addListener("will-navigate", handler)
    return () => {
      win.webContents.removeListener("will-navigate", handler)
      return Promise.resolve()
    }
  }

  private onLoaded(listener: (args: PageEvent) => void) {
    const win = this.requireWindow()
    const handler = () => {
      listener({ url: win.webContents.getURL() })
    }
    win.webContents.addListener("did-finish-load", handler)
    return () => {
      win.webContents.removeListener("did-finish-load", handler)
      return Promise.resolve()
    }
  }

  private onClosed(listener: () => void) {
    const win = this.requireWindow()
    const handler = () => {
      listener()
    }
    win.addListener("closed", handler)
    return () => {
      win.removeListener("closed", handler)
      return Promise.resolve()
    }
  }

  addListener(event: "navigation", listener: (args: PageEvent) => void): this & Promise<PluginListenerHandle> & PluginListenerHandle;
  addListener(event: "page loaded", listener: (args: PageEvent) => void): this & Promise<PluginListenerHandle> & PluginListenerHandle;
  addListener(event: "closed", listener: () => void): this & Promise<PluginListenerHandle> & PluginListenerHandle;
  addListener(event: "navigation" | "page loaded" | "closed", listener: ((args: PageEvent) => void)): this & Promise<PluginListenerHandle> & PluginListenerHandle {
    let removeListener: () => Promise<void>

    try {
      switch (event) {
        case "navigation":
          removeListener = this.onNavigate(listener as (args: PageEvent) => boolean)
        case "page loaded":
          removeListener = this.onLoaded(listener)
        case "closed":
          removeListener = this.onClosed(listener as () => void)
      }
      const listenerHandle = { remove: removeListener }
      return { ...this, ...Promise.resolve(listenerHandle), ...listenerHandle }
    } catch (e) {
      console.error(e)
      throw e
    }
  }
}
