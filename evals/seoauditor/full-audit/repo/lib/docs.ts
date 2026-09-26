export type Doc = {
  slug: string
  title: string
  summary: string
  updatedAt: string
  sections: { heading: string; text: string }[]
}

export const allDocs: Doc[] = [
  {
    slug: 'getting-started',
    title: 'Getting started with Brightdesk',
    summary: 'Connect your support email and invite your team.',
    updatedAt: '2026-08-14',
    sections: [
      { heading: 'Connect your support address', text: 'Forward your support address to the Brightdesk address shown in Settings.' },
      { heading: 'Invite your team', text: 'Add teammates from Settings, then assign them to the shared inbox.' },
    ],
  },
  {
    slug: 'automations',
    title: 'Route conversations with automations',
    summary: 'Tag, assign, and close conversations with rules.',
    updatedAt: '2026-06-02',
    sections: [
      { heading: 'Create a rule', text: 'Pick a trigger, add conditions, and choose the actions to run.' },
      { heading: 'Order of rules', text: 'Rules run from top to bottom, and the first matching rule wins.' },
    ],
  },
]

export function findDoc(slug: string): Doc | undefined {
  return allDocs.find((doc) => doc.slug === slug)
}
