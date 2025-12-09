import { font } from '@kit.ArkUI';

import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { UserStorage } from '../utils/UserStorage';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    //Set immersive mode
    
    let windowClass: window.Window | null = null;

    windowStage.getMainWindow((err: BusinessError, data) => {
      let errCode: number = err.code;
      if (errCode) {
        console.error('Failed to obtain the main window. Cause: ' + JSON.stringify(err));
        return;
      }
      windowClass = data;
      let names: Array<'status' | 'navigation'> = [];
      windowClass.setWindowSystemBarEnable(names).then(() => {
        console.info('Succeeded in setting the system bar to be visible.');
      });
      windowClass.setWindowLayoutFullScreen(true).then(() => {
        console.info('Succeeded in setting the window layout to full-screen mode.');
      });
    })
    
    // 加载启动页
    hilog.info(DOMAIN, 'testTag', 'Loading splash screen');

    windowStage.loadContent('pages/Splash', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      // 注册字体
      font.registerFont({
        familyName: 'Noto Sans SC',
        familySrc: $rawfile("font/NotoSansSC-Regular_2.ttf")
      })
      font.registerFont({
        familyName: 'Noto Sans SC',
        familySrc: $rawfile("font/NotoSansSC-Bold_2.ttf")
      })
      font.registerFont({
        familyName: 'Roboto',
        familySrc: $rawfile("font/Roboto-Regular_1.ttf")
      })
      font.registerFont({
        familyName: 'Roboto',
        familySrc: $rawfile("font/Roboto-Bold_1.ttf")
      })
      // UI导出项目使用的字体
      font.registerFont({
        familyName: 'Nunito',
        familySrc: $rawfile("font/Nunito-Regular_2.ttf")
      })
      font.registerFont({
        familyName: 'Nunito',
        familySrc: $rawfile("font/Nunito-Bold_2.ttf")
      })
      font.registerFont({
        familyName: 'Nunito',
        familySrc: $rawfile("font/Nunito-ExtraBold_2.ttf")
      })
      font.registerFont({
        familyName: 'Nunito',
        familySrc: $rawfile("font/Nunito-SemiBold_2.ttf")
      })
      font.registerFont({
        familyName: 'Nunito',
        familySrc: $rawfile("font/Nunito-Black_2.ttf")
      })
      font.registerFont({
        familyName: 'Arial',
        familySrc: $rawfile("font/ARIAL_1.ttf")
      })

    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
