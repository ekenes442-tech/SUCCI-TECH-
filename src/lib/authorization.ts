export const SYSTEM_ADMIN_ROLES = new Set(['system_admin','system-admin','admin']);

export function isSystemAdmin(staff: { role?: string | null } | null) {
  return !!staff?.role && SYSTEM_ADMIN_ROLES.has(staff.role.toLowerCase().trim());
}

export function canAccess(role: string | null | undefined, allowed: string | '*') {
  if (allowed === '*') return true;
  if (!role) return false;
  return allowed.split(',').map(x => x.trim()).includes(role.toLowerCase().trim());
}

export const ROLE_LABELS: Record<string,string> = {
  system_admin: 'System Admin',
  'system-admin': 'System Admin',
  general_overseer: 'General Overseer',
  general_supervisor: 'General Supervisor',
  operational_manager: 'Operational Manager',
  branch_manager: 'Branch Manager',
  supervisor: 'Supervisor',
  auditor: 'Auditor',
  credit_officer: 'Credit Officer',
  ceo: 'CEO',
  cashier: 'Cashier',
};

export function roleLabel(role: string | null | undefined) {
  if (!role) return 'Staff';
  return ROLE_LABELS[role.toLowerCase().trim()] ?? 'Staff';
}
