/**
 * The navigable options: everything the arrow keys, type-ahead and the active
 * option may land on. Disabled rows are left out, so nothing here can activate
 * a row the user cannot pick.
 */
export function options(dropdown: HTMLElement): HTMLElement[] {
  return Array.from(
    dropdown.querySelectorAll<HTMLElement>(".combobox-option:not([data-disabled])"),
  );
}

/**
 * Every option row, disabled ones included — for the passes that must cover the
 * whole list rather than only what is reachable: clearing stale state, reading
 * the checked value, keeping rendered order stable.
 */
export function allOptions(dropdown: HTMLElement): HTMLElement[] {
  return Array.from(dropdown.querySelectorAll<HTMLElement>(".combobox-option"));
}

export function isOpen(dropdown: HTMLElement): boolean {
  return dropdown.matches(":popover-open");
}

export function activeOption(host: HTMLElement, dropdown: HTMLElement): HTMLElement | null {
  const id = host.getAttribute("aria-activedescendant");
  return id ? dropdown.querySelector<HTMLElement>("#" + CSS.escape(id)) : null;
}

export function setActive(
  host: HTMLElement,
  dropdown: HTMLElement,
  index: number,
): HTMLElement | null {
  const opts = options(dropdown);
  if (!opts.length) return null;

  const opt = opts[Math.min(Math.max(index, 0), opts.length - 1)];
  opts.forEach((o) => o.classList.toggle("is-active", o === opt));
  host.setAttribute("aria-activedescendant", opt.id);
  opt.scrollIntoView({ block: "nearest" });

  return opt;
}

export function clearActive(host: HTMLElement, dropdown: HTMLElement): void {
  allOptions(dropdown).forEach((o) => o.classList.remove("is-active"));
  host.removeAttribute("aria-activedescendant");
}

export function setAriaSelected(dropdown: HTMLElement, option: HTMLElement | null): void {
  allOptions(dropdown).forEach((o) => {
    if (o === option) o.setAttribute("aria-selected", "true");
    else o.removeAttribute("aria-selected");
  });
}

export function nextIndex(current: number, delta: number, length: number): number {
  if (length === 0) return 0;
  if (current < 0) return delta > 0 ? 0 : length - 1;

  return (current + delta + length) % length;
}

/**
 * Where to land when the listbox opens: on the checked option.
 *
 * A checked option can be disabled — a value already held that is no longer
 * offered — and is then not navigable. Rather than falling back to the top of
 * the list, land on the first navigable option after it, which keeps the
 * opening position next to the selection it belongs to.
 */
export function checkedIndex(dropdown: HTMLElement): number {
  const all = allOptions(dropdown);
  const checked = all.find((o) => o.querySelector<HTMLInputElement>("input")?.checked);
  if (!checked) return 0;

  const navigable = options(dropdown);
  const index = navigable.indexOf(checked);
  if (index >= 0) return index;

  const next = all.slice(all.indexOf(checked) + 1).find((o) => navigable.includes(o));

  return next ? navigable.indexOf(next) : lastIndex(dropdown);
}

export function lastIndex(dropdown: HTMLElement): number {
  return Math.max(options(dropdown).length - 1, 0);
}

export function listboxFocused(host: HTMLElement): boolean {
  return host.hasAttribute("aria-activedescendant");
}

export function activate(host: HTMLElement, dropdown: HTMLElement, index: number): void {
  setAriaSelected(dropdown, setActive(host, dropdown, index));
}

export function deactivate(host: HTMLElement, dropdown: HTMLElement): void {
  clearActive(host, dropdown);
  setAriaSelected(dropdown, null);
}

export function move(host: HTMLElement, dropdown: HTMLElement, delta: number): void {
  const opts = options(dropdown);
  if (!opts.length) return;

  const active = activeOption(host, dropdown);
  const current = active ? opts.indexOf(active) : -1;

  activate(host, dropdown, nextIndex(current, delta, opts.length));
}
