import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { display } from '@kit.ArkUI';
import { HttpUtils } from '../utils/HttpUtils';
import { RegisterResponse } from '../model/UserModel';
import { UserStorage } from '../utils/UserStorage';

screenAdapter.designWidth = 375;

// 注册请求数据接口
interface RegisterRequestData {
  action: string;
  username: string;
  email: string;
  password: string;
}

@Entry
@Component
export struct Register {
  private scrollController = new Scroller()
  @State username: string = ''
  @State email: string = ''
  @State password: string = ''
  @State agreeProtocol: boolean = false
  @State isRegistering: boolean = false
  // 响应式布局状态
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint()
  @State isLandscape: boolean = isCurrentLandscape()
  private breakpointSystem: BreakpointSystem = new BreakpointSystem()

  aboutToAppear() {
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
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
    display.off('change');
  }

  // 根据断点获取卡片宽度
  getCardWidth(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 290;
      case 'sm': return 325;
      case 'md': return 380;
      case 'lg': return 420;
      default: return 325;
    }
  }

  // 根据断点获取标题字号
  getTitleFontSize(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 24;
      case 'sm': return 32;
      case 'md': return 36;
      case 'lg': return 40;
      default: return 32;
    }
  }

  // 根据断点获取字体大小
  getFontSize(base: number): number {
    const scale = this.currentBreakpoint === 'xs' ? 0.85 :
                  this.currentBreakpoint === 'lg' ? 1.15 :
                  this.currentBreakpoint === 'md' ? 1.1 : 1.0;
    return base * scale;
  }

  // 根据断点获取间距
  getSpacing(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 12;
      case 'sm': return 16;
      case 'md': return 20;
      case 'lg': return 24;
      default: return 16;
    }
  }

  // 根据断点获取输入框高度
  getInputHeight(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 40;
      case 'sm': return 45;
      case 'md': return 50;
      case 'lg': return 55;
      default: return 45;
    }
  }

  // 获取装饰元素缩放
  getDecorScale(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 0.7;
      case 'sm': return 1.0;
      case 'md': return 1.15;
      case 'lg': return 1.3;
      default: return 1.0;
    }
  }

  build() {
    Scroll(this.scrollController) {
      Stack() {
        // 顶部右侧装饰图片 - 响应式
        Row()
          .height(128 * this.getDecorScale())
          .width(128 * this.getDecorScale())
          .backgroundImageSize(ImageSize.FILL)
          .backgroundImage($r('app.media.5eb645d0ae29e233553fc27fcc9f9c1d008116a6'))
          .position({ right: -30 * this.getDecorScale(), top: 59 * this.getDecorScale() })

        // 左上角装饰图片 - 响应式
        Row()
          .height(64 * this.getDecorScale())
          .width(64 * this.getDecorScale())
          .backgroundImageSize(ImageSize.FILL)
          .backgroundImage($r('app.media.c5f56c2ed4e69c5262ba581aa283ab48698fce41'))
          .position({ left: 36 * this.getDecorScale(), top: 55 * this.getDecorScale() })

        // 顶部背景装饰图片 - 响应式
        Row() {
          Image($r('app.media.737d3651ee89ae5c280ba9bbc4474908293f40cb'))
            .objectFit(ImageFit.Contain)
            .width('100%')
            .height('100%')
        }
        .height('45%')
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .position({
          left: 0,
          top: (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') ? '5%' : 0
        })

        // 左侧装饰圆 - 响应式
        Row()
          .height(172 * this.getDecorScale())
          .width(172 * this.getDecorScale())
          .backgroundImageSize(ImageSize.FILL)
          .backgroundImage($r('app.media.485fbf0d864cc2b6e79ee9fe0ecd0d96b1ad5297'))
          .position({ left: -66 * this.getDecorScale(), top: '20%' })

        // 主卡片背景 - 响应式
        Row()
          .height('70%')
          .width('100%')
          .position({ left: 0, top: '30%' })
          .borderRadius({
            bottomLeft: 0,
            bottomRight: 0,
            topLeft: 40 * this.getDecorScale(),
            topRight: 40 * this.getDecorScale()
          })
          .shadow({
            radius: 40,
            offsetX: 0,
            offsetY: 10,
            fill: false,
            color: 'rgba(55, 62, 125, 0.047)'
          })
          .backgroundColor(ColorTheme.getColor('authCardBackground'))

        // 标题 - 响应式
        Text('注册')
          .fontColor(ColorTheme.getColor('textPrimary'))
          .fontFamily('Noto Sans SC')
          .fontWeight('Bold')
          .fontSize(this.getTitleFontSize())
          .position({
            left: '50%',
            top: (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') ? '31%' : '31%'
          })
          .translate({ x: '-50%' })

        // 返回按钮 - 响应式
        Stack() {
          SymbolGlyph($r('sys.symbol.arrow_left'))
            .fontSize(this.getFontSize(24))
            .fontColor([ColorTheme.getColor('textPrimary')])
        }
        .height(44)
        .width(44)
        .position({
          left: this.getSpacing(),
          top: (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') ? '30%' : '30%'
        })
        .onClick(() => {
          router.back();
        })

        // 输入表单 - 响应式
        Column({ space: this.getSpacing() }) {
          // 用户名输入
          Column() {
            Text('用户名')
              .fontSize(this.getFontSize(14))
              .fontColor(ColorTheme.getColor('textMuted'))
              .margin({ bottom: 6 })
            TextInput({ placeholder: '请输入用户名（3-20个字符）', text: this.username })
              .height(this.getInputHeight())
              .width('100%')
              .backgroundColor(Color.Transparent)
              .fontColor(ColorTheme.getColor('textPrimary'))
              .fontSize(this.getFontSize(16))
              .border({ width: 1, color: ColorTheme.getColor('divider'), radius: 8 })
              .onChange((value: string) => { this.username = value; })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          // 邮箱输入
          Column() {
            Text('邮箱')
              .fontSize(this.getFontSize(14))
              .fontColor(ColorTheme.getColor('textMuted'))
              .margin({ bottom: 6 })
            TextInput({ placeholder: '请输入邮箱地址', text: this.email })
              .height(this.getInputHeight())
              .width('100%')
              .backgroundColor(Color.Transparent)
              .fontColor(ColorTheme.getColor('textPrimary'))
              .fontSize(this.getFontSize(16))
              .type(InputType.Email)
              .border({ width: 1, color: ColorTheme.getColor('divider'), radius: 8 })
              .onChange((value: string) => { this.email = value; })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          // 密码输入
          Column() {
            Text('密码')
              .fontSize(this.getFontSize(14))
              .fontColor(ColorTheme.getColor('textMuted'))
              .margin({ bottom: 6 })
            TextInput({ placeholder: '请输入密码（至少6位）', text: this.password })
              .height(this.getInputHeight())
              .width('100%')
              .backgroundColor(Color.Transparent)
              .fontColor(ColorTheme.getColor('textPrimary'))
              .fontSize(this.getFontSize(16))
              .type(InputType.Password)
              .border({ width: 1, color: ColorTheme.getColor('divider'), radius: 8 })
              .onChange((value: string) => { this.password = value; })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .width(this.getCardWidth())
        .padding(this.getSpacing())
        .borderRadius(25)
        .backgroundColor(ColorTheme.getColor('authCardBackground'))
        .shadow({ radius: 20, offsetX: 0, offsetY: 8, color: 'rgba(55, 62, 125, 0.05)' })
        .position({ left: '50%', top: '38%' })
        .translate({ x: '-50%' })

        // 协议勾选 - 响应式
        Row() {
          Stack() {
            Image($r('app.media.Vector_10_42'))
              .height(this.getFontSize(17))
              .width(this.getFontSize(17))
              .opacity(this.agreeProtocol ? 0 : 1)
            Image($r('app.media.Vector_10_43'))
              .height(this.getFontSize(17))
              .width(this.getFontSize(17))
              .opacity(this.agreeProtocol ? 1 : 0)
          }
          .width(20)
          .height(20)
          .onClick(() => { this.agreeProtocol = !this.agreeProtocol; })

          Text() {
            Span('我已阅读并同意')
              .fontColor(ColorTheme.getColor('textPrimary'))
              .fontSize(this.getFontSize(13))
            Span('《用户协议》')
              .fontColor(ColorTheme.getColor('textLink'))
              .fontSize(this.getFontSize(13))
              .onClick(() => { this.handleUserAgreement(); })
            Span('和')
              .fontColor(ColorTheme.getColor('textPrimary'))
              .fontSize(this.getFontSize(13))
            Span('《隐私政策》')
              .fontColor(ColorTheme.getColor('textLink'))
              .fontSize(this.getFontSize(13))
              .onClick(() => { this.handlePrivacyPolicy(); })
          }
          .fontFamily('Noto Sans SC')
          .margin({ left: 8 })
        }
        .width(this.getCardWidth())
        .position({
          left: '50%',
          top: (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') ? '79%' : '76%'
        })
        .translate({ x: '-50%' })

        // 注册按钮 - 响应式
        Button('注册')
          .width(this.getCardWidth())
          .height(this.currentBreakpoint === 'xs' ? 45 : 55)
          .fontSize(this.getFontSize(16))
          .fontWeight(FontWeight.Bold)
          .backgroundColor(ColorTheme.getColor('authButtonBg'))
          .fontColor(ColorTheme.getColor('authButtonText'))
          .borderRadius(40)
          .shadow({
            radius: 20,
            offsetX: 0,
            offsetY: 8,
            color: 'rgba(25, 28, 50, 0.1)'
          })
          .position({
            left: '50%',
            top: (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') ? '85%' : '81%'
          })
          .translate({ x: '-50%' })
          .onClick(() => { this.handleRegister(); })

        // 已有账号提示 - 响应式
        Text() {
          Span('已有账号？')
            .fontColor(ColorTheme.getColor('textMuted'))
            .fontSize(this.getFontSize(14))
          Span('立即登录')
            .fontColor(ColorTheme.getColor('textLink'))
            .fontSize(this.getFontSize(14))
            .onClick(() => { router.back(); })
        }
        .fontFamily('Noto Sans SC')
        .position({
          left: '50%',
          top: (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') ? '94%' : '90%'
        })
        .translate({ x: '-50%' })
        .onClick(() => { router.back(); })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ColorTheme.getColor('authPageBackground'))
    }
    .width('100%')
    .height('100%')
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
      console.error('[Register] 显示提示失败', e);
    }
  }

  /**
   * 跳转到隐私政策页面
   */
  handlePrivacyPolicy(): void {
    try {
      router.pushUrl({
        url: 'pages/PrivacyPolicy'
      } as router.RouterOptions);
    } catch (error) {
      console.error('[Register] 跳转隐私政策页面失败:', error);
    }
  }

  /**
   * 跳转到用户协议页面
   */
  handleUserAgreement(): void {
    try {
      router.pushUrl({
        url: 'pages/UserAgreement'
      } as router.RouterOptions);
    } catch (error) {
      console.error('[Register] 跳转用户协议页面失败:', error);
    }
  }

  /**
   * 处理注册
   */
  async handleRegister() {
    // 验证输入
    if (!this.agreeProtocol) {
      this.showToast('请先同意用户协议和隐私政策');
      return;
    }

    if (this.username.trim() === '') {
      this.showToast('请输入用户名');
      return;
    }

    if (this.username.length < 3 || this.username.length > 20) {
      this.showToast('用户名长度应为3-20个字符');
      return;
    }

    if (!/^[a-zA-Z0-9_]+$/.test(this.username)) {
      this.showToast('用户名只能包含字母、数字和下划线');
      return;
    }

    if (this.email.trim() === '') {
      this.showToast('请输入邮箱地址');
      return;
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email)) {
      this.showToast('请输入有效的邮箱地址');
      return;
    }

    if (this.password.trim() === '') {
      this.showToast('请输入密码');
      return;
    }

    if (this.password.length < 6) {
      this.showToast('密码长度至少6位');
      return;
    }

    if (this.isRegistering) {
      return; // 防止重复提交
    }

    try {
      this.isRegistering = true;
      this.showToast('注册中...');

      const postData: RegisterRequestData = {
        action: 'register',
        username: this.username,
        email: this.email,
        password: this.password
      };

      const response = await HttpUtils.httpRequestPost('', postData);
      let result: RegisterResponse;

      try {
        result = JSON.parse(response) as RegisterResponse;
      } catch (parseError) {
        throw new Error('响应数据解析失败');
      }

      if (result.success && result.code === 200 && result.data) {
        // 保存用户信息到本地存储
        try {
          await UserStorage.saveUser(result.data);
          console.log('[Register] 注册成功，用户信息已保存:', result.data.username);

          this.showToast('注册成功！');

          // 延迟跳转
          await new Promise<void>((resolve) => {
            setTimeout(() => {
              resolve();
            }, 300);
          });

          // 跳转到主页
          try {
            router.replaceUrl({ url: 'pages/Index' });
          } catch (e) {
            console.error('[Register] 路由跳转失败', e);
          }
        } catch (saveError) {
          console.error('[Register] 保存用户信息失败:', saveError);
          this.showToast('注册成功，但保存用户信息失败');
        }
      } else {
        this.showToast(result.message || '注册失败');
      }
    } catch (error) {
      console.error('[Register] 注册请求失败', error);
      this.showToast('注册失败，请稍后再试');
    } finally {
      this.isRegistering = false;
    }
  }
}
