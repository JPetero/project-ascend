import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { App } from './App';
import { ConfigurationErrorScreen } from './config/ConfigurationErrorScreen';
import { validateApiConfig } from './config/apiConfigValidation';
import './index.css';

// S14 Part 28 — checked before anything else touches the network: a
// production build with a missing/unsafe backend host must never
// quietly render the real app and start talking to it.
const configValidation = validateApiConfig();

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    {configValidation.isValid ? (
      <BrowserRouter>
        <App />
      </BrowserRouter>
    ) : (
      <ConfigurationErrorScreen violations={configValidation.violations} />
    )}
  </StrictMode>,
);
