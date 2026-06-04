import { mount } from "svelte"
import App from "../App.svelte"
import "../styles/app.css"

const el = document.getElementById("app")
if (el) {
  el.replaceChildren()
  mount(App, { target: el })
}
