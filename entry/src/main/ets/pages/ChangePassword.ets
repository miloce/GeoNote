import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import { router, display } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { HttpUtils } from '../utils/HttpUtils';
import { User, ApiResponse } from '../model/UserModel';
import { UserStorage } from '../utils/UserStorage';

screenAdapter.designWidth = 375;

// 修改密码请求接口
interface ChangePasswordRequest {
  action: string;
  user_id: number;
  old_password?: string;
  new_password: string;
}

// 获取用户信息请求接口
interface GetUserInfoRequest {
  action: string;
  user_id: number;
}

@Entry
@Component
export struct ChangePassword {
  @State currentUser: User | null = null
  @State hasPassword: boolean = true
  @State oldPassword: string = ''
  @State newPassword: string = ''
  @State confirmPassword: string = ''
  @State isLoading: boolean = false
  @State oldPasswordError: string = ''
  @State newPasswordError: string = ''
  @State confirmPasswordError: string = ''
  // 响应式布局
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint();
  @State isLandscape: boolean = isCurrentLandscape();
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  async aboutToAppear() {
    this.breakpointSystem.register((bp: BreakpointType) => {
      this.currentBreakpoint = bp;
      this.isLandscape = isCurrentLandscape();
    });
    display.on('change', () => {
      screenAdapter.updateScreenSize();
      this.currentBreakpoint = getCurrentBreakpoint();
      this.isLandscape = isCurrentLandscape();
    });
    await this.loadUserInfo();
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
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(this.getFontSize(24))
          .fontColor([ColorTheme.getColor('textPrimary')])
          .onClick(() => router.back())

        Blank()

        Text(this.hasPassword ? '修改密码' : '设置密码')
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorTheme.getColor('textPrimary'))

        Blank()

        Stack()
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(this.getNavBarHeight())
      .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 44 })
      .backgroundColor(ColorTheme.getColor('cardBackground'))

      Scroll() {
        Column() {
          // 提示信息
          if (!this.hasPassword) {
            Row({ space: 8 }) {
              SymbolGlyph($r('sys.symbol.exclamationmark_triangle_fill'))
                .fontSize(this.getFontSize(16))
                .fontColor([ColorTheme.getColor('textMuted')])
              Text('您尚未设置密码，设置后可使用密码登录')
                .fontSize(this.getFontSize(12))
                .fontColor(ColorTheme.getColor('textMuted'))
            }
            .width(this.getContentWidth())
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor(ColorTheme.getColor('pageBackground'))
            .borderRadius(12)
            .margin({ top: this.getSpacing(), bottom: this.getSpacing() })
          }

          // 表单区域
          Column({ space: 20 }) {
            // 旧密码（仅在有密码时显示）
            if (this.hasPassword) {
              Column({ space: 8 }) {
                Text('当前密码')
                  .fontSize(this.getFontSize(14))
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorTheme.getColor('textPrimary'))
                  .width('100%')

                TextInput({ placeholder: '请输入当前密码', text: $$this.oldPassword })
                  .type(InputType.Password)
                  .width('100%')
                  .height(this.currentBreakpoint === 'xs' ? 44 : 48)
                  .backgroundColor(ColorTheme.getColor('pageBackground'))
                  .borderRadius(12)
                  .border({
                    width: this.oldPasswordError ? 2 : 0,
                    color: this.oldPasswordError ? '#E53E3E' : 'transparent'
                  })
                  .placeholderColor(ColorTheme.getColor('textMuted'))
                  .onChange((value: string) => {
                    this.oldPassword = value;
                    if (value) {
                      this.oldPasswordError = '';
                    }
                  })

                if (this.oldPasswordError) {
                  Text(this.oldPasswordError)
                    .fontSize(this.getFontSize(12))
                    .fontColor('#E53E3E')
                    .padding({ left: 12 })
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }

            // 新密码
            Column({ space: 8 }) {
              Text('新密码')
                .fontSize(this.getFontSize(14))
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorTheme.getColor('textPrimary'))
                .width('100%')

              TextInput({
                placeholder: this.hasPassword ? '请输入新密码（至少6位）' : '请设置密码（至少6位）',
                text: $$this.newPassword
              })
                .type(InputType.Password)
                .width('100%')
                .height(this.currentBreakpoint === 'xs' ? 44 : 48)
                .backgroundColor(ColorTheme.getColor('pageBackground'))
                .borderRadius(12)
                .border({
                  width: this.newPasswordError ? 2 : 0,
                  color: this.newPasswordError ? '#E53E3E' : 'transparent'
                })
                .placeholderColor(ColorTheme.getColor('textMuted'))
                .onChange((value: string) => {
                  this.newPassword = value;
                  if (value && value.length >= 6) {
                    this.newPasswordError = '';
                  } else if (value) {
                    this.newPasswordError = '密码长度至少6位';
                  }
                })

              if (this.newPasswordError) {
                Text(this.newPasswordError)
                  .fontSize(this.getFontSize(12))
                  .fontColor('#E53E3E')
                  .padding({ left: 12 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 确认新密码
            Column({ space: 8 }) {
              Text('确认新密码')
                .fontSize(this.getFontSize(14))
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorTheme.getColor('textPrimary'))
                .width('100%')

              TextInput({ placeholder: '请再次输入新密码', text: $$this.confirmPassword })
                .type(InputType.Password)
                .width('100%')
                .height(this.currentBreakpoint === 'xs' ? 44 : 48)
                .backgroundColor(ColorTheme.getColor('pageBackground'))
                .borderRadius(12)
                .border({
                  width: this.confirmPasswordError ? 2 : 0,
                  color: this.confirmPasswordError ? '#E53E3E' : 'transparent'
                })
                .placeholderColor(ColorTheme.getColor('textMuted'))
                .onChange((value: string) => {
                  this.confirmPassword = value;
                  if (value && value === this.newPassword) {
                    this.confirmPasswordError = '';
                  } else if (value) {
                    this.confirmPasswordError = '两次输入的密码不一致';
                  }
                })

              if (this.confirmPasswordError) {
                Text(this.confirmPasswordError)
                  .fontSize(this.getFontSize(12))
                  .fontColor('#E53E3E')
                  .padding({ left: 12 })
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .width(this.getContentWidth())
          .margin({ top: this.getSpacing() })

          // 提交按钮
          Button() {
            if (this.isLoading) {
              LoadingProgress()
                .width(24)
                .height(24)
                .color(ColorTheme.getColor('buttonPrimaryText'))
            } else {
              Text(this.hasPassword ? '确认修改' : '确认设置')
                .fontSize(this.getFontSize(16))
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorTheme.getColor('buttonPrimaryText'))
            }
          }
          .width(this.getContentWidth())
          .height(this.currentBreakpoint === 'xs' ? 46 : 50)
          .backgroundColor(this.isLoading ? ColorTheme.getColor('divider') : ColorTheme.getColor('buttonPrimaryBg'))
          .borderRadius(25)
          .margin({ top: 40, bottom: 40 })
          .enabled(!this.isLoading)
          .onClick(() => this.handleChangePassword())
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(ColorTheme.getColor('pageBackground'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTheme.getColor('pageBackground'))
  }

  /**
   * 加载用户信息
   */
  async loadUserInfo() {
    try {
      const user = await UserStorage.getUser();
      if (user && user.id > 0) {
        this.currentUser = user;

        // 从服务器获取用户信息，检查是否有密码
        try {
          const postData: GetUserInfoRequest = {
            action: 'get_user_info',
            user_id: user.id
          };

          const response = await HttpUtils.httpRequestPost('', postData);
          const result = JSON.parse(response) as ApiResponse<User>;

          if (result.success && result.data) {
            this.hasPassword = result.data.has_password !== false;
            console.log('[ChangePassword] 用户是否有密码:', this.hasPassword);
          }
        } catch (e) {
          console.error('[ChangePassword] 获取用户信息失败:', e);
          this.hasPassword = true;
        }
      } else {
        router.back();
      }
    } catch (e) {
      console.error('[ChangePassword] 加载用户信息失败:', e);
      router.back();
    }
  }

  /**
   * 修改密码
   */
  async handleChangePassword() {
    // 验证输入
    if (this.hasPassword && !this.oldPassword) {
      this.oldPasswordError = '请输入当前密码';
      this.showToast('请输入当前密码');
      return;
    }

    if (!this.newPassword || !this.confirmPassword) {
      this.showToast('请填写完整信息');
      return;
    }

    if (this.newPassword !== this.confirmPassword) {
      this.confirmPasswordError = '两次输入的密码不一致';
      this.showToast('两次输入的密码不一致');
      return;
    }

    if (this.newPassword.length < 6) {
      this.newPasswordError = '密码长度至少6位';
      this.showToast('密码长度至少6位');
      return;
    }

    if (!this.currentUser || !this.currentUser.id) {
      this.showToast('用户信息不存在');
      return;
    }

    this.isLoading = true;

    try {
      const postData: ChangePasswordRequest = {
        action: 'change_password',
        user_id: this.currentUser.id,
        new_password: this.newPassword
      };

      // 如果有密码，才传递old_password
      if (this.hasPassword) {
        postData.old_password = this.oldPassword;
      }

      const response = await HttpUtils.httpRequestPost('', postData);
      const result = JSON.parse(response) as ApiResponse<User>;

      if (result.success && result.code === 200) {
        // 更新本地用户信息
        if (result.data) {
          await UserStorage.saveUser(result.data);
        }

        this.showToast(result.message || (this.hasPassword ? '密码修改成功' : '密码设置成功'));

        // 延迟后返回
        setTimeout(() => {
          router.back();
        }, 1000);
      } else {
        this.showToast(result.message || (this.hasPassword ? '密码修改失败' : '密码设置失败'));
      }
    } catch (e) {
      console.error('[ChangePassword] 修改密码失败:', e);
      this.showToast((this.hasPassword ? '修改密码失败' : '设置密码失败') + '，请稍后再试');
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 显示Toast
   */
  showToast(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    } catch (e) {
      console.error('[ChangePassword] 显示提示失败', e);
    }
  }
}
