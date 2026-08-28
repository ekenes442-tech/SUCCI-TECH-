import { supabase } from './supabase'

export async function getClients() {
  return supabase.from('clients').select('*').order('created_at', { ascending: false })
}

export async function getLoanProducts() {
  return supabase.from('loan_products').select('*').eq('is_active', true).order('created_at', { ascending: false })
}

export async function getLoans() {
  return supabase.from('loans').select('*').order('created_at', { ascending: false })
}

export async function getCollections() {
  return supabase.from('collection_records').select('*').order('collection_date', { ascending: false }).limit(100)
}

export async function getDashboardCounts() {
  const [clients, loans, collections] = await Promise.all([
    supabase.from('clients').select('*', { count: 'exact', head: true }),
    supabase.from('loans').select('*', { count: 'exact', head: true }).in('status', ['active', 'disbursed']),
    supabase.from('collection_records').select('*', { count: 'exact', head: true }),
  ])
  return { clients: clients.count ?? 0, activeLoans: loans.count ?? 0, collections: collections.count ?? 0, error: clients.error || loans.error || collections.error }
}
