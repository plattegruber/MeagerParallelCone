import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}
Hooks.DeviceId = {
  mounted() {
    // Get device_id from localStorage
    let device_id = localStorage.getItem("device_id") || ""
    this.pushEvent("device_id_set", {device_id: device_id})

    // Listen for store_device_id event
    this.handleEvent("store_device_id", ({device_id}) => {
      localStorage.setItem("device_id", device_id)
      this.pushEvent("device_id_set", {device_id: device_id})
    })
  }
}

Hooks.HPAnimation = {
  mounted() {
    this.handleHPChange()
  },
  updated() {
    this.handleHPChange()
  },
  handleHPChange() {
    console.log('Handling HP change for', this.el.id)
    this.el.classList.add('animate')
    setTimeout(() => {
      this.el.classList.remove('animate')
    }, 200) // Match this to your animation duration
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks  // Add the hooks here
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket