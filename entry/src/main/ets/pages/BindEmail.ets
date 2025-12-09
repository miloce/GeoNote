import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import { router, display } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { HttpUtils } from '../utils/HttpUtils';
import { UserStorage } from '../utils/UserStorage';
import { ApiResponse, User } from '../model/UserModel';

screenAdapter.designWidth = 375;

// 绑定邮箱请求数据接口
interface BindEmailRequestData {
  action: string;
  user_id: number;
  email: string;
}

@Entry
@Component
export struct BindEmail {
  private scrollController = new Scroller()
  @State email: string = ''
  @State isBinding: boolean = false
  @State userId: number = 0
  @State username: string = ''
  @State fromHuaweiLogin: boolean = false
  @State emailError: string = ''
  // 响应式布局
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
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params) {
        this.userId = params['userId'] as number || 0;
        this.username = params['username'] as string || '';
        this.fromHuaweiLogin = params['fromHuaweiLogin'] as boolean || false;
      }
      console.log('[BindEmail] 用户ID:', this.userId);
      console.log('[BindEmail] 用户名:', this.username);
    } catch (error) {
      console.error('[BindEmail] 获取路由参数失败:', error);
    }
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

  getContentWidth(): string {
    switch (this.currentBreakpoint) {
      case 'xs': return '92%';
      case 'sm': return '90%';
      case 'md': return '60%';
      case 'lg': return '45%';
      default: return '90%';
    }
  }

  getSpacing(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 16;
      case 'sm': return 20;
      case 'md': return 28;
      case 'lg': return 36;
      default: return 20;
    }
  }

  build() {
    Scroll(this.scrollController) {
      Column() {
        // 顶部装饰区域
        Stack() {
          // 背景装饰图片
          Row()
            .width('100%')
            .height('100%')
            .backgroundImageSize(ImageSize.Cover)
            .backgroundImage($r('app.media.737d3651ee89ae5c280ba9bbc4474908293f40cb'))

          // 右上角装饰
          Row()
            .height(this.currentBreakpoint === 'lg' ? 140 : 128)
            .width(this.currentBreakpoint === 'lg' ? 140 : 128)
            .backgroundImageSize(ImageSize.FILL)
            .backgroundImage($r('app.media.5eb645d0ae29e233553fc27fcc9f9c1d008116a6'))
            .position({ right: 0, top: 30 })

          // 左上角装饰
          Row()
            .height(64)
            .width(64)
            .backgroundImageSize(ImageSize.FILL)
            .backgroundImage($r('app.media.c5f56c2ed4e69c5262ba581aa283ab48698fce41'))
            .position({ left: 36, top: 55 })

          // 左下角装饰
          Row()
            .height(172)
            .width(172)
            .backgroundImageSize(ImageSize.FILL)
            .backgroundImage($r('app.media.485fbf0d864cc2b6e79ee9fe0ecd0d96b1ad5297'))
            .position({ left: -66, bottom: 0 })
        }
        .width('100%')
        .height(this.isLandscape ? 180 : 280)

        // 主卡片区域
        Column() {
          // 标题
          Text('绑定邮箱')
            .fontColor(ColorTheme.getColor('textPrimary'))
            .fontWeight(FontWeight.Bold)
            .fontSize(this.getFontSize(32))
            .textAlign(TextAlign.Center)
            .margin({ top: this.getSpacing() + 20, bottom: 12 })

          // 提示文字
          Text('请绑定邮箱以完善账号信息')
            .fontColor(ColorTheme.getColor('textMuted'))
            .fontSize(this.getFontSize(14))
            .textAlign(TextAlign.Center)
            .margin({ bottom: this.getSpacing() })

          // 用户名显示卡片
          Row({ space: 8 }) {
            Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
              SymbolGlyph($r('sys.symbol.person_crop_circle_fill_1'))
                .fontSize(this.getFontSize(20))
                .fontColor([ColorTheme.getColor('textPrimary')])
            }
            .width(32)
            .height(32)
            .borderRadius(16)
            .backgroundColor(ColorTheme.getColor('pageBackground'))

            Column({ space: 2 }) {
              Text('当前用户')
                .fontColor(ColorTheme.getColor('textMuted'))
                .fontSize(this.getFontSize(12))
              Text(this.username)
                .fontColor(ColorTheme.getColor('textPrimary'))
                .fontWeight(FontWeight.Medium)
                .fontSize(this.getFontSize(15))
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width(this.getContentWidth())
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .borderRadius(16)
          .backgroundColor(ColorTheme.getColor('pageBackground'))
          .margin({ bottom: this.getSpacing() })

          // 邮箱输入框
          Column({ space: 4 }) {
            Row() {
              Flex({ justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
                SymbolGlyph($r('sys.symbol.envelope_fill'))
                  .fontSize(this.getFontSize(20))
                  .fontColor([ColorTheme.getColor('textPrimary')])
              }
              .width(32)
              .height(32)
              .margin({ left: 20, right: 12 })

              TextInput({ placeholder: '请输入邮箱地址', text: $$this.email })
                .layoutWeight(1)
                .height(this.currentBreakpoint === 'xs' ? 56 : 65)
                .backgroundColor(Color.Transparent)
                .fontColor(ColorTheme.getColor('textPrimary'))
                .fontSize(this.getFontSize(16))
                .type(InputType.Email)
                .placeholderColor(ColorTheme.getColor('textMuted'))
                .onChange((value: string) => {
                  this.email = value;
                  if (value && !this.validateEmail(value)) {
                    this.emailError = '邮箱格式不正确';
                  } else {
                    this.emailError = '';
                  }
                })
            }
            .width(this.getContentWidth())
            .height(this.currentBreakpoint === 'xs' ? 56 : 65)
            .borderRadius(25)
            .border({
              width: this.emailError ? 2 : 0,
              color: this.emailError ? '#E53E3E' : 'transparent'
            })
            .shadow({
              radius: 20,
              offsetX: 0,
              offsetY: 8,
              fill: false,
              color: 'rgba(55, 62, 125, 0.1)'
            })
            .backgroundColor(ColorTheme.getColor('pageBackground'))

            if (this.emailError) {
              Text(this.emailError)
                .fontColor('#E53E3E')
                .fontSize(this.getFontSize(12))
                .padding({ left: 20 })
                .width(this.getContentWidth())
            }
          }
          .margin({ bottom: this.getSpacing() })

          // 按钮区域
          Row() {
            // 跳过按钮
            Row({ space: 4 }) {
              Text('暂时跳过')
                .fontColor(ColorTheme.getColor('textMuted'))
                .fontSize(this.getFontSize(14))
              Text('→')
                .fontColor(ColorTheme.getColor('textMuted'))
                .fontSize(this.getFontSize(14))
            }
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(20)
            .onClick(() => {
              if (!this.isBinding) {
                this.handleSkip();
              }
            })

            Blank()

            // 绑定按钮
            Button() {
              if (this.isBinding) {
                LoadingProgress()
                  .width(24)
                  .height(24)
                  .color(ColorTheme.getColor('authButtonText'))
              } else {
                Text('绑定邮箱')
                  .fontColor(ColorTheme.getColor('authButtonText'))
                  .fontWeight(FontWeight.Bold)
                  .fontSize(this.getFontSize(16))
              }
            }
            .width(this.currentBreakpoint === 'xs' ? 130 : 145)
            .height(this.currentBreakpoint === 'xs' ? 50 : 55)
            .borderRadius(40)
            .backgroundColor(ColorTheme.getColor('authButtonBg'))
            .opacity(this.isBinding || this.emailError ? 0.6 : 1)
            .shadow({
              radius: 20,
              offsetX: 0,
              offsetY: 8,
              fill: false,
              color: 'rgba(25, 28, 50, 0.1)'
            })
            .onClick(() => {
              if (!this.isBinding && !this.emailError) {
                this.handleBindEmail();
              }
            })
          }
          .width(this.getContentWidth())
          .margin({ bottom: this.getSpacing() + 20 })

          // 提示信息
          Column({ space: 8 }) {
            Row({ space: 4 }) {
              SymbolGlyph($r('sys.symbol.exclamationmark_triangle_fill'))
                .fontSize(this.getFontSize(14))
                .fontColor([ColorTheme.getColor('textMuted')])
              Text('绑定邮箱后可用于找回密码')
                .fontColor(ColorTheme.getColor('textMuted'))
                .fontSize(this.getFontSize(12))
            }
            .justifyContent(FlexAlign.Center)

            Text('您的邮箱信息将被安全保护')
              .fontColor(ColorTheme.getColor('textMuted'))
              .fontSize(this.getFontSize(11))
              .opacity(0.6)
          }
          .width(this.getContentWidth())
          .margin({ bottom: 40 })
        }
        .width('100%')
        .borderRadius({ topLeft: 40, topRight: 40 })
        .backgroundColor(ColorTheme.getColor('authCardBackground'))
        .alignItems(HorizontalAlign.Center)
        .margin({ top: -40 })
        .shadow({
          radius: 40,
          offsetX: 0,
          offsetY: -10,
          fill: false,
          color: 'rgba(55, 62, 125, 0.05)'
        })
      }
      .width('100%')
      .backgroundColor(ColorTheme.getColor('authPageBackground'))
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  /**
   * 显示Toast提示
   */
  showToast(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    } catch (e) {
      console.error('[BindEmail] 显示提示失败', e);
    }
  }

  /**
   * 验证邮箱格式
   */
  validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * 处理绑定邮箱
   */
  async handleBindEmail() {
    // 验证输入
    if (this.email.trim() === '') {
      this.emailError = '请输入邮箱';
      this.showToast('请输入邮箱');
      return;
    }

    if (!this.validateEmail(this.email)) {
      this.emailError = '邮箱格式不正确';
      this.showToast('请输入有效的邮箱地址');
      return;
    }

    this.emailError = '';

    if (this.userId === 0) {
      this.showToast('用户信息异常，请重新登录');
      return;
    }

    if (this.isBinding) {
      return; // 防止重复提交
    }

    try {
      this.isBinding = true;

      const postData: BindEmailRequestData = {
        action: 'bind_email',
        user_id: this.userId,
        email: this.email
      };
      const response = await HttpUtils.httpRequestPost('', postData);
      let result: ApiResponse<User>;

      try {
        result = JSON.parse(response) as ApiResponse<User>;
      } catch (parseError) {
        throw new Error('响应数据解析失败');
      }

      if (result.success && result.code === 200) {
        // 更新本地存储的用户信息
        if (result.data) {
          await UserStorage.saveUser(result.data);
        }

        this.showToast('邮箱绑定成功！');

        // 延迟跳转
        await new Promise<void>((resolve) => {
          setTimeout(() => {
            resolve();
          }, 500);
        });

        // 跳转到主页
        try {
          router.replaceUrl({ url: 'pages/Index' });
        } catch (e) {
          console.error('[BindEmail] 路由跳转失败:', e);
        }
      } else {
        this.showToast(result.message || '绑定失败');
      }
    } catch (error) {
      console.error('[BindEmail] 绑定邮箱失败', error);
      this.showToast('绑定失败，请稍后再试');
    } finally {
      this.isBinding = false;
    }
  }

  /**
   * 处理跳过
   */
  async handleSkip() {
    try {
      this.showToast('已跳过，您可以稍后在设置中绑定邮箱');

      await new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve();
        }, 500);
      });

      // 跳转到主页
      router.replaceUrl({ url: 'pages/Index' });
    } catch (error) {
      console.error('[BindEmail] 跳转失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
  }
}
