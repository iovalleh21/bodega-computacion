import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// El frontend NUNCA toca SQL Server: todo pasa por /api -> Express
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: { '/api': 'http://localhost:3000' },
  },
});