<script setup>
import { computed, onMounted, ref } from 'vue'

const props = defineProps({ clinicId: { type: String, required: true } })
const emit = defineEmits(['select'])

const slots = ref([])
const status = ref('loading')
const query = ref('')
const selectedId = ref(null)

onMounted(async () => {
  try {
    const response = await fetch(`/api/clinics/${props.clinicId}/slots`)
    if (!response.ok) throw new Error(`HTTP ${response.status}`)
    slots.value = await response.json()
    status.value = 'ready'
  } catch {
    status.value = 'error'
  }
})

const visible = computed(() =>
  slots.value
    .filter((slot) => slot.therapist.toLowerCase().includes(query.value.toLowerCase()))
    .sort((a, b) => new Date(a.start) - new Date(b.start)),
)

const statusText = computed(() => {
  if (status.value === 'loading') return 'Loading open times'
  if (status.value === 'error') return 'We could not load open times. Refresh the page to try again.'
  if (visible.value.length === 0) return 'No open times match this therapist.'
  return `${visible.value.length} open times`
})

function choose(slot) {
  selectedId.value = slot.id
  emit('select', slot)
}
</script>

<template>
  <section aria-labelledby="slots-heading">
    <h2 id="slots-heading">Choose a time</h2>
    <label for="therapist-filter">Filter by therapist</label>
    <input id="therapist-filter" v-model="query" type="search" autocomplete="off" />
    <p class="hint" role="status">{{ statusText }}</p>
    <ul v-if="status === 'ready' && visible.length" class="slots" role="list">
      <li v-for="slot in visible" :key="slot.id">
        <button type="button" :aria-pressed="slot.id === selectedId" @click="choose(slot)">
          {{ slot.label }} with {{ slot.therapist }}
        </button>
      </li>
    </ul>
  </section>
</template>
