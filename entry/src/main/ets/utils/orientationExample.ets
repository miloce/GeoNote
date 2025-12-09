/**
 * 横竖屏适配示例
 * 在实际页面中参考此代码实现横竖屏监听
 */

import { display } from '@kit.ArkUI';
import { screenAdapter, toPx, toPy, isLandscape, isPortrait } from './screenAdapter';

@Entry
@Component
struct OrientationExample {
  @State isLandscapeMode: boolean = isLandscape();

  aboutToAppear() {
    // 监听屏幕旋转
    display.on('change', (id: number) => {
      // 更新屏幕尺寸
      screenAdapter.updateScreenSize();
      // 更新横竖屏状态
      this.isLandscapeMode = isLandscape();
      console.info(`屏幕旋转: ${this.isLandscapeMode ? '横屏' : '竖屏'}`);
    });
  }

  aboutToDisappear() {
    // 取消监听
    display.off('change');
  }

  build() {
    Column() {
      Text(this.isLandscapeMode ? '横屏模式' : '竖屏模式')
        .fontSize(toPx(32))
        .margin(toPx(20))

      // 根据横竖屏调整布局
      if (this.isLandscapeMode) {
        // 横屏：水平布局
        Row() {
          Column()
            .width('50%')
            .height('100%')
            .backgroundColor('#FFE0E0')
          Column()
            .width('50%')
            .height('100%')
            .backgroundColor('#E0FFE0')
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        // 竖屏：垂直布局
        Column() {
          Column()
            .width('100%')
            .height('50%')
            .backgroundColor('#FFE0E0')
          Column()
            .width('100%')
            .height('50%')
            .backgroundColor('#E0FFE0')
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
  }
}
