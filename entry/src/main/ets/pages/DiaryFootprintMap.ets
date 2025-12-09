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
  MarkerOptions,
  BitmapDescriptorFactory,
  OnCameraChangeListener
} from '@amap/amap_lbs_map3d';
import { router, display } from '@kit.ArkUI';
import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter";
import { ColorTheme } from "../utils/colorTheme";
import { Diary } from '../model/DiaryModel';
import { DiaryStorage } from '../utils/DiaryStorage';
import promptAction from '@ohos.promptAction';
import { mapHelper, ClusterLevel, ClusterMarkerInfo } from '../utils/MapHelper';
const MAP_VIEW_NAME = "DiaryFootprintMap";

screenAdapter.designWidth = 375;

@Entry
@Component
export struct DiaryFootprintMap {
  private mapView?: MapView;
  private aMap?: AMap;
  @State diaries: Diary[] = [];
  @State isLoading: boolean = false;
  @State showTip: boolean = true;
  @State selectedLocation: string = '';
  @State selectedDiaryCount: number = 0;
  @State showLocationCard: boolean = false;
  // 聚合相关状态
  @State currentClusterLevel: ClusterLevel = ClusterLevel.LOCATION;
  @State currentClusters: ClusterMarkerInfo[] = [];
  @State selectedCluster: ClusterMarkerInfo | null = null;
  private lastZoom: number = 5.0;
  // 响应式布局
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint();
  @State isLandscape: boolean = isCurrentLandscape();
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  async onPageShow() {
    await this.loadDiaries();
  }

  async aboutToAppear() {
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

    // 注册地图视图
    MapViewManager.getInstance().registerMapViewCreatedCallback(this.mapViewCreateCallback);

    await this.loadDiaries();
  }

  aboutToDisappear() {
    // 注销断点监听
    this.breakpointSystem.unregister();
    display.off('change');
    // 销毁地图
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

  getCardWidth(): string {
    switch (this.currentBreakpoint) {
      case 'xs': return '92%';
      case 'sm': return '90%';
      case 'md': return '70%';
      case 'lg': return '50%';
      default: return '90%';
    }
  }

  async loadDiaries() {
    this.isLoading = true;
    try {
      const allDiaries = await DiaryStorage.getDiaries();
      // 只加载有经纬度的日记（使用MapHelper过滤）
      this.diaries = mapHelper.filterDiariesWithLocation(allDiaries);
      console.info('[DiaryFootprintMap] 加载了', this.diaries.length, '条有位置的日记');
    } catch (error) {
      console.error('[DiaryFootprintMap] 加载日记失败:', error);
      promptAction.showToast({ message: '加载日记失败' });
    } finally {
      this.isLoading = false;
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
        // 配置地图UI（足迹地图允许手势操作）
        mapHelper.configureMapUI(this.aMap, {
          disableGestures: false,
          showZoomControls: true,
          showScaleControls: true,
          showCompass: false
        });

        // 添加标记点击监听器
        this.aMap.setOnMarkerClickListener((marker: Marker) => {
          console.info('[DiaryFootprintMap] 标记被点击:', marker.getTitle());
          this.handleMarkerClick(marker);
          return true; // 返回 true 表示消费了点击事件
        });

        // 添加相机变化监听器，用于动态更新聚合级别
        this.aMap.setOnCameraChangeListener(new OnCameraChangeListener(
          (cameraPosition: CameraPosition) => {
            // 相机移动中，不做处理
          },
          (cameraPosition: CameraPosition) => {
            const newZoom = cameraPosition.zoom || 5.0;
            const newLevel = mapHelper.getClusterLevelByZoom(newZoom);
            
            // 只有当聚合级别变化时才重新渲染标记
            if (newLevel !== this.currentClusterLevel) {
              console.info(`[DiaryFootprintMap] 缩放级别变化: ${this.lastZoom.toFixed(1)} -> ${newZoom.toFixed(1)}, 聚合级别: ${this.currentClusterLevel} -> ${newLevel}`);
              this.currentClusterLevel = newLevel;
              this.lastZoom = newZoom;
              this.updateClusterMarkers();
            }
          }
        ));

        // 添加所有日记标记
        await this.addDiaryMarkers();
      }
    });
  };

  /**
   * 处理标记点击事件
   */
  handleMarkerClick(marker: Marker) {
    const title = marker.getTitle();
    
    // 在当前聚合列表中查找对应的聚合
    const cluster = this.currentClusters.find(c => c.name === title);
    
    if (cluster) {
      this.selectedCluster = cluster;
      this.selectedLocation = cluster.name;
      this.selectedDiaryCount = cluster.count;
      this.showLocationCard = true;
      console.info(`[DiaryFootprintMap] 显示${this.getLevelText(cluster.level)}信息:`, title, '共', cluster.count, '条');
    } else {
      // 回退到旧逻辑：按地点名称查找
      const locationDiaries = this.diaries.filter(d => d.location === title);
      if (locationDiaries.length > 0) {
        this.selectedCluster = {
          level: ClusterLevel.LOCATION,
          name: title,
          diaries: locationDiaries,
          centerLat: 0,
          centerLng: 0,
          count: locationDiaries.length
        };
        this.selectedLocation = title;
        this.selectedDiaryCount = locationDiaries.length;
        this.showLocationCard = true;
      } else {
        console.warn('[DiaryFootprintMap] 未找到对应的日记:', title);
      }
    }
  }

  /**
   * 获取聚合级别文本
   */
  getLevelText(level: ClusterLevel): string {
    switch (level) {
      case ClusterLevel.PROVINCE:
        return '省份';
      case ClusterLevel.CITY:
        return '城市';
      case ClusterLevel.DISTRICT:
        return '区县';
      default:
        return '地点';
    }
  }

  /**
   * 查看选中地点的日记详情
   */
  viewLocationDiaries() {
    if (!this.selectedCluster || this.selectedCluster.diaries.length === 0) {
      console.warn('[DiaryFootprintMap] 没有选中的日记');
      return;
    }

    const clusterDiaries = this.selectedCluster.diaries;
    console.info(`[DiaryFootprintMap] 跳转到${this.getLevelText(this.selectedCluster.level)}日记详情:`, this.selectedLocation, '共', clusterDiaries.length, '条');
    
    router.pushUrl({
      url: 'pages/MapDiaryDetail',
      params: {
        diary: clusterDiaries[0],
        locationDiaries: clusterDiaries,
        currentIndex: 0
      }
    }).catch((err: Error) => {
      console.error('[DiaryFootprintMap] 跳转失败:', err);
      promptAction.showToast({ message: '打开日记详情失败' });
    });
  }

  /**
   * 更新聚合标记
   */
  updateClusterMarkers() {
    if (!this.aMap || this.diaries.length === 0) {
      return;
    }

    // 清除现有标记
    mapHelper.clearMap(this.aMap);

    // 根据当前聚合级别分组日记
    this.currentClusters = mapHelper.clusterDiaries(this.diaries, this.currentClusterLevel);

    // 添加聚合标记
    const markerCount = mapHelper.addClusterMarkers(this.aMap, this.currentClusters);
    console.info(`[DiaryFootprintMap] 更新聚合标记: level=${this.currentClusterLevel}, 标记数=${markerCount}`);

    // 关闭当前显示的卡片
    this.showLocationCard = false;
    this.selectedCluster = null;
  }


  async addDiaryMarkers() {
    if (!this.aMap) {
      console.error('[DiaryFootprintMap] 地图未初始化');
      return;
    }

    if (this.diaries.length === 0) {
      console.warn('[DiaryFootprintMap] 没有日记数据');
      // 没有数据时显示默认视角
      mapHelper.fitMapToDiaries(this.aMap, [], false);
      return;
    }

    console.info('[DiaryFootprintMap] 开始添加标记，共', this.diaries.length, '条日记');

    // 计算初始聚合级别（根据日记分布范围）
    const bounds = mapHelper.calculateBounds(this.diaries);
    if (bounds) {
      const initialZoom = mapHelper.calculateZoomLevel(bounds);
      this.lastZoom = initialZoom;
      this.currentClusterLevel = mapHelper.getClusterLevelByZoom(initialZoom);
    }

    // 清除现有标记
    mapHelper.clearMap(this.aMap);

    // 根据当前聚合级别分组日记
    this.currentClusters = mapHelper.clusterDiaries(this.diaries, this.currentClusterLevel);

    // 添加聚合标记
    const markerCount = mapHelper.addClusterMarkers(this.aMap, this.currentClusters);

    console.info(`[DiaryFootprintMap] 成功添加 ${markerCount} 个聚合标记, 级别: ${this.currentClusterLevel}`);

    // 调整地图视角以显示所有标记
    if (markerCount > 0) {
      setTimeout(() => {
        if (this.aMap) {
          mapHelper.fitMapToDiaries(this.aMap, this.diaries, true);
          console.info('[DiaryFootprintMap] 地图视角调整完成');
        }
      }, 500);
    }
  }

  build() {
    Stack() {
      // 地图视图
      MapViewComponent({ mapViewName: MAP_VIEW_NAME })
        .width('100%')
        .height('100%')

      // 顶部导航栏 - 响应式
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(this.getFontSize(24))
          .fontColor([ColorTheme.getColor('textPrimary')])
          .onClick(() => {
            router.back();
          })

        Text('足迹地图')
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 统计信息（右侧）
        Row() {
          Text(`${this.diaries.length}个足迹`)
            .fontSize(this.getFontSize(12))
            .fontColor(ColorTheme.getColor('textMuted'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(ColorTheme.getColor('cardBackground'))
            .borderRadius(12)
        }
        .width(this.getFontSize(80))
        .justifyContent(FlexAlign.End)
      }
      .width('100%')
      .height(this.getNavBarHeight())
      .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 44 })
      .backgroundColor(ColorTheme.getColor('cardBackground'))
      .position({ x: 0, y: 0 })
      .zIndex(10)

      // 加载指示器
      if (this.isLoading) {
        LoadingProgress()
          .width(this.getFontSize(40))
          .height(this.getFontSize(40))
          .color(ColorTheme.getColor('textPrimary'))
      }

      // 空状态提示
      if (!this.isLoading && this.diaries.length === 0) {
        Column({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.map'))
            .fontSize(this.getFontSize(48))
            .fontColor([ColorTheme.getColor('textMuted')])
          Text('暂无足迹记录')
            .fontSize(this.getFontSize(14))
            .fontColor(ColorTheme.getColor('textMuted'))
          Text('创建日记时会自动记录位置')
            .fontSize(this.getFontSize(12))
            .fontColor(ColorTheme.getColor('textMuted'))
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(ColorTheme.getColor('pageBackground'))
      }

      // 地点信息卡片 - 响应式
      if (this.showLocationCard && this.selectedLocation) {
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            // 地点图标
            Stack() {
              SymbolGlyph($r('sys.symbol.local_fill'))
                .fontSize(this.getFontSize(24))
                .fontColor(['#FF6B6B'])
            }
            .width(this.getFontSize(40))
            .height(this.getFontSize(40))
            .borderRadius(20)
            .backgroundColor(ColorTheme.getColor('pageBackground'))
            .alignContent(Alignment.Center)

            // 地点信息
            Column({ space: 4 }) {
              Text(this.selectedLocation)
                .fontSize(this.getFontSize(16))
                .fontWeight(FontWeight.Bold)
                .fontColor(ColorTheme.getColor('textPrimary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              
              Text(`${this.selectedCluster ? this.getLevelText(this.selectedCluster.level) : '地点'} · 共 ${this.selectedDiaryCount} 条日记`)
                .fontSize(this.getFontSize(12))
                .fontColor(ColorTheme.getColor('textMuted'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            // 关闭按钮
            SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
              .fontSize(this.getFontSize(20))
              .fontColor([ColorTheme.getColor('textMuted')])
              .onClick(() => {
                this.showLocationCard = false;
              })
          }
          .width('100%')

          // 查看详情按钮
          Row({ space: 6 }) {
            SymbolGlyph($r('sys.symbol.satellite_map_fill'))
              .fontSize(this.getFontSize(16))
              .fontColor(['#5D4037'])
            Text('查看日记详情')
              .fontSize(this.getFontSize(14))
              .fontWeight(FontWeight.Medium)
              .fontColor('#5D4037')
          }
          .width('100%')
          .height(this.currentBreakpoint === 'xs' ? 40 : 44)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FFE082')
          .borderRadius(22)
          .onClick(() => {
            this.viewLocationDiaries();
          })
        }
        .width(this.getCardWidth())
        .padding(this.getSpacing())
        .backgroundColor(ColorTheme.getColor('cardBackground'))
        .borderRadius(16)
        .shadow({
          radius: 16,
          offsetX: 0,
          offsetY: 4,
          color: 'rgba(0, 0, 0, 0.15)'
        })
        .position({ left: '50%', top: this.getNavBarHeight() + 10 })
        .translate({ x: '-50%' })
        .zIndex(20)
      }

      // 操作提示浮窗 - 响应式
      if (this.showTip && this.diaries.length > 0 && !this.showLocationCard) {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.position'))
              .fontSize(this.getFontSize(16))
              .fontColor([ColorTheme.getColor('textPrimary')])
            Text('点击标记查看日记')
              .fontSize(this.getFontSize(13))
              .fontColor(ColorTheme.getColor('textPrimary'))
              .layoutWeight(1)
            
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(this.getFontSize(16))
              .fontColor([ColorTheme.getColor('textMuted')])
              .onClick(() => {
                this.showTip = false;
              })
          }
          .width('100%')
          
          Text('双指缩放地图查看更多')
            .fontSize(this.getFontSize(11))
            .fontColor(ColorTheme.getColor('textMuted'))
        }
        .width(this.getCardWidth())
        .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 12, bottom: 12 })
        .backgroundColor(ColorTheme.getColor('cardBackground'))
        .borderRadius(12)
        .shadow({
          radius: 10,
          offsetX: 0,
          offsetY: 2,
          color: 'rgba(0, 0, 0, 0.1)'
        })
        .position({ left: '50%', top: this.getNavBarHeight() + 20 })
        .translate({ x: '-50%' })
        .zIndex(20)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTheme.getColor('pageBackground'))
  }

}
