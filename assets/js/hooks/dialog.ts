import { ViewHook } from "phoenix_live_view";

/**
 * The hook behind both `<dialog>` containers, `Containers.modal/1` and
 * `Containers.drawer/1` — they differ only in where the panel sits.
 *
 * Opening and closing go through `dialog:open` / `dialog:close` from the
 * client and `open-dialog:<id>` / `close-dialog:<id>` from the server.
 */
export default class DialogHook extends ViewHook<HTMLDialogElement> {
  declare open: () => void;
  declare close: () => void;
  declare dropdownOpen: boolean;

  mounted() {
    const dialog = this.el;

    this.open = () => {
      if (dialog.open) return;

      // A non-modal dialog leaves the page behind it live.
      if (dialog.dataset.modal === "false") dialog.show();
      else dialog.showModal();
    };

    this.close = () => {
      if (dialog.open) dialog.close();
    };

    if (dialog.dataset.openOnMount === "true") {
      dialog.getBoundingClientRect();
      this.open();
    }

    dialog.addEventListener("dialog:open", this.open);
    dialog.addEventListener("dialog:close", this.close);

    dialog.addEventListener(
      "keydown",
      (e) => {
        if (e.key === "Escape")
          this.dropdownOpen = !!dialog.querySelector(".combobox-dropdown:popover-open");
      },
      true,
    );

    dialog.addEventListener("cancel", (e) => {
      if (dialog.dataset.dismissable === "false" || this.dropdownOpen) {
        e.preventDefault();
        this.dropdownOpen = false;
      }
    });

    dialog.addEventListener("close", () => {
      const event = dialog.dataset.cancel;
      if (event) this.pushCancel(event);
    });

    this.handleEvent(`open-dialog:${dialog.id}`, this.open);
    this.handleEvent(`close-dialog:${dialog.id}`, this.close);
  }

  /** Pushes `on_cancel`, honouring `on_cancel_target` when one was given. */
  pushCancel(event: string): void {
    const target = this.el.dataset.cancelTarget;

    if (target) this.pushEventTo(/^\d+$/.test(target) ? Number(target) : target, event, {});
    else this.pushEvent(event, {});
  }
}
