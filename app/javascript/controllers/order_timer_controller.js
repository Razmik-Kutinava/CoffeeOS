import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    created: Number
  }
  
  connect() {
    this.updateTimer()
    this.interval = setInterval(() => this.updateTimer(), 1000)
  }
  
  disconnect() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }
  
  updateTimer() {
    const timerElement = this.element.querySelector('[data-order-timer-target="timer"]')
    if (!timerElement) return
    
    const createdTime = new Date(this.createdValue * 1000)
    const now = new Date()
    const diffMs = now - createdTime
    const diffMins = Math.floor(diffMs / 60000)
    
    let text
    if (diffMins < 1) {
      text = "Только что"
    } else if (diffMins < 60) {
      text = `${diffMins} мин назад`
    } else {
      const hours = Math.floor(diffMins / 60)
      const mins = diffMins % 60
      text = `${hours} ч ${mins} мин назад`
    }
    
    timerElement.textContent = text
    
    // Обновление классов для предупреждений
    timerElement.classList.remove('timer-warning', 'timer-critical')
    if (diffMins > 10) {
      timerElement.classList.add('timer-critical')
    } else if (diffMins > 5) {
      timerElement.classList.add('timer-warning')
    }
  }
}
