import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import { router, display } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { HttpUtils } from '../utils/HttpUtils';
import { User, ApiResponse } from '../model/UserModel';
import { UserStorage } from '../utils/UserStorage';
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import buffer from '@ohos.buffer';
import { Diary } from '../model/DiaryModel';
import { DiaryStorage } from '../utils/DiaryStorage';

screenAdapter.designWidth = 375;

// 绑定华为账号请求接口
interface BindHuaweiAccountRequest {
  action: string;
  user_id: number;
  authorization_code: string;
}

// 解绑华为账号请求接口
interface UnbindHuaweiAccountRequest {
  action: string;
  user_id: number;
}

// 获取用户信息请求接口
interface GetUserInfoRequest {
  action: string;
  user_id: number;
}

// 日历日期数据
interface CalendarDay {
  day: number;
  isCurrentMonth: boolean;
  hasDiary: boolean;
  dateKey: string;
}

// 日记导出数据结构
interface DiaryExportData {
  export_time: string;
  app_version: string;
  total_count: number;
  diaries: Diary[];
}

@Entry
@Component
export struct Profile {
  @State currentUser: User | null = null
  @State isLoading: boolean = true
  @State currentTab: 'diary' | 'info' = 'info'
  @State diaries: Diary[] = []
  @State diaryDates: Set<string> = new Set()
  @State currentYear: number = new Date().getFullYear()
  @State currentMonth: number = new Date().getMonth() + 1
  @State totalDiaryCount: number = 0
  private scroller: Scroller = new Scroller()
  // 响应式布局
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint();
  @State isLandscape: boolean = isCurrentLandscape();
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();
  
  // 华为账号登录按钮控制器
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          this.showToast('华为账号授权失败，请重试');
          console.error('[Profile] 华为账号授权失败:', error);
          return;
        }

        if (response && response.authorizationCode) {
          this.bindHuaweiAccount(response.authorizationCode);
        } else {
          this.showToast('获取授权码失败');
        }
      })

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
    await this.loadDiaries();
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
        .onClick(() => router.back())

        Blank()

        Text('个人中心')
          .fontSize(this.getFontSize(16))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))

        Blank()

        Stack() {
          SymbolGlyph($r('sys.symbol.text_alignright'))
            .fontSize(this.getFontSize(24))
            .fontColor([ColorTheme.getColor('textPrimary')])
        }
        .width(24)
        .height(24)
        .onClick(() => this.handleSettings())
      }
      .width('100%')
      .height(this.getNavBarHeight())
      .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 44 })
      .backgroundColor(ColorTheme.getColor('cardBackground'))

      Scroll(this.scroller) {
        Column() {
          if (this.isLoading) {
            this.buildLoadingState()
          } else if (this.currentUser) {
            this.buildUserProfile()
            this.buildTabToggle()
            
            if (this.currentTab === 'diary') {
              this.buildDiaryTabContent()
            } else {
              this.buildInfoTabContent()
            }
          } else {
            this.buildNotLoginState()
          }
        }
        .width('100%')
        .padding({ bottom: 40 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor(ColorTheme.getColor('cardBackground'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTheme.getColor('cardBackground'))
  }

  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(this.getFontSize(48))
        .height(this.getFontSize(48))
        .color(ColorTheme.getColor('buttonPrimaryBg'))
      Text('加载中...')
        .fontSize(this.getFontSize(14))
        .fontColor(ColorTheme.getColor('textMuted'))
        .margin({ top: 12 })
    }
    .width('100%')
    .height(300)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildNotLoginState() {
    Column() {
      SymbolGlyph($r('sys.symbol.person'))
        .fontSize(this.getFontSize(80))
        .fontColor([ColorTheme.getColor('divider')])
        .margin({ top: 60, bottom: 20 })

      Text('欢迎来到 GeoNote')
        .fontSize(this.getFontSize(22))
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorTheme.getColor('textPrimary'))
        .margin({ bottom: 8 })

      Text('登录以同步您的云端数据')
        .fontSize(this.getFontSize(14))
        .fontColor(ColorTheme.getColor('textMuted'))
        .margin({ bottom: 40 })

      Button('立即登录')
        .width(200)
        .height(44)
        .backgroundColor(ColorTheme.getColor('buttonPrimaryBg'))
        .fontColor(Color.White)
        .fontSize(this.getFontSize(16))
        .borderRadius(22)
        .onClick(() => router.replaceUrl({ url: 'pages/Login' }))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildUserProfile() {
    Column() {
      Stack() {
        if (this.currentUser?.avatar) {
          Image(this.currentUser.avatar)
            .width('100%')
            .height('100%')
            .borderRadius(40)
            .objectFit(ImageFit.Cover)
        } else {
          Image($r('app.media.appico'))
            .width('100%')
            .height('100%')
            .borderRadius(40)
            .objectFit(ImageFit.Cover)
            .backgroundColor(ColorTheme.getColor('cardBackground'))
        }
      }
      .width(this.currentBreakpoint === 'lg' ? 100 : 80)
      .height(this.currentBreakpoint === 'lg' ? 100 : 80)
      .margin({ top: 18, bottom: 16 })

      Text(this.currentUser?.username || 'GeoNote User')
        .fontSize(this.getFontSize(20))
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorTheme.getColor('textPrimary'))
        .margin({ bottom: 8 })

      Text(this.currentUser?.email || (this.currentUser?.id ? `UID: ${this.currentUser.id}` : '点击登录'))
        .fontSize(this.getFontSize(12))
        .fontColor(ColorTheme.getColor('textMuted'))
        .margin({ bottom: 24 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildTabToggle() {
    Stack() {
      Row() {
        Stack() {
          Text('日记')
            .fontSize(this.getFontSize(14))
            .fontWeight(this.currentTab === 'diary' ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.currentTab === 'diary' ? ColorTheme.getColor('buttonPrimaryText') : ColorTheme.getColor('textPrimary'))
        }
        .height('100%')
        .layoutWeight(1)
        .backgroundColor(this.currentTab === 'diary' ? ColorTheme.getColor('buttonPrimaryBg') : Color.Transparent)
        .borderRadius(12)
        .onClick(() => this.currentTab = 'diary')

        Stack() {
          Text('信息')
            .fontSize(this.getFontSize(14))
            .fontWeight(this.currentTab === 'info' ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.currentTab === 'info' ? ColorTheme.getColor('buttonPrimaryText') : ColorTheme.getColor('textPrimary'))
        }
        .height('100%')
        .layoutWeight(1)
        .backgroundColor(this.currentTab === 'info' ? ColorTheme.getColor('buttonPrimaryBg') : Color.Transparent)
        .borderRadius(12)
        .onClick(() => this.currentTab = 'info')
      }
      .width(this.getContentWidth())
      .height(this.currentBreakpoint === 'xs' ? 52 : 60)
      .padding(8)
      .backgroundColor(ColorTheme.getColor('pageBackground'))
      .borderRadius(12)
    }
    .width('100%')
    .margin({ bottom: 30 })
  }

  @Builder
  buildDiaryTabContent() {
    Column() {
      // 统计数据
      Row() {
        this.buildStatItem('日记', this.totalDiaryCount.toString(), 'sys.symbol.book')
        Divider().vertical(true).height(20).color(ColorTheme.getColor('divider'))
        this.buildStatItem('天数', this.calculateDays(), 'sys.symbol.calendar')
        Divider().vertical(true).height(20).color(ColorTheme.getColor('divider'))
        this.buildStatItem('足迹', this.diaryDates.size.toString(), 'sys.symbol.location')
      }
      .width(this.getContentWidth())
      .height(this.currentBreakpoint === 'xs' ? 70 : 80)
      .backgroundColor(ColorTheme.getColor('cardBackground'))
      .borderRadius(16)
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ bottom: 20 })

      // 月份导航
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(this.getFontSize(20))
          .fontColor([ColorTheme.getColor('textPrimary')])
          .onClick(() => this.previousMonth())

        Text(`${this.currentYear}年${this.currentMonth}月`)
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(this.getFontSize(20))
          .fontColor([ColorTheme.getColor('textPrimary')])
          .onClick(() => this.nextMonth())
      }
      .width(this.getContentWidth())
      .height(44)
      .margin({ bottom: 16 })

      this.buildCalendar()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildInfoTabContent() {
    Column() {
      // 快捷功能
      Grid() {
        GridItem() {
          this.buildGridItem('设置', 'sys.symbol.gearshape', '#8b5cf6', () => this.handleSettings())
        }
        GridItem() {
          this.buildGridItem('导出日记', 'sys.symbol.arrow_down_and_rectangle_on_rectangle', '#10b981', () => this.handleExportDiaries())
        }
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(10)
      .width(this.getContentWidth())
      .height(this.currentBreakpoint === 'xs' ? 80 : 90)
      .margin({ bottom: 16 })

      // 账号管理
      Column() {
        this.buildActionRow('修改用户名', 'sys.symbol.square_and_pencil', () => this.handleChangeUsername())
        Divider().color(ColorTheme.getColor('divider')).margin({ left: 48 })
        this.buildActionRow('修改密码', 'sys.symbol.lock', () => this.handleChangePassword())
        
        if (!this.currentUser?.email || this.currentUser.email.endsWith('@huawei.temp')) {
          Divider().color(ColorTheme.getColor('divider')).margin({ left: 48 })
          this.buildActionRow('绑定邮箱', 'sys.symbol.envelope', () => this.handleBindEmail())
        }
        
        Divider().color(ColorTheme.getColor('divider')).margin({ left: 48 })
        if (!this.currentUser?.huawei_union_id) {
          this.buildHuaweiBindRow()
        } else {
          this.buildActionRow('解绑华为账号', 'sys.symbol.link', () => this.handleUnbindHuawei(), '#f59e0b')
        }
      }
      .width(this.getContentWidth())
      .backgroundColor(ColorTheme.getColor('cardBackground'))
      .borderRadius(16)
      .margin({ bottom: 16 })

      // 危险操作
      Column() {
        this.buildActionRow('退出登录', 'sys.symbol.arrow_right', () => this.handleLogout(), '#ef4444')
        Divider().color(ColorTheme.getColor('divider')).margin({ left: 48 })
        this.buildActionRow('注销账号', 'sys.symbol.trash', () => this.handleDeleteAccount(), '#dc2626')
      }
      .width(this.getContentWidth())
      .backgroundColor(ColorTheme.getColor('cardBackground'))
      .borderRadius(16)
      .margin({ bottom: 40 })

      Text('GeoNote v1.0')
        .fontSize(this.getFontSize(11))
        .fontColor(ColorTheme.getColor('textMuted'))
        .margin({ bottom: 20 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildStatItem(label: string, value: string, icon: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(this.getFontSize(20))
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorTheme.getColor('textPrimary'))

      Text(label)
        .fontSize(this.getFontSize(12))
        .fontColor(ColorTheme.getColor('textMuted'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildGridItem(label: string, icon: string, color: string, onClick: () => void) {
    Column({ space: 8 }) {
      Column() {
        SymbolGlyph($r(icon))
          .fontSize(this.getFontSize(26))
          .fontColor([color])
      }
      .width(this.currentBreakpoint === 'xs' ? 44 : 48)
      .height(this.currentBreakpoint === 'xs' ? 44 : 48)
      .borderRadius(24)
      .backgroundColor(this.getBackgroundColor(color))
      .justifyContent(FlexAlign.Center)

      Text(label)
        .fontSize(this.getFontSize(12))
        .fontColor(ColorTheme.getColor('textMuted'))
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(onClick)
  }

  // 根据主题色生成浅色背景
  getBackgroundColor(color: string): string {
    const colorMap: Record<string, string> = {
      '#f59e0b': '#FFF0E6', // 橙色 -> 浅橙色
      '#3b82f6': '#E3F2FD', // 蓝色 -> 浅蓝色
      '#8b5cf6': '#F3E5F5', // 紫色 -> 浅紫色
      '#10b981': '#E8F5E9'  // 绿色 -> 浅绿色
    };
    return colorMap[color] || '#F5F5F5';
  }

  @Builder
  buildTag(text: string, textColor: string, bgColor: string) {
    Text(text)
      .fontSize(toPx(10))
      .fontColor(textColor)
      .padding({
        left: 10,
        right: 10,
        top: 3,
        bottom: 3
      })
      .backgroundColor(bgColor)
      .borderRadius(10)
      .fontWeight(FontWeight.Medium)
  }

  @Builder
  buildInfoRow(label: string, value: string, isCopyable: boolean = false) {
    Row() {
      Row() {
        SymbolGlyph($r('sys.symbol.info_circle'))
          .fontSize(this.getFontSize(20))
          .fontColor([ColorTheme.getColor('textMuted')])
      }
      .width(36)
      .justifyContent(FlexAlign.Center)

      Text(label)
        .fontSize(this.getFontSize(15))
        .fontColor(ColorTheme.getColor('textPrimary'))
        .layoutWeight(1)

      Text(value)
        .fontSize(this.getFontSize(14))
        .fontColor(ColorTheme.getColor('textMuted'))
    }
    .width('100%')
    .height(this.currentBreakpoint === 'xs' ? 46 : 50)
    .padding({ left: 12, right: 16 })
    .backgroundColor(ColorTheme.getColor('cardBackground'))
    .onClick(() => {
      if (isCopyable) {
        this.showToast('已复制 ID');
      }
    })
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

      SymbolGlyph($r('sys.symbol.arrow_right'))
        .fontSize(this.getFontSize(14))
        .fontColor([ColorTheme.getColor('textMuted')])
        .margin({ right: 16 })
    }
    .width('100%')
    .height(this.currentBreakpoint === 'xs' ? 44 : 48)
    .onClick(onClick)
  }

  @Builder
  buildHuaweiBindRow() {
    Stack() {
      Row() {
        SymbolGlyph($r('sys.symbol.link'))
          .fontSize(this.getFontSize(20))
          .fontColor([ColorTheme.getColor('textPrimary')])
          .margin({ left: 16, right: 12 })

        Text('绑定华为账号')
          .fontSize(this.getFontSize(14))
          .fontColor(ColorTheme.getColor('textPrimary'))
          .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.arrow_right'))
          .fontSize(this.getFontSize(14))
          .fontColor([ColorTheme.getColor('textMuted')])
          .margin({ right: 16 })
      }
      .width('100%')
      .height(this.currentBreakpoint === 'xs' ? 44 : 48)

      LoginWithHuaweiIDButton({
        params: {
          style: loginComponentManager.Style.BUTTON_RED,
          borderRadius: 24,
          loginType: loginComponentManager.LoginType.ID,
          supportDarkMode: true
        },
        controller: this.controller
      })
        .width('100%')
        .height(this.currentBreakpoint === 'xs' ? 44 : 48)
        .opacity(0)
    }
    .width('100%')
    .height(this.currentBreakpoint === 'xs' ? 44 : 48)
  }

  @Builder
  buildCalendar() {
    Column() {
      Row() {
        ForEach(['日', '一', '二', '三', '四', '五', '六'], (day: string) => {
          Text(day)
            .fontSize(this.getFontSize(12))
            .fontColor(ColorTheme.getColor('textMuted'))
            .width(this.currentBreakpoint === 'xs' ? 40 : 44)
            .textAlign(TextAlign.Center)
        })
      }
      .width(this.getContentWidth())
      .margin({ bottom: 8 })

      Grid() {
        ForEach(this.getCalendarDays(), (day: CalendarDay) => {
          GridItem() {
            this.buildDayCell(day)
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(4)
      .width(this.getContentWidth())
      .backgroundColor(ColorTheme.getColor('cardBackground'))
      .borderRadius(16)
      .padding(12)
    }
  }

  @Builder
  buildDayCell(day: CalendarDay) {
    Stack() {
      Text(day.day.toString())
        .fontSize(this.getFontSize(14))
        .fontColor(day.isCurrentMonth ?
          (day.hasDiary ? Color.White : ColorTheme.getColor('textPrimary')) :
          ColorTheme.getColor('textMuted'))
        .fontWeight(day.hasDiary ? FontWeight.Bold : FontWeight.Regular)

      if (day.hasDiary) {
        Stack()
          .width('100%')
          .height('100%')
          .backgroundColor('#42A5F5')
          .borderRadius(20)
          .zIndex(-1)
      }
    }
    .width(this.currentBreakpoint === 'xs' ? 36 : 40)
    .height(this.currentBreakpoint === 'xs' ? 36 : 40)
    .onClick(() => {
      if (day.hasDiary && day.isCurrentMonth) {
        this.navigateToDiaryDetail(day.dateKey)
      }
    })
  }

  /**
   * 加载日记数据
   */
  async loadDiaries(): Promise<void> {
    try {
      this.diaries = await DiaryStorage.getDiaries();
      this.totalDiaryCount = this.diaries.length;

      // 提取所有有日记的日期
      const dates = new Set<string>();
      this.diaries.forEach(diary => {
        if (diary.created_at) {
          const dateKey = this.getDateKey(diary.created_at);
          dates.add(dateKey);
        }
      });
      this.diaryDates = dates;

      console.log('[Profile] 加载日记成功，共', this.totalDiaryCount, '篇，', this.diaryDates.size, '天');
    } catch (error) {
      console.error('[Profile] 加载日记失败:', error);
    }
  }

  /**
   * 获取日期键（YYYY-MM-DD）
   */
  getDateKey(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    } catch {
      return '';
    }
  }

  /**
   * 获取日历天数数据
   */
  getCalendarDays(): CalendarDay[] {
    const days: CalendarDay[] = [];
    const firstDay = new Date(this.currentYear, this.currentMonth - 1, 1);
    const lastDay = new Date(this.currentYear, this.currentMonth, 0);
    const firstDayOfWeek = firstDay.getDay();
    const daysInMonth = lastDay.getDate();

    // 上个月的日期填充
    const prevMonthLastDay = new Date(this.currentYear, this.currentMonth - 1, 0).getDate();
    for (let i = firstDayOfWeek - 1; i >= 0; i--) {
      const day = prevMonthLastDay - i;
      const dateKey = this.getDateKeyForDay(this.currentYear, this.currentMonth - 1, day);
      days.push({
        day: day,
        isCurrentMonth: false,
        hasDiary: this.diaryDates.has(dateKey),
        dateKey: dateKey
      });
    }

    // 当前月的日期
    for (let day = 1; day <= daysInMonth; day++) {
      const dateKey = this.getDateKeyForDay(this.currentYear, this.currentMonth, day);
      days.push({
        day: day,
        isCurrentMonth: true,
        hasDiary: this.diaryDates.has(dateKey),
        dateKey: dateKey
      });
    }

    // 下个月的日期填充（补齐到42天，6周）
    const remainingDays = 42 - days.length;
    for (let day = 1; day <= remainingDays; day++) {
      const dateKey = this.getDateKeyForDay(this.currentYear, this.currentMonth + 1, day);
      days.push({
        day: day,
        isCurrentMonth: false,
        hasDiary: this.diaryDates.has(dateKey),
        dateKey: dateKey
      });
    }

    return days;
  }

  /**
   * 获取指定日期的dateKey
   */
  getDateKeyForDay(year: number, month: number, day: number): string {
    const date = new Date(year, month - 1, day);
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  /**
   * 上一个月
   */
  previousMonth(): void {
    if (this.currentMonth === 1) {
      this.currentYear--;
      this.currentMonth = 12;
    } else {
      this.currentMonth--;
    }
  }

  /**
   * 下一个月
   */
  nextMonth(): void {
    if (this.currentMonth === 12) {
      this.currentYear++;
      this.currentMonth = 1;
    } else {
      this.currentMonth++;
    }
  }

  /**
   * 跳转到日记详情页
   */
  navigateToDiaryDetail(dateKey: string): void {
    try {
      router.pushUrl({
        url: 'pages/DiaryFootprint',
        params: {
          dateKey: dateKey
        }
      } as router.RouterOptions);
    } catch (error) {
      console.error('[Profile] 跳转日记详情失败:', error);
      this.showToast('跳转失败');
    }
  }

  /**
   * 加载用户信息
   */
  async loadUserInfo(): Promise<void> {
    try {
      this.isLoading = true;
      const user = await UserStorage.getUser();

      if (user) {
        // 从服务器获取最新信息
        interface PostData {
          action: string;
          user_id: number;
        }

        const postData: PostData = {
          action: 'get_user_info',
          user_id: user.id
        };
        const response = await HttpUtils.httpRequestPost('', postData as Object);

        const result: ApiResponse<User> = JSON.parse(response);
        if (result.success && result.data) {
          this.currentUser = result.data;
          await UserStorage.saveUser(result.data);
          console.log('[Profile] 用户信息加载成功');
          console.log('[Profile] 华为UnionID:', this.currentUser.huawei_union_id || '未绑定');
          console.log('[Profile] 昵称:', this.currentUser.nickname || '无');
          console.log('[Profile] 头像:', this.currentUser.avatar || '无');
        } else {
          this.currentUser = user;
          console.log('[Profile] 使用本地缓存的用户信息');
        }
      }
    } catch (error) {
      console.error('[Profile] 加载用户信息失败:', error);
      const user = await UserStorage.getUser();
      this.currentUser = user;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 格式化日期
   */
  formatDate(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate()
        .toString()
        .padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes()
        .toString()
        .padStart(2, '0')}`;
    } catch {
      return dateStr;
    }
  }

  /**
   * 显示Toast
   */
  showToast(message: string): void {
    promptAction.showToast({
      message: message,
      duration: 2000
    } as promptAction.ShowToastOptions);
  }

  /**
   * 计算使用天数
   */
  calculateDays(): string {
    if (!this.currentUser?.created_at) return '0';
    try {
      const created = new Date(this.currentUser.created_at);
      const now = new Date();
      const days = Math.floor((now.getTime() - created.getTime()) / (1000 * 60 * 60 * 24));
      return days.toString();
    } catch {
      return '0';
    }
  }


  /**
   * 设置
   */
  handleSettings(): void {
    try {
      router.pushUrl({
        url: 'pages/Settings'
      } as router.RouterOptions);
    } catch (error) {
      console.error('[Profile] 跳转设置页面失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
  }

  /**
   * 导出日记
   */
  async handleExportDiaries(): Promise<void> {
    try {
      // 获取所有日记
      const diaries: Diary[] = await DiaryStorage.getDiaries();
      
      if (diaries.length === 0) {
        this.showToast('暂无日记可导出');
        return;
      }

      // 确认导出
      const result = await promptAction.showDialog({
        title: '导出日记',
        message: `将导出 ${diaries.length} 条日记为JSON文件，保存到应用文档目录。确定要继续吗？`,
        buttons: [
          { text: '取消', color: '#999999' } as promptAction.Button,
          { text: '导出', color: ColorTheme.getColor('buttonPrimaryBg') } as promptAction.Button
        ]
      } as promptAction.ShowDialogOptions);

      if (result.index === 1) {
        await this.exportDiariesToFile(diaries);
      }
    } catch (error) {
      console.error('[Profile] 导出日记失败:', error);
      this.showToast('导出失败，请稍后再试');
    }
  }

  /**
   * 导出日记到文件
   */
  async exportDiariesToFile(diaries: Diary[]): Promise<void> {
    try {
      const context = getContext();
      const filesDir = context.filesDir;
      
      // 生成文件名（包含时间戳）
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
      const fileName = `geonote_export_${timestamp}.json`;
      const filePath = `${filesDir}/${fileName}`;
      
      // 准备导出数据
      const exportData: DiaryExportData = {
        export_time: new Date().toISOString(),
        app_version: 'v1.0',
        total_count: diaries.length,
        diaries: diaries
      };
      
      // 转换为JSON字符串
      const jsonString = JSON.stringify(exportData, null, 2);
      
      // 写入文件
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      const buf = buffer.from(jsonString, 'utf-8');
      fs.writeSync(file.fd, buf.buffer);
      fs.closeSync(file);
      
      console.log('[Profile] 日记导出成功:', filePath);
      
      // 显示成功提示
      await promptAction.showDialog({
        title: '导出成功',
        message: `已导出 ${diaries.length} 条日记\n\n文件路径：\n${filePath}`,
        buttons: [
          { text: '确定', color: ColorTheme.getColor('buttonPrimaryBg') } as promptAction.Button
        ]
      } as promptAction.ShowDialogOptions);
      
    } catch (error) {
      console.error('[Profile] 写入文件失败:', error);
      this.showToast('导出失败，无法写入文件');
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
      console.error('[Profile] 跳转绑定邮箱页面失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
  }

  /**
   * 修改用户名
   */
  handleChangeUsername(): void {
    try {
      router.pushUrl({
        url: 'pages/ChangeUsername'
      } as router.RouterOptions);
    } catch (error) {
      console.error('[Profile] 跳转修改用户名页面失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
  }

  /**
   * 修改密码
   */
  handleChangePassword(): void {
    try {
      router.pushUrl({
        url: 'pages/ChangePassword'
      } as router.RouterOptions);
    } catch (error) {
      console.error('[Profile] 跳转修改密码页面失败:', error);
      this.showToast('跳转失败，请稍后再试');
    }
  }

  /**
   * 绑定华为账号
   */
  async bindHuaweiAccount(authorizationCode: string): Promise<void> {
    if (!this.currentUser || !this.currentUser.id) {
      this.showToast('用户信息不存在');
      return;
    }

    this.isLoading = true;

    try {
      const postData: BindHuaweiAccountRequest = {
        action: 'bind_huawei_account',
        user_id: this.currentUser.id,
        authorization_code: authorizationCode
      };

      const response = await HttpUtils.httpRequestPost('', postData as Object);
      const result: ApiResponse<User> = JSON.parse(response);

      if (result.success && result.code === 200) {
        // 更新用户信息
        if (result.data) {
          await UserStorage.saveUser(result.data);
          this.currentUser = result.data;
          console.log('[Profile] 绑定成功，更新用户信息 - 昵称:', result.data.nickname || '无', '头像:', result.data.avatar || '无');
        }
        this.showToast(result.message || '华为账号绑定成功');
      } else {
        this.showToast(result.message || '华为账号绑定失败');
      }
    } catch (e) {
      console.error('[Profile] 绑定华为账号失败:', e);
      this.showToast('绑定华为账号失败，请稍后再试');
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 解绑华为账号
   */
  async handleUnbindHuawei(): Promise<void> {
    // 检查用户是否有密码
    if (!this.currentUser?.has_password) {
      this.showToast('请先设置密码后再解绑华为账号');
      return;
    }

    try {
      const result = await promptAction.showDialog({
        title: '解绑华为账号',
        message: '解绑后将无法使用华为账号登录，确定要解绑吗？',
        buttons: [
          { text: '取消', color: '#999999' } as promptAction.Button,
          { text: '确定', color: '#ef4444' } as promptAction.Button
        ]
      } as promptAction.ShowDialogOptions);

      if (result.index === 1 && this.currentUser) {
        this.isLoading = true;

        const postData: UnbindHuaweiAccountRequest = {
          action: 'unbind_huawei_account',
          user_id: this.currentUser.id
        };
        const response = await HttpUtils.httpRequestPost('', postData as Object);

        const apiResult: ApiResponse<User> = JSON.parse(response);
        if (apiResult.success && apiResult.data) {
          this.currentUser = apiResult.data;
          await UserStorage.saveUser(apiResult.data);
          console.log('[Profile] 解绑成功，更新用户信息');
          this.showToast('解绑成功');
        } else {
          this.showToast(apiResult.message || '解绑失败');
        }
      }
    } catch (error) {
      console.error('[Profile] 解绑失败:', error);
      this.showToast('解绑失败，请稍后再试');
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 退出登录
   */
  async handleLogout(): Promise<void> {
    try {
      const result = await promptAction.showDialog({
        title: '退出登录',
        message: '确定要退出登录吗？',
        buttons: [
          { text: '取消', color: '#999999' } as promptAction.Button,
          { text: '确定', color: '#ef4444' } as promptAction.Button
        ]
      } as promptAction.ShowDialogOptions);

      if (result.index === 1) {
        // 清除用户信息
        await UserStorage.clearUser();
        // 清除DiaryStorage的当前用户ID
        await DiaryStorage.setCurrentUserId(0);
        this.showToast('已退出登录');
        router.replaceUrl({
          url: 'pages/Login'
        } as router.RouterOptions);
      }
    } catch (error) {
      console.error('[Profile] 退出登录失败:', error);
    }
  }

  /**
   * 注销账号
   */
  async handleDeleteAccount(): Promise<void> {
    try {
      const result = await promptAction.showDialog({
        title: '注销账号',
        message: '注销后所有数据将被删除且无法恢复，确定要注销吗？',
        buttons: [
          { text: '取消', color: '#999999' } as promptAction.Button,
          { text: '确定注销', color: '#dc2626' } as promptAction.Button
        ]
      } as promptAction.ShowDialogOptions);

      if (result.index === 1 && this.currentUser) {
        interface DeletePostData {
          action: string;
          user_id: number;
        }

        const postData: DeletePostData = {
          action: 'delete_my_account',
          user_id: this.currentUser.id
        };
        const response = await HttpUtils.httpRequestPost('', postData as Object);

        const apiResult: ApiResponse = JSON.parse(response);
        if (apiResult.success) {
          // 清除用户信息
          await UserStorage.clearUser();
          // 清除DiaryStorage的当前用户ID
          await DiaryStorage.setCurrentUserId(0);
          this.showToast('账号已注销');
          router.replaceUrl({
            url: 'pages/Login'
          } as router.RouterOptions);
        } else {
          this.showToast(apiResult.message || '注销失败');
        }
      }
    } catch (error) {
      console.error('[Profile] 注销账号失败:', error);
      this.showToast('注销失败，请稍后再试');
    }
  }
}
