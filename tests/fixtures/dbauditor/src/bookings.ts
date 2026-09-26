import { prisma } from './db'

const DAY_MS = 24 * 60 * 60 * 1000

export async function createBooking(roomId: number, guestName: string, checkIn: Date, checkOut: Date) {
  const clash = await prisma.booking.findFirst({
    where: { roomId, checkIn: { lt: checkOut }, checkOut: { gt: checkIn } },
  })
  if (clash) throw new Error('room already booked for those dates')
  const room = await prisma.room.findUniqueOrThrow({ where: { id: roomId } })
  const nights = Math.round((checkOut.getTime() - checkIn.getTime()) / DAY_MS)
  return prisma.booking.create({
    data: { roomId, guestName, checkIn, checkOut, totalPrice: Number(room.nightly) * nights },
  })
}

export async function findBookingsByGuest(name: string) {
  return prisma.booking.findMany({
    where: { guestName: { contains: name, mode: 'insensitive' } },
    orderBy: { checkIn: 'desc' },
    take: 50,
  })
}
