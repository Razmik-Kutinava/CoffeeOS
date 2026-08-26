/** Конфиг экрана «О нас» и поддержки (#69/#70). URL не хардкодить в Svelte. */

import { SUPPORT_TELEGRAM_URL } from "./supportConfig.js"

const PLACEHOLDER_DOC = "https://docs.google.com/document/d/placeholder"

function env(key, fallback = "") {
  const v = typeof import.meta !== "undefined" ? import.meta.env?.[key] : ""
  return (v || fallback).trim()
}

export function shopAppVersionInfo() {
  return {
    version: env("VITE_SHOP_APP_VERSION", "3.39.0"),
    buildCode: env("VITE_SHOP_BUILD_CODE", "32396"),
    buildLabel: env("VITE_SHOP_BUILD_LABEL", "51 - release")
  }
}

export function shopAboutLegalLinks() {
  return [
    {
      id: "privacy",
      label: "Политика обработки персональных данных",
      url: env("VITE_SHOP_LEGAL_PRIVACY_URL", PLACEHOLDER_DOC)
    },
    {
      id: "terms",
      label: "Пользовательское соглашение",
      url: env("VITE_SHOP_LEGAL_TERMS_URL", PLACEHOLDER_DOC)
    },
    {
      id: "offer",
      label: "Публичная оферта",
      url: env("VITE_SHOP_LEGAL_OFFER_URL", PLACEHOLDER_DOC)
    },
    {
      id: "promo",
      label: "Полные правила акций",
      url: env("VITE_SHOP_LEGAL_PROMO_URL", PLACEHOLDER_DOC)
    },
    {
      id: "nutrition",
      label: "Калорийность и состав",
      url: env("VITE_SHOP_LEGAL_NUTRITION_URL", PLACEHOLDER_DOC)
    },
    {
      id: "loyalty",
      label: "Программа благодарности",
      url: env("VITE_SHOP_LEGAL_LOYALTY_URL", PLACEHOLDER_DOC)
    }
  ]
}

export function shopAboutFooter() {
  return {
    legalName: env("VITE_SHOP_LEGAL_ENTITY", "CoffeeOS"),
    supportEmail: env("VITE_SHOP_SUPPORT_EMAIL", "support@coffeeos.app"),
    copyrightYear: new Date().getFullYear()
  }
}

export function shopSupportTelegramUrl() {
  return env("VITE_SHOP_SUPPORT_TELEGRAM_URL", env("VITE_SHOP_TELEGRAM_URL", SUPPORT_TELEGRAM_URL))
}

export function shopSupportMailto() {
  const email = shopAboutFooter().supportEmail
  if (!email) return ""
  return `mailto:${encodeURIComponent(email)}?subject=${encodeURIComponent("Обратная связь CoffeeOS")}`
}

export function formatAboutCopyText() {
  const { version, buildCode, buildLabel } = shopAppVersionInfo()
  return `CoffeeOS ${version} (код ${buildCode}, сборка ${buildLabel})`
}
