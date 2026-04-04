import { mount } from "svelte"
import App from "../App.svelte"
import "../styles/app.css"

const el = document.getElementById("app")
if (el) {
  mount(App, { target: el })
}
