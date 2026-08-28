import { createClient } from '@supabase/supabase-js'

// Publishable Supabase values are safe to ship in a browser application.
// Netlify can override these with VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY.
const url = import.meta.env.VITE_SUPABASE_URL || 'https://pescjtcaggyyafulstkl.supabase.co'
const key = import.meta.env.VITE_SUPABASE_ANON_KEY || 'sb_publishable_vJdmMRw1nZdAE_mucqlECQ_cFAyqn1S'
export const supabase = createClient(url,key,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}})
