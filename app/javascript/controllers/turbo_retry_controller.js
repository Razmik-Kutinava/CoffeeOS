// Контроллер для retry Turbo Streams при разрыве соединения
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    maxRetries: { type: Number, default: 3 },
    retryTimeout: { type: Number, default: 10000 } // 10 секунд
  }
  
  connect() {
    this.retryCount = 0
    this.setupReconnect()
  }
  
  disconnect() {
    if (this.checkTimeout) {
      clearTimeout(this.checkTimeout)
    }
  }
  
  setupReconnect() {
    // Сброс счётчика при успешном обновлении
    document.addEventListener('turbo:submit-end', (event) => {
      if (event.detail.fetchResponse.succeeded) {
        this.retryCount = 0
        this.resetTimeout()
      }
    })
    
    // Если обновление не пришло за retryTimeout — ретрай
    this.resetTimeout()
  }
  
  resetTimeout() {
    if (this.checkTimeout) {
      clearTimeout(this.checkTimeout)
    }
    
    this.checkTimeout = setTimeout(() => {
      this.retry()
    }, this.retryTimeoutValue)
  }
  
  retry() {
    if (this.retryCount < this.maxRetriesValue) {
      this.retryCount++
      console.log(`Retrying Turbo Stream connection (attempt ${this.retryCount}/${this.maxRetriesValue})`)
      
      Turbo.visit(window.location.href, { action: 'replace' })
      this.resetTimeout()
    } else {
      this.showFallback()
    }
  }
  
  showFallback() {
    this.element.innerHTML = `
      <div class="alert alert-warning">
        <p>Не удалось обновить данные.</p>
        <a href="#" data-action="click->turbo-retry#retry" class="btn btn-primary">
          Повторить
        </a>
      </div>
    `
  }
}
