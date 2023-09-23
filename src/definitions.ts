export interface WebviewControllerPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
