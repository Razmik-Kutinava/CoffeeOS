/**
 * TASK_111 — плашка установки на главный экран [TDD].
 *
 * Модуль `shopInstallBanner.js` — вызовами; панель-инструкция — SSR-рендером;
 * плашка `ShopPwaBanner.svelte` — по исходнику (вариант выбирается в onMount, SSR его не видит).
 *
 * node --test test/javascript/shop_install_banner_test.mjs
 */
import assert from "node:assert/strict"
import { describe, it, beforeEach } from "node:test"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"

import {
  INSTALL_BANNER_TEXT,
  INSTALL_BANNER_HOW,
  INSTALL_BANNER_INSTALL,
  INSTALL_BANNER_CLOSE_LABEL,
  IOS_INSTALL_TITLE,
  IOS_INSTALL_STEPS,
  IOS_INSTALL_DONE,
  INSTALL_BANNER_REAPPEAR,
  INSTALL_BANNER_DISMISS_KEY,
  INSTALL_BANNER_SHOWN_KEY,
  INSTALL_PROFILE_KEY,
  INSTALL_EVENT_KINDS,
  isStandaloneEnv,
  iosInstallEligible,
  bannerDismissed,
  dismissBanner,
  resolveInstalled,
  decideBannerVariant,
  reportInstallEvent,
  reportBannerShownOnce,
  __resetInstallBannerForTests
} from "../../app/frontend/lib/shopInstallBanner.js"
import { renderSvelte } from "./svelte_ssr_helper.mjs"

const root = join(dirname(fileURLToPath(import.meta.url)), "../..")
const bannerPath = join(root, "app/frontend/components/ShopPwaBanner.svelte")
const sheetPath = join(root, "app/frontend/components/IosInstallSheet.svelte")
const bannerSrc = () => readFileSync(bannerPath, "utf8")

const UA = {
  iphoneSafari:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
  iphoneChrome:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/126.0.6478.54 Mobile/15E148 Safari/604.1",
  iphoneTelegram:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Telegram-iOS/11.0",
  iphoneInstagram:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 330.0.0.0",
  androidChrome:
    "Mozilla/5.0 (Linux; Android 14; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36",
  desktopChrome:
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
}

function memoryStorage(initial = {}) {
  const data = { ...initial }
  return {
    data,
    getItem: (k) => (k in data ? data[k] : null),
    setItem: (k, v) => {
      data[k] = String(v)
    },
    removeItem: (k) => {
      delete data[k]
    }
  }
}

const throwingStorage = {
  getItem() {
    throw new Error("SecurityError")
  },
  setItem() {
    throw new Error("SecurityError")
  },
  removeItem() {
    throw new Error("SecurityError")
  }
}

function env({ ua = UA.iphoneSafari, standalone = false, displayMode = false, session = memoryStorage() } = {}) {
  const platform = ua.includes("iPhone") ? "iPhone" : ua.includes("Android") ? "Linux armv8l" : "Win32"
  return {
    navigator: { userAgent: ua, platform, maxTouchPoints: platform === "Win32" ? 0 : 5, standalone },
    matchMedia: () => ({ matches: displayMode }),
    sessionStorage: session,
    localStorage: memoryStorage()
  }
}

function profileSpy(result) {
  const calls = []
  const loadProfile = () => {
    calls.push(1)
    return result instanceof Error ? Promise.reject(result) : Promise.resolve(result)
  }
  return { calls, loadProfile }
}

function beaconSpy() {
  const sent = []
  return {
    sent,
    opts: {
      resolveUrl: (u) => u,
      beacon: (url, blob) => {
        sent.push(blob)
        return true
      }
    },
    async bodies() {
      return Promise.all(sent.map(async (b) => JSON.parse(await b.text())))
    }
  }
}

beforeEach(() => {
  __resetInstallBannerForTests()
})

describe("тексты и константы", () => {
  it("тексты плашки и инструкции без версии iOS", () => {
    assert.equal(INSTALL_BANNER_TEXT, "Установить CoffeeOS на главный экран")
    assert.equal(INSTALL_BANNER_HOW, "Как установить")
    assert.equal(INSTALL_BANNER_INSTALL, "Установить")
    assert.equal(INSTALL_BANNER_CLOSE_LABEL, "Закрыть")
    assert.equal(IOS_INSTALL_DONE, "Понятно")
    assert.ok(IOS_INSTALL_TITLE.length > 0)
    assert.equal(IOS_INSTALL_STEPS.length, 3)
    assert.match(IOS_INSTALL_STEPS[0], /«Поделиться»/)
    assert.match(IOS_INSTALL_STEPS[1], /«На экран «Домой»»/)
    assert.match(IOS_INSTALL_STEPS[2], /иконк/)
    for (const s of [IOS_INSTALL_TITLE, ...IOS_INSTALL_STEPS]) assert.doesNotMatch(s, /iOS\s*\d|версии/i)
  })

  it("Subtask 3: интервал повторного показа — одна константа (по умолчанию следующая сессия)", () => {
    assert.equal(INSTALL_BANNER_REAPPEAR, "next_session")
  })

  it("ключи и виды событий — константы", () => {
    assert.equal(INSTALL_BANNER_DISMISS_KEY, "coffeeos_shop_install_banner_dismissed_v1")
    assert.equal(INSTALL_BANNER_SHOWN_KEY, "coffeeos_shop_install_banner_shown_v1")
    assert.equal(INSTALL_PROFILE_KEY, "coffeeos_shop_install_profile_v1")
    assert.deepEqual(INSTALL_EVENT_KINDS, [
      "install_banner_shown",
      "install_banner_tap",
      "install_banner_dismiss",
      "pwa_first_launch"
    ])
  })
})

describe("Subtask 1, 4, 5 — кому показывать вариант iPhone", () => {
  it("iPhone Safari и Chrome на iPhone, не с иконки → да", () => {
    assert.equal(iosInstallEligible(env({ ua: UA.iphoneSafari })), true)
    assert.equal(iosInstallEligible(env({ ua: UA.iphoneChrome })), true)
  })

  it("Subtask 4: запуск с иконки (navigator.standalone или display-mode) → нет", () => {
    assert.equal(iosInstallEligible(env({ standalone: true })), false)
    assert.equal(iosInstallEligible(env({ displayMode: true })), false)
    assert.equal(isStandaloneEnv(env({ standalone: true })), true)
    assert.equal(isStandaloneEnv(env({ displayMode: true })), true)
    assert.equal(isStandaloneEnv(env()), false)
  })

  it("Subtask 5 (отложен): во встроенных браузерах iPhone плашки нет", () => {
    assert.equal(iosInstallEligible(env({ ua: UA.iphoneTelegram })), false)
    assert.equal(iosInstallEligible(env({ ua: UA.iphoneInstagram })), false)
  })

  it("Android и компьютер — не вариант iPhone", () => {
    assert.equal(iosInstallEligible(env({ ua: UA.androidChrome })), false)
    assert.equal(iosInstallEligible(env({ ua: UA.desktopChrome })), false)
  })

  it("сбой чтения окружения → не показываем", () => {
    const broken = {}
    Object.defineProperty(broken, "navigator", {
      get() {
        throw new Error("boom")
      }
    })
    assert.equal(iosInstallEligible(broken), false)
    assert.equal(isStandaloneEnv(broken), false)
  })
})

describe("Subtask 3 — крестик до конца сессии", () => {
  it("закрыта в этой сессии; в новой сессии — снова", () => {
    const session = memoryStorage()
    assert.equal(bannerDismissed(env({ session })), false)
    dismissBanner(env({ session }))
    assert.equal(bannerDismissed(env({ session })), true)
    assert.equal(session.data[INSTALL_BANNER_DISMISS_KEY], "1")

    __resetInstallBannerForTests()
    assert.equal(bannerDismissed(env({ session })), true, "перезагрузка в той же вкладке")
    __resetInstallBannerForTests()
    assert.equal(bannerDismissed(env({ session: memoryStorage() })), false, "новая сессия")
  })

  it("хранилище недоступно → память на время жизни страницы", () => {
    const e = env({ session: throwingStorage })
    assert.doesNotThrow(() => dismissBanner(e))
    assert.equal(bannerDismissed(e), true)
  })
})

describe("Subtask 3b — «приложение установлено» по профилю", () => {
  it("pwa_installed true → установлено; false / нет профиля / ошибка → не установлено", async () => {
    assert.equal(await resolveInstalled({ env: env(), ...profileSpy({ pwa_installed: true }) }), true)
    __resetInstallBannerForTests()
    assert.equal(await resolveInstalled({ env: env(), ...profileSpy({ pwa_installed: false }) }), false)
    __resetInstallBannerForTests()
    assert.equal(await resolveInstalled({ env: env(), ...profileSpy(null) }), false)
    __resetInstallBannerForTests()
    assert.equal(await resolveInstalled({ env: env(), ...profileSpy(new Error("401")) }), false)
  })

  it("профиль запрашивается не больше одного раза за сессию (и после перезагрузки вкладки)", async () => {
    const session = memoryStorage()
    const spy = profileSpy({ pwa_installed: true })
    await Promise.all([
      resolveInstalled({ env: env({ session }), loadProfile: spy.loadProfile }),
      resolveInstalled({ env: env({ session }), loadProfile: spy.loadProfile })
    ])
    __resetInstallBannerForTests()
    assert.equal(await resolveInstalled({ env: env({ session }), loadProfile: spy.loadProfile }), true)
    assert.equal(spy.calls.length, 1)
  })

  it("по умолчанию — общий загрузчик loadOfferProfile, отдельного запроса нет", () => {
    const src = readFileSync(join(root, "app/frontend/lib/shopInstallBanner.js"), "utf8")
    assert.match(src, /import \{ loadOfferProfile \} from "\.\/subscriptionOffer\.js"/)
    assert.doesNotMatch(src, /api\(["']\/profile/)
  })
})

describe("Subtask 1, 3, 3b, 4 — какой вариант показать", () => {
  it("iPhone Safari, не закрыта, не установлено → ios", async () => {
    const spy = profileSpy({ pwa_installed: false })
    assert.equal(await decideBannerVariant({ installable: false, env: env(), loadProfile: spy.loadProfile }), "ios")
  })

  it("Android после beforeinstallprompt → android; без него — ничего и без запроса профиля", async () => {
    const spy = profileSpy({ pwa_installed: false })
    const e = env({ ua: UA.androidChrome })
    assert.equal(await decideBannerVariant({ installable: true, env: e, loadProfile: spy.loadProfile }), "android")
    __resetInstallBannerForTests()
    const idle = profileSpy({ pwa_installed: false })
    assert.equal(await decideBannerVariant({ installable: false, env: e, loadProfile: idle.loadProfile }), null)
    assert.equal(idle.calls.length, 0)
  })

  it("установлено по профилю → ничего (все платформы)", async () => {
    const spy = profileSpy({ pwa_installed: true })
    assert.equal(await decideBannerVariant({ installable: false, env: env(), loadProfile: spy.loadProfile }), null)
    __resetInstallBannerForTests()
    const android = profileSpy({ pwa_installed: true })
    const e = env({ ua: UA.androidChrome })
    assert.equal(await decideBannerVariant({ installable: true, env: e, loadProfile: android.loadProfile }), null)
  })

  it("закрыта / с иконки / встроенный браузер → ничего и без запроса профиля", async () => {
    const session = memoryStorage({ [INSTALL_BANNER_DISMISS_KEY]: "1" })
    for (const e of [env({ session }), env({ standalone: true }), env({ ua: UA.iphoneTelegram })]) {
      __resetInstallBannerForTests()
      const spy = profileSpy({ pwa_installed: false })
      assert.equal(await decideBannerVariant({ installable: true, env: e, loadProfile: spy.loadProfile }), null)
      assert.equal(spy.calls.length, 0)
    }
  })
})

describe("Subtask 6 — события воронки установки", () => {
  it("снимок окружения с подменой event_kind, без идентификатора гостя", async () => {
    const spy = beaconSpy()
    assert.equal(reportInstallEvent("install_banner_tap", { env: env(), ...spy.opts }), true)
    const [body] = await spy.bodies()
    assert.equal(body.event_kind, "install_banner_tap")
    assert.equal(body.os_family, "ios")
    assert.equal(body.standalone, "browser")
    for (const key of ["customer_id", "phone", "email", "user_agent"]) assert.ok(!(key in body), key)
  })

  it("чужой вид не отправляется", () => {
    const spy = beaconSpy()
    assert.equal(reportInstallEvent("session_open", { env: env(), ...spy.opts }), false)
    assert.equal(spy.sent.length, 0)
  })

  it("install_banner_shown — раз за сессию", async () => {
    const session = memoryStorage()
    const spy = beaconSpy()
    reportBannerShownOnce({ env: env({ session }), ...spy.opts })
    reportBannerShownOnce({ env: env({ session }), ...spy.opts })
    __resetInstallBannerForTests()
    reportBannerShownOnce({ env: env({ session }), ...spy.opts })
    __resetInstallBannerForTests()
    reportBannerShownOnce({ env: env({ session: memoryStorage() }), ...spy.opts })
    assert.deepEqual((await spy.bodies()).map((b) => b.event_kind), ["install_banner_shown", "install_banner_shown"])
  })

  it("ошибка отправки не бросает", () => {
    const opts = {
      env: env(),
      resolveUrl: (u) => u,
      beacon: () => {
        throw new Error("blocked")
      },
      fetchFn: () => {
        throw new Error("blocked")
      }
    }
    assert.doesNotThrow(() => reportInstallEvent("install_banner_dismiss", opts))
  })
})

describe("Subtask 2 — панель-инструкция IosInstallSheet.svelte", () => {
  it("SSR: заголовок, три шага, «Понятно»", async () => {
    const html = await renderSvelte(sheetPath, {})
    assert.match(html, /data-testid="ios-install-sheet"/)
    for (const text of [IOS_INSTALL_TITLE, IOS_INSTALL_DONE]) assert.ok(html.includes(text), text)
    for (const step of IOS_INSTALL_STEPS) assert.ok(html.includes(step), step)
    assert.match(html, /data-testid="ios-install-done"/)
  })

  it("раскрывается из плашки сверху: без второй нижней шторки и затемнения; закрытие свайпом вверх", () => {
    const src = readFileSync(sheetPath, "utf8")
    assert.doesNotMatch(src, /position:\s*(fixed|absolute|sticky)|bottom:|z-index|role="dialog"|aria-modal|backdrop/)
    assert.match(src, /ontouchstart/)
    assert.match(src, /ontouchend/)
    assert.match(src, /from "\.\.\/lib\/shopInstallBanner\.js"/)
  })
})

describe("Subtask 1, 3, 10 — плашка ShopPwaBanner.svelte", () => {
  it("подключает модуль и панель-инструкцию", () => {
    const src = bannerSrc()
    assert.match(src, /import IosInstallSheet from "\.\/IosInstallSheet\.svelte"/)
    assert.match(src, /from "\.\.\/lib\/shopInstallBanner\.js"/)
    assert.match(src, /decideBannerVariant\(/)
  })

  it("Subtask 1: вариант iPhone — «Как установить» открывает инструкцию; вариант Android — «Установить»", () => {
    const src = bannerSrc()
    assert.match(src, /variant === "ios"/)
    assert.match(src, /\{INSTALL_BANNER_HOW\}/)
    assert.match(src, /\{INSTALL_BANNER_INSTALL\}/)
    assert.match(src, /<IosInstallSheet/)
  })

  it("Subtask 3: крестик на всех вариантах — dismissBanner + событие install_banner_dismiss", () => {
    const src = bannerSrc()
    assert.match(src, /aria-label=\{INSTALL_BANNER_CLOSE_LABEL\}/)
    const close = src.slice(src.indexOf("function closeBanner"), src.indexOf("\n  }\n", src.indexOf("function closeBanner")))
    assert.match(close, /dismissBanner\(\)/)
    assert.match(close, /reportInstallEvent\("install_banner_dismiss"\)/)
  })

  it("Subtask 10: отказ в системном окне на Android скрывает плашку как крестик", () => {
    const src = bannerSrc()
    const install = src.slice(src.indexOf("async function install"), src.indexOf("\n  }\n", src.indexOf("async function install")))
    const promptAt = install.indexOf("promptPwaInstall()")
    const tapAt = install.indexOf('reportInstallEvent("install_banner_tap")')
    assert.ok(promptAt > -1 && tapAt > promptAt, "системное окно открывается до отправки события")
    assert.match(install, /if \(!ok\) dismissBanner\(\)/)
    assert.match(install, /variant = null/)
  })

  it("показ — после проверки установки; событие показа — раз за сессию; положение сверху как было", () => {
    const src = bannerSrc()
    assert.match(src, /reportBannerShownOnce\(\)/)
    assert.match(src, /top: 3\.25rem/)
    assert.match(src, /\{#if variant && \$shopOnline\}/)
  })

  it("boot не ждёт плашку: в onMount нет await", () => {
    const src = bannerSrc()
    const mount = src.slice(src.indexOf("onMount(() => {"), src.indexOf("\n  })\n", src.indexOf("onMount(() => {")))
    assert.doesNotMatch(mount, /await /)
  })
})
