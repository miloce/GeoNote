import { router } from '@kit.ArkUI';
import { Component_Ark } from '../components/Component_Ark';
import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import promptAction from '@ohos.promptAction';
import { Diary } from '../model/DiaryModel';
import { User } from '../model/UserModel';
import { DiaryStorage } from '../utils/DiaryStorage';
import { DiarySyncManager } from '../utils/DiarySyncManager';
import { UserStorage } from '../utils/UserStorage';
import { UuidUtil } from '../utils/UuidUtil';
import { display } from '@kit.ArkUI';
import http from '@ohos.net.http';
import { LocationManager, LocationResult } from '../utils/LocationManager';
import common from '@ohos.app.ability.common';
import {
  AMap,
  CameraUpdateFactory,
  LatLng,
  MapView,
  MapViewComponent,
  MapViewManager,
  MapViewCreateCallback,
  MarkerOptions
} from '@amap/amap_lbs_map3d';
import { mapHelper } from '../utils/MapHelper';

interface DiaryDaySummary {
  dateKey: string;
  dayLabel: string;
  monthLabel: string;
  weekdayLabel: string;
  headline: string;
  contentPreview: string;
  locationLabel: string;
  hasExplicitLocation: boolean;
  unsynced: boolean;
  dateStatusLabel: string;
  diaries: Diary[];
}

interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
  timestamp: number;
  displayContent?: string;  // 用于打字机效果的显示内容
  isTyping?: boolean;  // 是否正在打字
}

screenAdapter.designWidth = 375;

@Entry
@Component
export struct Index {
  private scrollController = new Scroller()
  private diaryScrollController = new Scroller()
  private aiScrollController = new Scroller()
  @State diaries: Diary[] = []
  @State isLoading: boolean = false
  @State isSyncing: boolean = false
  @State currentUserId: number = 0
  // 响应式布局状态
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint()
  @State isLandscape: boolean = isCurrentLandscape()
  private breakpointSystem: BreakpointSystem = new BreakpointSystem()
  // 添加日记对话框状态
  @State showAddDiaryDialog: boolean = false
  @State diaryLocation: string = ''
  @State diaryAddress: string = ''  // 完整地址
  @State diaryLatitude: number = 0
  @State diaryLongitude: number = 0
  @State diaryContent: string = ''
  @State contentLength: number = 0
  @State selectedDate: Date = new Date()
  @State isSavingDiary: boolean = false
  @State isGettingLocation: boolean = false
  private locationManager?: LocationManager
  @State addDiaryDialogHeight: number = 0
  @State addDiaryDialogOffset: number = 0
  @State addDiaryMaskOpacity: number = 0  // 添加日记对话框蒙版透明度
  private maxDialogHeight: number = 0
  private minDialogHeight: number = 400
  private diaryStartY: number = 0
  private diaryStartHeight: number = 0
  // AI助手对话框状态
  @State showAiDialog: boolean = false
  @State aiInputText: string = ''
  @State aiMessages: ChatMessage[] = []
  @State isAiLoading: boolean = false
  @State aiDialogHeight: number = 0
  @State aiDialogOffset: number = 0
  @State aiMaskOpacity: number = 0  // AI对话框蒙版透明度
  private aiStartY: number = 0
  private aiStartHeight: number = 0
  private aiSuggestions: string[] = [
    '总结一下我本周的行程和记忆',
    '我和朋友去玩是哪一天？',
    '今年我去过哪些地方旅游？'
  ]
  private typingIntervalId?: number  // 打字机效果定时器ID
  // 地图相关
  private cardMapViews: Map<string, MapView> = new Map()
  private cardAMaps: Map<string, AMap> = new Map()
  @State privacyAgreed: boolean = false

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
      this.updateDialogHeight();
    });

    // 计算对话框高度 - 响应式
    this.updateDialogHeight();

    // 初始化高德地图（使用统一的MapHelper）
    mapHelper.initializeMapSDK(getContext(this));

    // 获取当前用户ID
    const user: User | null = await UserStorage.getUser();
    if (user) {
      this.currentUserId = user.id;
      // 设置DiaryStorage的当前用户ID，确保数据隔离
      await DiaryStorage.setCurrentUserId(user.id);
      console.log('[Index] 当前用户ID:', this.currentUserId);
    }

    // 记录隐私同意状态（用于控制后续权限申请）
    this.privacyAgreed = await UserStorage.isPrivacyAgreed();
    if (!this.privacyAgreed) {
      console.info('[Index] 用户未同意隐私政策，定位相关流程将延后至弹窗中触发');
    }

    await this.loadDiaries();
    await this.syncDiaries();

    // 注册地图视图回调
    MapViewManager.getInstance().registerMapViewCreatedCallback(this.cardMapViewCreateCallback);
  }

  async onPageShow() {
    // 从其他页面返回时重新加载日记数据
    await this.loadDiaries();
  }

  /**
   * 页面即将消失时的清理工作
   */
  aboutToDisappear() {
    // 注销断点监听
    this.breakpointSystem.unregister();
    display.off('change');
    // 清除打字机定时器
    if (this.typingIntervalId) {
      clearInterval(this.typingIntervalId);
      this.typingIntervalId = undefined;
    }
    // 清理地图资源
    this.cardMapViews.forEach((mapView) => {
      mapView.onDestroy();
    });
    this.cardMapViews.clear();
    this.cardAMaps.clear();
    MapViewManager.getInstance().unregisterMapViewCreatedCallback(this.cardMapViewCreateCallback);
    console.log('[Index] 页面销毁，清理资源完成');
  }

  /**
   * 卡片地图创建回调
   * 使用MapHelper统一管理地图操作
   */
  private cardMapViewCreateCallback: MapViewCreateCallback = (mapview?: MapView, mapViewName?: string) => {
    if (!mapview || !mapViewName || !mapViewName.startsWith('IndexCard_')) {
      return;
    }

    // 从 mapViewName 解析 dateKey
    const dateKey = mapViewName.replace('IndexCard_', '');
    this.cardMapViews.set(dateKey, mapview);
    mapview.onCreate();

    mapview.getMapAsync(async (map) => {
      this.cardAMaps.set(dateKey, map);

      // 配置地图UI：禁用所有手势，使地图固定不可移动
      mapHelper.configureMapUI(map, {
        disableGestures: true,
        showZoomControls: false,
        showScaleControls: false,
        showCompass: false
      });

      // 获取该日期的日记数据
      const summaries = this.getDailySummaries();
      const summary = summaries.find(s => s.dateKey === dateKey);
      if (!summary || summary.diaries.length === 0) return;

      try {
        // 清除现有标记
        mapHelper.clearMap(map);

        // 添加所有日记标记（每条日记一个标记）
        const markerCount = mapHelper.addDiaryMarkersIndividual(map, summary.diaries);

        // 自动调整地图视角以显示所有标记点
        if (markerCount > 0) {
          mapHelper.fitMapToDiaries(map, summary.diaries, false);
        } else {
          // 没有有效坐标，使用默认视角
          map.moveCamera(CameraUpdateFactory.newLatLngZoom(new LatLng(35.0, 110.0), 5.0));
        }

        console.info(`[Index] 卡片地图初始化完成: ${dateKey}, 标记数: ${markerCount}`);
      } catch (error) {
        console.error('[Index] 初始化卡片地图失败:', error);
      }
    });
  };

  // 响应式尺寸方法
  getCardWidth(): string {
    switch (this.currentBreakpoint) {
      case 'xs': return '92%';
      case 'sm': return '90%';
      case 'md': return '80%';
      case 'lg': return '70%';
      default: return '90%';
    }
  }

  getContentPadding(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 12;
      case 'sm': return 20;
      case 'md': return 32;
      case 'lg': return 48;
      default: return 20;
    }
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
      case 'md': return 20;
      case 'lg': return 24;
      default: return 16;
    }
  }

  getNavBarHeight(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 90;
      case 'sm': return 110;
      case 'md': return 120;
      case 'lg': return 130;
      default: return 110;
    }
  }

  getBottomButtonWidth(): string {
    switch (this.currentBreakpoint) {
      case 'xs': return '85%';
      case 'sm': return '75%';
      case 'md': return '50%';
      case 'lg': return '40%';
      default: return '75%';
    }
  }

  // 弹窗响应式方法
  updateDialogHeight() {
    const screenHeight = px2vp(display.getDefaultDisplaySync().height);
    // 横屏时弹窗占满高度，竖屏时占80%
    if (this.isLandscape) {
      this.maxDialogHeight = screenHeight * 0.80;
      this.minDialogHeight = screenHeight * 0.40;
    } else {
      this.maxDialogHeight = screenHeight * 0.80;
      this.minDialogHeight = 360;
    }
    this.addDiaryDialogHeight = this.maxDialogHeight;
    this.aiDialogHeight = this.maxDialogHeight;
  }

  getDialogWidth(): string {
    // 大屏横屏时弹窗居中显示，宽度受限
    if (this.isLandscape) {
      switch (this.currentBreakpoint) {
        case 'lg': return '50%';
        case 'md': return '65%';
        default: return '100%';
      }
    }
    return '100%';
  }

  getDialogContentWidth(): string {
    // 弹窗内部内容宽度
    if (this.isLandscape && (this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'md')) {
      return '90%';
    }
    return '87%';
  }

  /**
   * 加载本地日记
   */
  async loadDiaries() {
    try {
      this.isLoading = true;
      this.diaries = await DiaryStorage.getDiaries();
      console.info('[Index] 加载日记成功, 数量:', this.diaries.length);
    } catch (error) {
      console.error('[Index] 加载日记失败:', error);
      promptAction.showToast({ message: '加载日记失败' });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 同步日记
   */
  async syncDiaries() {
    try {
      const user = await UserStorage.getUser();
      if (!user) {
        console.info('[Index] 未登录，跳过同步');
        return;
      }

      this.isSyncing = true;
      const result = await DiarySyncManager.fullSync(user.id);

      if (result.success) {
        await this.loadDiaries();
        console.info('[Index] 同步成功:', result.message);
      } else {
        console.warn('[Index] 同步失败:', result.message);
      }
    } catch (error) {
      console.error('[Index] 同步失败:', error);
    } finally {
      this.isSyncing = false;
    }
  }

  build() {
    Stack() {
      // 可滚动内容区域
      Scroll(this.scrollController) {
        Column({ space: this.getSpacing() }) {
          // 顶部留白，避免首条紧贴导航
          Blank()
            .height(this.getSpacing())

          // 日记列表区域 - 响应式
          Column({ space: this.getSpacing() }) {
            if (this.getDailySummaries().length > 0) {
              ForEach(this.getDailySummaries(), (summary: DiaryDaySummary) => {
                this.buildDiaryCard(summary);
              })
            } else {
              // 空状态 - 居中显示
              Column({ space: 16 }) {
                // 盒子图标
                SymbolGlyph($r('sys.symbol.doc_text_badge_magnifyingglass'))
                  .fontSize(this.getFontSize(100))
                  .fontColor([ColorTheme.getColor('textMuted')])
                  .opacity(0.4)

                Text('开始使用迹记吧！')
                  .fontSize(this.getFontSize(18))
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorTheme.getColor('textPrimary'))

                Text('点击"新增"添加一条全新日记')
                  .fontSize(this.getFontSize(14))
                  .fontColor(ColorTheme.getColor('textMuted'))
              }
              .width('100%')
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
              .padding({ top: 120, bottom: 120 })
            }
          }
          .width('100%')

          Row() {
            Component_Ark({
              propList: [{
                "componentId": "27:3841",
                "pathString": "27:3841",
                "width": toPx(24),
                "height": toPy(24),
                "left": toPx(329),
                "top": toPy(188)
              }, {
                "componentId": "27:3842",
                "pathString": "27:3842",
                "width": toPx(24),
                "visibility": Visibility.None,
                "height": toPy(24)
              }, {
                "componentId": "27:3843",
                "pathString": "27:3843",
                "fillPaints": [{ "backgroundColor": "rgba(31, 190, 66, 1)" }],
                "width": toPx(24),
                "height": toPy(24)
              }, {
                "componentId": "27:3844",
                "pathString": "27:3844",
                "fillPaints": [{ "backgroundColor": "rgba(31, 190, 66, 1)" }],
                "width": toPx(9.59),
                "height": toPy(3.71),
                "left": toPx(7.21),
                "top": toPy(14.61)
              }, {
                "componentId": "27:3845",
                "pathString": "27:3845",
                "fillPaints": [{ "backgroundColor": "rgba(31, 190, 66, 1)" }],
                "width": toPx(2.91),
                "height": toPy(2.91),
                "left": toPx(5.89),
                "top": toPy(8.22)
              }, {
                "componentId": "27:3846",
                "pathString": "27:3846",
                "fillPaints": [{ "backgroundColor": "rgba(31, 190, 66, 1)" }],
                "width": toPx(2.91),
                "height": toPy(2.91),
                "left": toPx(15.2),
                "top": toPy(8.22)
              }]
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .padding({ right: toPx(20) })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: this.getNavBarHeight() - this.getSpacing(), bottom: 180 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.TopStart)
      .backgroundColor(ColorTheme.getColor('pageBackground'))

      // 顶部导航栏 - 响应式
      Row() {
        // 左侧菜单图标 - 跳转到个人中心
        SymbolGlyph($r('sys.symbol.sort'))
          .fontSize(this.getFontSize(24))
          .fontColor([ColorTheme.getColor('textPrimary')])
          .onClick(() => {
            console.info('[Index] 跳转到个人中心');
            router.pushUrl({
              url: 'pages/Profile'
            }).catch((err: Error) => {
              console.error('[Index] 跳转个人中心失败:', err);
              promptAction.showToast({ message: '打开个人中心失败' });
            });
          })

        Blank()

        // 中间标题
        Text('迹记')
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))

        Blank()

        // 右侧足迹地图图标
        SymbolGlyph($r('sys.symbol.map_badge_local'))
          .fontSize(this.getFontSize(24))
          .fontColor([ColorTheme.getColor('textPrimary')])
          .onClick(() => {
            console.info('[Index] 打开足迹地图');
            router.pushUrl({
              url: 'pages/DiaryFootprintMap'
            }).catch((err: Error) => {
              console.error('[Index] 跳转足迹地图失败:', err);
              promptAction.showToast({ message: '打开地图失败' });
            });
          })
      }
      .width('100%')
      .height(this.getNavBarHeight())
      .padding({ left: this.getContentPadding(), right: this.getContentPadding(), top: 44 })
      .position({ left: 0, top: 0 })
      .backgroundColor(ColorTheme.getColor('cardBackground'))
      .zIndex(10)

      // 底部悬浮按钮组 - 响应式
      Row({ space: 8 }) {
        // 新增按钮
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.pencil_waveform_fill'))
            .fontSize(this.getFontSize(18))
            .fontColor(['#5D4037'])
          Text('新增+')
            .fontSize(this.getFontSize(14))
            .fontWeight(FontWeight.Medium)
            .fontColor('#5D4037')
        }
        .height(this.currentBreakpoint === 'xs' ? 48 : 54)
        .padding({ left: this.getContentPadding(), right: this.getContentPadding() })
        .backgroundColor('#FFE082')
        .borderRadius(27)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .onClick(() => {
          console.info('[Index] 打开添加日记弹窗');
          this.showAddDiaryDialog = true;
          this.addDiaryDialogOffset = 1000;
          this.addDiaryMaskOpacity = 0;
          animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
            this.addDiaryDialogOffset = 0;
            this.addDiaryMaskOpacity = 1;
          });
          // 用户主动打开记录弹窗后，再触发定位/权限申请
          this.ensureLocationReady().then((ready) => {
            if (ready) {
              this.autoGetLocation();
            }
          });
        })

        // AI助手按钮
        Row({ space: 8 }) {
          SymbolGlyph($r('sys.symbol.discover_fill'))
            .fontSize(this.getFontSize(18))
            .fontColor([ColorTheme.getColor('textPrimary')])
          Text('AI 助手')
            .fontSize(this.getFontSize(14))
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTheme.getColor('textPrimary'))
        }
        .height(this.currentBreakpoint === 'xs' ? 48 : 54)
        .padding({ left: this.getContentPadding(), right: this.getContentPadding() })
        .backgroundColor(ColorTheme.getColor('cardBackground'))
        .borderRadius(27)
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .onClick(() => {
          console.info('[Index] 打开AI助手弹窗');
          if (!this.currentUserId || this.currentUserId === 0) {
            promptAction.showToast({ message: '请先登录' });
            return;
          }
          this.showAiDialog = true;
          this.aiDialogOffset = 1000;
          this.aiMaskOpacity = 0;
          animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
            this.aiDialogOffset = 0;
            this.aiMaskOpacity = 1;
          });
        })
      }
      .width(this.getBottomButtonWidth())
      .padding(8)
      .backgroundColor(ColorTheme.getColor('cardBackground'))
      .borderRadius(36)
      .shadow({
        radius: 20,
        offsetX: 0,
        offsetY: 4,
        color: 'rgba(0, 0, 0, 0.08)'
      })
      .position({ left: '50%', bottom: 30 })
      .translate({ x: '-50%' })
      .zIndex(10)

      // 添加日记对话框
      if (this.showAddDiaryDialog) {
        Stack() {
          this.buildAddDiaryDialog()
        }
        .width('100%')
        .height('100%')
        .zIndex(100)
      }

      // AI助手对话框
      if (this.showAiDialog) {
        Stack() {
          this.buildAiAssistantDialog()
        }
        .width('100%')
        .height('100%')
        .zIndex(100)
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建日记卡片 - 参考设计图：顶部地图、中间轨迹链、底部日期
   */
  @Builder
  buildDiaryCard(summary: DiaryDaySummary) {
    Column() {
      // 顶部地图区域 - 使用真实高德地图
      Stack() {
        // 高德地图组件
        MapViewComponent({ mapViewName: `IndexCard_${summary.dateKey}` })
          .width('100%')
          .height('100%')
          .borderRadius({ topLeft: 16, topRight: 16 })
          .hitTestBehavior(HitTestMode.None) // 禁用地图触摸，允许滑动穿透

        // 透明覆盖层 - 用于接收点击事件跳转到足迹地图
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            console.info('[Index] 点击地图，打开日记时间轴');
            router.pushUrl({
              url: 'pages/DiaryFootprint',
              params: {
                dateKey: summary.dateKey
              }
            }).catch((err: Error) => {
              console.error('[Index] 跳转日记时间轴失败:', err);
              promptAction.showToast({ message: '打开时间轴失败' });
            });
          })

        // 未同步标识
        if (summary.unsynced) {
          Row({ space: 4 }) {
            if (this.isSyncing) {
              LoadingProgress()
                .width(12)
                .height(12)
                .color(ColorTheme.getColor('textMuted'))
            } else {
              SymbolGlyph($r('sys.symbol.icloud_slash_fill'))
                .fontSize(12)
                .fontColor([ColorTheme.getColor('textMuted')])
            }
            Text(this.isSyncing ? '同步中' : '未同步')
              .fontSize(this.getFontSize(11))
              .fontColor(ColorTheme.getColor('textMuted'))
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('rgba(255,255,255,0.9)')
          .borderRadius(10)
          .position({ right: 8, top: 8 })
          .hitTestBehavior(HitTestMode.Block) // 同步按钮单独响应点击
          .onClick(() => {
            if (!this.isSyncing) {
              this.syncDiaries();
            }
          })
        }
      }
      .width('100%')
      .height(160)
      .borderRadius({ topLeft: 16, topRight: 16 })
      .clip(true)

      // 中间轨迹链区域
      Column({ space: 8 }) {
        Text(this.getTrailChainText(summary.diaries))
          .fontSize(this.getFontSize(15))
          .fontColor(ColorTheme.getColor('textPrimary'))
          .lineHeight(this.getFontSize(22))
          .maxLines(4)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 12, bottom: 12 })
      .alignItems(HorizontalAlign.Start)

      // 分隔线
      Divider()
        .width('92%')
        .strokeWidth(0.5)
        .color(ColorTheme.getColor('divider'))

      // 底部日期区域
      Row() {
        Text(summary.dayLabel)
          .fontSize(this.getFontSize(32))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))

        Text(summary.monthLabel)
          .fontSize(this.getFontSize(14))
          .fontColor(ColorTheme.getColor('textPrimary'))
          .margin({ left: 6, bottom: 4 })

        Blank()

        Text(summary.weekdayLabel)
          .fontSize(this.getFontSize(13))
          .fontColor(ColorTheme.getColor('textMuted'))
      }
      .width('100%')
      .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 10, bottom: 14 })
      .alignItems(VerticalAlign.Bottom)
    }
    .width('92%')
    .backgroundColor(ColorTheme.getColor('cardBackground'))
    .borderRadius(16)
    .shadow({
      radius: 12,
      offsetX: 0,
      offsetY: 4,
      color: 'rgba(0, 0, 0, 0.06)'
    })
    .onClick(() => {
      console.info('[Index] 查看日记详情-按日汇总:', summary.dateKey);
      router.pushUrl({
        url: 'pages/DiaryFootprint',
        params: {
          dateKey: summary.dateKey
        }
      });
    })
  }

  /**
   * 获取轨迹链文本（地点1-地点2-地点3...）
   */
  getTrailChainText(diaries: Diary[]): string {
    // 按时间排序（从早到晚）
    const sorted = [...diaries].sort((a, b) =>
      this.getDateTimestamp(a.created_at) - this.getDateTimestamp(b.created_at)
    );

    // 提取所有地点，去重但保留顺序
    const locations: string[] = [];
    sorted.forEach((diary) => {
      if (diary.location && diary.location.trim().length > 0) {
        const loc = diary.location.trim();
        // 避免连续重复
        if (locations.length === 0 || locations[locations.length - 1] !== loc) {
          locations.push(loc);
        }
      }
    });

    if (locations.length === 0) {
      return `共 ${diaries.length} 条轨迹记录`;
    }

    return locations.join('-');
  }

  /**
   * 获取日期中的天数
   */
  getDayOfMonth(dateStr: string): string {
    if (!dateStr) {
      return '1';
    }
    try {
      const date = new Date(dateStr);
      return String(date.getDate());
    } catch (error) {
      return '1';
    }
  }

  /**
   * 获取星期几
   */
  getWeekday(dateStr: string): string {
    if (!dateStr) {
      return '周一';
    }
    try {
      const date = new Date(dateStr);
      const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
      return weekdays[date.getDay()];
    } catch (error) {
      return '周一';
    }
  }

  /**
   * 获取月份标签
   */
  getMonthLabel(dateStr: string): string {
    if (!dateStr) {
      return '1月';
    }
    try {
      const date = new Date(dateStr);
      return `${date.getMonth() + 1}月`;
    } catch (error) {
      return '1月';
    }
  }

  /**
   * 获取展示标题
   */
  getDiaryHeadline(diary: Diary): string {
    if (diary.title && diary.title.trim().length > 0) {
      return diary.title.trim();
    }
    if (diary.location && diary.location.trim().length > 0) {
      return diary.location.trim();
    }
    return '轨迹记录';
  }

  /**
   * 获取内容预览
   */
  getDiaryContentPreview(diary: Diary): string {
    if (diary.content && diary.content.trim().length > 0) {
      return diary.content.trim();
    }
    return '暂无文字描述，已记录行程轨迹';
  }

  /**
   * 获取地点标签内容
   */
  getDiaryLocationLabel(diary: Diary): string {
    if (diary.location && diary.location.trim().length > 0) {
      return diary.location.trim();
    }
    return '轨迹自动记录';
  }

  /**
   * 将日记按天汇总
   */
  getDailySummaries(): DiaryDaySummary[] {
    if (!this.diaries || this.diaries.length === 0) {
      return [];
    }

    const grouped = new Map<string, Diary[]>();
    this.diaries.forEach((diary) => {
      const dateKey = this.getDateKey(diary.created_at);
      if (!grouped.has(dateKey)) {
        grouped.set(dateKey, []);
      }
      grouped.get(dateKey)!.push(diary);
    });

    const summaries: DiaryDaySummary[] = [];

    grouped.forEach((diaries, dateKey) => {
      const sorted = diaries.sort((a, b) => this.getDateTimestamp(b.created_at) - this.getDateTimestamp(a.created_at));
      const primary = sorted[0];
      const locationLabel = this.getGroupLocationLabel(sorted);
      const hasExplicitLocation = locationLabel !== '轨迹自动记录';
      const contentPreview = this.getGroupContentPreview(sorted);
      const headline = this.getGroupHeadline(sorted, locationLabel);
      const unsynced = sorted.some((item) => !item.synced);
      const referenceDate = primary?.created_at || dateKey;

      summaries.push({
        dateKey,
        dayLabel: this.getDayOfMonth(referenceDate),
        monthLabel: this.getMonthLabel(referenceDate),
        weekdayLabel: this.getWeekday(referenceDate),
        headline,
        contentPreview,
        locationLabel,
        hasExplicitLocation,
        unsynced,
        dateStatusLabel: this.formatDiaryDate(referenceDate),
        diaries: sorted
      });
    });

    return summaries.sort((a, b) => this.getDateTimestamp(b.dateKey) - this.getDateTimestamp(a.dateKey));
  }

  /**
   * 获取日记集合的地点标签
   */
  getGroupLocationLabel(diaries: Diary[]): string {
    const locationDiary = diaries.find((item) => item.location && item.location.trim().length > 0);
    if (locationDiary) {
      return locationDiary.location!.trim();
    }
    return '轨迹自动记录';
  }

  /**
   * 获取日记集合的内容预览
   */
  getGroupContentPreview(diaries: Diary[]): string {
    const contentDiary = diaries.find((item) => item.content && item.content.trim().length > 0);
    if (contentDiary) {
      return contentDiary.content.trim();
    }

    const uniqueLocations = Array.from(new Set(diaries
      .map((item) => item.location?.trim())
      .filter((location) => !!location))) as string[];

    if (uniqueLocations.length > 0) {
      return uniqueLocations.join(' → ');
    }

    return '暂无文字描述，已记录行程轨迹';
  }

  /**
   * 获取日记集合的标题
   */
  getGroupHeadline(diaries: Diary[], locationLabel: string): string {
    const titleDiary = diaries.find((item) => item.title && item.title.trim().length > 0);
    if (titleDiary) {
      return titleDiary.title.trim();
    }

    if (locationLabel !== '轨迹自动记录') {
      return locationLabel;
    }

    return `共${diaries.length}条轨迹记录`;
  }

  /**
   * 获取日期键（yyyy-MM-dd）
   */
  getDateKey(dateStr?: string): string {
    try {
      const date = dateStr ? new Date(dateStr) : new Date();
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    } catch (error) {
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    }
  }

  /**
   * 将日期转时间戳（用于排序）
   */
  getDateTimestamp(dateStr?: string): number {
    if (!dateStr) {
      return 0;
    }
    try {
      return new Date(dateStr).getTime();
    } catch (error) {
      return 0;
    }
  }

  /**
   * 格式化日记日期
   */
  formatDiaryDate(dateStr: string): string {
    if (!dateStr) {
      return '';
    }

    try {
      const date = new Date(dateStr);
      const now = new Date();
      const diff = now.getTime() - date.getTime();
      const days = Math.floor(diff / (1000 * 60 * 60 * 24));

      if (days === 0) {
        return '今天';
      } else if (days === 1) {
        return '昨天';
      } else if (days < 7) {
        return `${days}天前`;
      } else {
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${month}-${day}`;
      }
    } catch (error) {
      return '';
    }
  }

  /**
   * 构建添加日记对话框
   */
  @Builder
  buildAddDiaryDialog() {
    Stack() {
      // 对话框内容容器
      Stack() {
        Column() {
          // 拖动条
          Stack()
            .height(6)
            .width(48)
            .margin({ top: 16, bottom: 8 })
            .borderRadius(3)
            .backgroundColor(ColorTheme.getColor('divider'))
            .gesture(
              PanGesture()
                .onActionStart((event: GestureEvent) => {
                  this.diaryStartY = event.fingerList[0].globalY;
                  this.diaryStartHeight = this.addDiaryDialogHeight;
                })
                .onActionUpdate((event: GestureEvent) => {
                  const deltaY = this.diaryStartY - event.fingerList[0].globalY;
                  let newHeight = this.diaryStartHeight + deltaY;
                  if (deltaY < 0) {
                    newHeight = Math.max(this.minDialogHeight, newHeight);
                  } else {
                    newHeight = Math.max(this.minDialogHeight, Math.min(this.maxDialogHeight, newHeight));
                  }
                  this.addDiaryDialogHeight = newHeight;
                })
                .onActionEnd((event: GestureEvent) => {
                  const deltaY = this.diaryStartY - event.fingerList[0].globalY;
                  if (deltaY < 0 && Math.abs(deltaY) > this.maxDialogHeight * 0.60) {
                    this.closeAddDiaryDialog();
                  } else {
                    animateTo({ duration: 200 }, () => {
                      this.addDiaryDialogHeight = this.maxDialogHeight;
                    });
                  }
                })
            )

          // 可滚动表单区域
          Scroll(this.diaryScrollController) {
            Column({ space: this.isLandscape ? 12 : 20 }) {
              // 地点输入区域
              Column({ space: 8 }) {
                Row({ space: 4 }) {
                  Text('地点')
                    .fontColor(ColorTheme.getColor('textPrimary'))
                    .fontWeight(FontWeight.Bold)
                    .fontSize(this.getFontSize(18))
                  Text('*')
                    .fontColor('#E53E3E')
                    .fontSize(this.getFontSize(18))
                }
                .width('100%')

                Row({ space: 8 }) {
                  TextInput({ placeholder: '输入地点...', text: this.diaryLocation })
                    .onChange((value: string) => { this.diaryLocation = value; })
                    .layoutWeight(1)
                    .backgroundColor(ColorTheme.getColor('pageBackground'))
                    .fontColor(ColorTheme.getColor('textPrimary'))
                    .placeholderColor(ColorTheme.getColor('textMuted'))
                    .fontSize(this.getFontSize(16))
                    .border({ width: 0 })

                  Stack() {
                    if (this.isGettingLocation) {
                      LoadingProgress()
                        .width(20)
                        .height(20)
                        .color(ColorTheme.getColor('textPrimary'))
                    } else {
                      SymbolGlyph($r('sys.symbol.location_north_up_right_circle_fill'))
                        .fontSize(this.getFontSize(22))
                        .fontColor([ColorTheme.getColor('textPrimary')])
                    }
                  }
                  .width(40)
                  .height(40)
                  .alignContent(Alignment.Center)
                  .onClick(() => { this.handleGetLocation(); })
                }
                .height(this.isLandscape ? 48 : 56)
                .padding({ left: 16, right: 8 })
                .backgroundColor(ColorTheme.getColor('cardBackground'))
                .borderRadius(12)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)

              // 日期选择区域
              Column({ space: 8 }) {
                Row({ space: 4 }) {
                  Text('日期')
                    .fontColor(ColorTheme.getColor('textPrimary'))
                    .fontWeight(FontWeight.Bold)
                    .fontSize(this.getFontSize(18))
                  Text('*')
                    .fontColor('#E53E3E')
                    .fontSize(this.getFontSize(18))
                }
                .width('100%')

                Row({ space: 12 }) {
                  Text(this.formatDateString(this.selectedDate))
                    .fontSize(this.getFontSize(16))
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ColorTheme.getColor('textPrimary'))
                    .layoutWeight(1)
                    .height(this.isLandscape ? 40 : 44)
                    .padding({ left: 16, right: 16 })
                    .backgroundColor(ColorTheme.getColor('pageBackground'))
                    .borderRadius(10)
                    .textAlign(TextAlign.Start)

                  Row({ space: 4 }) {
                    Text(this.formatTimeString(this.selectedDate))
                      .fontSize(this.getFontSize(16))
                      .fontWeight(FontWeight.Medium)
                      .fontColor(ColorTheme.getColor('textPrimary'))
                    SymbolGlyph($r('sys.symbol.calendar_fill'))
                      .fontSize(this.getFontSize(16))
                      .fontColor([ColorTheme.getColor('textPrimary')])
                  }
                  .height(this.isLandscape ? 40 : 44)
                  .padding({ left: 16, right: 16 })
                  .backgroundColor(ColorTheme.getColor('pageBackground'))
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)

              // 日记内容区域
              Column({ space: 8 }) {
                Text('日记')
                  .fontColor(ColorTheme.getColor('textPrimary'))
                  .fontWeight(FontWeight.Bold)
                  .fontSize(this.getFontSize(18))
                  .width('100%')

                Column() {
                  TextArea({ placeholder: '写下记录文字...', text: this.diaryContent })
                    .width('100%')
                    .layoutWeight(1)
                    .backgroundColor('transparent')
                    .fontColor(ColorTheme.getColor('textPrimary'))
                    .placeholderColor(ColorTheme.getColor('textMuted'))
                    .fontSize(this.getFontSize(16))
                    .maxLength(100)
                    .onChange((value: string) => {
                      this.diaryContent = value;
                      this.contentLength = value.length;
                    })

                  Row({ space: 8 }) {
                    Text(`${this.contentLength}/100`)
                      .fontColor(ColorTheme.getColor('textMuted'))
                      .fontSize(this.getFontSize(13))
                    SymbolGlyph($r('sys.symbol.picture_fill'))
                      .fontSize(this.getFontSize(16))
                      .fontColor([ColorTheme.getColor('textMuted')])
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.End)
                  .padding({ right: 8, bottom: 8 })
                }
                .width('100%')
                .height(this.isLandscape ? 120 : 180)
                .padding(12)
                .borderRadius(12)
                .backgroundColor(ColorTheme.getColor('pageBackground'))
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
            .width(this.getDialogContentWidth())
            .padding({ top: 8, bottom: 16 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)

          // 底部按钮
          Row({ space: 12 }) {
            Text('取消')
              .fontSize(this.getFontSize(15))
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorTheme.getColor('textMuted'))
              .width(90)
              .height(this.isLandscape ? 44 : 48)
              .textAlign(TextAlign.Center)
              .borderRadius(24)
              .backgroundColor(ColorTheme.getColor('cardBackground'))
              .border({ width: 1, color: ColorTheme.getColor('divider') })
              .onClick(() => { this.closeAddDiaryDialog(); })

            Text(this.isSavingDiary ? '保存中...' : '保存')
              .fontSize(this.getFontSize(15))
              .fontWeight(FontWeight.Bold)
              .fontColor('#5D4037')
              .layoutWeight(1)
              .height(this.isLandscape ? 44 : 48)
              .textAlign(TextAlign.Center)
              .borderRadius(24)
              .backgroundColor('#FFE082')
              .onClick(() => { this.handleSaveDiary(); })
          }
          .width(this.getDialogContentWidth())
          .padding({ bottom: 20 })
        }
        .height(this.addDiaryDialogHeight)
        .width(this.getDialogWidth())
        .borderRadius({ topLeft: 32, topRight: 32 })
        .backgroundColor(ColorTheme.getColor('cardBackground'))
        .translate({ y: this.addDiaryDialogOffset })
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {})
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Bottom)
      .onClick(() => { this.closeAddDiaryDialog(); })
    }
    .width('100%')
    .height('100%')
    .position({ left: 0, top: 0 })
    .backgroundColor(`rgba(0, 0, 0, ${this.addDiaryMaskOpacity * 0.5})`)
  }

  /**
   * 构建AI助手对话框
   */
  @Builder
  buildAiAssistantDialog() {
    Stack() {
      // 对话框内容容器
      Stack() {
        Column() {
          // 拖动条
          Stack()
            .height(6)
            .width(48)
            .margin({ top: 16, bottom: 8 })
            .borderRadius(3)
            .backgroundColor(ColorTheme.getColor('divider'))
            .gesture(
              PanGesture()
                .onActionStart((event: GestureEvent) => {
                  this.aiStartY = event.fingerList[0].globalY;
                  this.aiStartHeight = this.aiDialogHeight;
                })
                .onActionUpdate((event: GestureEvent) => {
                  const deltaY = this.aiStartY - event.fingerList[0].globalY;
                  let newHeight = this.aiStartHeight + deltaY;
                  if (deltaY < 0) {
                    newHeight = Math.max(this.minDialogHeight, newHeight);
                  } else {
                    newHeight = Math.max(this.minDialogHeight, Math.min(this.maxDialogHeight, newHeight));
                  }
                  this.aiDialogHeight = newHeight;
                })
                .onActionEnd((event: GestureEvent) => {
                  const deltaY = this.aiStartY - event.fingerList[0].globalY;
                  if (deltaY < 0 && Math.abs(deltaY) > this.maxDialogHeight * 0.60) {
                    this.closeAiDialog();
                  } else {
                    animateTo({ duration: 200 }, () => {
                      this.aiDialogHeight = this.maxDialogHeight;
                    });
                  }
                })
            )

          // 标题
          Text('AI 记忆助手')
            .fontColor(ColorTheme.getColor('textPrimary'))
            .fontWeight(FontWeight.Bold)
            .fontSize(this.getFontSize(18))
            .margin({ top: this.isLandscape ? 8 : 16 })

          // 内容区域
          Stack() {
            if (this.aiMessages.length === 0) {
              // 欢迎界面
              Scroll() {
                Column({ space: this.isLandscape ? 12 : 20 }) {
                  Row({ space: 12 }) {
                    Stack() {
                      Text('迹')
                        .fontColor('#FFE082')
                        .fontWeight(FontWeight.Bold)
                        .fontSize(this.getFontSize(16))
                    }
                    .width(this.isLandscape ? 32 : 38)
                    .height(this.isLandscape ? 32 : 38)
                    .borderRadius(12)
                    .backgroundColor('#5D4037')
                    .alignContent(Alignment.Center)

                    Column() {
                      Text('嗨！我是迹记AI，你的日程记录私人助理，负责帮你查询和管理过往行程。')
                        .fontSize(this.getFontSize(14))
                        .fontColor(ColorTheme.getColor('textPrimary'))
                        .lineHeight(this.getFontSize(20))
                    }
                    .padding(this.isLandscape ? 12 : 16)
                    .backgroundColor(ColorTheme.getColor('cardBackground'))
                    .borderRadius(14)
                    .border({ width: 1, color: ColorTheme.getColor('divider') })
                    .layoutWeight(1)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Top)

                  // 建议列表
                  Column({ space: this.isLandscape ? 8 : 12 }) {
                    ForEach(this.aiSuggestions, (suggestion: string, index: number) => {
                      this.buildAiSuggestion(suggestion, index)
                    })
                  }
                  .width('100%')
                }
                .width(this.getDialogContentWidth())
                .padding({ top: this.isLandscape ? 12 : 20 })
              }
              .scrollBar(BarState.Off)
              .width('100%')
              .height('100%')
              .align(Alignment.Top)
            } else {
              // 聊天列表
              List({ scroller: this.aiScrollController }) {
                ForEach(this.aiMessages, (message: ChatMessage) => {
                  ListItem() {
                    if (message.role === 'user') {
                      Row() {
                        Text(message.content)
                          .fontColor('#5D4037')
                          .fontSize(this.getFontSize(14))
                          .padding(this.isLandscape ? 10 : 12)
                          .backgroundColor('#FFE082')
                          .borderRadius(14)
                          .maxLines(100)
                      }
                      .width('100%')
                      .justifyContent(FlexAlign.End)
                      .padding({ right: 12 })
                    } else {
                      Row({ space: 8 }) {
                        Stack() {
                          Text('迹')
                            .fontColor('#FFE082')
                            .fontSize(this.getFontSize(12))
                            .fontWeight(FontWeight.Bold)
                        }
                        .width(this.isLandscape ? 24 : 28)
                        .height(this.isLandscape ? 24 : 28)
                        .borderRadius(8)
                        .backgroundColor('#5D4037')
                        .alignContent(Alignment.Center)

                        Column({ space: 8 }) {
                          if (message.displayContent !== undefined && message.displayContent !== null && message.displayContent.length > 0) {
                            Text(message.displayContent)
                              .fontColor(ColorTheme.getColor('textPrimary'))
                              .fontSize(this.getFontSize(14))
                              .padding(this.isLandscape ? 10 : 12)
                              .backgroundColor(ColorTheme.getColor('cardBackground'))
                              .borderRadius(14)
                              .border({ width: 1, color: ColorTheme.getColor('divider') })
                              .maxLines(100)
                          } else if (message.content && !message.isTyping) {
                            Text(message.content)
                              .fontColor(ColorTheme.getColor('textPrimary'))
                              .fontSize(this.getFontSize(14))
                              .padding(this.isLandscape ? 10 : 12)
                              .backgroundColor(ColorTheme.getColor('cardBackground'))
                              .borderRadius(14)
                              .border({ width: 1, color: ColorTheme.getColor('divider') })
                              .maxLines(100)
                          } else {
                            Row({ space: 8 }) {
                              Text('思考中')
                                .fontColor(ColorTheme.getColor('textMuted'))
                                .fontSize(this.getFontSize(14))
                              LoadingProgress()
                                .width(16)
                                .height(16)
                                .color(ColorTheme.getColor('textMuted'))
                            }
                            .padding(this.isLandscape ? 10 : 12)
                            .backgroundColor(ColorTheme.getColor('cardBackground'))
                            .borderRadius(14)
                            .border({ width: 1, color: ColorTheme.getColor('divider') })
                          }
                        }
                        .layoutWeight(1)
                        .alignItems(HorizontalAlign.Start)
                      }
                      .width('100%')
                      .alignItems(VerticalAlign.Top)
                      .padding({ left: 12 })
                    }
                  }
                  .margin({ top: this.isLandscape ? 8 : 12 })
                })
              }
              .width(this.getDialogContentWidth())
              .height('100%')
              .padding({ bottom: 12 })
              .scrollBar(BarState.Off)
            }
          }
          .width('100%')
          .layoutWeight(1)
          .margin({ top: this.isLandscape ? 8 : 16 })

          // 底部输入区域
          Column({ space: 6 }) {
            Row({ space: 8 }) {
              TextInput({ placeholder: '请输入您的问题', text: this.aiInputText })
                .onChange((value: string) => { this.aiInputText = value; })
                .layoutWeight(1)
                .backgroundColor('transparent')
                .fontColor(ColorTheme.getColor('textPrimary'))
                .placeholderColor(ColorTheme.getColor('textMuted'))
                .border({ width: 0 })
                .fontSize(this.getFontSize(14))
                .onSubmit(() => { this.handleSendAiMessage(); })

              Stack() {
                SymbolGlyph($r('sys.symbol.paperplane'))
                  .fontSize(this.getFontSize(18))
                  .fontColor(['#5D4037'])
              }
              .width(36)
              .height(36)
              .borderRadius(18)
              .backgroundColor(this.isAiLoading || this.aiInputText.trim().length === 0 ? '#CCCCCC' : '#FFE082')
              .alignContent(Alignment.Center)
              .enabled(!this.isAiLoading && this.aiInputText.trim().length > 0)
              .onClick(() => { this.handleSendAiMessage(); })
            }
            .height(this.isLandscape ? 44 : 48)
            .width('100%')
            .padding({ left: 16, right: 6 })
            .backgroundColor(ColorTheme.getColor('pageBackground'))
            .borderRadius(24)

            Text('AI 助手的答复可能存在错误，请仔细核实')
              .fontSize(this.getFontSize(10))
              .fontColor(ColorTheme.getColor('textMuted'))
              .opacity(0.7)
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          .width(this.getDialogContentWidth())
          .padding({ bottom: this.isLandscape ? 12 : 20 })
        }
        .height(this.aiDialogHeight)
        .width(this.getDialogWidth())
        .borderRadius({ topLeft: 32, topRight: 32 })
        .backgroundColor(ColorTheme.getColor('cardBackground'))
        .translate({ y: this.aiDialogOffset })
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {})
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Bottom)
      .onClick(() => { this.closeAiDialog(); })
    }
    .width('100%')
    .height('100%')
    .position({ left: 0, top: 0 })
    .backgroundColor(`rgba(0, 0, 0, ${this.aiMaskOpacity * 0.5})`)
  }

  @Builder
  buildAiSuggestion(text: string, index: number) {
    Row({ space: 10 }) {
      Stack() {
        SymbolGlyph($r('sys.symbol.lightbulb'))
          .fontSize(this.getFontSize(16))
          .fontColor([ColorTheme.getColor('textPrimary')])
      }
      .width(this.isLandscape ? 28 : 32)
      .height(this.isLandscape ? 28 : 32)
      .borderRadius(14)
      .backgroundColor(ColorTheme.getColor('pageBackground'))
      .alignContent(Alignment.Center)

      Text(text)
        .fontSize(this.getFontSize(13))
        .fontWeight(FontWeight.Medium)
        .fontColor(ColorTheme.getColor('textPrimary'))
        .layoutWeight(1)
    }
    .width('100%')
    .padding(this.isLandscape ? 10 : 12)
    .backgroundColor(ColorTheme.getColor('cardBackground'))
    .borderRadius(10)
    .border({ width: 1, color: ColorTheme.getColor('divider') })
    .onClick(() => {
      this.aiInputText = text;
      this.handleSendAiMessage();
    })
  }

  // 日记相关方法
  closeAddDiaryDialog() {
    animateTo({ duration: 250, curve: Curve.EaseIn }, () => {
      this.addDiaryDialogOffset = 1000;
      this.addDiaryMaskOpacity = 0;  // 同时淡出蒙版
    });
    setTimeout(() => {
      this.showAddDiaryDialog = false;
      this.resetDiaryForm();
      this.addDiaryDialogOffset = 0;
      this.addDiaryMaskOpacity = 0;
    }, 250);
  }

  async handleSaveDiary() {
    if (!this.diaryLocation.trim()) {
      promptAction.showToast({ message: '请输入地点' });
      return;
    }

    if (this.isSavingDiary) {
      return;
    }

    this.isSavingDiary = true;

    try {
      const user = await UserStorage.getUser();
      if (!user) {
        promptAction.showToast({ message: '请先登录' });
        return;
      }

      const diary: Diary = {
        uuid: UuidUtil.generate(),
        user_id: user.id,
        title: this.diaryLocation,
        content: this.diaryContent,
        location: this.diaryLocation,
        address: this.diaryAddress || undefined,  // 添加完整地址
        latitude: this.diaryLatitude || undefined,
        longitude: this.diaryLongitude || undefined,
        is_public: false,
        synced: false,
        created_at: this.selectedDate.toISOString()
      };

      const result = await DiarySyncManager.createAndSync(user.id, diary);

      if (result.success) {
        promptAction.showToast({ message: result.message });
        this.closeAddDiaryDialog();
        await this.loadDiaries();
      } else {
        promptAction.showToast({ message: result.message });
      }
    } catch (error) {
      console.error('[Index] 保存失败:', error);
      promptAction.showToast({ message: '保存失败，请重试' });
    } finally {
      this.isSavingDiary = false;
    }
  }

  resetDiaryForm() {
    this.diaryLocation = '';
    this.diaryAddress = '';  // 重置地址
    this.diaryLatitude = 0;
    this.diaryLongitude = 0;
    this.diaryContent = '';
    this.contentLength = 0;
    this.selectedDate = new Date();
  }

  /**
   * 确保定位能力仅在用户同意隐私且主动触发时初始化/申请
   */
  async ensureLocationReady(): Promise<boolean> {
    if (!this.privacyAgreed) {
      promptAction.showToast({ message: '请先同意隐私政策后再定位' });
      return false;
    }

    if (!this.locationManager) {
      const context = getContext(this) as common.UIAbilityContext;
      this.locationManager = LocationManager.getInstance(context);
    }

    return true;
  }

  /**
   * 自动获取定位（静默，无提示）
   */
  async autoGetLocation() {
    if (!this.privacyAgreed) {
      console.warn('[Index] 未同意隐私政策，禁止自动定位');
      return;
    }

    // 确保定位管理器已初始化
    if (!this.locationManager) {
      const context = getContext(this) as common.UIAbilityContext;
      this.locationManager = LocationManager.getInstance(context);
    }

    if (this.isGettingLocation) {
      return;
    }

    this.isGettingLocation = true;

    try {
      if (!this.locationManager) {
        console.error('[Index] 定位服务未初始化');
        return;
      }

      const location: LocationResult = await this.locationManager.getCurrentLocation();
      
      // 保存经纬度
      this.diaryLatitude = location.latitude;
      this.diaryLongitude = location.longitude;
      
      // 保存完整地址
      this.diaryAddress = location.address || '';
      
      // 优先使用POI名称，其次使用完整地址
      if (location.poiName && location.poiName.trim().length > 0) {
        this.diaryLocation = location.poiName;
      } else if (location.address && location.address.trim().length > 0) {
        this.diaryLocation = location.address;
      } else {
        // 如果没有地址，显示经纬度
        this.diaryLocation = `经度: ${location.longitude.toFixed(6)}, 纬度: ${location.latitude.toFixed(6)}`;
      }

      console.info('[Index] 自动定位成功:', JSON.stringify(location));
    } catch (error) {
      console.error('[Index] 自动定位失败:', error);
      // 静默失败，不显示提示
    } finally {
      this.isGettingLocation = false;
    }
  }

  /**
   * 手动获取当前位置（点击定位按钮）
   */
  async handleGetLocation() {
    if (!(await this.ensureLocationReady())) {
      return;
    }

    if (this.isGettingLocation) {
      return;
    }

    this.isGettingLocation = true;

    try {
      if (!this.locationManager) {
        promptAction.showToast({ message: '定位服务未初始化' });
        return;
      }

      promptAction.showToast({ message: '正在定位，请稍候...' });
      
      const location: LocationResult = await this.locationManager.getCurrentLocation();
      
      // 保存经纬度
      this.diaryLatitude = location.latitude;
      this.diaryLongitude = location.longitude;
      
      // 保存完整地址
      this.diaryAddress = location.address || '';
      
      // 优先使用POI名称，其次使用完整地址
      if (location.poiName && location.poiName.trim().length > 0) {
        this.diaryLocation = location.poiName;
        promptAction.showToast({ 
          message: `定位成功: ${location.poiName}\n精度: ${location.accuracy.toFixed(0)}米`,
          duration: 2000
        });
      } else if (location.address && location.address.trim().length > 0) {
        this.diaryLocation = location.address;
        promptAction.showToast({ 
          message: `定位成功\n精度: ${location.accuracy.toFixed(0)}米`,
          duration: 2000
        });
      } else {
        // 如果没有地址，显示经纬度
        this.diaryLocation = `经度: ${location.longitude.toFixed(6)}, 纬度: ${location.latitude.toFixed(6)}`;
        promptAction.showToast({ 
          message: `定位成功（仅坐标）\n精度: ${location.accuracy.toFixed(0)}米`,
          duration: 2000
        });
      }

      console.info('[Index] 定位结果:', JSON.stringify(location));
    } catch (error) {
      console.error('[Index] 定位失败:', error);
      const errorMsg = error instanceof Error ? error.message : '定位失败，请检查定位权限和网络';
      promptAction.showToast({ 
        message: errorMsg,
        duration: 3000
      });
    } finally {
      this.isGettingLocation = false;
    }
  }

  formatDateString(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}年${month}月${day}日`;
  }

  formatTimeString(date: Date): string {
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  // AI助手相关方法
  closeAiDialog() {
    // 清除打字机定时器
    if (this.typingIntervalId) {
      clearInterval(this.typingIntervalId);
      this.typingIntervalId = undefined;
    }
    animateTo({ duration: 250, curve: Curve.EaseIn }, () => {
      this.aiDialogOffset = 1000;
      this.aiMaskOpacity = 0;  // 同时淡出蒙版
    });
    setTimeout(() => {
      this.showAiDialog = false;
      this.resetAiForm();
      this.aiDialogOffset = 0;
      this.aiMaskOpacity = 0;
    }, 250);
  }

  // 打字机效果
  startTypingEffect(messageIndex: number, fullText: string) {
    // 清除之前的定时器
    if (this.typingIntervalId) {
      clearInterval(this.typingIntervalId);
      this.typingIntervalId = undefined;
    }

    // 检查参数有效性
    if (messageIndex < 0 || messageIndex >= this.aiMessages.length) {
      console.error('[Index] 打字机效果：无效的消息索引', messageIndex);
      return;
    }

    if (!fullText || typeof fullText !== 'string') {
      console.error('[Index] 打字机效果：无效的文本内容', fullText);
      if (messageIndex < this.aiMessages.length) {
        this.aiMessages[messageIndex].content = '抱歉，内容显示异常。';
        this.aiMessages[messageIndex].isTyping = false;
        this.aiMessages = [...this.aiMessages];
      }
      return;
    }

    let position = 0;
    const speed = 50; // 每个字符显示间隔（毫秒）

    this.typingIntervalId = setInterval(() => {
      try {
        position += 2; // 每次显示2个字符
        const displayText = fullText.substring(0, position);

        if (messageIndex < this.aiMessages.length) {
          this.aiMessages[messageIndex].displayContent = displayText;
          this.aiMessages[messageIndex].isTyping = true;
          this.aiMessages = [...this.aiMessages]; // 触发UI更新

          // 使用nextTick确保UI更新后再滚动
          setTimeout(() => {
            try {
              if (this.aiScrollController) {
                this.aiScrollController.scrollEdge(Edge.Bottom);
              }
            } catch (e) {
              console.error('[Index] 打字机滚动失败:', e);
            }
          }, 10);
        }

        if (position >= fullText.length) {
          if (this.typingIntervalId) {
            clearInterval(this.typingIntervalId);
            this.typingIntervalId = undefined;
          }

          if (messageIndex < this.aiMessages.length) {
            this.aiMessages[messageIndex].isTyping = false;
            this.aiMessages[messageIndex].displayContent = fullText;
            this.aiMessages = [...this.aiMessages];

            // 打字完成后再次确保滚动到底部
            setTimeout(() => {
              try {
                if (this.aiScrollController) {
                  this.aiScrollController.scrollEdge(Edge.Bottom);
                }
              } catch (e) {
                console.error('[Index] 打字机完成滚动失败:', e);
              }
            }, 10);
          }
        }
      } catch (error) {
        console.error('[Index] 打字机效果执行出错:', error);
        if (this.typingIntervalId) {
          clearInterval(this.typingIntervalId);
          this.typingIntervalId = undefined;
        }
        if (messageIndex < this.aiMessages.length) {
          this.aiMessages[messageIndex].isTyping = false;
          this.aiMessages[messageIndex].displayContent = fullText;
          this.aiMessages = [...this.aiMessages];
        }
      }
    }, speed);
  }

  async handleSendAiMessage() {
    if (this.aiInputText.trim().length === 0 || this.isAiLoading) {
      return;
    }

    // 检查消息数组状态
    if (!this.aiMessages) {
      console.error('[Index] aiMessages未初始化');
      return;
    }

    const userMessage = this.aiInputText.trim();
    this.aiInputText = '';

    this.aiMessages.push({
      role: 'user',
      content: userMessage,
      timestamp: Date.now()
    });

    const aiMessageIndex = this.aiMessages.length;
    this.aiMessages.push({
      role: 'assistant',
      content: '',
      timestamp: Date.now()
    });

    // 确保UI更新后再滚动
    setTimeout(() => {
      try {
        if (this.aiScrollController) {
          this.aiScrollController.scrollEdge(Edge.Bottom);
        }
      } catch (e) {
        console.error('[Index] 发送消息滚动失败:', e);
      }
    }, 100);

    this.isAiLoading = true;

    try {
      await this.sendAiRequest(userMessage, aiMessageIndex);
    } catch (error) {
      console.error('[Index] AI请求失败:', error);
      // 错误已在sendAiRequest中处理，这里不需要额外处理
    } finally {
      this.isAiLoading = false;
      // 确保最终滚动到底部
      setTimeout(() => {
        try {
          if (this.aiScrollController) {
            this.aiScrollController.scrollEdge(Edge.Bottom);
          }
        } catch (e) {
          console.error('[Index] 最终滚动失败:', e);
        }
      }, 100);
    }
  }

  async sendAiRequest(userMessage: string, messageIndex: number) {
    const httpRequest = http.createHttp();
    const url = 'https://note.luozhinet.com/api.php';

    const history: Array<Record<string, string>> = [];
    for (let i = 0; i < messageIndex; i++) {
      const msg = this.aiMessages[i];
      history.push({
        'role': msg.role,
        'content': msg.content
      });
    }

    const requestData: Record<string, Object> = {
      'action': 'ai_chat',
      'user_id': this.currentUserId,
      'message': userMessage,
      'history': history
    };

    return new Promise<void>((resolve, reject) => {
      httpRequest.request(
        url,
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: JSON.stringify(requestData),
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 60000,
          readTimeout: 60000,
        },
        (err, data) => {
          try {
            // 检查消息索引是否有效
            if (messageIndex >= this.aiMessages.length || messageIndex < 0) {
              console.error('[Index] 消息索引无效:', messageIndex, '数组长度:', this.aiMessages.length);
              if (this.aiMessages.length > 0) {
                this.aiMessages[this.aiMessages.length - 1].content = '抱歉，系统内部错误，请重试。';
                this.aiMessages = [...this.aiMessages];
              }
              reject(new Error('Invalid message index'));
              return;
            }

            if (!err && data.responseCode === 200) {
              let response: Record<string, ESObject>;
              try {
                // 添加JSON解析的安全检查
                if (!data.result || typeof data.result !== 'string') {
                  throw new Error('Invalid response data');
                }
                response = JSON.parse(data.result as string) as Record<string, ESObject>;
              } catch (parseError) {
                console.error('[Index] JSON解析失败:', parseError, '原始数据:', data.result);
                this.aiMessages[messageIndex].content = '抱歉，服务响应格式错误，请稍后重试。';
                this.aiMessages = [...this.aiMessages];
                reject(parseError);
                return;
              }

              if (response['success']) {
                const responseData: Record<string, ESObject> = response['data'] as Record<string, ESObject>;
                const reply: string = responseData['reply'] as string;

                // 检查reply是否为有效字符串
                if (typeof reply !== 'string' || reply.trim().length === 0) {
                  console.error('[Index] 无效的回复内容:', reply);
                  this.aiMessages[messageIndex].content = '抱歉，AI回复内容为空。';
                  this.aiMessages = [...this.aiMessages];
                  reject(new Error('Empty reply'));
                  return;
                }

                // 立即设置完整内容和空的显示内容，然后启动打字机效果
                this.aiMessages[messageIndex].content = reply;
                this.aiMessages[messageIndex].displayContent = '';
                this.aiMessages[messageIndex].isTyping = true;
                this.aiMessages = [...this.aiMessages];

                // 立即启动打字机效果
                setTimeout(() => {
                  try {
                    this.aiScrollController.scrollEdge(Edge.Bottom);
                  } catch (scrollError) {
                    console.error('[Index] 滚动失败:', scrollError);
                  }
                  this.startTypingEffect(messageIndex, reply);
                }, 50);
                resolve();
              } else {
                const errorMsg = (response['message'] as string) || '服务暂时不可用';
                console.error('[Index] AI服务错误:', errorMsg);
                this.aiMessages[messageIndex].content = '抱歉，' + errorMsg;
                this.aiMessages = [...this.aiMessages];
                reject(new Error(errorMsg));
              }
            } else {
              const errorMessage = err ? `网络错误: ${err.message || err}` : `HTTP错误: ${data.responseCode}`;
              console.error('[Index] AI请求失败:', errorMessage);
              this.aiMessages[messageIndex].content = '抱歉，网络连接失败，请检查网络后重试。';
              this.aiMessages = [...this.aiMessages];
              reject(new Error(errorMessage));
            }
          } catch (unexpectedError) {
            console.error('[Index] AI请求处理中发生意外错误:', unexpectedError);
            if (messageIndex < this.aiMessages.length) {
              this.aiMessages[messageIndex].content = '抱歉，系统发生意外错误，请重试。';
              this.aiMessages = [...this.aiMessages];
            }
            reject(unexpectedError);
          } finally {
            httpRequest.destroy();
          }
        }
      );
    });
  }

  resetAiForm() {
    this.aiInputText = '';
    this.aiMessages = [];
  }

  pageTransition() {
    PageTransitionExit({})
    PageTransitionEnter({})
  }
}