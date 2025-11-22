"use client"

import { useEffect, useMemo, useState } from 'react'
import Link from 'next/link'
import { useSearchParams } from 'next/navigation'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { MapPin, Clock, AlertTriangle, ArrowLeft, Printer } from 'lucide-react'
import { getClientDb } from '@/lib/firebase/client'
import { doc, getDoc } from 'firebase/firestore'

type AnyDoc = Record<string, any> & { id?: string }

export default function SARReportPage() {
  const sp = useSearchParams()
  const [loading, setLoading] = useState(true)
  const [data, setData] = useState<AnyDoc | null>(null)
  const [collection, setCollection] = useState<'sos_sessions' | 'help_requests' | null>(null)

  const id = useMemo(() => sp?.get('id') || '', [sp])

  useEffect(() => {
    const load = async () => {
      if (!id) { setLoading(false); return }
      try {
        const db = getClientDb()
        if (!db) { setLoading(false); return }
        let snap = await getDoc(doc(db, 'sos_sessions', id))
        if (snap.exists()) {
          setData({ id: snap.id, ...snap.data() })
          setCollection('sos_sessions')
          setLoading(false)
          return
        }
        snap = await getDoc(doc(db, 'help_requests', id))
        if (snap.exists()) {
          setData({ id: snap.id, ...snap.data() })
          setCollection('help_requests')
          setLoading(false)
          return
        }
      } catch {}
      setLoading(false)
    }
    load()
  }, [id])

  const formatTimestamp = (v: any): string => {
    if (!v) return 'Unknown time'
    try {
      if (typeof v === 'object' && v) {
        if (typeof (v as any).toDate === 'function') return (v as any).toDate().toLocaleString()
        if (typeof (v as any).seconds === 'number') return new Date((v as any).seconds * 1000).toLocaleString()
        if (typeof (v as any)._seconds === 'number') return new Date((v as any)._seconds * 1000).toLocaleString()
      }
      const d = new Date(v)
      if (!isNaN(d.getTime())) return d.toLocaleString()
    } catch {}
    return 'Unknown time'
  }

  const formatCoords = (loc: any): string => {
    if (!loc) return ''
    const lat = (loc.latitude as any)
    const lon = (loc.longitude as any)
    const latStr = typeof lat === 'number' && !isNaN(lat) ? lat.toFixed(5) : lat
    const lonStr = typeof lon === 'number' && !isNaN(lon) ? lon.toFixed(5) : lon
    return (latStr != null && lonStr != null) ? `${latStr}, ${lonStr}` : ''
  }

  const titleCase = (s: any): string => {
    const str = String(s ?? '')
    return str ? str.charAt(0).toUpperCase() + str.slice(1).toLowerCase() : ''
  }
  const normalizeStatus = (val: any): string => {
    const s = String(val ?? 'active').toLowerCase()
    switch (s) {
      case 'responder_assigned':
      case 'assigned':
        return 'Assigned'
      case 'responding':
      case 'enroute':
      case 'inprogress':
        return 'Enroute'
      case 'resolved':
      case 'completed':
        return 'Completed'
      case 'cancelled':
      case 'canceled':
        return 'Cancelled'
      case 'dispatch':
      case 'dispatched':
        return 'Dispatch'
      case 'pending':
        return 'Pending'
      case 'acknowledged':
        return 'Acknowledged'
      default:
        return s.charAt(0).toUpperCase() + s.slice(1)
    }
  }

  return (
    <div className="min-h-screen bg-gray-900 text-white">
      <div className="max-w-5xl mx-auto px-4 py-6">
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Button variant="darkOutline" asChild>
              <Link href="/sar-dashboard"><ArrowLeft className="h-4 w-4 mr-2" />Back</Link>
            </Button>
            <Button variant="darkOutline" onClick={() => window.print()}>
              <Printer className="h-4 w-4 mr-2" /> Print / Save PDF
            </Button>
          </div>
          {id && (
            <Badge variant="secondary" className="border border-gray-600">ID: {id}</Badge>
          )}
        </div>

        <Card className="bg-gray-800 border border-gray-700 print:border-0 print:bg-white print:text-black">
          <CardHeader>
            <CardTitle className="flex items-center print:text-black">
              <AlertTriangle className="h-5 w-5 mr-2 text-red-400 print:text-red-600" />
              SAR Mission Report
            </CardTitle>
            <CardDescription className="print:text-gray-700">
              {collection === 'sos_sessions' ? 'SOS Session' : collection === 'help_requests' ? 'Help Request' : 'Record'} details and timeline
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {loading ? (
              <div className="text-gray-400 print:text-gray-700">Loading report…</div>
            ) : !data ? (
              <div className="text-gray-400 print:text-gray-700">No data found for this ID.</div>
            ) : (
              <div className="space-y-4">
                <div className="flex flex-wrap items-center gap-2">
                  <Badge variant="secondary" className="border border-gray-600 print:border-gray-400 print:text-black print:bg-gray-100">{titleCase(data.type || data.category || 'sos')}</Badge>
                  <Badge variant="secondary" className="border border-gray-600 print:border-gray-400 print:text-black print:bg-gray-100">{normalizeStatus(data.status)}</Badge>
                  {data.priority && (
                    <Badge variant="destructive" className="print:text-white">{String(data.priority).toUpperCase()}</Badge>
                  )}
                </div>

                <div className="text-sm text-gray-300 print:text-black">
                  <div className="flex items-center">
                    <Clock className="h-4 w-4 mr-2 text-blue-400 print:text-blue-700" />
                    <span>Created: {formatTimestamp(data.createdAt)}</span>
                  </div>
                  <div className="flex items-center mt-1">
                    <Clock className="h-4 w-4 mr-2 text-green-400 print:text-green-700" />
                    <span>Last Update: {formatTimestamp(data.updatedAt || data.timestamp)}</span>
                  </div>
                </div>

                {data.location && (
                  <div className="flex items-center text-sm text-gray-300 print:text-black">
                    <MapPin className="h-4 w-4 mr-2 text-red-400 print:text-red-700" />
                    <span>
                      {data.location.address ? `${data.location.address} - ` : ''}
                      {formatCoords(data.location)}
                      {typeof data.location.accuracy === 'number' ? ` (+/-${Math.round(data.location.accuracy)}m)` : ''}
                    </span>
                  </div>
                )}

                {data.userMessage && (
                  <div>
                    <div className="text-xs text-gray-400 mb-1 print:text-gray-700">Message</div>
                    <div className="text-sm text-gray-200 bg-gray-900/40 rounded p-3 border border-gray-700 print:bg-white print:border-gray-300 print:text-black">
                      {data.userMessage}
                    </div>
                  </div>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
      <style jsx global>{`
        @media print {
          body { background: white; }
          * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
          .print\:text-black { color: #000 !important; }
          .print\:bg-white { background: #fff !important; }
          .print\:border-0 { border: 0 !important; }
          .print\:border-gray-300 { border-color: #d1d5db !important; }
        }
      `}</style>
    </div>
  )
}

