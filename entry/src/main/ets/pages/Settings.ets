import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import { router, display } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { User } from '../model/UserModel';
import { UserStorage } from '../utils/UserStorage';
import { SettingsStorage, AppSettings } from '../utils/SettingsStorage';
import { DiaryStorage } from '../utils/DiaryStorage';
import preferences from '@ohos.data.preferences';

screenAdapter.designWidth = 375;

@Entry
@Component
export struct Settings {
  @State currentUser: User | null = null
  @State notificationEnabled: boolean = true
  @State autoSyncEnabled: boolean = true
  @State locationEnabled: boolean = true
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
    await this.loadSettings();
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
      case 'sm': return '90%';
      case 'md': return '70%';
      case 'lg': return '50%';
      default: return '90%';
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
        .onClick(() => {
          router.back();
        })

        Blank()

        Text('设置')
          .fontSize(this.getFontSize(16))
          .fontWeight(FontWeight.Bold)
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
        Column({ space: this.getSpacing() }) {
          // 通知设置
          Column() {
            Text('通知设置')
              .fontSize(this.getFontSize(13))
              .fontColor(ColorTheme.getColor('textMuted'))
              .width(this.getContentWidth())
              .margin({ bottom: 8 })

            Column() {
              this.buildToggleRow('消息通知', 'sys.symbol.bell', this.notificationEnabled, (value: boolean) => {
                this.notificationEnabled = value;
                this.saveSettings();
              })
              Divider().color(ColorTheme.getColor('divider')).margin({ left: 48 })
              this.buildToggleRow('自动同步', 'sys.symbol.arrow_clockwise', this.autoSyncEnabled, (value: boolean) => {
                this.autoSyncEnabled = value;
                this.saveSettings();
              })
            }
            .width(this.getContentWidth())
            .backgroundColor(ColorTheme.getColor('cardBackground'))
            .borderRadius(16)
          }

          // 账号设置
          Column() {
            Text('账号设置')
              .fontSize(this.getFontSize(13))
              .fontColor(ColorTheme.getColor('textMuted'))
              .width(this.getContentWidth())
              .margin({ bottom: 8 })

            Column() {
              if (this.currentUser && (!this.currentUser.email || this.currentUser.email.endsWith('@huawei.temp'))) {
                this.buildActionRow('绑定邮箱', 'sys.symbol.envelope', () => this.handleBindEmail())
                Divider().color(ColorTheme.getColor('divider')).margin({ left: 48 })
              }
              this.buildActionRow('修改密码', 'sys.symbol.lock', () => this.handleChangePassword())
            }
            .width(this.getContentWidth())
            .backgroundColor(ColorTheme.getColor('cardBackground'))
            .borderRadius(16)
          }

          // 隐私设置
          Column() {
            Text('隐私设置')
              .fontSize(this.getFontSize(13))
              .fontColor(ColorTheme.getColor('textMuted'))
              .width(this.getContentWidth())
              .margin({ bottom: 8 })

            Column() {
              this.buildToggleRow('位置服务', 'sys.symbol.local_fill', this.locationEnabled, (value: boolean) => {
                this.locationEnabled = value;
                this.saveSettings();
              })
              Divider().color(ColorTheme.getColor('divider')).margin({ left: 48 })
              this.buildActionRow('清除缓存', 'sys.symbol.trash', () => this.handleClearCache())
            }
            .width(this.getContentWidth())
            .backgroundColor(ColorTheme.getColor('cardBackground'))
            .borderRadius(16)
          }

          // 关于
          Column() {
            Text('关于')
              .fontSize(this.getFontSize(13))
              .fontColor(ColorTheme.getColor('textMuted'))
              .width(this.getContentWidth())
              .margin({ bottom: 8 })

            Column() {
              this.buildActionRow('关于我们', 'sys.symbol.info_circle', () => this.handleAbout())
              Divider().color(ColorTheme.getColor('divider')).margin({ left: 48 })
              this.buildActionRow('问题反馈', 'sys.symbol.forum_fill', () => this.handleFeedback())
              Divider().color(ColorTheme.getColor('divider')).margin({ left: 48 })
              this.buildActionRow('隐私政策', 'sys.symbol.person_shield_fill', () => this.handlePrivacyPolicy())
              Divider().color(ColorTheme.getColor('divider')).margin({ left: 48 })
              this.buildActionRow('用户协议', 'sys.symbol.doc_text', () => this.handleUserAgreement())
              Divider().color(ColorTheme.getColor('divider')).margin({ left: 48 })
              this.buildInfoRow('当前版本', 'sys.symbol.app_badge', 'v1.0')
            }
            .width(this.getContentWidth())
            .backgroundColor(ColorTheme.getColor('cardBackground'))
            .borderRadius(16)
          }

          Column().height(40)
        }
        .width('100%')
        .padding({ top: this.getSpacing() })
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

  @Builder
  buildActionRow(label: string, icon: string, onClick: () => void, color?: string) {
    Row() {
      SymbolGlyph($r(icon))
        .fontSize(this.getFontSize(20))
        .fontColor([color || ColorTheme.getColor('textPrimary')])
        .margin({ left: 16, right: 12 })

      Text(label)
        .fontSize(this.getFontSize(14))
        .fontColor(color || ColorTheme.getColor('textPrimary'))
        .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(this.getFontSize(16))
        .fontColor([ColorTheme.getColor('textMuted')])
        .margin({ right: 16 })
    }
    .width('100%')
    .height(this.currentBreakpoint === 'xs' ? 44 : 48)
    .onClick(onClick)
  }

  @Builder
  buildToggleRow(label: string, icon: string, value: boolean, onChange: (value: boolean) => void) {
    Row() {
      SymbolGlyph($r(icon))
        .fontSize(this.getFontSize(20))
        .fontColor([ColorTheme.getColor('textPrimary')])
        .margin({ left: 16, right: 12 })

      Text(label)
        .fontSize(this.getFontSize(14))
        .fontColor(ColorTheme.getColor('textPrimary'))
        .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor(ColorTheme.getColor('buttonPrimaryBg'))
        .margin({ right: 16 })
        .onChange((isOn: boolean) => {
          onChange(isOn);
        })
    }
    .width('100%')
    .height(this.currentBreakpoint === 'xs' ? 44 : 48)
  }

  @Builder
  buildInfoRow(label: string, icon: string, value: string) {
    Row() {
      SymbolGlyph($r(icon))
        .fontSize(this.getFontSize(20))
        .fontColor([ColorTheme.getColor('textPrimary')])
        .margin({ left: 16, right: 12 })

      Text(label)
        .fontSize(this.getFontSize(14))
        .fontColor(ColorTheme.getColor('textPrimary'))
        .layoutWeight(1)

      Text(value)
        .fontSize(this.getFontSize(14))
        .fontColor(ColorTheme.getColor('textMuted'))
        .margin({ right: 16 })
    }
    .width('100%')
    .height(this.currentBreakpoint === 'xs' ? 44 : 48)
  }

  /**
   * 加载用户信息
   */
  async loadUserInfo(): Promise<void> {
    try {
      const user = await UserStorage.getUser();
      if (user) {
        this.currentUser = user;
      }
    } catch (error) {
      console.error('[Settings] 加载用户信息失败:', error);
    }
  }

  /**
   * 加载设置
   */
  async loadSettings(): Promise<void> {
    try {
      const settings = await SettingsStorage.getSettings();
      this.notificationEnabled = settings.notificationEnabled;
      this.autoSyncEnabled = settings.autoSyncEnabled;
      this.locationEnabled = settings.locationEnabled;
      console.log('[Settings] 设置加载成功:', settings);
    } catch (error) {
      console.error('[Settings] 加载设置失败:', error);
    }
  }

  /**
   * 保存设置
   */
  async saveSettings(): Promise<void> {
    try {
      const settings: AppSettings = {
        notificationEnabled: this.notificationEnabled,
        autoSyncEnabled: this.autoSyncEnabled,
        locationEnabled: this.locationEnabled
      };
      await SettingsStorage.saveSettings(settings);
      console.log('[Settings] 设置保存成功:', settings);
      this.showToast('设置已保存');
    } catch (error) {
      console.error('[Settings] 保存设置失败:', error);
      this.showToast('保存设置失败');
    }
  }

  /**
   * 清除缓存
   */
  async handleClearCache(): Promise<void> {
    try {
      const result = await promptAction.showDialog({
        title: '清除缓存',
        message: '将清除应用缓存数据，但不会删除您的日记和账号信息。确定要继续吗？',
        buttons: [
          { text: '取消', color: '#999999' } as promptAction.Button,
          { text: '确定', color: ColorTheme.getColor('buttonPrimaryBg') } as promptAction.Button
        ]
      } as promptAction.ShowDialogOptions);

      if (result.index === 1) {
        // 清除应用缓存（不包括用户数据和日记数据）
        try {
          const context = getContext();
          // 清除所有preferences缓存（除了用户和日记数据）
          const cachePrefsName = 'app_cache';
          const cachePrefs = await preferences.getPreferences(context, cachePrefsName);
          await cachePrefs.clear();
          await cachePrefs.flush();
          
          console.log('[Settings] 缓存清除成功');
          this.showToast('缓存已清除');
        } catch (error) {
          console.error('[Settings] 清除缓存失败:', error);
          this.showToast('清除缓存失败');
        }
      }
    } catch (error) {
      console.error('[Settings] 清除缓存对话框失败:', error);
    }
  }

  /**
   * 关于我们
   */
  handleAbout(): void {
    try {
      promptAction.showDialog({
        title: '关于迹记',
        message: '迹记（GeoNote）是一款基于地理位置的日记应用\n\n版本：v1.0\n\n© 2025 迹记团队',
        buttons: [
          { text: '确定', color: ColorTheme.getColor('buttonPrimaryBg') } as promptAction.Button
        ]
      } as promptAction.ShowDialogOptions);
    } catch (error) {
      console.error('[Settings] 显示关于对话框失败:', error);
    }
  }

  /**
   * 问题反馈
   */
  handleFeedback(): void {
    try {
      router.pushUrl({
        url: 'pages/Feedback'
      } as router.RouterOptions);
    } catch (error) {
      console.error('[Settings] 跳转反馈页面失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
  }

  /**
   * 隐私政策
   */
  handlePrivacyPolicy(): void {
    try {
      router.pushUrl({
        url: 'pages/PrivacyPolicy'
      } as router.RouterOptions);
    } catch (error) {
      console.error('[Settings] 跳转隐私政策页面失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
  }

  /**
   * 用户协议
   */
  handleUserAgreement(): void {
    try {
      router.pushUrl({
        url: 'pages/UserAgreement'
      } as router.RouterOptions);
    } catch (error) {
      console.error('[Settings] 跳转用户协议页面失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
  }

  /**
   * 绑定邮箱
   */
  handleBindEmail(): void {
    try {
      if (!this.currentUser) {
        this.showToast('请先登录');
        return;
      }
      
      router.pushUrl({
        url: 'pages/BindEmail',
        params: {
          userId: this.currentUser.id,
          username: this.currentUser.username,
          fromHuaweiLogin: false
        }
      } as router.RouterOptions);
    } catch (error) {
      console.error('[Settings] 跳转绑定邮箱页面失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
  }

  /**
   * 修改密码
   */
  handleChangePassword(): void {
    try {
      if (!this.currentUser) {
        this.showToast('请先登录');
        return;
      }
      
      router.pushUrl({
        url: 'pages/ChangePassword'
      } as router.RouterOptions);
    } catch (error) {
      console.error('[Settings] 跳转修改密码页面失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
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
    } catch (error) {
      console.error('[Settings] 显示Toast失败:', error);
    }
  }
}
