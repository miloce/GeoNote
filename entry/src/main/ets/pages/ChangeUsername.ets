import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import { router, display } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { HttpUtils } from '../utils/HttpUtils';
import { User, ApiResponse } from '../model/UserModel';
import { UserStorage } from '../utils/UserStorage';

screenAdapter.designWidth = 375;

// 修改用户名请求接口
interface ChangeUsernameRequest {
  action: string;
  user_id: number;
  new_username: string;
}

// 获取用户信息请求接口
interface GetUserInfoRequest {
  action: string;
  user_id: number;
}

@Entry
@Component
export struct ChangeUsername {
  @State currentUser: User | null = null
  @State newUsername: string = ''
  @State isLoading: boolean = false
  @State canModify: boolean = true
  @State usernameError: string = ''
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

        Text('修改用户名')
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
          if (!this.canModify) {
            Row({ space: 8 }) {
              SymbolGlyph($r('sys.symbol.exclamationmark_triangle_fill'))
                .fontSize(this.getFontSize(16))
                .fontColor(['#E53E3E'])
              Text('您已修改过用户名，无法再次修改')
                .fontSize(this.getFontSize(12))
                .fontColor('#E53E3E')
            }
            .width(this.getContentWidth())
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor('#FFF0E6')
            .borderRadius(12)
            .margin({ top: this.getSpacing(), bottom: this.getSpacing() })
          } else {
            Row({ space: 8 }) {
              SymbolGlyph($r('sys.symbol.exclamationmark_triangle_fill'))
                .fontSize(this.getFontSize(16))
                .fontColor([ColorTheme.getColor('textMuted')])
              Text('用户名只能修改一次，请谨慎操作')
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
            // 当前用户名
            Column({ space: 8 }) {
              Text('当前用户名')
                .fontSize(this.getFontSize(14))
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorTheme.getColor('textPrimary'))
                .width('100%')

              Text(this.currentUser?.username || '')
                .fontSize(this.getFontSize(16))
                .fontColor(ColorTheme.getColor('textPrimary'))
                .width('100%')
                .padding({ left: 12, right: 12, top: 14, bottom: 14 })
                .backgroundColor(ColorTheme.getColor('pageBackground'))
                .borderRadius(12)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 新用户名
            Column({ space: 8 }) {
              Text('新用户名')
                .fontSize(this.getFontSize(14))
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorTheme.getColor('textPrimary'))
                .width('100%')

              TextInput({ placeholder: '请输入新用户名（3-20个字符）', text: $$this.newUsername })
                .type(InputType.Normal)
                .width('100%')
                .height(this.currentBreakpoint === 'xs' ? 44 : 48)
                .backgroundColor(ColorTheme.getColor('pageBackground'))
                .borderRadius(12)
                .border({
                  width: this.usernameError ? 2 : 0,
                  color: this.usernameError ? '#E53E3E' : 'transparent'
                })
                .placeholderColor(ColorTheme.getColor('textMuted'))
                .enabled(this.canModify && !this.isLoading)
                .onChange((value: string) => {
                  this.newUsername = value.trim();
                  if (value) {
                    if (value.length < 3 || value.length > 20) {
                      this.usernameError = '用户名长度需在3-20个字符之间';
                    } else if (!/^[a-zA-Z0-9_]+$/.test(value)) {
                      this.usernameError = '用户名只能包含字母、数字和下划线';
                    } else {
                      this.usernameError = '';
                    }
                  } else {
                    this.usernameError = '';
                  }
                })

              if (this.usernameError) {
                Text(this.usernameError)
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
              Text('确认修改')
                .fontSize(this.getFontSize(16))
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorTheme.getColor('buttonPrimaryText'))
            }
          }
          .width(this.getContentWidth())
          .height(this.currentBreakpoint === 'xs' ? 46 : 50)
          .backgroundColor(
            this.isLoading || !this.canModify || this.usernameError ?
            ColorTheme.getColor('divider') :
            ColorTheme.getColor('buttonPrimaryBg')
          )
          .borderRadius(25)
          .margin({ top: 40, bottom: 40 })
          .enabled(!this.isLoading && this.canModify && !this.usernameError)
          .onClick(() => this.handleChangeUsername())
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

        // 检查是否可以修改用户名
        try {
          const postData: GetUserInfoRequest = {
            action: 'get_user_info',
            user_id: user.id
          };

          const response = await HttpUtils.httpRequestPost('', postData);
          const result = JSON.parse(response) as ApiResponse<User>;

          if (result.success && result.data) {
            const usernameModified = result.data.username_modified;
            this.canModify = usernameModified !== true;
            console.log('[ChangeUsername] 用户是否可以修改用户名:', this.canModify);
          }
        } catch (e) {
          console.error('[ChangeUsername] 获取用户信息失败:', e);
          this.canModify = true;
        }
      } else {
        router.back();
      }
    } catch (e) {
      console.error('[ChangeUsername] 加载用户信息失败:', e);
      router.back();
    }
  }

  /**
   * 修改用户名
   */
  async handleChangeUsername() {
    if (!this.newUsername) {
      this.usernameError = '请输入新用户名';
      this.showToast('请输入新用户名');
      return;
    }

    if (this.newUsername.length < 3 || this.newUsername.length > 20) {
      this.usernameError = '用户名长度需在3-20个字符之间';
      this.showToast('用户名长度需在3-20个字符之间');
      return;
    }

    // 检查用户名格式
    const usernamePattern = /^[a-zA-Z0-9_]+$/;
    if (!usernamePattern.test(this.newUsername)) {
      this.usernameError = '用户名只能包含字母、数字和下划线';
      this.showToast('用户名只能包含字母、数字和下划线');
      return;
    }

    if (!this.currentUser || !this.currentUser.id) {
      this.showToast('用户信息不存在');
      return;
    }

    if (this.newUsername === this.currentUser.username) {
      this.usernameError = '新用户名与当前用户名相同';
      this.showToast('新用户名与当前用户名相同');
      return;
    }

    this.isLoading = true;

    try {
      const postData: ChangeUsernameRequest = {
        action: 'change_username',
        user_id: this.currentUser.id,
        new_username: this.newUsername
      };

      const response = await HttpUtils.httpRequestPost('', postData);
      const result = JSON.parse(response) as ApiResponse<User>;

      if (result.success && result.code === 200) {
        // 更新本地用户信息
        if (result.data) {
          await UserStorage.saveUser(result.data);
          this.currentUser = result.data;
        }

        this.showToast(result.message || '用户名修改成功');

        // 延迟后返回
        setTimeout(() => {
          router.back();
        }, 1000);
      } else {
        this.showToast(result.message || '用户名修改失败');
      }
    } catch (e) {
      console.error('[ChangeUsername] 修改用户名失败:', e);
      this.showToast('修改用户名失败，请稍后再试');
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
      console.error('[ChangeUsername] 显示提示失败', e);
    }
  }
}
