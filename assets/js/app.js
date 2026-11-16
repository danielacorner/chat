// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {};

Hooks.SubmitOnEnter = {
  mounted() {
    this.resize = () => {
      this.el.style.height = "auto";
      this.el.style.height = Math.min(this.el.scrollHeight + 2, 320) + "px";
    };
    this.el.addEventListener("input", this.resize);
    this.el.addEventListener("keydown", e => {
      // Enter sends; Shift+Enter inserts a line break (default textarea behaviour)
      if (e.key === "Enter" && !e.shiftKey && !e.isComposing) {
        e.preventDefault();
        if (this.el.value.trim() === "") return;
        this.el.form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
      }
    });
    this.resize();
  },
  updated() { this.resize(); }
};

Hooks.ScrollToBottom = {
  mounted() { this.el.scrollTop = this.el.scrollHeight; },
  beforeUpdate() {
    this.atBottom = this.el.scrollHeight - this.el.scrollTop - this.el.clientHeight < 40;
  },
  updated() { if (this.atBottom) this.el.scrollTop = this.el.scrollHeight; }
};

// Copy button on each chat message
const COPY_ICON = '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4"><path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" /></svg>';
const CHECK_ICON = '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4"><path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" /></svg>';

async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text);
  } catch (_e) {
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.style.position = "fixed";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.select();
    document.execCommand("copy");
    ta.remove();
  }
}

document.addEventListener("click", async e => {
  const btn = e.target.closest("[data-copy-message]");
  if (!btn) return;
  const content = btn.closest(".message")?.querySelector(".message-content");
  if (!content) return;
  await copyText(content.textContent);
  btn.innerHTML = CHECK_ICON + '<span>Copied</span>';
  btn.classList.add("copied");
  clearTimeout(btn._copyTimer);
  btn._copyTimer = setTimeout(() => {
    btn.innerHTML = COPY_ICON;
    btn.classList.remove("copied");
  }, 1500);
});

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: Hooks })

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
