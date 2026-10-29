/**
 * TASK_109: класс окружения A–E и pushPossible поверх снимка TASK_112 (`collectPushEnvironment`).
 * A — установленное PWA с push; B — вкладка браузера с push; C — iPhone вне главного экрана
 * без push; D / E — встроенный браузер iPhone / Android без push. Вне A–E без push — класса нет
 * (решение владельца 2026-10-29), показ push-CTA решает только pushPossible.
 */
import { collectPushEnvironment } from "./pushEnvironment.js"

/**
 * @param {{ os_family?: string, standalone?: string, notification_state?: string,
 *   push_manager?: string, service_worker?: string, inapp_label?: string }} [flags]
 * @returns {{ pushClass: "A"|"B"|"C"|"D"|"E"|null, pushPossible: boolean }}
 */
export function classifyPushEnvironment(flags = {}) {
  const f = flags || {}
  const pushPossible =
    Boolean(f.notification_state) &&
    f.notification_state !== "unavailable" &&
    f.push_manager === "available" &&
    f.service_worker === "available"
  const standalone = f.standalone === "standalone"

  if (pushPossible) return { pushClass: standalone ? "A" : "B", pushPossible }

  // Метка встроенного браузера уточняет класс только при отсутствии возможностей.
  const inApp = Boolean(f.inapp_label) && f.inapp_label !== "none"
  let pushClass = null
  if (inApp && f.os_family === "ios") pushClass = "D"
  else if (inApp && f.os_family === "android") pushClass = "E"
  else if (!inApp && f.os_family === "ios" && !standalone) pushClass = "C"
  return { pushClass, pushPossible }
}

/** Один вызов на монтирование компонента; при сбое снимка — показ как до TASK_109. */
export function currentPushPossible(env = globalThis) {
  try {
    return classifyPushEnvironment(collectPushEnvironment(env)).pushPossible
  } catch {
    return true
  }
}
