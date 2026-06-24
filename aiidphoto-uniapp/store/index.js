import { defineStore } from 'pinia'

export const useAppStore = defineStore('app', {
  state: () => ({
    locale: uni.getStorageSync('locale') || 'zh-Hans',
    appearance: uni.getStorageSync('appearance') || 'system', // light, dark, system
    isSubscribed: false,
    generationAttemptsLeft: 0,
    hasGivenAIConsent: false
  }),
  
  getters: {
    effectiveLocale: (state) => state.locale,
    isDarkMode: (state) => {
      if (state.appearance === 'system') {
        return uni.getSystemInfoSync().theme === 'dark'
      }
      return state.appearance === 'dark'
    }
  },
  
  actions: {
    setLocale(locale) {
      this.locale = locale
      uni.setStorageSync('locale', locale)
    },
    
    setAppearance(appearance) {
      this.appearance = appearance
      uni.setStorageSync('appearance', appearance)
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
