import { registerPlugin } from '@capacitor/core';

import type { CapacitorVoiceRecorderPlugin } from './definitions';

const CapacitorVoiceRecorder = registerPlugin<CapacitorVoiceRecorderPlugin>('CapacitorVoiceRecorder', {
  web: () => import('./web').then((m) => new m.CapacitorVoiceRecorderWeb()),
});

export * from './definitions';
export { CapacitorVoiceRecorder };
