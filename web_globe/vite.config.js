import { defineConfig } from 'vite';
import cesium from 'vite-plugin-cesium';

export default defineConfig({
  base: '/',
  plugins: [cesium({ cesiumBaseUrl: '/' })],
  build: {
    outDir: '../assets/globe',
    emptyOutDir: true,
  },
});
