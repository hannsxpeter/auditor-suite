<script setup>
import { ref } from 'vue'
import SlotPicker from './components/SlotPicker.vue'

const reminders = ref(true)
const chosen = ref(null)
const message = ref('')
const sending = ref(false)

function toggleReminders() {
  reminders.value = !reminders.value
}

async function book() {
  sending.value = true
  try {
    const response = await fetch('/api/bookings', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ slotId: chosen.value.id, reminders: reminders.value }),
    })
    message.value = response.ok ? 'Booked. The details are on their way to your email.' : 'We could not book that time. Pick another time and try again.'
  } catch {
    message.value = 'We could not reach the clinic. Check your connection and try again.'
  } finally {
    sending.value = false
  }
}
</script>

<template>
  <header class="site-header">
    <a href="/" class="brand">Harbor Physio</a>
  </header>
  <main class="page">
    <h1>Book an appointment</h1>
    <p class="hint">Pick a time below. You can change or cancel up to 24 hours before.</p>
    <form @submit.prevent="book">
      <SlotPicker clinic-id="harbor-central" @select="chosen = $event" />
      <div class="reminder">
        <span id="reminder-label">Text me a reminder the day before</span>
        <div role="switch" tabindex="0" aria-labelledby="reminder-label" class="switch" :class="{ on: reminders }" @click="toggleReminders" @keydown.space.prevent="toggleReminders"></div>
      </div>
      <button type="submit" :disabled="!chosen || sending">Confirm booking</button>
      <p role="status">{{ message }}</p>
    </form>
  </main>
</template>
