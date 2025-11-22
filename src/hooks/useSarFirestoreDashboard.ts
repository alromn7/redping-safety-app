import { useEffect, useState, useCallback } from 'react'
import {
  collection,
  doc,
  onSnapshot,
  query,
  where,
  serverTimestamp,
  setDoc,
} from 'firebase/firestore'
import { getClientDb } from '@/lib/firebase/client'

export type SarStatus =
  | 'countdown'
  | 'active'
  | 'acknowledged'
  | 'assigned'
  | 'enroute'
  | 'en_route'
  | 'dispatch'
  | 'dispatched'
  | 'responded'
  | 'inProgress'
  | 'in_progress'
  | 'resolved'
  | 'cancelled'
  | 'false_alarm'

export type HelpStatus =
  | 'active'
  | 'pending'
  | 'acknowledged'
  | 'assigned'
  | 'inProgress'
  | 'in_progress'
  | 'resolved'
  | 'cancelled'

export interface SosDoc {
  id: string
  userId?: string
  userName?: string
  phoneNumber?: string
  userMessage?: string
  status: SarStatus
  type?: string
  location?: {
    latitude?: number
    longitude?: number
    accuracy?: number
    address?: string
  }
  priority?: string
  metadata?: Record<string, any>
  statusHistory?: Array<{ status: string; timestamp?: any; by?: string }>
  createdAt?: any
  updatedAt?: any
}

export interface HelpDoc {
  id: string
  userId?: string
  userName?: string
  phoneNumber?: string
  description?: string
  status: HelpStatus
  priority?: string
  location?: {
    latitude?: number
    longitude?: number
    address?: string
  }
  assignedToName?: string
  assignedToId?: string
  statusHistory?: Array<{ status: string; timestamp?: any; by?: string }>
  createdAt?: any
  updatedAt?: any
}

const ACTIVE_SOS_STATUSES: SarStatus[] = [
  'active',
  'acknowledged',
  'assigned',
  'enroute',
  'en_route',
  'dispatch',
  'dispatched',
  'responded',
  'inProgress',
  'in_progress',
]

const ACTIVE_HELP_STATUSES: HelpStatus[] = [
  'active',
  'pending',
  'acknowledged',
  'assigned',
  'inProgress',
  'in_progress',
]

interface UseSarFirestoreDashboardOptions {
  autoListen?: boolean
}

export function useSarFirestoreDashboard(options: UseSarFirestoreDashboardOptions = {}) {
  const { autoListen = true } = options
  const db = getClientDb()

  const [sos, setSos] = useState<SosDoc[]>([])
  const [help, setHelp] = useState<HelpDoc[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)

  const activeSosCount = sos.length
  const activeHelpCount = help.length

  useEffect(() => {
    if (!db || !autoListen) {
      setLoading(false)
      if (!db) setError('Firestore client not configured')
      return
    }

    setLoading(true)
    setError(null)

    // sos_sessions listener (whereIn supports up to 10 values)
    const sosRef = collection(db, 'sos_sessions')
    const sosInValues = ACTIVE_SOS_STATUSES.map((s) => s as string)
    const sosQ = query(sosRef, where('status', 'in', sosInValues))
    const unsubSos = onSnapshot(
      sosQ,
      (snap) => {
        const docs = snap.docs.map((d) => ({ id: d.id, ...(d.data() as any) })) as SosDoc[]
        setSos(docs)
      },
      (err) => setError(err.message),
    )

    // help_requests listener
    const helpRef = collection(db, 'help_requests')
    const helpInValues = ACTIVE_HELP_STATUSES.map((s) => s as string)
    const helpQ = query(helpRef, where('status', 'in', helpInValues))
    const unsubHelp = onSnapshot(
      helpQ,
      (snap) => {
        const docs = snap.docs.map((d) => ({ id: d.id, ...(d.data() as any) })) as HelpDoc[]
        setHelp(docs)
      },
      (err) => setError(err.message),
    )

    setLoading(false)

    return () => {
      unsubSos()
      unsubHelp()
    }
  }, [db, autoListen])

  const updateSosStatus = useCallback(
    async (sosId: string, status: SarStatus, extra?: Record<string, any>) => {
      if (!db) throw new Error('Firestore not initialized')
      const ref = doc(db, 'sos_sessions', sosId)
      const payload: Record<string, any> = {
        status,
        updatedAt: serverTimestamp(),
        statusHistory: [{ status, timestamp: serverTimestamp(), by: 'web' }],
        ...(extra || {}),
      }
      // Merge status history via arrayUnion alternative: fetch & append to avoid missing rules
      // Safer approach: update doc with setDoc merge to avoid overwrite of nested metadata
      await setDoc(ref, payload, { merge: true })
    },
    [db],
  )

  const assignSosResponder = useCallback(
    async (sosId: string, responderName: string, responderId?: string) => {
      const meta: Record<string, any> = {
        metadata: {
          responderName,
          ...(responderId ? { responderId } : {}),
        },
      }
      await updateSosStatus(sosId, 'assigned', meta)
    },
    [updateSosStatus],
  )

  const updateHelpStatus = useCallback(
    async (helpId: string, status: HelpStatus, extra?: Record<string, any>) => {
      if (!db) throw new Error('Firestore not initialized')
      const ref = doc(db, 'help_requests', helpId)
      const payload: Record<string, any> = {
        status,
        updatedAt: serverTimestamp(),
        statusHistory: [{ status, timestamp: serverTimestamp(), by: 'web' }],
        ...(extra || {}),
      }
      await setDoc(ref, payload, { merge: true })
    },
    [db],
  )

  const assignHelp = useCallback(
    async (helpId: string, name: string, assigneeId?: string) => {
      const extra: Record<string, any> = {
        assignedToName: name,
        ...(assigneeId ? { assignedToId: assigneeId } : {}),
      }
      await updateHelpStatus(helpId, 'assigned', extra)
    },
    [updateHelpStatus],
  )

  return {
    loading,
    error,
    sos,
    help,
    activeSosCount,
    activeHelpCount,
    updateSosStatus,
    assignSosResponder,
    updateHelpStatus,
    assignHelp,
  }
}

export default useSarFirestoreDashboard
