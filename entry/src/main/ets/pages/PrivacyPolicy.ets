import {
  screenAdapter,
  toPx,
  toPy,
  BreakpointSystem,
  BreakpointType,
  getCurrentBreakpoint,
  isCurrentLandscape
} from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import { router, display } from '@kit.ArkUI';
import webview from '@ohos.web.webview';

screenAdapter.designWidth = 375;

@Entry
@Component
export struct PrivacyPolicy {
  controller: webview.WebviewController = new webview.WebviewController();
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint();
  @State isLandscape: boolean = isCurrentLandscape();
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  aboutToAppear() {
    this.breakpointSystem.register((bp: BreakpointType) => {
      this.currentBreakpoint = bp;
      this.isLandscape = isCurrentLandscape();
    });
    display.on('change', () => {
      screenAdapter.updateScreenSize();
      this.currentBreakpoint = getCurrentBreakpoint();
      this.isLandscape = isCurrentLandscape();
    });
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
    display.off('change');
  }

  getFontSize(base: number): number {
    const scale = this.currentBreakpoint === 'xs' ? 0.9 :
      this.currentBreakpoint === 'lg' ? 1.15 :
        this.currentBreakpoint === 'md' ? 1.1 : 1.0;
    return base * scale;
  }

  getSpacing(): number {
    switch (this.currentBreakpoint) {
      case 'xs':
        return 12;
      case 'sm':
        return 16;
      case 'md':
        return 24;
      case 'lg':
        return 32;
      default:
        return 16;
    }
  }

  getNavBarHeight(): number {
    switch (this.currentBreakpoint) {
      case 'xs':
        return 90;
      case 'sm':
        return 100;
      case 'md':
        return 110;
      case 'lg':
        return 120;
      default:
        return 100;
    }
  }

  build() {
    Column() {
      // 顶部导航栏 - 响应式
      Row() {
        Stack() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(this.getFontSize(24))
            .fontColor([ColorTheme.getColor('textPrimary')])
        }
        .width(40)
        .height(40)
        .onClick(() => {
          router.back();
        })

        Text('隐私政策')
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTheme.getColor('textPrimary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Stack()
          .width(40)
          .height(40)
      }
      .width('100%')
      .height(this.getNavBarHeight())
      .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 44 })
      .backgroundColor(ColorTheme.getColor('pageBackground'))

      // WebView显示HTML内容
      Web({ src: 'https://note.luozhinet.com/agreement/geonote_privacy.html', controller: this.controller })
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(ColorTheme.getColor('pageBackground'))
        .darkMode(2) // AUTO模式通常对应数字2
        .forceDarkAccess(true)
        .onPageEnd(() => {
          console.log('[PrivacyPolicy] 页面加载完成');
        })
        .onErrorReceive((event) => {
          console.error('[PrivacyPolicy] 页面加载失败:', JSON.stringify(event));
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTheme.getColor('pageBackground'))
  }
}
