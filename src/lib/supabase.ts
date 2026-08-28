import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL || 'https://pescjtcaggyyafulstkl.supabase.co'
const key = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!key) {
  console.warn('VITE_SUPABASE_ANON_KEY is not configured. Set it in Netlify before production deployment.')
}

export const supabase = createClient(url, key || '', {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true },
})
