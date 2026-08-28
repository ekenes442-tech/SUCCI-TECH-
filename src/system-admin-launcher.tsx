import React,{useEffect,useState}from'react';
import{createClient}from'@supabase/supabase-js';
import{ShieldCheck,X}from'lucide-react';
import{SystemAdmin}from'./modules/system-admin';

const db=createClient(import.meta.env.VITE_SUPABASE_URL||'https://pescjtca ggyyafulstkl.supabase.co'.replace(' ',''),import.meta.env.VITE_SUPABASE_ANON_KEY||'');

export default function SystemAdminLauncher(){
 const[allowed,setAllowed]=useState(false),[open,setOpen]=useState(false),[email,setEmail]=useState('');
 useEffect(()=>{let live=true;(async()=>{
   const{data:{session}}=await db.auth.getSession(); if(!session)return;
   if(live)setEmail(session.user.email||'');
   const{data:identity}=await db.from('system_admin_identities').select('id').eq('auth_user_id',session.user.id).eq('is_active',true).maybeSingle();
   if(live)setAllowed(!!identity);
 })();return()=>{live=false}},[]);
 if(!allowed)return null;
 if(open)return <div style={{position:'fixed',inset:0,zIndex:9999,background:'#0b0b0bcc',overflow:'auto'}}><button onClick={()=>setOpen(false)} style={{position:'fixed',right:18,top:18,zIndex:10001,width:44,height:44,border:0,borderRadius:10,background:'#b91c1c',color:'#fff',fontSize:24,cursor:'pointer'}} aria-label="Close System Admin"><X/></button><div style={{maxWidth:1200,margin:'70px auto',padding:'0 20px'}}><SystemAdmin email={email}/></div></div>;
 return <button onClick={()=>setOpen(true)} aria-label="Open System Admin" title="System Admin" style={{position:'fixed',right:18,bottom:18,zIndex:9998,width:56,height:56,border:0,borderRadius:14,background:'#b91c1c',color:'#fff',display:'grid',placeItems:'center',boxShadow:'0 8px 25px #0006',cursor:'pointer'}}><ShieldCheck size={27}/></button>;
}
