// Сводка before/after из results.json: node compare.mjs
import { readFileSync } from "node:fs"
import { join, dirname } from "node:path"
import { fileURLToPath } from "node:url"

const dir = dirname(fileURLToPath(import.meta.url))
const load = (l) => JSON.parse(readFileSync(join(dir, l, "results.json"), "utf8"))
const B = load("before")
const A = load("after")

const rows = []
const add = (what, f) => {
  let b, a
  try { b = f(B) } catch (e) { b = `ERR ${e.message}` }
  try { a = f(A) } catch (e) { a = `ERR ${e.message}` }
  rows.push({ what, before: JSON.stringify(b), after: JSON.stringify(a) })
}

add("107 шапка 412: текст профиля", (r) => r.catalog_empty_412x915.header.profileText)
add("107 шапка 320: текст / иконка / бейдж", (r) => [r.header_320x640.profileText, r.header_320x640.profileHasSvg, r.header_320x640.badge])
add("107 шапка 320: адрес / часы / высота", (r) => [r.header_320x640.address, r.header_320x640.hours, r.header_320x640.headerH])
add("106 пустой каталог: блок «Итого»", (r) => r.catalog_empty_412x915.cart.itogoBlock)
add("106 пустой каталог: кнопка текст / ширина / шторка ширина", (r) => [r.catalog_empty_412x915.cart.checkoutBtn?.text, r.catalog_empty_412x915.cart.checkoutBtn?.w, r.catalog_empty_412x915.cart.sheet?.w])
add("106 пустой каталог: высота шторки", (r) => r.catalog_empty_412x915.cart.sheet?.h)
add("106 «Холодные» не под шторкой (bottom < sheet.top)", (r) => [r.catalog_empty_412x915.cart.coldHeader?.bottom, r.catalog_empty_412x915.cart.sheet?.top])
add("106 каталог c историей: «повторить» есть", (r) => [r.repeat_catalog_vs_product_412x915.catalog.repeatSectionRendered, r.repeat_catalog_vs_product_412x915.catalog.repeatSlots])
add("106 товар: «повторить» / слоты", (r) => [r.repeat_catalog_vs_product_412x915.product.repeatSectionRendered, r.repeat_catalog_vs_product_412x915.product.repeatSlots])
add("106 товар: высота шторки / CTA «добавить»", (r) => [r.repeat_catalog_vs_product_412x915.product.sheet?.h, r.repeat_catalog_vs_product_412x915.product.productCta?.h])
for (const n of [2, 3]) {
  const k = `active_orders_${n}_390x844`
  add(`103 ${n} заказа: контейнер списка overflow`, (r) => r[k].before.list?.overflowY ?? `нет списка, панель ${r[k].before.panel?.overflowY}`)
  add(`103 ${n} заказа: видимость строк до колеса`, (r) => r[k].before.rows.map((x) => x.visiblePx))
  add(`103 ${n} заказа: видимость строк после колеса`, (r) => r[k].after.rows.map((x) => x.visiblePx))
  add(`103 ${n} заказа: scrollTop список / панель / окно после`, (r) => [r[k].after.list?.scrollTop ?? null, r[k].after.panel?.scrollTop, r[k].after.windowScrollY])
  add(`103 ${n} заказа: высота панели до → после`, (r) => [r[k].before.panel?.h, r[k].after.panel?.h])
}
const T = "receipt_arrow_toggle_390x844"
add("104 закрыт: видимый текст / aria-label / aria-expanded", (r) => [r[T].closed.cta.visibleText, r[T].closed.cta.ariaLabel, r[T].closed.cta.ariaExpanded])
add("104 закрыт: фон / ширина×высота / прижат вправо", (r) => [r[T].closed.cta.bg, `${r[T].closed.cta.w}x${r[T].closed.cta.h}`, r[T].closed.cta.right === r[T].closed.cta.rowRight])
add("104 клик → текст / aria-expanded / чеков открыто", (r) => [r[T].opened.cta.visibleText, r[T].opened.cta.ariaExpanded, r[T].opened.openReceipts])
add("104/103 чек открыт: scrollTop список / панель / окно", (r) => [r[T].opened.list?.scrollTop ?? null, r[T].opened.panel.scrollTop, r[T].opened.windowScrollY])
add("104 повторный клик → aria-expanded / чеков", (r) => [r[T].closedAgain.cta.ariaExpanded, r[T].closedAgain.openReceipts])
add("104 Enter с клавиатуры → aria-expanded / чеков", (r) => [r[T].afterEnter.cta.ariaExpanded, r[T].afterEnter.openReceipts])
for (const [w, h] of [[412, 915], [390, 844], [360, 640]]) {
  const k = `pay_stack_${w}x${h}`
  add(`105 ${w}x${h}: шторка корзины в стеке оплаты`, (r) => r[k].kbCard.cartSheetRendered)
  add(`105 ${w}x${h}: «Итого» в шторке оплаты`, (r) => r[k].kbCard.totalLine)
  add(`105 ${w}x${h} без клав.: «Оплатить» bottom / экран`, (r) => [r[k].noKb.payBtn?.bottom, r[k].noKb.visualViewportH, r[k].noKb.payBtnAboveKeyboard])
  add(`105 ${w}x${h} клав.: «Оплатить» bottom / верх клав. / над клав.`, (r) => [r[k].kbCard.payBtn?.bottom, r[k].kbCard.visualViewportH, r[k].kbCard.payBtnAboveKeyboard])
  add(`105 ${w}x${h} клав.: тело scrollH/clientH/overflow`, (r) => r[k].kbCard.body ? [r[k].kbCard.body.scrollH, r[k].kbCard.body.clientH, r[k].kbCard.body.overflowY] : null)
  add(`105 ${w}x${h} клав.: номер / ММ-ГГ / CVV — поле видно, «Оплатить» над клав.`, (r) => [
    [r[k].kbCard.activeEl, r[k].kbCard.activeVisible, r[k].kbCard.payBtnAboveKeyboard],
    [r[k].fields["cc-exp"].activeEl, r[k].fields["cc-exp"].activeVisible, r[k].fields["cc-exp"].payBtnAboveKeyboard],
    [r[k].fields["cc-csc"].activeEl, r[k].fields["cc-csc"].activeVisible, r[k].fields["cc-csc"].payBtnAboveKeyboard]
  ])
  add(`105 ${w}x${h}: прокрутка окна (должна быть 0)`, (r) => [r[k].kbCard.windowScrollY, r[k].kbScrolled.windowScrollY])
  add(`105 ${w}x${h} клав. закрыта: шторка h / «Оплатить» над низом`, (r) => [r[k].kbClosed.sheet?.h, r[k].kbClosed.payBtnAboveKeyboard])
}

for (const r of rows) console.log(`${r.what}\n   ДО:    ${r.before}\n   ПОСЛЕ: ${r.after}`)
