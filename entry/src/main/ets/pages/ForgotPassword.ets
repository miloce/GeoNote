import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import { router, display } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { HttpUtils } from '../utils/HttpUtils';

screenAdapter.designWidth = 375;

// 请求密码重置接口
interface RequestResetRequest {
  action: string;
  email: string;
}
// 重置密码接口
interface ResetPasswordRequest {
  action: string;
  email: string;
  code: string;
  new_password: string;
}

// 验证验证码接口
interface VerifyCodeRequest {
  action: string;
  email: string;
  code: string;
}

// API响应接口
interface ApiResponse {
  success: boolean;
  message: string;
  code?: number;
}

@Entry
@Component
export struct ForgotPassword {
  @State currentStep: number = 1 // 1: 输入邮箱, 2: 输入token, 3: 设置新密码
  @State email: string = ''
  @State token: string = ''
  @State newPassword: string = ''
  @State confirmPassword: string = ''
  @State isLoading: boolean = false
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
      case 'xs': return 12;
      case 'sm': return 16;
      case 'md': return 24;
      case 'lg': return 32;
      default: return 16;
    }
  }

  getNavBarHeight(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 90;
      case 'sm': return 100;
      case 'md': return 110;
      case 'lg': return 120;
      default: return 100;
    }
  }

  getContentWidth(): string {
    switch (this.currentBreakpoint) {
      case 'xs': return '92%';
      case 'sm': return '88%';
      case 'md': return '60%';
      case 'lg': return '45%';
      default: return '88%';
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
        .width(24)
        .height(24)
        .onClick(() => router.back())

        Blank()

        Text('找回密码')
          .fontSize(this.getFontSize(16))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))

        Blank()

        Row()
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(this.getNavBarHeight())
      .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 44 })
      .backgroundColor(ColorTheme.getColor('cardBackground'))

      // 步骤指示器
      Row({ space: 8 }) {
        this.buildStepIndicator(1, '邮箱验证')
        this.buildStepLine(1)
        this.buildStepIndicator(2, '重置令牌')
        this.buildStepLine(2)
        this.buildStepIndicator(3, '设置密码')
      }
      .width(this.getContentWidth())
      .padding({ top: this.getSpacing(), bottom: this.getSpacing() })
      .justifyContent(FlexAlign.Center)

      // 内容区域
      Scroll() {
        Column({ space: 24 }) {
          if (this.currentStep === 1) {
            this.buildEmailStep()
          } else if (this.currentStep === 2) {
            this.buildVerificationStep()
          } else {
            this.buildPasswordStep()
          }
        }
        .width(this.getContentWidth())
        .padding({ top: this.getSpacing() })
      }
      .layoutWeight(1)
      .width('100%')
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ColorTheme.getColor('pageBackground'))
  }

  @Builder
  buildStepIndicator(step: number, label: string) {
    Column({ space: 4 }) {
      Stack() {
        if (this.currentStep > step) {
          SymbolGlyph($r('sys.symbol.checkmark'))
            .fontSize(this.getFontSize(16))
            .fontColor(['#FFFFFF'])
        } else {
          Text(`${step}`)
            .fontSize(this.getFontSize(14))
            .fontColor(this.currentStep === step ? ColorTheme.getColor('buttonPrimaryText') : ColorTheme.getColor('textMuted'))
        }
      }
      .width(this.currentBreakpoint === 'xs' ? 28 : 32)
      .height(this.currentBreakpoint === 'xs' ? 28 : 32)
      .borderRadius(16)
      .backgroundColor(this.currentStep >= step ? ColorTheme.getColor('buttonPrimaryBg') : ColorTheme.getColor('divider'))
      .alignContent(Alignment.Center)

      Text(label)
        .fontSize(this.getFontSize(12))
        .fontColor(this.currentStep >= step ? ColorTheme.getColor('textLink') : ColorTheme.getColor('textMuted'))
    }
  }

  @Builder
  buildStepLine(step: number) {
    Row()
      .width(this.currentBreakpoint === 'xs' ? 30 : 40)
      .height(2)
      .backgroundColor(this.currentStep > step ? ColorTheme.getColor('buttonPrimaryBg') : ColorTheme.getColor('divider'))
  }

  @Builder
  buildEmailStep() {
    Column({ space: 24 }) {
      Column({ space: 16 }) {
        Text('请输入您的注册邮箱')
          .fontSize(this.getFontSize(20))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))
          .alignSelf(ItemAlign.Start)

        Text('我们将向您的邮箱发送验证码')
          .fontSize(this.getFontSize(14))
          .fontColor(ColorTheme.getColor('textMuted'))
          .alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text('邮箱地址')
          .fontSize(this.getFontSize(14))
          .fontColor(ColorTheme.getColor('textPrimary'))
          .alignSelf(ItemAlign.Start)

        TextInput({ placeholder: '请输入邮箱地址', text: this.email })
          .type(InputType.Email)
          .width('100%')
          .height(this.currentBreakpoint === 'xs' ? 44 : 48)
          .backgroundColor(ColorTheme.getColor('cardBackground'))
          .fontColor(ColorTheme.getColor('textPrimary'))
          .borderRadius(12)
          .fontSize(this.getFontSize(14))
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => { this.email = value; })
      }
      .width('100%')

      Button('发送验证码')
        .width('100%')
        .height(this.currentBreakpoint === 'xs' ? 44 : 48)
        .fontSize(this.getFontSize(16))
        .fontColor(ColorTheme.getColor('buttonPrimaryText'))
        .backgroundColor(ColorTheme.getColor('buttonPrimaryBg'))
        .borderRadius(24)
        .margin({ top: 16 })
        .enabled(!this.isLoading)
        .onClick(() => { this.sendVerificationCode(); })
    }
    .width('100%')
  }

  @Builder
  buildVerificationStep() {
    Column({ space: 24 }) {
      Column({ space: 16 }) {
        Text('输入验证码')
          .fontSize(this.getFontSize(20))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))
          .alignSelf(ItemAlign.Start)

        Text(`验证码已发送至 ${this.email}`)
          .fontSize(this.getFontSize(14))
          .fontColor(ColorTheme.getColor('textMuted'))
          .alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text('验证码')
          .fontSize(this.getFontSize(14))
          .fontColor(ColorTheme.getColor('textPrimary'))
          .alignSelf(ItemAlign.Start)

        TextInput({ placeholder: '请输入6位验证码', text: this.token })
          .type(InputType.Number)
          .maxLength(6)
          .width('100%')
          .height(this.currentBreakpoint === 'xs' ? 44 : 48)
          .backgroundColor(ColorTheme.getColor('cardBackground'))
          .fontColor(ColorTheme.getColor('textPrimary'))
          .borderRadius(12)
          .fontSize(this.getFontSize(14))
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => { this.token = value; })
      }
      .width('100%')

      Button('下一步')
        .width('100%')
        .height(this.currentBreakpoint === 'xs' ? 44 : 48)
        .fontSize(this.getFontSize(16))
        .fontColor(ColorTheme.getColor('buttonPrimaryText'))
        .backgroundColor(ColorTheme.getColor('buttonPrimaryBg'))
        .borderRadius(24)
        .margin({ top: 16 })
        .enabled(!this.isLoading)
        .onClick(() => { this.verifyCode(); })

      Text('没有收到验证码？')
        .fontSize(this.getFontSize(14))
        .fontColor(ColorTheme.getColor('textMuted'))
        .margin({ top: 16 })
        .onClick(() => { this.sendVerificationCode(); })
    }
    .width('100%')
  }

  @Builder
  buildPasswordStep() {
    Column({ space: 24 }) {
      Column({ space: 16 }) {
        Text('设置新密码')
          .fontSize(this.getFontSize(20))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))
          .alignSelf(ItemAlign.Start)

        Text('请设置一个安全的新密码')
          .fontSize(this.getFontSize(14))
          .fontColor(ColorTheme.getColor('textMuted'))
          .alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Column({ space: 8 }) {
        Text('新密码')
          .fontSize(this.getFontSize(14))
          .fontColor(ColorTheme.getColor('textPrimary'))
          .alignSelf(ItemAlign.Start)

        TextInput({ placeholder: '请输入新密码（6-20位）', text: this.newPassword })
          .type(InputType.Password)
          .width('100%')
          .height(this.currentBreakpoint === 'xs' ? 44 : 48)
          .backgroundColor(ColorTheme.getColor('cardBackground'))
          .fontColor(ColorTheme.getColor('textPrimary'))
          .borderRadius(12)
          .fontSize(this.getFontSize(14))
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => { this.newPassword = value; })
      }
      .width('100%')

      Column({ space: 8 }) {
        Text('确认密码')
          .fontSize(this.getFontSize(14))
          .fontColor(ColorTheme.getColor('textPrimary'))
          .alignSelf(ItemAlign.Start)

        TextInput({ placeholder: '请再次输入新密码', text: this.confirmPassword })
          .type(InputType.Password)
          .width('100%')
          .height(this.currentBreakpoint === 'xs' ? 44 : 48)
          .backgroundColor(ColorTheme.getColor('cardBackground'))
          .fontColor(ColorTheme.getColor('textPrimary'))
          .borderRadius(12)
          .fontSize(this.getFontSize(14))
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => { this.confirmPassword = value; })
      }
      .width('100%')

      Button('完成重置')
        .width('100%')
        .height(this.currentBreakpoint === 'xs' ? 44 : 48)
        .fontSize(this.getFontSize(16))
        .fontColor(ColorTheme.getColor('buttonPrimaryText'))
        .backgroundColor(ColorTheme.getColor('buttonPrimaryBg'))
        .borderRadius(24)
        .margin({ top: 16 })
        .enabled(!this.isLoading)
        .onClick(() => { this.resetPassword(); })
    }
    .width('100%')
  }

  /**
   * 显示Toast
   */
  showToast(message: string) {
    promptAction.showToast({ message, duration: 2000 });
  }

  /**
   * 验证邮箱格式
   */
  validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * 发送验证码
   */
  async sendVerificationCode() {
    if (!this.email.trim()) {
      this.showToast('请输入邮箱地址');
      return;
    }

    if (!this.validateEmail(this.email)) {
      this.showToast('邮箱格式不正确');
      return;
    }

    try {
      this.isLoading = true;
      this.showToast('发送中...');

      const postData: RequestResetRequest = {
        action: 'send_reset_code',
        email: this.email.trim()
      };

      const response = await HttpUtils.httpRequestPost('', postData);
      const result: ApiResponse = JSON.parse(response) as ApiResponse;

      if (result.success) {
        this.showToast('验证码已发送到您的邮箱，请查收');
        this.currentStep = 2;
      } else {
        this.showToast(result.message || '发送失败，请稍后再试');
      }
    } catch (error) {
      console.error('[ForgotPassword] 发送验证码失败:', error);
      // 尝试从错误信息中提取 message
      const errorMsg = this.extractErrorMessage(error);
      this.showToast(errorMsg);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 验证验证码
   */
  async verifyCode() {
    if (!this.token.trim()) {
      this.showToast('请输入验证码');
      return;
    }

    if (this.token.length !== 6) {
      this.showToast('请输入6位验证码');
      return;
    }

    try {
      this.isLoading = true;
      this.showToast('验证中...');
      const postData: VerifyCodeRequest = {
        action: 'verify_reset_code',
        email: this.email.trim(),
        code: this.token.trim()
      };

      const response = await HttpUtils.httpRequestPost('', postData);
      const result: ApiResponse = JSON.parse(response) as ApiResponse;

      if (result.success) {
        this.showToast('验证成功');
        // 验证码验证通过，进入下一步
        this.currentStep = 3;
      } else {
        this.showToast(result.message || '验证码错误');
      }
    } catch (error) {
      console.error('[ForgotPassword] 验证验证码失败:', error);
      // 尝试从错误信息中提取 message
      const errorMsg = this.extractErrorMessage(error);
      this.showToast(errorMsg);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 重置密码
   */
  async resetPassword() {
    if (!this.newPassword.trim()) {
      this.showToast('请输入新密码');
      return;
    }

    if (this.newPassword.length < 6 || this.newPassword.length > 20) {
      this.showToast('密码长度应为6-20位');
      return;
    }

    if (this.newPassword !== this.confirmPassword) {
      this.showToast('两次输入的密码不一致');
      return;
    }

    try {
      this.isLoading = true;
      this.showToast('重置中...');

      const postData: ResetPasswordRequest = {
        action: 'reset_password_with_code',
        email: this.email.trim(),
        code: this.token.trim(),
        new_password: this.newPassword
      };

      const response = await HttpUtils.httpRequestPost('', postData);
      const result: ApiResponse = JSON.parse(response) as ApiResponse;

      if (result.success) {
        this.showToast('密码重置成功，请使用新密码登录');
        // 延迟跳转到登录页
        setTimeout(() => {
          router.replaceUrl({ url: 'pages/Login' });
        }, 1500);
      } else {
        this.showToast(result.message || '重置失败，请稍后再试');
      }
    } catch (error) {
      console.error('[ForgotPassword] 重置密码失败:', error);
      // 尝试从错误信息中提取 message
      const errorMsg = this.extractErrorMessage(error);
      this.showToast(errorMsg);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 从错误对象中提取 message
   */
  extractErrorMessage(error: Error): string {
    try {
      const errorStr = String(error);
      // 错误格式: "Error: HTTP 400: {json}"
      const jsonMatch = errorStr.match(/HTTP \d+: ({.*})/);
      if (jsonMatch && jsonMatch[1]) {
        const errorData = JSON.parse(jsonMatch[1]) as ApiResponse;
        if (errorData.message) {
          return errorData.message;
        }
      }
    } catch (e) {
      console.error('[ForgotPassword] 解析错误信息失败:', e);
    }
    // 默认返回通用错误信息
    return '操作失败，请检查网络连接';
  }
}
