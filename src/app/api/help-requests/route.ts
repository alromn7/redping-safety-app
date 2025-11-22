import { NextRequest, NextResponse } from 'next/server'
import { getAdminDb } from '@/lib/firebase/admin'

const ALLOWED = new Set(['active', 'pending', 'acknowledged', 'assigned', 'inprogress', 'inProgress', 'resolved'])

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const limitParam = searchParams.get('limit')
    const statusParam = searchParams.get('status')
    const limit = Math.max(1, Math.min(parseInt(limitParam || '50', 10) || 50, 200))

    const db = getAdminDb()
    if (!db) {
      return NextResponse.json({ success: false, error: 'Admin not configured' }, { status: 503 })
    }

    let ref = db.collection('help_requests').orderBy('createdAt', 'desc').limit(limit)
    if (statusParam && ALLOWED.has(statusParam)) {
      ref = db.collection('help_requests').where('status', '==', statusParam).orderBy('createdAt', 'desc').limit(limit)
    }

    const snap = await ref.get()
    const docs = snap.docs.map((d: any) => ({ id: d.id, ...(d.data() as any) }))
    return NextResponse.json({ success: true, data: docs })
  } catch (e) {
    console.error('GET /api/help-requests error:', e)
    return NextResponse.json({ success: false, error: 'Internal server error' }, { status: 500 })
  }
}
