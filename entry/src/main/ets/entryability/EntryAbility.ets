import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { DBService } from '../services/DBService';
import { PreferencesService } from '../services/PreferencesService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'EntryAbility', 'setColorMode failed: %{public}s', JSON.stringify(err));
    }

    // Initialize DB and Preferences before any page loads
    try {
      await DBService.getInstance().init(this.context);
      hilog.info(DOMAIN, 'EntryAbility', 'DBService initialized');
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'EntryAbility', 'DBService init failed: %{public}s %{public}s', e.code.toString(), e.message);
    }

    try {
      await PreferencesService.getInstance().init(this.context);
      hilog.info(DOMAIN, 'EntryAbility', 'PreferencesService initialized');
    } catch (err) {
      const e = err as BusinessError;
      hilog.error(DOMAIN, 'EntryAbility', 'PreferencesService init failed: %{public}s %{public}s', e.code.toString(), e.message);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'EntryAbility', 'Ability onWindowStageCreate');

    // Lock orientation to landscape for the MatePad Pro
    windowStage.getMainWindow().then((win: window.Window) => {
      win.setPreferredOrientation(window.Orientation.LANDSCAPE).catch((err: BusinessError) => {
        hilog.error(DOMAIN, 'EntryAbility', 'setOrientation failed: %{public}s', err.message);
      });
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN, 'EntryAbility', 'getMainWindow failed: %{public}s', err.message);
    });

    windowStage.loadContent('pages/HomePage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'EntryAbility', 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'EntryAbility', 'Content loaded successfully');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'Ability onBackground');
  }
}
