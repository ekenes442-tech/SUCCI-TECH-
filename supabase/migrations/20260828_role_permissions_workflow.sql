-- SUCCI TECH authoritative role/permission and workflow security rules.
-- Applied to the connected Supabase project on 2026-08-28.

alter table public.role_permissions drop constraint if exists role_permissions_role_permission_key_key;
alter table public.role_navigation_rules drop constraint if exists role_navigation_rules_role_nav_key_key;
alter table public.role_permissions add constraint role_permissions_role_permission_key_key unique (role, permission_key);
alter table public.role_navigation_rules add constraint role_navigation_rules_role_nav_key_key unique (role, nav_key);

insert into public.staff_role_catalog(role,label,active) values
('system_admin','System Admin',true),('general_overseer','General Overseer / CEO',true),('general_supervisor','General Supervisor',true),('operational_manager','Operational Manager',true),('branch_manager','Branch Manager',true),('supervisor','Supervisor',true),('auditor','Auditor',true),('credit_officer','Credit Officer',true),('cashier','Cashier',true)
on conflict (role) do update set label=excluded.label,active=excluded.active;

-- Permissions are intentionally granular so UI and server-side authorization can use the same source of truth.
insert into public.role_permissions(role,permission_key) values
('system_admin','platform_full_control'),('system_admin','manage_branding'),('system_admin','manage_organizations'),('system_admin','manage_branches'),('system_admin','manage_staff'),('system_admin','manage_roles'),('system_admin','view_security_audit'),
('general_overseer','view_clients'),('general_overseer','view_loans'),('general_overseer','view_reports'),('general_overseer','view_branch_staff'),('general_overseer','create_staff'),
('general_supervisor','view_clients'),('general_supervisor','view_loans'),('general_supervisor','view_reports'),('general_supervisor','view_branch_staff'),
('operational_manager','view_clients'),('operational_manager','view_loans'),('operational_manager','view_reports'),('operational_manager','view_branch_staff'),
('branch_manager','view_clients'),('branch_manager','view_loans'),('branch_manager','view_branch_staff'),('branch_manager','create_staff'),('branch_manager','approve_disbursement'),('branch_manager','reject_to_ceo'),
('supervisor','view_clients'),('supervisor','view_loans'),('supervisor','view_branch_staff'),('supervisor','approve_loan'),('supervisor','reject_to_ceo'),
('auditor','view_clients'),('auditor','view_loans'),('auditor','view_repayment_history'),('auditor','audit_repayments'),('auditor','correct_repayment'),('auditor','mark_audited'),
('credit_officer','view_clients'),('credit_officer','create_clients'),('credit_officer','edit_cleared_client'),('credit_officer','view_loans'),('credit_officer','create_loan_application'),('credit_officer','submit_application'),('credit_officer','manage_guarantors'),('credit_officer','upload_documents'),('credit_officer','record_compulsory_savings'),('credit_officer','enter_repayments'),('credit_officer','view_repayment_history'),('credit_officer','view_cleared_files'),('credit_officer','reapply_loan'),
('cashier','view_clients'),('cashier','create_clients'),('cashier','edit_cleared_client'),('cashier','view_loans'),('cashier','create_loan_application'),('cashier','submit_application'),('cashier','manage_guarantors'),('cashier','upload_documents'),('cashier','record_compulsory_savings'),('cashier','enter_repayments'),('cashier','view_repayment_history'),('cashier','view_cleared_files'),('cashier','reapply_loan')
on conflict (role,permission_key) do nothing;

-- Navigation is informational; database RLS remains authoritative.
insert into public.role_navigation_rules(role,nav_key) values
('general_overseer','dashboard'),('general_overseer','clients'),('general_overseer','reports'),('general_overseer','disbursement_reports'),('general_overseer','repayment_reports'),('general_overseer','staff'),
('general_supervisor','dashboard'),('general_supervisor','clients'),('general_supervisor','loans'),('general_supervisor','reports'),
('operational_manager','dashboard'),('operational_manager','clients'),('operational_manager','loans'),('operational_manager','reports'),
('branch_manager','dashboard'),('branch_manager','clients'),('branch_manager','loans'),('branch_manager','staff'),('branch_manager','awaiting_disbursement'),
('supervisor','dashboard'),('supervisor','clients'),('supervisor','loans'),('supervisor','pending_approval'),
('auditor','dashboard'),('auditor','clients'),('auditor','loans'),('auditor','awaiting_audit'),
('credit_officer','dashboard'),('credit_officer','clients'),('credit_officer','loans'),('credit_officer','collection'),('credit_officer','awaiting_supervisor_submission'),('credit_officer','cleared_files'),
('cashier','dashboard'),('cashier','clients'),('cashier','loans'),('cashier','collection'),('cashier','awaiting_supervisor_submission'),('cashier','cleared_files'),
('system_admin','system_admin'),('system_admin','organizations'),('system_admin','branches'),('system_admin','staff'),('system_admin','roles_permissions'),('system_admin','security_audit'),('system_admin','branding')
on conflict (role,nav_key) do nothing;

-- Only CO/Cashier create and edit clients; all other roles are view-only.
drop policy if exists clients_insert on public.clients;
create policy clients_insert on public.clients for insert with check (private.is_system_admin() or (organization_id=private.current_org_id() and branch_id=private.current_branch_id() and private.current_role() in ('Credit Officer','Cashier')));
drop policy if exists clients_update on public.clients;
create policy clients_update on public.clients for update using (private.is_system_admin() or (organization_id=private.current_org_id() and branch_id=private.current_branch_id() and private.current_role() in ('Credit Officer','Cashier') and (credit_officer_id=public.current_staff_id() or credit_officer_id is null))) with check (private.is_system_admin() or (organization_id=private.current_org_id() and branch_id=private.current_branch_id() and private.current_role() in ('Credit Officer','Cashier')));

-- Organization executives are organization-wide; Auditor uses explicit multi-branch assignments; CO is assigned-client scoped.
drop policy if exists clients_select on public.clients;
create policy clients_select on public.clients for select using (private.is_system_admin() or (organization_id=private.current_org_id() and (private.current_role() in ('General Overseer','General Supervisor','Operational Manager','CEO') or (private.current_role()='Auditor' and exists(select 1 from public.auditor_branch_assignments aba where aba.organization_id=clients.organization_id and aba.auditor_staff_id=public.current_staff_id() and aba.branch_id=clients.branch_id)) or (private.current_role()='Credit Officer' and credit_officer_id=public.current_staff_id()) or (private.current_role() in ('Branch Manager','Supervisor','Cashier') and branch_id=private.current_branch_id()) or id=public.current_staff_id())));

-- Only Supervisor performs the ordinary approval decision.
drop policy if exists approvals_insert on public.approvals;
create policy approvals_insert on public.approvals for insert with check (private.is_system_admin() or (organization_id=private.current_org_id() and approver_staff_id=public.current_staff_id() and private.current_role()='Supervisor' and branch_id=private.current_branch_id()));

-- Branch Manager is the only ordinary disbursement role.
drop policy if exists disbursements_insert on public.disbursements;
create policy disbursements_insert on public.disbursements for insert with check (private.is_system_admin() or (organization_id=private.current_org_id() and branch_id=private.current_branch_id() and disbursed_by_staff_id=public.current_staff_id() and private.current_role()='Branch Manager'));

-- Only CO/Cashier enter collection records.
drop policy if exists collections_insert on public.collection_records;
create policy collections_insert on public.collection_records for insert with check (private.is_system_admin() or (organization_id=private.current_org_id() and branch_id=private.current_branch_id() and private.current_role() in ('Credit Officer','Cashier') and entered_by_staff_id=public.current_staff_id()));
drop policy if exists collections_update on public.collection_records;
create policy collections_update on public.collection_records for update using (private.is_system_admin() or (organization_id=private.current_org_id() and branch_id=private.current_branch_id() and private.current_role()='Auditor') or (organization_id=private.current_org_id() and branch_id=private.current_branch_id() and entered_by_staff_id=public.current_staff_id() and audited=false and private.current_role() in ('Credit Officer','Cashier'))) with check (private.is_system_admin() or (organization_id=private.current_org_id() and branch_id=private.current_branch_id() and private.current_role()='Auditor') or (organization_id=private.current_org_id() and branch_id=private.current_branch_id() and entered_by_staff_id=public.current_staff_id() and private.current_role() in ('Credit Officer','Cashier')));

-- Only CO/Cashier create applications.
drop policy if exists apps_insert on public.loan_applications;
create policy apps_insert on public.loan_applications for insert with check (private.is_system_admin() or (organization_id=private.current_org_id() and branch_id=private.current_branch_id() and credit_officer_staff_id=public.current_staff_id() and private.current_role() in ('Credit Officer','Cashier')));
drop policy if exists apps_select on public.loan_applications;
create policy apps_select on public.loan_applications for select using (private.is_system_admin() or (organization_id=private.current_org_id() and (private.current_role() in ('General Overseer','General Supervisor','Operational Manager','CEO') or (private.current_role()='Auditor' and exists(select 1 from public.auditor_branch_assignments aba where aba.organization_id=loan_applications.organization_id and aba.auditor_staff_id=public.current_staff_id() and aba.branch_id=loan_applications.branch_id)) or (private.current_role() in ('Branch Manager','Supervisor') and branch_id=private.current_branch_id()) or (private.current_role() in ('Credit Officer','Cashier') and credit_officer_staff_id=public.current_staff_id()))));

-- Staff creation: General Overseer/CEO may create organization staff; Branch Manager may create only Supervisor/CO in own branch.
drop policy if exists staff_write on public.staff;
create policy staff_write on public.staff for all using (private.is_system_admin() or (organization_id=private.current_org_id() and ((private.current_role() in ('General Overseer','CEO')) or (private.current_role()='Branch Manager' and branch_id=private.current_branch_id() and role in ('Supervisor','Credit Officer'))))) with check (private.is_system_admin() or (organization_id=private.current_org_id() and ((private.current_role() in ('General Overseer','CEO') and role not in ('System Admin','system_admin')) or (private.current_role()='Branch Manager' and branch_id=private.current_branch_id() and role in ('Supervisor','Credit Officer')))));

-- Auditor may cover multiple assigned branches.
drop policy if exists auditor_assignments_access on public.auditor_branch_assignments;
create policy auditor_assignments_access on public.auditor_branch_assignments for select using (private.is_system_admin() or (organization_id=private.current_org_id() and (private.current_role() in ('General Overseer','CEO','General Supervisor','Operational Manager') or auditor_staff_id=public.current_staff_id())));

-- Loans are viewable by authorized scope; ordinary editing is removed from non-Auditors.
drop policy if exists loans_select on public.loans;
create policy loans_select on public.loans for select using (private.is_system_admin() or (organization_id=private.current_org_id() and (private.current_role() in ('General Overseer','General Supervisor','Operational Manager','CEO') or (private.current_role()='Auditor' and exists(select 1 from public.auditor_branch_assignments aba where aba.organization_id=loans.organization_id and aba.auditor_staff_id=public.current_staff_id() and aba.branch_id=loans.branch_id)) or (private.current_role()='Credit Officer' and exists(select 1 from public.clients c where c.id=loans.client_id and c.credit_officer_id=public.current_staff_id())) or (private.current_role() in ('Branch Manager','Supervisor','Cashier') and branch_id=private.current_branch_id()))));
drop policy if exists loans_update on public.loans;
create policy loans_update on public.loans for update using (private.is_system_admin() or (organization_id=private.current_org_id() and private.current_role()='Auditor' and exists(select 1 from public.auditor_branch_assignments aba where aba.organization_id=loans.organization_id and aba.auditor_staff_id=public.current_staff_id() and aba.branch_id=loans.branch_id))) with check (private.is_system_admin() or (organization_id=private.current_org_id() and private.current_role()='Auditor' and exists(select 1 from public.auditor_branch_assignments aba where aba.organization_id=loans.organization_id and aba.auditor_staff_id=public.current_staff_id() and aba.branch_id=loans.branch_id)));

create index if not exists idx_auditor_branch_assignments_auditor_branch on public.auditor_branch_assignments(auditor_staff_id,branch_id);
create index if not exists idx_clients_credit_officer on public.clients(credit_officer_id);
create index if not exists idx_clients_org_branch on public.clients(organization_id,branch_id);
create index if not exists idx_loan_applications_org_branch_status on public.loan_applications(organization_id,branch_id,status);
create index if not exists idx_collection_records_org_branch_date on public.collection_records(organization_id,branch_id,collection_date);

create or replace function public.succi_supervisor_decide_application(p_application_id uuid,p_decision text,p_reason text default null) returns public.approvals language plpgsql security definer set search_path=public as $function$
declare s public.staff%rowtype; a public.loan_applications%rowtype; r public.approvals%rowtype; d text;
begin
 select * into s from public.succi_current_staff(); if not found or lower(coalesce(s.role,'')) <> 'supervisor' then raise exception 'Only a Supervisor can approve or reject a loan application'; end if;
 d:=lower(trim(p_decision)); if d not in ('approved','rejected') then raise exception 'Decision must be approved or rejected'; end if;
 if d='rejected' and nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'Rejection reason is required'; end if;
 select * into a from public.loan_applications where id=p_application_id and organization_id=s.organization_id and branch_id=s.branch_id for update; if not found then raise exception 'Application not found in your branch'; end if;
 if lower(a.status) not in ('submitted','resubmitted','corrected') then raise exception 'Only submitted applications can be decided'; end if;
 insert into public.approvals(organization_id,branch_id,loan_application_id,approver_staff_id,decision,reason) values(a.organization_id,a.branch_id,a.id,s.id,d,p_reason) returning * into r;
 update public.loan_applications set status=case when d='approved' then 'approved_by_supervisor' else 'rejected_by_supervisor' end where id=a.id; return r;
end; $function$;

create or replace function public.succi_supervisor_pending_applications() returns setof public.loan_applications language plpgsql set search_path=public as $function$
declare s public.staff%rowtype;
begin
 select * into s from public.succi_current_staff(); if not found or lower(coalesce(s.role,'')) <> 'supervisor' then raise exception 'Only a Supervisor can access the pending approval queue'; end if;
 return query select a from public.loan_applications a where a.organization_id=s.organization_id and a.branch_id=s.branch_id and lower(coalesce(a.status,''))='submitted' order by a.created_at asc;
end; $function$;
