import { common } from '@kit.AbilityKit';
import audio from '@ohos.multimedia.audio';
import media from '@ohos.multimedia.media';

type SoundKey =
  'attack' |
  'warning' |
  'shrink' |
  'snap' |
  'win' |
  'power' |
  'suika_merge_pop' |
  'suika_merge_splash' |
  'suika_merge_final' |
  'freecellClick' |
  'freecellHint';

interface SoundAsset {
  key: SoundKey;
  path: string;
}

const SOUND_ASSETS: SoundAsset[] = [
  { key: 'attack', path: 'audio/attack.mp3' },
  { key: 'warning', path: 'audio/warning-dengdeng.mp3' },
  { key: 'shrink', path: 'audio/warning-diudiu.mp3' },
  { key: 'snap', path: 'audio/y2155.mp3' },
  { key: 'win', path: 'audio/win.mp3' },
  { key: 'power', path: 'audio/warning-diudiu.mp3' },
  { key: 'suika_merge_pop', path: 'games/suika/audio/merge_pop.mp3' },
  { key: 'suika_merge_splash', path: 'games/suika/audio/merge_splash.mp3' },
  { key: 'suika_merge_final', path: 'games/suika/audio/merge_final.mp3' },
  { key: 'freecellClick', path: 'audio/freecell-click.mp3' },
  { key: 'freecellHint', path: 'audio/freecell-hint.mp3' }
];

export class NativeAudioService {
  private context: common.Context | null = null;
  private soundPool: media.SoundPool | null = null;
  private soundIds: Map<string, number> = new Map();
  private bgmPlayer: media.AVPlayer | null = null;
  private bgmFdPath: string = '';
  private bgmReady: boolean = false;
  private loading: boolean = false;
  private bgmVolume: number = 0.45;
  private sfxVolume: number = 0.8;

  async init(context: common.Context): Promise<void> {
    if (this.loading || this.context !== null) {
      return;
    }
    this.loading = true;
    this.context = context;
    try {
      await this.prepareSoundPool();
      await this.prepareBgm();
    } catch (error) {
      console.error(`Audio init failed: ${JSON.stringify(error)}`);
    } finally {
      this.loading = false;
    }
  }

  setBgmVolume(value: number): void {
    this.bgmVolume = this.clampVolume(value);
    if (this.bgmPlayer !== null && this.bgmReady) {
      this.bgmPlayer.setVolume(this.bgmVolume);
    }
  }

  setSfxVolume(value: number): void {
    this.sfxVolume = this.clampVolume(value);
  }

  playBgm(): void {
    if (this.bgmPlayer === null || !this.bgmReady || this.bgmVolume <= 0) {
      return;
    }
    this.bgmPlayer.setVolume(this.bgmVolume);
    this.bgmPlayer.play().catch((error: Error) => {
      console.error(`BGM play failed: ${JSON.stringify(error)}`);
    });
  }

  pauseBgm(): void {
    if (this.bgmPlayer === null || !this.bgmReady) {
      return;
    }
    this.bgmPlayer.pause().catch((error: Error) => {
      console.error(`BGM pause failed: ${JSON.stringify(error)}`);
    });
  }

  play(key: SoundKey, volumeScale: number = 1): void {
    if (this.soundPool === null || this.sfxVolume <= 0) {
      return;
    }
    const soundId = this.soundIds.get(key);
    if (soundId === undefined) {
      return;
    }
    const volume = this.clampVolume(this.sfxVolume * volumeScale);
    if (volume <= 0) {
      return;
    }
    this.soundPool.play(soundId, {
      loop: 0,
      leftVolume: volume,
      rightVolume: volume,
      priority: 1
    }).catch((error: Error) => {
      console.error(`SFX play failed: ${JSON.stringify(error)}`);
    });
  }

  async release(): Promise<void> {
    if (this.bgmPlayer !== null) {
      try {
        await this.bgmPlayer.release();
      } catch (error) {
        console.error(`BGM release failed: ${JSON.stringify(error)}`);
      }
      this.bgmPlayer = null;
    }
    if (this.context !== null && this.bgmFdPath.length > 0) {
      try {
        await this.context.resourceManager.closeRawFd(this.bgmFdPath);
      } catch (error) {
        console.error(`BGM fd close failed: ${JSON.stringify(error)}`);
      }
      this.bgmFdPath = '';
    }
    if (this.soundPool !== null) {
      try {
        await this.soundPool.release();
      } catch (error) {
        console.error(`SoundPool release failed: ${JSON.stringify(error)}`);
      }
      this.soundPool = null;
    }
    this.soundIds.clear();
    this.context = null;
    this.bgmReady = false;
  }

  private async prepareSoundPool(): Promise<void> {
    const context = this.context;
    if (context === null) {
      return;
    }
    const rendererInfo: audio.AudioRendererInfo = {
      usage: audio.StreamUsage.STREAM_USAGE_GAME,
      rendererFlags: 0
    };
    try {
      this.soundPool = await media.createSoundPool(10, rendererInfo);
    } catch (error) {
      console.error(`SoundPool create failed: ${JSON.stringify(error)}`);
      return;
    }
    const soundPool = this.soundPool;
    for (let i = 0; i < SOUND_ASSETS.length; i += 1) {
      const asset = SOUND_ASSETS[i];
      try {
        const rawFd = await context.resourceManager.getRawFd(asset.path);
        try {
          const id = await soundPool.load(rawFd.fd, rawFd.offset, rawFd.length);
          this.soundIds.set(asset.key, id);
        } finally {
          try {
            await context.resourceManager.closeRawFd(asset.path);
          } catch (error) {
            console.error(`SFX fd close failed: ${JSON.stringify(error)}`);
          }
        }
      } catch (error) {
        console.error(`SFX load failed (${asset.path}): ${JSON.stringify(error)}`);
      }
    }
  }

  private async prepareBgm(): Promise<void> {
    const context = this.context;
    if (context === null) {
      return;
    }
    try {
      this.bgmPlayer = await media.createAVPlayer();
      this.bgmFdPath = 'audio/bgm.mp3';
      const rawFd = await context.resourceManager.getRawFd(this.bgmFdPath);
      this.bgmPlayer.fdSrc = {
        fd: rawFd.fd,
        offset: rawFd.offset,
        length: rawFd.length
      };
      await this.bgmPlayer.prepare();
      this.bgmPlayer.loop = true;
      this.bgmPlayer.setVolume(this.bgmVolume);
      this.bgmReady = true;
    } catch (error) {
      console.error(`BGM prepare failed: ${JSON.stringify(error)}`);
      this.bgmReady = false;
    }
  }

  private clampVolume(value: number): number {
    return Math.max(0, Math.min(1, value));
  }
}
