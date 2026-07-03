import { defineStore } from 'pinia'

export const useAppStore = defineStore('app', {
  state: () => ({
    locale: uni.getStorageSync('locale') || 'zh-Hans',
    isSubscribed: false,
    generationAttemptsLeft: 0,
    hasGivenAIConsent: false
  }),
  
  getters: {
    effectiveLocale: (state) => state.locale
  },
  
  actions: {
    setLocale(locale) {
      this.locale = locale
      uni.setStorageSync('locale', locale)
    },
    
    setSubscribed(isSubscribed) {
      this.isSubscribed = isSubscribed
    },
    
    setGenerationAttemptsLeft(attempts) {
      this.generationAttemptsLeft = attempts
    },
    
    consumeGenerationAttempt() {
      if (this.generationAttemptsLeft > 0) {
        this.generationAttemptsLeft--
      }
    },
    
    setAIConsent(consent) {
      this.hasGivenAIConsent = consent
      uni.setStorageSync('hasGivenAIConsent', consent)
    }
  }
})
