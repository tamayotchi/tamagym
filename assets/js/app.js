import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import "../css/app.css"

const GuestStore = {
  mounted() {
    this.handleEvent("guest:save", ({state}) => {
      localStorage.setItem("gym_local_mode", "1")
      localStorage.setItem("gym_local_state_v1", JSON.stringify(state))
      document.documentElement.dataset.localGuest = "true"
    })
    this.handleEvent("guest:leave", () => {
      localStorage.removeItem("gym_local_mode")
      delete document.documentElement.dataset.localGuest
    })
    this.handleEvent("prefs:apply", ({theme, accent, language}) => applyPrefs(theme, accent, language))

    if (localStorage.getItem("gym_local_mode") === "1") {
      document.documentElement.dataset.localGuest = "true"
      let state = {}
      try { state = JSON.parse(localStorage.getItem("gym_local_state_v1") || "{}") } catch (_) {}
      this.pushEvent("guest:restore", {state})
    }
  }
}

const Elapsed = {
  mounted() {
    const startedAt = Number(this.el.dataset.startedAt || Date.now())
    const tick = () => {
      const seconds = Math.max(0, Math.floor((Date.now() - startedAt) / 1000))
      this.el.textContent = `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`
    }
    tick()
    this.timer = window.setInterval(tick, 1000)
  },
  destroyed() { window.clearInterval(this.timer) }
}

const ExerciseMedia = {
  mounted() {
    this.playing = true
    this.el.addEventListener("click", event => {
      const sizeButton = event.target.closest(".giftoggle")
      if (sizeButton) {
        event.stopPropagation()
        const compact = this.el.classList.toggle("compact")
        const label = sizeButton.querySelector("span")
        sizeButton.setAttribute("aria-label", compact ? this.el.dataset.expandLabel : this.el.dataset.collapseLabel)
        if (label) label.textContent = compact ? this.el.dataset.expandLabel : this.el.dataset.collapseLabel
        return
      }

      this.playing = !this.playing
      const image = this.el.querySelector("img")
      const label = this.el.querySelector(".gifhint span")
      if (image) image.src = this.playing ? this.el.dataset.gif : this.el.dataset.still
      if (label) label.textContent = this.playing ? this.el.dataset.pauseLabel : this.el.dataset.playLabel
    })
  }
}

const NumericInputs = {
  mounted() {
    this.onFocusIn = event => {
      const input = this.numericInput(event.target)
      if (!input) return

      window.requestAnimationFrame(() => {
        if (document.activeElement !== input) return
        input.select()
        try { input.setSelectionRange(0, input.value.length) } catch (_) {}
      })
    }

    this.onInput = event => {
      const input = this.numericInput(event.target)
      if (!input) return

      const value = input.value
      const cursor = input.selectionStart
      const normalized = this.normalize(value, input.dataset.numericInput)
      if (normalized === value) return

      input.value = normalized
      if (cursor !== null) {
        const nextCursor = this.normalize(value.slice(0, cursor), input.dataset.numericInput).length
        try { input.setSelectionRange(nextCursor, nextCursor) } catch (_) {}
      }
    }

    this.el.addEventListener("focusin", this.onFocusIn)
    this.el.addEventListener("input", this.onInput, true)
  },

  destroyed() {
    this.el.removeEventListener("focusin", this.onFocusIn)
    this.el.removeEventListener("input", this.onInput, true)
  },

  numericInput(target) {
    return target?.matches?.("input[data-numeric-input]") ? target : null
  },

  normalize(value, kind) {
    const decimal = kind === "decimal"
    let normalized = String(value).replace(/,/g, decimal ? "." : "")
    normalized = normalized.replace(decimal ? /[^0-9.]/g : /[^0-9]/g, "")

    if (decimal) {
      const decimalAt = normalized.indexOf(".")
      if (decimalAt >= 0) {
        normalized = normalized.slice(0, decimalAt + 1) + normalized.slice(decimalAt + 1).replace(/\./g, "")
      }
      if (normalized.startsWith(".")) normalized = `0${normalized}`
    }

    return normalized.replace(/^0+(?=\d)/, "")
  }
}

const ScrollEnd = {
  mounted() { this.el.scrollLeft = this.el.scrollWidth }
}

const PointChart = {
  mounted() {
    this.onPointerMove = event => {
      const svg = this.el.querySelector("svg")
      const points = [...this.el.querySelectorAll("[data-chart-point]")]
      if (!svg || points.length === 0) return

      const rect = svg.getBoundingClientRect()
      const x = (event.clientX - rect.left) / Math.max(rect.width, 1) * 340
      const point = points.reduce((best, candidate) =>
        Math.abs(Number(candidate.getAttribute("cx")) - x) < Math.abs(Number(best.getAttribute("cx")) - x)
          ? candidate
          : best
      )
      this.showPoint(point)
    }

    this.onPointerLeave = event => {
      if (event.pointerType === "mouse" && !this.el.contains(document.activeElement)) this.hidePoint()
    }

    this.onFocus = event => {
      if (event.target.matches?.("[data-chart-point]")) this.showPoint(event.target)
    }

    this.onKeyDown = event => {
      if (!event.target.matches?.("[data-chart-point]")) return
      if (event.key === "Escape") {
        event.target.blur()
        this.hidePoint()
        return
      }
      if (!['ArrowLeft', 'ArrowRight'].includes(event.key)) return

      event.preventDefault()
      const points = [...this.el.querySelectorAll("[data-chart-point]")]
      const current = points.indexOf(event.target)
      const direction = event.key === "ArrowRight" ? 1 : -1
      points[Math.max(0, Math.min(points.length - 1, current + direction))]?.focus()
    }

    this.el.addEventListener("pointerdown", this.onPointerMove)
    this.el.addEventListener("pointermove", this.onPointerMove)
    this.el.addEventListener("pointerleave", this.onPointerLeave)
    this.el.addEventListener("focusin", this.onFocus)
    this.el.addEventListener("keydown", this.onKeyDown)
  },

  updated() { this.hidePoint() },

  destroyed() {
    this.el.removeEventListener("pointerdown", this.onPointerMove)
    this.el.removeEventListener("pointermove", this.onPointerMove)
    this.el.removeEventListener("pointerleave", this.onPointerLeave)
    this.el.removeEventListener("focusin", this.onFocus)
    this.el.removeEventListener("keydown", this.onKeyDown)
  },

  showPoint(point) {
    const selection = this.el.querySelector(".chart-selection")
    const vertical = selection?.querySelector(".chart-select-v")
    const horizontal = selection?.querySelector(".chart-select-h")
    const dot = selection?.querySelector(".chart-select-dot")
    const tip = this.el.querySelector(".ctip")
    if (!selection || !vertical || !horizontal || !dot || !tip) return

    const x = Number(point.getAttribute("cx"))
    const y = Number(point.getAttribute("cy"))
    vertical.setAttribute("x1", x)
    vertical.setAttribute("x2", x)
    horizontal.setAttribute("y1", y)
    horizontal.setAttribute("y2", y)
    dot.setAttribute("cx", x)
    dot.setAttribute("cy", y)
    selection.hidden = false

    this.el.querySelectorAll("[data-chart-point]").forEach(node => node.classList.toggle("selected", node === point))
    const date = this.formatDate(point.dataset.date)
    const unit = this.el.dataset.unit ? ` ${this.el.dataset.unit}` : ""
    tip.textContent = `${date} · ${point.dataset.value}${unit}`
    tip.hidden = false

    requestAnimationFrame(() => {
      const chartWidth = this.el.clientWidth
      const chartHeight = this.el.clientHeight
      const tipWidth = tip.offsetWidth
      const tipHeight = tip.offsetHeight
      const pixelX = x / 340 * chartWidth
      const pixelY = y / 130 * chartHeight
      tip.style.left = `${Math.max(4, Math.min(chartWidth - tipWidth - 4, pixelX - tipWidth / 2))}px`
      tip.style.top = `${pixelY < tipHeight + 14 ? Math.min(chartHeight - tipHeight - 4, pixelY + 14) : 4}px`
    })
  },

  hidePoint() {
    this.el.querySelector(".chart-selection")?.setAttribute("hidden", "")
    this.el.querySelector(".ctip")?.setAttribute("hidden", "")
    this.el.querySelectorAll("[data-chart-point]").forEach(node => node.classList.remove("selected"))
  },

  formatDate(iso) {
    const date = new Date(`${iso}T12:00:00`)
    if (Number.isNaN(date.getTime())) return iso
    return new Intl.DateTimeFormat(document.documentElement.lang || "en", {day: "numeric", month: "short", year: "numeric"}).format(date)
  }
}

const RestTimer = {
  mounted() {
    this.time = this.el.querySelector("[data-rest-time]")
    this.progress = this.el.querySelector("[data-rest-progress]")
    this.adjustButtons = [...this.el.querySelectorAll("[data-rest-adjust]")]
    this.skipButton = this.el.querySelector("[data-rest-skip]")

    this.onAdjust = event => this.adjust(Number(event.currentTarget.dataset.restAdjust || 0))
    this.onSkip = () => this.stop()
    this.adjustButtons.forEach(button => button.addEventListener("click", this.onAdjust))
    this.skipButton?.addEventListener("click", this.onSkip)
    this.handleEvent("rest:start", ({seconds}) => this.start(Number(seconds)))
  },

  destroyed() {
    window.clearInterval(this.interval)
    this.adjustButtons.forEach(button => button.removeEventListener("click", this.onAdjust))
    this.skipButton?.removeEventListener("click", this.onSkip)
  },

  start(seconds) {
    if (!Number.isFinite(seconds) || seconds <= 0) return this.stop()
    window.clearInterval(this.interval)
    this.duration = seconds
    this.endsAt = Date.now() + seconds * 1000
    this.el.hidden = false
    this.tick()
    this.interval = window.setInterval(() => this.tick(), 250)
  },

  adjust(delta) {
    if (!this.endsAt) return
    const left = Math.max(0, Math.ceil((this.endsAt - Date.now()) / 1000) + delta)
    if (left <= 0) return this.stop()
    this.duration = Math.max(1, this.duration + delta)
    this.endsAt = Date.now() + left * 1000
    this.tick()
  },

  tick() {
    const left = Math.max(0, Math.ceil((this.endsAt - Date.now()) / 1000))
    if (left <= 0) return this.stop()
    if (this.time) this.time.textContent = `${Math.floor(left / 60)}:${String(left % 60).padStart(2, "0")}`
    if (this.progress) this.progress.style.width = `${Math.min(100, left / Math.max(this.duration, 1) * 100)}%`
  },

  stop() {
    window.clearInterval(this.interval)
    this.interval = null
    this.endsAt = null
    this.el.hidden = true
  }
}

function applyPrefs(theme = "dark", accent = "lime", language = "en") {
  const resolved = theme === "system"
    ? (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
    : theme
  document.documentElement.dataset.theme = resolved
  document.documentElement.dataset.accent = accent
  document.documentElement.lang = language
  document.querySelector('meta[name="theme-color"]')?.setAttribute("content", resolved === "light" ? "#f2f2f7" : "#000000")
}

applyPrefs(localStorage.getItem("gym_theme") || "dark", localStorage.getItem("gym_accent") || "lime", localStorage.getItem("gym_language") || "en")
window.addEventListener("phx:prefs", event => {
  const {theme, accent, language} = event.detail
  localStorage.setItem("gym_theme", theme)
  localStorage.setItem("gym_accent", accent)
  localStorage.setItem("gym_language", language)
  applyPrefs(theme, accent, language)
})

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {GuestStore, Elapsed, ExerciseMedia, NumericInputs, PointChart, RestTimer, ScrollEnd},
})

liveSocket.connect()
window.liveSocket = liveSocket

if ("serviceWorker" in navigator) navigator.serviceWorker.register("/sw.js").catch(() => {})
