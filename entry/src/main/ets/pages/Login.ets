import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { display } from '@kit.ArkUI';
import { HttpUtils } from '../utils/HttpUtils';
import { LoginResponse, User } from '../model/UserModel';
import { UserStorage } from '../utils/UserStorage';
import { DiaryStorage } from '../utils/DiaryStorage';
import { authentication } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';


screenAdapter.designWidth = 375;

// 登录请求数据接口
interface LoginRequestData {
  action: string;
  username: string;
  password: string;
}

// 华为登录请求数据接口
interface HuaweiLoginRequestData {
  action: string;
  authorization_code: string;
  nick_name?: string;
  avatar_uri?: string;
}

/**
 * 错误码枚举
 */
enum ErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_INTERNAL_ERROR = 1001502009,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002,
  ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED = 1005300001,
  ERROR_CODE_SIGNATURE_FAILED = 1001500001
}

@Entry
@Component
export struct Login {
  private scrollController = new Scroller()
  @State username: string = ''
  @State password: string = ''
  @State agreeProtocol: boolean = false
  @State isLogging: boolean = false
  // 响应式布局状态
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint()
  @State isLandscape: boolean = isCurrentLandscape()
  private breakpointSystem: BreakpointSystem = new BreakpointSystem()

  /**
   * 页面即将显示时检查登录状态
   */
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

    try {
      const isLoggedIn = await UserStorage.isLoggedIn();
      if (isLoggedIn) {
        console.log('[Login] 用户已登录，跳转到主页');
        // 用户已登录，直接跳转到主页
        router.replaceUrl({ url: 'pages/Index', params: { from: 'pages_Login' } });
      }
    } catch (error) {
      console.error('[Login] 检查登录状态失败:', error);
    }
  }

  aboutToDisappear() {
    // 注销断点监听
    this.breakpointSystem.unregister();
    display.off('change');
  }

  // 根据断点获取内容区域宽度
  getContentWidth(): string {
    switch (this.currentBreakpoint) {
      case 'xs': return '100%';
      case 'sm': return '100%';
      case 'md': return '480vp';
      case 'lg': return '520vp';
      default: return '100%';
    }
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

  // 根据断点获取按钮宽度
  getButtonWidth(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 120;
      case 'sm': return 145;
      case 'md': return 160;
      case 'lg': return 180;
      default: return 145;
    }
  }

  // 根据断点获取输入框高度
  getInputHeight(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 36;
      case 'sm': return 40;
      case 'md': return 44;
      case 'lg': return 48;
      default: return 40;
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
        Stack() {
          Row()
            .id('6:405')
            .height(172 * this.getDecorScale())
            .width(172 * this.getDecorScale())
            .opacity(1)
            .position({ left: 0, top: 0 })
            .backgroundImageSize(ImageSize.FILL)
            .backgroundImage($r('app.media.485fbf0d864cc2b6e79ee9fe0ecd0d96b1ad5297'))
        }
        .height(172 * this.getDecorScale())
        .width(172 * this.getDecorScale())
        .opacity(1)
        .clip(true)
        .position({ left: -66 * this.getDecorScale(), top: '20%' })

        Row()
          .id('6:406')
          .height('65%')
          .width('100%')
          .opacity(1)
          .position({ left: 0, top: '35%' })
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
        // 顶部 logo 图，统一大小，居中放置，大屏下移一些并保持不放大
        Row() {
          Image($r('app.media.737d3651ee89ae5c280ba9bbc4474908293f40cb'))
            .objectFit(ImageFit.Contain)
            .width('100%')
            .height('100%')
        }
        .id('11:36')
        .height('45%') // 各端统一高度
        .width('100%')
        .opacity(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .position({
          left: 0,
          top: (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') ? '5%' : 0
        }) // 大屏下移并居中，手机保持
        // 协议勾选区 - 响应式
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
          .onClick(() => {
            this.agreeProtocol = !this.agreeProtocol;
          })

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
          top: (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') ? '70%' : '65%'
        }) // 大屏下移，手机保持
        .translate({ x: '-50%' })

        // 注册链接 - 响应式
        Text() {
          Span('还没有账号？')
            .fontColor(ColorTheme.getColor('textLink'))
            .fontSize(this.getFontSize(16))
          Span('现在注册')
            .fontColor(ColorTheme.getColor('textLink'))
            .fontSize(this.getFontSize(16))
            .decoration({ type: TextDecorationType.Underline })
            .onClick(() => { this.handleRegister(); })
        }
        .fontFamily('Noto Sans SC')
        .position({ left: '50%', top: '94%' })
        .translate({ x: '-50%' })
        .onClick(() => { this.handleRegister(); })

        // 分隔线"或" - 响应式
        Row() {
          Divider().layoutWeight(1).strokeWidth(1).color(ColorTheme.getColor('divider'))
          Text('或')
            .fontColor(ColorTheme.getColor('textPrimary'))
            .fontSize(this.getFontSize(16))
            .opacity(0.5)
            .margin({ left: this.getSpacing(), right: this.getSpacing() })
          Divider().layoutWeight(1).strokeWidth(1).color(ColorTheme.getColor('divider'))
        }
        .width(this.getCardWidth() * 0.85)
        .position({ left: '50%', top: '80%' })
        .translate({ x: '-50%' })

        // 华为登录按钮 - 响应式
        Stack() {
          Image($r('app.media.Boolean_operation_6_596'))
            .height(54 * this.getDecorScale())
            .width(54 * this.getDecorScale())
        }
        .height(54 * this.getDecorScale())
        .width(54 * this.getDecorScale())
        .clip(true)
        .position({ left: '50%', top: '85%' })
        .translate({ x: '-50%' })
        .onClick(() => { this.handleHuaweiLogin(); })

        // 标题"登录" - 响应式
        Text('登录')
          .fontColor(ColorTheme.getColor('textPrimary'))
          .fontFamily('Noto Sans SC')
          .fontWeight('Bold')
          .fontSize(this.getTitleFontSize())
          .position({
            left: '50%',
            top: (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') ? '39%' : '40%' // 大屏再上移一点
          }) // 大屏下移，手机保持原位
          .translate({ x: '-50%' })

        // 忘记密码和登录按钮行 - 响应式
        Row() {
          Text('忘记密码?')
            .fontColor(ColorTheme.getColor('textMuted'))
            .fontFamily('Noto Sans SC')
            .fontSize(this.getFontSize(14))
            .onClick(() => { this.handleForgotPassword(); })

          Blank()

          Button('登录')
            .width(this.getButtonWidth())
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
            .onClick(() => { this.handleLogin(); })
        }
        .width(this.getCardWidth())
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .position({
          left: '50%',
          top: (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') ? '74%' : '69%'
        }) // 大屏下移，手机保持原位
        .translate({ x: '-50%' })

        // 输入表单卡片 - 响应式
        Column({ space: 0 }) {
          Row() {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(this.getFontSize(24))
              .fontColor([ColorTheme.getColor('textMuted')])
              .margin({ right: this.getSpacing() })
            TextInput({ placeholder: '用户名', text: this.username })
              .layoutWeight(1)
              .height(this.getInputHeight())
              .backgroundColor(Color.Transparent)
              .fontColor(ColorTheme.getColor('textPrimary'))
              .fontSize(this.getFontSize(16))
              .onChange((value: string) => { this.username = value; })
          }
          .width('100%')
          .padding({ left: this.getSpacing(), right: this.getSpacing(), top: this.getSpacing() })

          Divider().width('90%').strokeWidth(0.5).color(ColorTheme.getColor('divider')).margin({ top: 8, bottom: 8 })

          Row() {
            SymbolGlyph($r('sys.symbol.lock'))
              .fontSize(this.getFontSize(24))
              .fontColor([ColorTheme.getColor('textMuted')])
              .margin({ right: this.getSpacing() })
            TextInput({ placeholder: '密码', text: this.password })
              .layoutWeight(1)
              .height(this.getInputHeight())
              .backgroundColor(Color.Transparent)
              .fontColor(ColorTheme.getColor('textPrimary'))
              .fontSize(this.getFontSize(16))
              .type(InputType.Password)
              .onChange((value: string) => { this.password = value; })
          }
          .width('100%')
          .padding({ left: this.getSpacing(), right: this.getSpacing(), bottom: this.getSpacing() })
        }
        .width(this.getCardWidth())
        .borderRadius(25)
        .backgroundColor(ColorTheme.getColor('authCardBackground'))
        .shadow({ radius: 20, offsetX: 0, offsetY: 8, color: 'rgba(55, 62, 125, 0.05)' })
        .position({ left: '50%', top: '47%' })
        .translate({ x: '-50%' })

        // 装饰图片 - 响应式
        Image($r('app.media.Vector_6_451'))
          .height(53 * this.getDecorScale())
          .width(142 * this.getDecorScale())
          .opacity(0.2)
          .position({ left: '50%', top: '32%' })
          .translate({ x: '-50%' })

        // 右上装饰 - 响应式
        Row()
          .height(128 * this.getDecorScale())
          .width(128 * this.getDecorScale())
          .backgroundImageSize(ImageSize.FILL)
          .backgroundImage($r('app.media.5eb645d0ae29e233553fc27fcc9f9c1d008116a6'))
          .position({ right: -30 * this.getDecorScale(), top: 59 * this.getDecorScale() })

        // 左上装饰 - 响应式
        Row()
          .height(64 * this.getDecorScale())
          .width(64 * this.getDecorScale())
          .backgroundImageSize(ImageSize.FILL)
          .backgroundImage($r('app.media.c5f56c2ed4e69c5262ba581aa283ab48698fce41'))
          .position({ left: 36 * this.getDecorScale(), top: 55 * this.getDecorScale() })
      }
      .width('100%')
      .height('100%')
      .clip(true)
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
      console.error('[Login] 显示提示失败', e);
    }
  }

  /**
   * 处理普通登录
   */
  async handleLogin() {
    // 验证输入
    if (!this.agreeProtocol) {
      this.showToast('请先同意用户协议和隐私政策');
      return;
    }

    if (this.username.trim() === '') {
      this.showToast('请输入用户名或邮箱');
      return;
    }

    if (this.password.trim() === '') {
      this.showToast('请输入密码');
      return;
    }

    if (this.isLogging) {
      return; // 防止重复提交
    }

    try {
      this.isLogging = true;
      this.showToast('登录中...');
      const postData: LoginRequestData = {
        action: 'app_login',
        username: this.username,
        password: this.password
      };

      const response = await HttpUtils.httpRequestPost('', postData);
      let result: LoginResponse;

      try {
        result = JSON.parse(response) as LoginResponse;
      } catch (parseError) {
        throw new Error('响应数据解析失败');
      }

      if (result.success && result.code === 200 && result.data) {
        // 保存用户信息到本地存储
        try {
          await UserStorage.saveUser(result.data);
          // 设置当前用户ID到DiaryStorage，实现数据隔离
          await DiaryStorage.setCurrentUserId(result.data.id);
          console.log('[Login] 登录成功，用户信息已保存:', result.data.username, 'ID:', result.data.id);

          this.showToast('登录成功！');

          // 延迟跳转，确保数据已保存
          await new Promise<void>((resolve) => {
            setTimeout(() => {
              resolve();
            }, 300);
          });

          // 跳转到主页
          try {
            router.pushUrl({ url: 'pages/Index', params: { from: 'pages_Login' } });
          } catch (e) {
            console.error('[Login] 路由跳转失败', e);
          }
        } catch (saveError) {
          console.error('[Login] 保存用户信息失败:', saveError);
          this.showToast('登录成功，但保存用户信息失败');
        }
      } else {
        this.showToast(result.message || '登录失败');
      }
    } catch (error) {
      console.error('[Login] 登录请求失败', error);
      this.showToast('登录失败，请稍后再试');
    } finally {
      this.isLogging = false;
    }
  }

  /**
   * 处理华为账号登录
   */
  async handleHuaweiLogin() {
    if (this.isLogging) {
      return; // 防止重复提交
    }

    // 验证是否同意协议
    if (!this.agreeProtocol) {
      this.showToast('请先同意用户协议和隐私政策');
      return;
    }

    try {
      this.isLogging = true;
      this.showToast('正在登录...');

      // 获取Context
      const context = getContext() as common.UIAbilityContext;

      // 创建授权请求
      const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();

      // 获取头像昵称需要传profile scope
      authRequest.scopes = ['profile'];

      // 若开发者需要进行服务端开发，则需传serviceauthcode permission获取authorizationCode
      authRequest.permissions = ['serviceauthcode'];

      // 用户是否需要登录授权
      authRequest.forceAuthorization = true;

      // 用于防跨站点请求伪造
      authRequest.state = util.generateRandomUUID();

      // 执行授权请求
      const controller = new authentication.AuthenticationController(context);
      const data = await controller.executeRequest(authRequest);

      const authorizationWithHuaweiIDResponse = data as authentication.AuthorizationWithHuaweiIDResponse;
      const state = authorizationWithHuaweiIDResponse.state;

      if (state && authRequest.state !== state) {
        console.error('[Login] 授权失败：state不匹配');
        this.showToast('授权失败，请重试');
        return;
      }

      console.log('[Login] 华为账号授权成功');

      const authorizationWithHuaweiIDCredential = authorizationWithHuaweiIDResponse.data;
      if (!authorizationWithHuaweiIDCredential) {
        console.error('[Login] 获取授权信息失败');
        this.showToast('获取授权信息失败');
        this.isLogging = false;
        return;
      }

      // 从授权响应中获取头像、昵称和授权码
      const avatarUri = authorizationWithHuaweiIDCredential.avatarUri;
      const nickName = authorizationWithHuaweiIDCredential.nickName;
      const authorizationCode = authorizationWithHuaweiIDCredential.authorizationCode;

      console.log('[Login] 授权码:', authorizationCode ? authorizationCode.substring(0, 20) + '...' : '无');
      console.log('[Login] 昵称:', nickName || '无');
      console.log('[Login] 头像URI:', avatarUri || '无');

      if (!authorizationCode) {
        console.error('[Login] 获取授权码失败');
        this.showToast('获取授权码失败');
        this.isLogging = false;
        return;
      }

      // 将授权码、头像和昵称发送到服务端
      await this.handleHuaweiAuthCode(authorizationCode, nickName || '', avatarUri || '');

    } catch (error) {
      console.error('[Login] 华为账号登录异常:', error);
      this.dealAllError(error as BusinessError);
    } finally {
      this.isLogging = false;
    }
  }

  /**
   * 处理华为账号授权码
   */
  async handleHuaweiAuthCode(authorizationCode: string, nickName: string = '', avatarUri: string = '') {
    if (!authorizationCode) {
      console.error('[Login] 授权码为空');
      this.showToast('授权码为空');
      return;
    }

    try {
      const postData: HuaweiLoginRequestData = {
        action: 'huawei_login',
        authorization_code: authorizationCode
      };

      // 如果客户端获取到了昵称和头像，一并发送
      if (nickName) {
        postData.nick_name = nickName;
      }
      if (avatarUri) {
        postData.avatar_uri = avatarUri;
      }

      console.log('[Login] 发送授权码到服务端');

      const response = await HttpUtils.httpRequestPost('', postData);
      console.log('[Login] 服务端响应:', response);

      let result: LoginResponse;
      try {
        result = JSON.parse(response) as LoginResponse;
      } catch (parseError) {
        console.error('[Login] 响应数据解析失败');
        throw new Error('响应数据解析失败');
      }

      console.log('[Login] 登录结果:', result);

      // 检查响应状态
      if (!result) {
        throw new Error('服务端无响应');
      }

      if (result.success && result.code === 200 && result.data) {
        // 保存用户信息到本地存储
        try {
          await UserStorage.saveUser(result.data);
          // 设置当前用户ID到DiaryStorage，实现数据隔离
          await DiaryStorage.setCurrentUserId(result.data.id);
          console.log('[Login] 华为账号登录成功，用户信息已保存, ID:', result.data.id);

          // 检查是否是新用户
          const isNewUser = result.data.is_new_user === true;
          const email = result.data.email || '';
          const hasNoEmail = !email || email.endsWith('@huawei.temp');

          if (isNewUser && hasNoEmail) {
            // 新用户且没有邮箱，跳转到绑定邮箱页面
            this.showToast('欢迎！请绑定邮箱以完善账号信息');
            
            await new Promise<void>((resolve) => {
              setTimeout(() => {
                resolve();
              }, 300);
            });

            try {
              router.pushUrl({
                url: 'pages/BindEmail',
                params: {
                  userId: result.data.id,
                  username: result.data.username,
                  fromHuaweiLogin: true
                }
              });
            } catch (e) {
              console.error('[Login] 跳转绑定邮箱页面失败:', e);
              // 跳转失败，直接进入主页
              router.pushUrl({ url: 'pages/Index', params: { from: 'pages_Login' } });
            }
          } else {
            // 老用户或已绑定邮箱，直接跳转到主页
            this.showToast('登录成功！');

            await new Promise<void>((resolve) => {
              setTimeout(() => {
                resolve();
              }, 300);
            });

            try {
              router.pushUrl({ url: 'pages/Index', params: { from: 'pages_Login' } });
            } catch (e) {
              console.error('[Login] 路由跳转失败:', e);
            }
          }
        } catch (saveError) {
          console.error('[Login] 保存用户信息失败:', saveError);
          this.showToast('登录成功，但保存用户信息失败');
        }
      } else {
        // 处理服务端返回的错误
        console.error('[Login] 服务端返回登录失败');
        console.error('[Login] 错误码:', result.code);
        console.error('[Login] 错误信息:', result.message);
        
        // 根据错误码提供更友好的提示
        let errorMessage = result.message || '登录失败';
        
        if (result.code === 400) {
          errorMessage = result.message || '请求参数错误，请重新登录';
        } else if (result.code === 401) {
          errorMessage = '授权失败，请重新登录';
        } else if (result.code === 403) {
          errorMessage = '账号已被禁用，请联系管理员';
        } else if (result.code === 500) {
          errorMessage = '服务器异常，请稍后重试';
        }
        
        this.showToast(errorMessage);
      }
    } catch (error) {
      console.error('[Login] 华为账号登录异常:', error);
      
      // 详细的错误处理
      let errorMsg = '登录失败，请稍后再试';
      
      if (error instanceof Error) {
        const errMsg = error.message.toLowerCase();
        
        // 网络相关错误
        if (errMsg.includes('network') || errMsg.includes('timeout') || errMsg.includes('连接')) {
          errorMsg = '网络连接失败，请检查网络后重试';
        }
        // HTTP错误
        else if (errMsg.includes('http 400')) {
          errorMsg = '请求参数错误，请重新登录';
        }
        else if (errMsg.includes('http 401')) {
          errorMsg = '授权失败，请重新登录';
        }
        else if (errMsg.includes('http 403')) {
          errorMsg = '账号已被禁用，请联系管理员';
        }
        else if (errMsg.includes('http 500')) {
          errorMsg = '服务器异常，请稍后重试';
        }
        // 授权码相关错误
        else if (errMsg.includes('授权码')) {
          errorMsg = '授权码获取失败，请重新登录';
        }
        // 解析错误
        else if (errMsg.includes('解析') || errMsg.includes('parse')) {
          errorMsg = '数据解析失败，请稍后重试';
        }
        // 其他错误，显示部分错误信息
        else {
          errorMsg = `登录失败: ${error.message.substring(0, 30)}`;
        }
      }
      
      this.showToast(errorMsg);
      
      // 记录详细错误日志供调试
      console.error('[Login] 错误详情:', JSON.stringify({
        message: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
        timestamp: new Date().toISOString()
      }));
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
      console.error('[Login] 跳转隐私政策页面失败:', error);
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
      console.error('[Login] 跳转用户协议页面失败:', error);
    }
  }

  /**
   * 处理华为账号登录错误
   */
  dealAllError(error: BusinessError): void {
    const errorCode = error.code;
    const errorMessage = error.message || '';

    console.error('[Login] 华为账号登录错误，错误码:', errorCode);
    console.error('[Login] 错误信息:', errorMessage);

    // 根据错误码提示用户
    if (errorCode === ErrorCode.ERROR_CODE_LOGIN_OUT) {
      this.showToast('用户未登录华为账号，请登录华为账号后重试');
    } else if (errorCode === ErrorCode.ERROR_CODE_NETWORK_ERROR) {
      this.showToast('网络异常，请检查网络状态后重试');
    } else if (errorCode === ErrorCode.ERROR_CODE_INTERNAL_ERROR) {
      this.showToast(`登录失败（${errorCode}），请稍后重试`);
    } else if (errorCode === ErrorCode.ERROR_CODE_USER_CANCEL) {
      this.showToast('用户取消授权');
    } else if (errorCode === ErrorCode.ERROR_CODE_SYSTEM_SERVICE) {
      this.showToast(`系统服务异常（${errorCode}），请稍后重试`);
    } else if (errorCode === ErrorCode.ERROR_CODE_REQUEST_REFUSE) {
      // 重复请求，无需处理
      console.log('[Login] 重复请求，忽略');
    } else if (errorCode === ErrorCode.ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED) {
      this.showToast('用户未同意协议');
    } else if (errorCode === ErrorCode.ERROR_CODE_SIGNATURE_FAILED || errorCode === 1001502003) {
      // 1001502003: 签名证书指纹校验失败
      this.showToast('应用签名验证失败，请检查签名配置');
      console.error('[Login] 签名证书指纹校验失败');
      console.error('[Login] 请确认：');
      console.error('[Login] 1. 华为开发者联盟配置的SHA256证书指纹与当前应用签名一致');
      console.error('[Login] 2. 应用包名与华为开发者联盟配置的包名一致');
      console.error('[Login] 3. Client ID配置正确');
    } else {
      this.showToast(`登录失败（错误码:${errorCode}）`);
      console.error('[Login] 未处理的错误码:', errorCode);
    }
  }

  /**
   * 处理注册
   */
  handleRegister() {
    try {
      router.pushUrl({ url: 'pages/Register' });
    } catch (error) {
      console.error('[Login] 跳转注册页面失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
  }

  /**
   * 处理忘记密码
   */
  handleForgotPassword() {
    try {
      router.pushUrl({
        url: 'pages/ForgotPassword'
      });
    } catch (error) {
      console.error('[Login] 跳转忘记密码页面失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
  }
}