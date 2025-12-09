import { router, display } from '@kit.ArkUI';
import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter";
import { ColorTheme } from "../utils/colorTheme";
import { Diary } from '../model/DiaryModel';
import promptAction from '@ohos.promptAction';
import {
  AMap,
  CameraPosition,
  CameraUpdateFactory,
  LatLng,
  MapView,
  MapViewComponent,
  MapViewManager,
  MapViewCreateCallback,
  Marker,
  MarkerOptions
} from '@amap/amap_lbs_map3d';
import { mapHelper } from '../utils/MapHelper';
const MAP_VIEW_NAME = "MapDiaryDetail";

screenAdapter.designWidth = 375;

@Entry
@Component
export struct MapDiaryDetail {
  @State @Watch('onDiaryChange') selectedDiary?: Diary = undefined;
  @State selectedLocationDiaries: Diary[] = [];
  @State currentIndex: number = 0;
  private mapView?: MapView;
  private aMap?: AMap;
  // 响应式布局
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint();
  @State isLandscape: boolean = isCurrentLandscape();
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  onDiaryChange() {
    // 当日记变化时，更新地图位置
    if (this.aMap && this.selectedDiary) {
      try {
        // 使用MapHelper清除地图
        mapHelper.clearMap(this.aMap);
        
        // 使用MapHelper添加单个日记标记并调整视角
        const diaryArray = [this.selectedDiary];
        const markerCount = mapHelper.addDiaryMarkersIndividual(this.aMap, diaryArray);
        
        if (markerCount > 0) {
          mapHelper.fitMapToDiaries(this.aMap, diaryArray, true);
        }
        
        console.info('[MapDiaryDetail] 地图已更新到新日记位置');
      } catch (error) {
        console.error('[MapDiaryDetail] 更新地图失败:', error);
      }
    }
  }

  aboutToAppear() {
    // 注册断点监听
    this.breakpointSystem.register((bp: BreakpointType) => {
      this.currentBreakpoint = bp;
      this.isLandscape = isCurrentLandscape();
    });
    display.on('change', () => {
      screenAdapter.updateScreenSize();
      this.currentBreakpoint = getCurrentBreakpoint();
      this.isLandscape = isCurrentLandscape();
    });

    // 初始化高德地图（使用统一的MapHelper）
    mapHelper.initializeMapSDK(getContext(this));

    // 获取路由参数
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.selectedDiary = params['diary'] as Diary;
      this.selectedLocationDiaries = params['locationDiaries'] as Diary[] || [];
      this.currentIndex = params['currentIndex'] as number || 0;
    }

    // 注册地图视图
    MapViewManager.getInstance().registerMapViewCreatedCallback(this.mapViewCreateCallback);
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
    display.off('change');
    if (this.mapView) {
      this.mapView.onDestroy();
    }
    MapViewManager.getInstance().unregisterMapViewCreatedCallback(this.mapViewCreateCallback);
  }

  // 响应式尺寸方法
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
      case 'xs': return '100%';
      case 'sm': return '100%';
      case 'md': return '80%';
      case 'lg': return '60%';
      default: return '100%';
    }
  }

  private mapViewCreateCallback: MapViewCreateCallback = (mapview?: MapView, mapViewName?: string) => {
    if (!mapview || mapViewName !== MAP_VIEW_NAME) {
      return;
    }

    this.mapView = mapview;
    this.mapView.onCreate();
    this.mapView.getMapAsync(async (map) => {
      this.aMap = map;
      if (this.aMap) {
        // 配置地图UI（详情页允许手势操作）
        mapHelper.configureMapUI(this.aMap, {
          disableGestures: false,
          showZoomControls: true,
          showScaleControls: false,
          showCompass: false
        });

        if (this.selectedDiary) {
          try {
            // 使用MapHelper添加日记标记
            const diaryArray = [this.selectedDiary];
            const markerCount = mapHelper.addDiaryMarkersIndividual(this.aMap, diaryArray);
            
            if (markerCount > 0) {
              mapHelper.fitMapToDiaries(this.aMap, diaryArray, false);
            }
            
            console.info('[MapDiaryDetail] 地图初始化完成');
          } catch (error) {
            console.error('[MapDiaryDetail] 初始化地图失败:', error);
          }
        }
      }
    });
  };

  build() {
    Column() {
      // 顶部导航栏 - 响应式
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(this.getFontSize(24))
          .fontColor([ColorTheme.getColor('textPrimary')])
          .onClick(() => {
            router.back();
          })

        Text('日记详情')
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

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
          // 地图区域
          Stack() {
            MapViewComponent({ mapViewName: MAP_VIEW_NAME })
              .width('100%')
              .height('100%')

            // 地图上的位置标签
            if (this.selectedDiary?.location) {
              Row({ space: 4 }) {
                SymbolGlyph($r('sys.symbol.local_fill'))
                  .fontSize(this.getFontSize(14))
                  .fontColor([ColorTheme.getColor('textPrimary')])
                Text(this.selectedDiary.location)
                  .fontSize(this.getFontSize(14))
                  .fontColor(ColorTheme.getColor('textPrimary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor(ColorTheme.getColor('cardBackground'))
              .borderRadius(20)
              .position({ x: 16, y: 16 })
            }
          }
          .width('100%')
          .height(this.currentBreakpoint === 'lg' ? 280 : 200)
          .borderRadius(16)
          .clip(true)

          // 日记信息卡片
          Column({ space: this.getSpacing() }) {
            // 标题和日期
            Column({ space: 8 }) {
              if (this.selectedDiary?.title) {
                Text(this.selectedDiary.title)
                  .fontSize(this.getFontSize(20))
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ColorTheme.getColor('textPrimary'))
                  .width('100%')
              }

              Row({ space: 8 }) {
                SymbolGlyph($r('sys.symbol.calendar'))
                  .fontSize(this.getFontSize(14))
                  .fontColor([ColorTheme.getColor('textMuted')])
                Text(this.selectedDiary?.created_at || '')
                  .fontSize(this.getFontSize(14))
                  .fontColor(ColorTheme.getColor('textMuted'))
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')

            Divider()
              .color(ColorTheme.getColor('divider'))

            // 内容
            if (this.selectedDiary?.content) {
              Text(this.selectedDiary.content)
                .fontSize(this.getFontSize(16))
                .fontColor(ColorTheme.getColor('textPrimary'))
                .lineHeight(this.getFontSize(26))
                .width('100%')
            } else {
              Text('暂无内容')
                .fontSize(this.getFontSize(16))
                .fontColor(ColorTheme.getColor('textMuted'))
                .fontStyle(FontStyle.Italic)
            }

            // 坐标信息
            Row({ space: 8 }) {
              SymbolGlyph($r('sys.symbol.local_fill'))
                .fontSize(this.getFontSize(14))
                .fontColor([ColorTheme.getColor('textMuted')])
              Text(`${this.selectedDiary?.latitude || 0}, ${this.selectedDiary?.longitude || 0}`)
                .fontSize(this.getFontSize(14))
                .fontColor(ColorTheme.getColor('textMuted'))
            }
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor(ColorTheme.getColor('pageBackground'))
            .borderRadius(8)
          }
          .padding(this.getSpacing())
          .backgroundColor(ColorTheme.getColor('cardBackground'))
          .borderRadius(16)

          // 切换按钮（如果有多条日记）
          if (this.selectedLocationDiaries.length > 1) {
            Row({ space: 12 }) {
              // 上一条
              Row({ space: 8 }) {
                SymbolGlyph($r('sys.symbol.chevron_left'))
                  .fontSize(this.getFontSize(18))
                  .fontColor([ColorTheme.getColor('textPrimary')])
                  .opacity(this.currentIndex > 0 ? 1 : 0.4)
                Text('上一条')
                  .fontSize(this.getFontSize(16))
                  .fontColor(ColorTheme.getColor('textPrimary'))
                  .opacity(this.currentIndex > 0 ? 1 : 0.4)
              }
              .layoutWeight(1)
              .height(this.currentBreakpoint === 'xs' ? 44 : 48)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(ColorTheme.getColor('cardBackground'))
              .borderRadius(12)
              .onClick(() => {
                if (this.currentIndex > 0) {
                  this.currentIndex--;
                  this.selectedDiary = this.selectedLocationDiaries[this.currentIndex];
                }
              })

              // 计数
              Text(`${this.currentIndex + 1}/${this.selectedLocationDiaries.length}`)
                .fontSize(this.getFontSize(16))
                .fontColor(ColorTheme.getColor('textPrimary'))
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .backgroundColor(ColorTheme.getColor('buttonPrimaryBg'))
                .borderRadius(12)

              // 下一条
              Row({ space: 8 }) {
                Text('下一条')
                  .fontSize(this.getFontSize(16))
                  .fontColor(ColorTheme.getColor('textPrimary'))
                  .opacity(this.currentIndex < this.selectedLocationDiaries.length - 1 ? 1 : 0.4)
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontSize(this.getFontSize(18))
                  .fontColor([ColorTheme.getColor('textPrimary')])
                  .opacity(this.currentIndex < this.selectedLocationDiaries.length - 1 ? 1 : 0.4)
              }
              .layoutWeight(1)
              .height(this.currentBreakpoint === 'xs' ? 44 : 48)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(ColorTheme.getColor('cardBackground'))
              .borderRadius(12)
              .onClick(() => {
                if (this.currentIndex < this.selectedLocationDiaries.length - 1) {
                  this.currentIndex++;
                  this.selectedDiary = this.selectedLocationDiaries[this.currentIndex];
                }
              })
            }
            .width('100%')
          }

          // 编辑按钮
          Button('编辑日记')
            .width('100%')
            .height(this.currentBreakpoint === 'xs' ? 44 : 48)
            .fontSize(this.getFontSize(16))
            .fontColor(ColorTheme.getColor('textPrimary'))
            .backgroundColor(ColorTheme.getColor('buttonPrimaryBg'))
            .borderRadius(12)
            .onClick(() => {
              if (this.selectedDiary) {
                router.pushUrl({
                  url: 'pages/DiaryEdit',
                  params: {
                    diaryId: this.selectedDiary.id || this.selectedDiary.local_id
                  }
                }).catch((err: Error) => {
                  console.error('[MapDiaryDetail] 跳转编辑页失败:', err);
                  promptAction.showToast({ message: '打开编辑页失败' });
                });
              }
            })
        }
        .width(this.getContentWidth())
        .padding(this.getSpacing())
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ColorTheme.getColor('pageBackground'))
  }
}
