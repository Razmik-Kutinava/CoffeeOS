const DELAY_MS = 5000

let pending = 0
let timer = null
let visible = false
const listeners = new Set()

function notify() {
  listeners.forEach((cb) => cb(visible))
}

function begin() {
  pending += 1
  if (pending === 1 && !timer) {
    timer = setTimeout(() => {
      visible = true
      notify()
    }, DELAY_MS)
  }
}

function end() {
  pending = Math.max(0, pending - 1)
  if (pending === 0) {
    clearTimeout(timer)
    timer = null
    if (visible) {
      visible = false
      notify()
    }
  }
}

export function onSlowRequestChange(callback) {
  listeners.add(callback)
  callback(visible)
  return () => listeners.delete(callback)
}

export function installSlowRequestTracker() {
  if (window.__coffeeosSlowFetch) return
  window.__coffeeosSlowFetch = true

  const original = window.fetch.bind(window)
  window.fetch = (input, init) => {
    begin()
    return original(input, init).finally(end)
  }
}

export function resetSlowRequestTrackerForTests() {
  pending = 0
  clearTimeout(timer)
  timer = null
  visible = false
  listeners.clear()
  delete window.__coffeeosSlowFetch
}
