import { registerPlugin } from '@capacitor/core';

import type { WebviewControllerPlugin } from './definitions';

const WebviewController = registerPlugin<WebviewControllerPlugin>(
  'WebviewController',
  {
    web: () => import('./web').then(m => new m.WebviewControllerWeb()),
  },
);

export * from './definitions';
export { WebviewController };
