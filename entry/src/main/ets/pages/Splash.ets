import { router, display } from '@kit.ArkUI';
import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, responsiveFontScale, isCurrentLandscape } from "../utils/screenAdapter";
import { ColorTheme } from "../utils/colorTheme";
import { UserStorage } from '../utils/UserStorage';

screenAdapter.designWidth = 375;

@Entry
@Component
export struct Splash {
  @State logoScale: number = 0.8
  @State logoOpacity: number = 0
  @State titleOpacity: number = 0
  @State subtitleOpacity: number = 0
  @State progressOpacity: number = 0
  @State decorRotation: number = 0
  @State decorOpacity: number = 0.6
  // 响应式布局状态
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint()
  @State isLandscape: boolean = isCurrentLandscape()
  private breakpointSystem: BreakpointSystem = new BreakpointSystem()

  async aboutToAppear() {
    // 注册断点监听
    this.breakpointSystem.register((breakpoint: BreakpointType) => {
      this.currentBreakpoint = breakpoint;
      this.isLandscape = isCurrentLandscape();
    });

    // 监听屏幕旋转
    display.on('change', () => {
      screenAdapter.updateScreenSize();
      this.currentBreakpoint = getCurrentBreakpoint();
      this.isLandscape = isCurrentLandscape();
    });

    // 启动动画序列
    this.startAnimations();
    
    // 检查登录状态并跳转
    setTimeout(async () => {
      try {
        const isLoggedIn = await UserStorage.isLoggedIn();
        const targetPage = isLoggedIn ? 'pages/Index' : 'pages/Login';
        
        router.replaceUrl({
          url: targetPage
        });
      } catch (error) {
        console.error('[Splash] 检查登录状态失败:', error);
        // 出错时默认跳转到登录页
        router.replaceUrl({
          url: 'pages/Login'
        });
      }
    }, 2500); // 2.5秒后跳转
  }

  aboutToDisappear() {
    // 注销断点监听
    this.breakpointSystem.unregister();
    display.off('change');
  }

  // 根据断点获取Logo尺寸
  getLogoSize(): number {
    const sizeMap: Record<BreakpointType, number> = {
      'xs': 80,
      'sm': 120,
      'md': 150,
      'lg': 180
    };
    return sizeMap[this.currentBreakpoint];
  }

  // 根据断点获取标题字号
  getTitleFontSize(): number {
    const sizeMap: Record<BreakpointType, number> = {
      'xs': 36,
      'sm': 52,
      'md': 64,
      'lg': 72
    };
    return sizeMap[this.currentBreakpoint];
  }

  // 根据断点获取副标题字号
  getSubtitleFontSize(): number {
    const sizeMap: Record<BreakpointType, number> = {
      'xs': 12,
      'sm': 15,
      'md': 18,
      'lg': 20
    };
    return sizeMap[this.currentBreakpoint];
  }

  // 根据断点获取英文名字号
  getEnglishNameFontSize(): number {
    const sizeMap: Record<BreakpointType, number> = {
      'xs': 14,
      'sm': 18,
      'md': 22,
      'lg': 26
    };
    return sizeMap[this.currentBreakpoint];
  }

  // 根据断点获取间距
  getSpacing(): number {
    const spacingMap: Record<BreakpointType, number> = {
      'xs': 16,
      'sm': 24,
      'md': 32,
      'lg': 40
    };
    return spacingMap[this.currentBreakpoint];
  }

  // 根据断点获取装饰圆圈缩放比例
  getDecorScale(): number {
    const scaleMap: Record<BreakpointType, number> = {
      'xs': 0.6,
      'sm': 1.0,
      'md': 1.3,
      'lg': 1.6
    };
    return scaleMap[this.currentBreakpoint];
  }

  startAnimations() {
    // 装饰元素淡入
    animateTo({
      duration: 600,
      curve: Curve.EaseOut,
      delay: 0
    }, () => {
      this.decorOpacity = 1;
    });

    // Logo 缩放和淡入 - 更快更流畅
    animateTo({
      duration: 600,
      curve: Curve.FastOutSlowIn,
      delay: 150
    }, () => {
      this.logoScale = 1;
      this.logoOpacity = 1;
    });

    // 标题淡入 - 紧跟Logo
    animateTo({
      duration: 500,
      curve: Curve.EaseOut,
      delay: 400
    }, () => {
      this.titleOpacity = 1;
    });

    // 副标题淡入 - 更快出现
    animateTo({
      duration: 500,
      curve: Curve.EaseOut,
      delay: 650
    }, () => {
      this.subtitleOpacity = 1;
    });

    // 进度指示器淡入 - 提前出现
    animateTo({
      duration: 400,
      curve: Curve.EaseOut,
      delay: 900
    }, () => {
      this.progressOpacity = 1;
    });

    // 装饰元素持续旋转
    animateTo({
      duration: 20000,
      curve: Curve.Linear,
      iterations: -1 // 无限循环
    }, () => {
      this.decorRotation = 360;
    });
  }

  // 构建装饰性圆圈
  @Builder
  buildDecorCircles() {
    Stack() {
      // 大圆圈 - 响应式尺寸
      Circle()
        .width(300 * this.getDecorScale())
        .height(300 * this.getDecorScale())
        .fill('rgba(255, 255, 255, 0.08)')
        .position({ x: -100 * this.getDecorScale(), y: '10%' })

      Circle()
        .width(200 * this.getDecorScale())
        .height(200 * this.getDecorScale())
        .fill('rgba(255, 255, 255, 0.06)')
        .position({ x: '70%', y: '70%' })

      Circle()
        .width(150 * this.getDecorScale())
        .height(150 * this.getDecorScale())
        .fill('rgba(255, 255, 255, 0.1)')
        .position({ x: '75%', y: '20%' })

      // 旋转的装饰圆环
      Circle()
        .width(250 * this.getDecorScale())
        .height(250 * this.getDecorScale())
        .fillOpacity(0)
        .stroke('rgba(255, 255, 255, 0.2)')
        .strokeWidth(2)
        .strokeDashArray([10, 10])
        .position({ x: '15%', y: '35%' })
        .rotate({ angle: this.decorRotation })
    }
    .width('100%')
    .height('100%')
    .opacity(this.decorOpacity)
  }

  // 构建主内容 - 竖屏布局
  @Builder
  buildPortraitContent() {
    Column({ space: this.getSpacing() }) {
      // Logo 区域
      Column({ space: 16 }) {
        Image($r('app.media.logo'))
          .width(this.getLogoSize())
          .height(this.getLogoSize())
          .objectFit(ImageFit.Contain)
          .scale({ x: this.logoScale, y: this.logoScale })
          .opacity(this.logoOpacity)
      }

      // 应用名称
      Column({ space: this.currentBreakpoint === 'xs' ? 6 : 12 }) {
        Text('迹记')
          .fontSize(this.getTitleFontSize())
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))
          .fontFamily('Nunito')
          .letterSpacing(this.currentBreakpoint === 'xs' ? 2 : 4)
          .opacity(this.titleOpacity)

        Text('GeoNote')
          .fontSize(this.getEnglishNameFontSize())
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTheme.getColor('textMuted'))
          .fontFamily('Nunito')
          .letterSpacing(this.currentBreakpoint === 'xs' ? 3 : 6)
          .opacity(this.titleOpacity)
      }

      // 副标题
      Column({ space: this.currentBreakpoint === 'xs' ? 4 : 6 }) {
        Text('记录每一个足迹')
          .fontSize(this.getSubtitleFontSize())
          .fontColor(ColorTheme.getColor('textMuted'))
          .fontFamily('Nunito')
          .opacity(this.subtitleOpacity * 0.9)

        Text('珍藏每一段记忆')
          .fontSize(this.getSubtitleFontSize())
          .fontColor(ColorTheme.getColor('textMuted'))
          .fontFamily('Nunito')
          .opacity(this.subtitleOpacity * 0.9)
      }
      .margin({ top: this.currentBreakpoint === 'xs' ? 8 : 12 })

      // 加载指示器
      Column({ space: this.currentBreakpoint === 'xs' ? 8 : 16 }) {
        LoadingProgress()
          .width(this.currentBreakpoint === 'xs' ? 20 : 28)
          .height(this.currentBreakpoint === 'xs' ? 20 : 28)
          .color(ColorTheme.getColor('textPrimary'))

        Text('加载中...')
          .fontSize(this.currentBreakpoint === 'xs' ? 11 : 13)
          .fontColor(ColorTheme.getColor('textMuted'))
          .fontFamily('Nunito')
          .opacity(0.8)
      }
      .margin({ top: this.currentBreakpoint === 'xs' ? 24 : 48 })
      .opacity(this.progressOpacity)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // 构建主内容 - 横屏布局
  @Builder
  buildLandscapeContent() {
    Row() {
      // 左侧 Logo 区域
      Column() {
        Image($r('app.media.logo'))
          .width(this.getLogoSize())
          .height(this.getLogoSize())
          .objectFit(ImageFit.Contain)
          .scale({ x: this.logoScale, y: this.logoScale })
          .opacity(this.logoOpacity)
      }
      .width('40%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 右侧文字区域
      Column({ space: this.getSpacing() / 2 }) {
        // 应用名称
        Column({ space: 8 }) {
          Text('迹记')
            .fontSize(this.getTitleFontSize())
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorTheme.getColor('textPrimary'))
            .fontFamily('Nunito')
            .letterSpacing(4)
            .opacity(this.titleOpacity)

          Text('GeoNote')
            .fontSize(this.getEnglishNameFontSize())
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTheme.getColor('textMuted'))
            .fontFamily('Nunito')
            .letterSpacing(6)
            .opacity(this.titleOpacity)
        }

        // 副标题
        Column({ space: 4 }) {
          Text('记录每一个足迹')
            .fontSize(this.getSubtitleFontSize())
            .fontColor(ColorTheme.getColor('textMuted'))
            .fontFamily('Nunito')
            .opacity(this.subtitleOpacity * 0.9)

          Text('珍藏每一段记忆')
            .fontSize(this.getSubtitleFontSize())
            .fontColor(ColorTheme.getColor('textMuted'))
            .fontFamily('Nunito')
            .opacity(this.subtitleOpacity * 0.9)
        }

        // 加载指示器
        Row({ space: 12 }) {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(ColorTheme.getColor('textPrimary'))

          Text('加载中...')
            .fontSize(13)
            .fontColor(ColorTheme.getColor('textMuted'))
            .fontFamily('Nunito')
            .opacity(0.8)
        }
        .margin({ top: 24 })
        .opacity(this.progressOpacity)
      }
      .width('60%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 32 })
    }
    .width('100%')
    .height('100%')
  }

  // 构建底部版本信息
  @Builder
  buildVersionInfo() {
    Column({ space: 4 }) {
      Text('Version 1.0.0')
        .fontSize(this.currentBreakpoint === 'xs' ? 10 : 12)
        .fontColor(ColorTheme.getColor('textMuted'))
        .opacity(0.6)
        .fontFamily('Nunito')

      Text('© 2025 GeoNote')
        .fontSize(this.currentBreakpoint === 'xs' ? 8 : 10)
        .fontColor(ColorTheme.getColor('textMuted'))
        .opacity(0.5)
        .fontFamily('Nunito')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .opacity(this.subtitleOpacity)
  }

  build() {
    Stack() {
      // 背景 - 适配深色模式
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ColorTheme.getColor('pageBackground'))

      // 装饰性圆圈 - 响应式
      this.buildDecorCircles()

      // 主内容区域 - 根据横竖屏切换布局
      if (this.isLandscape && (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg')) {
        this.buildLandscapeContent()
      } else {
        this.buildPortraitContent()
      }

      // 底部版本信息 - 使用安全区域
      Column() {
        Blank()
        this.buildVersionInfo()
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: this.currentBreakpoint === 'xs' ? 16 : 24 })
    }
    .width('100%')
    .height('100%')
  }
}
