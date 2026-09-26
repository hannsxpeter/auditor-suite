# Harbor Stays booking API

Booking backend for Harbor Stays, a group of 12 boutique hotels with about 400
rooms. Guests book through the public website, about 300 bookings a day, and
front-desk staff search bookings by guest name.

Stack: TypeScript, Prisma 5, PostgreSQL 16. Migrations live in
`prisma/migrations` and run with `prisma migrate deploy` on each release.
