import { WebPlugin } from '@capacitor/core';

import type { WebviewControllerPlugin } from './definitions';

export class WebviewControllerWeb
  extends WebPlugin
  implements WebviewControllerPlugin
{
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
