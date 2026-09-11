// esbuild replaces `process.env.NODE_ENV` at build time for the browser platform;
// there is no Node runtime here, so this is just enough of a type to satisfy tsc.
declare const process: { env: { NODE_ENV?: string } };

// Minimal shape of the `phx:live_reload:attached` event detail, provided by
// phoenix_live_reload's injected browser script (no published types exist for it).
type LiveReloader = {
  enableServerLogs(): void;
  disableServerLogs(): void;
  openEditorAtCaller(el: EventTarget | null): void;
  openEditorAtDef(el: EventTarget | null): void;
};

interface Window {
  liveReloader?: LiveReloader;
  liveSocket?: InstanceType<(typeof import("phoenix_live_view"))["LiveSocket"]>;
}

declare module "phoenix_html";

declare module "live_toast" {
  import type { Hook } from "phoenix_live_view";

  export function createLiveToastHook(duration: number, maxItems: number): Hook;
}

declare module "phoenix-colocated/my_app" {
  import type { HooksOptions } from "phoenix_live_view";

  export const hooks: HooksOptions;
}
