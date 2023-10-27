import type { PluginListenerHandle } from "@capacitor/core";

export type PageEvent = {
  url: string
}

export interface WebviewControllerPlugin {
  loadURL(options: { url: string, userAgent?: string }): Promise<void>
  closeWindow(): Promise<void>
  evaluateJavaScript(options: { javascript: string }): Promise<{ result: string; }>;

  show(): Promise<void>;
  hide(): Promise<void>;

  addListener(event: "navigation", listener: (args: PageEvent) => void): Promise<PluginListenerHandle> & PluginListenerHandle;
  addListener(event: "page loaded", listener: (args: PageEvent) => void): Promise<PluginListenerHandle> & PluginListenerHandle;
  addListener(event: "closed", listener: () => void): Promise<PluginListenerHandle> & PluginListenerHandle;
}
