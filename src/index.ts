import { registerPlugin } from "@capacitor/core";

import type { WebviewControllerPlugin } from "./definitions";

const WebviewController = registerPlugin<WebviewControllerPlugin>(
  "WebviewController",
  {
    electron: () => (window as any).CapacitorCustomPlatform.plugins.WebviewController,
  }
);

export * from "./definitions";
export { WebviewController };
