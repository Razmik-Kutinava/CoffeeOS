import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "password", "emailError", "passwordError", "submit", "success", "form"]
  
  connect() {
    // Скрываем сообщение об успехе при загрузке
    this.hideSuccess()
  }
  
  validate() {
    const email = this.emailTarget.value.trim()
    const password = this.passwordTarget.value
    
    let isValid = true
    
    // Валидация email/phone
    if (!email) {
      this.showError(this.emailErrorTarget, "Поле обязательно для заполнения")
      isValid = false
    } else if (!this.isValidEmailOrPhone(email)) {
      this.showError(this.emailErrorTarget, "Введите корректный email или телефон")
      isValid = false
    } else {
      this.hideError(this.emailErrorTarget)
    }
    
    // Валидация password
    if (!password) {
      this.showError(this.passwordErrorTarget, "Поле обязательно для заполнения")
      isValid = false
    } else if (password.length < 8) {
      this.showError(this.passwordErrorTarget, "Пароль должен быть не менее 8 символов")
      isValid = false
    } else {
      this.hideError(this.passwordErrorTarget)
    }
    
    // Если все валидно - показываем сообщение об успехе
    if (isValid && email && password) {
      this.showSuccess()
    } else {
      this.hideSuccess()
    }
    
    return isValid
  }
  
  handleSubmit(event) {
    if (!this.validate()) {
      event.preventDefault()
      return false
    }
    
    // Показываем сообщение об успехе перед отправкой
    this.showSuccess()
  }
  
  isValidEmailOrPhone(value) {
    // Email без nested + (CodeQL js/redos); допускает demo.coffeeos.local
    const emailOk = this.isValidEmail(value)
    // Phone regex (российский формат)
    const phoneRegex = /^\+?[1-9]\d{10,14}$/

    return emailOk || phoneRegex.test(value.replace(/[\s\-\(\)]/g, ''))
  }

  isValidEmail(value) {
    if (typeof value !== "string" || value.length > 254) return false
    const at = value.indexOf("@")
    if (at < 1 || at !== value.lastIndexOf("@")) return false
    const local = value.slice(0, at)
    const domain = value.slice(at + 1)
    if (local.length > 64 || /\s/.test(local) || /\s/.test(domain)) return false
    if (!domain.includes(".") || domain.startsWith(".") || domain.endsWith(".")) return false
    return true
  }
  
  showError(target, message) {
    target.textContent = message
    target.classList.remove("hidden")
  }
  
  hideError(target) {
    target.classList.add("hidden")
  }
  
  showSuccess() {
    this.successTarget.classList.remove("hidden")
  }
  
  hideSuccess() {
    this.successTarget.classList.add("hidden")
  }
}
