import React from 'react';import{createRoot}from'react-dom/client';import App from'./app';import'./styles.css';
const root=document.getElementById('root');if(!root)throw new Error('SUCCI TECH root element not found');createRoot(root).render(<React.StrictMode><App/></React.StrictMode>);
if('serviceWorker'in navigator)window.addEventListener('load',()=>navigator.serviceWorker.register('/sw.js').catch(()=>{}));
