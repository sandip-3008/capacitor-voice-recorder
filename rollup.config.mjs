export default {
  input: 'dist/esm/index.js',
  output: [
    {
      file: 'dist/plugin.js',
      format: 'iife',
      name: 'capacitorCapacitorVoiceRecorder',
      globals: {
        '@capacitor/core': 'capacitorExports',
        'extendable-media-recorder': 'extendableMediaRecorder',
        'extendable-media-recorder-wav-encoder': 'extendableMediaRecorderWavEncoder',
      },
      sourcemap: true,
      inlineDynamicImports: true,
    },
    {
      file: 'dist/plugin.cjs.js',
      format: 'cjs',
      sourcemap: true,
      inlineDynamicImports: true,
    },
  ],
  external: ['@capacitor/core', 'extendable-media-recorder', 'extendable-media-recorder-wav-encoder'],
};
