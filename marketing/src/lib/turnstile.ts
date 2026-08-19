// Cloudflare Turnstile helpers. Explicit rendering (not the implicit
// `.cf-turnstile` auto-render) so widgets re-render after client-side view
// transitions, when the forms re-initialize on astro:page-load. All no-ops when
// the widget/script is absent (i.e. before a site key is configured).

interface TurnstileApi {
  render(el: HTMLElement, opts: { sitekey: string }): string;
  getResponse(id?: string): string | undefined;
  reset(id?: string): void;
}

declare global {
  interface Window {
    turnstile?: TurnstileApi;
  }
}

/// Renders the widget in `container` once its api.js has loaded (retries briefly
/// if the script is still loading). Safe to call repeatedly.
export function renderTurnstile(container: HTMLElement | null): void {
  if (!container) return;
  const sitekey = container.dataset.sitekey;
  if (!sitekey || container.dataset.rendered === 'true') return;

  const tryRender = (): boolean => {
    if (!window.turnstile) return false;
    container.dataset.widgetId = window.turnstile.render(container, { sitekey });
    container.dataset.rendered = 'true';
    return true;
  };

  if (tryRender()) return;
  const iv = setInterval(() => {
    if (tryRender()) clearInterval(iv);
  }, 200);
  setTimeout(() => clearInterval(iv), 10000);
}

/// The current token, or '' if no widget (so the server decides whether a token
/// is required based on whether the secret is configured).
export function turnstileToken(container: HTMLElement | null): string {
  if (!container || !window.turnstile) return '';
  try {
    return window.turnstile.getResponse(container.dataset.widgetId) ?? '';
  } catch {
    return '';
  }
}

/// Resets the widget after a failed submit so the user can retry.
export function resetTurnstile(container: HTMLElement | null): void {
  if (!container || !window.turnstile) return;
  try {
    window.turnstile.reset(container.dataset.widgetId);
  } catch {
    // ignore
  }
}
