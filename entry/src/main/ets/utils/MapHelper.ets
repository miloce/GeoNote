/**
 * MapHelper - 统一的地图操作模块
 * 提供地图初始化、标记管理、视角调整等通用功能
 */
import {
  AMap,
  CameraUpdateFactory,
  LatLng,
  MapView,
  MarkerOptions,
  BitmapDescriptorFactory
} from '@amap/amap_lbs_map3d';
import { MapsInitializer } from '@amap/amap_lbs_map3d';
import { ServiceSettings } from '@amap/amap_lbs_search';
import { AMapPrivacyInfoStatus, AMapPrivacyShowStatus, AMapPrivacyAgreeStatus } from '@amap/amap_lbs_common';
import { Diary } from '../model/DiaryModel';

// 高德地图API Key
const AMAP_KEY = "eeea05310fb64a33ac288adc22cb102e";

/**
 * 地图边界信息
 */
export interface MapBounds {
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
  centerLat: number;
  centerLng: number;
}

/**
 * 地图配置选项
 */
export interface MapOptions {
  /** 是否禁用所有手势 */
  disableGestures?: boolean;
  /** 是否显示缩放控件 */
  showZoomControls?: boolean;
  /** 是否显示比例尺 */
  showScaleControls?: boolean;
  /** 是否显示指南针 */
  showCompass?: boolean;
  /** 默认缩放级别 */
  defaultZoom?: number;
  /** 默认中心点 */
  defaultCenter?: LatLng;
}

/**
 * 标记配置
 */
export interface MarkerConfig {
  position: LatLng;
  title: string;
  snippet?: string;
  clickable?: boolean;
  showInfoWindow?: boolean;
}

/**
 * 聚合级别枚举
 */
export enum ClusterLevel {
  LOCATION = 'location',  // 地点级别（最详细）
  DISTRICT = 'district',  // 区/县级别
  CITY = 'city',          // 市级别
  PROVINCE = 'province'   // 省级别
}

/**
 * 聚合标记信息
 */
export interface ClusterMarkerInfo {
  level: ClusterLevel;
  name: string;           // 显示名称（省/市/区/地点）
  diaries: Diary[];       // 该聚合包含的日记
  centerLat: number;
  centerLng: number;
  count: number;
}

/**
 * MapHelper 类 - 地图操作工具类
 */
export class MapHelper {
  private static instance: MapHelper;
  private initialized: boolean = false;

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): MapHelper {
    if (!MapHelper.instance) {
      MapHelper.instance = new MapHelper();
    }
    return MapHelper.instance;
  }

  /**
   * 初始化高德地图SDK
   * @param context 应用上下文
   */
  initializeMapSDK(context: Context): void {
    if (this.initialized) {
      return;
    }
    MapsInitializer.setApiKey(AMAP_KEY);
    ServiceSettings.updatePrivacyShow(AMapPrivacyShowStatus.DidShow, AMapPrivacyInfoStatus.DidContain, context);
    ServiceSettings.updatePrivacyAgree(AMapPrivacyAgreeStatus.DidAgree, context);
    this.initialized = true;
    console.info('[MapHelper] 地图SDK初始化完成');
  }

  /**
   * 配置地图UI设置
   * @param map AMap实例
   * @param options 配置选项
   */
  configureMapUI(map: AMap, options: MapOptions): void {
    const uiSettings = map.getUiSettings();
    if (!uiSettings) {
      console.warn('[MapHelper] 无法获取UiSettings');
      return;
    }

    // 手势控制
    if (options.disableGestures) {
      uiSettings.setAllGesturesEnabled(false);
      uiSettings.setScrollGesturesEnabled(false);
      uiSettings.setZoomGesturesEnabled(false);
      uiSettings.setRotateGesturesEnabled(false);
      uiSettings.setTiltGesturesEnabled(false);
    }

    // UI控件
    uiSettings.setZoomControlsEnabled(options.showZoomControls ?? false);
    uiSettings.setScaleControlsEnabled(options.showScaleControls ?? false);
    uiSettings.setCompassEnabled(options.showCompass ?? false);

    console.info('[MapHelper] 地图UI配置完成');
  }

  /**
   * 从日记列表中提取有效坐标的日记
   * @param diaries 日记列表
   * @returns 有坐标的日记列表
   */
  filterDiariesWithLocation(diaries: Diary[]): Diary[] {
    return diaries.filter(diary =>
      diary.latitude !== undefined &&
      diary.longitude !== undefined &&
      diary.latitude !== null &&
      diary.longitude !== null &&
      diary.latitude !== 0 &&
      diary.longitude !== 0
    );
  }

  /**
   * 计算日记列表的地图边界
   * @param diaries 有坐标的日记列表
   * @returns 边界信息，如果没有有效坐标返回null
   */
  calculateBounds(diaries: Diary[]): MapBounds | null {
    const validDiaries = this.filterDiariesWithLocation(diaries);
    if (validDiaries.length === 0) {
      return null;
    }

    let minLat = 90.0;
    let maxLat = -90.0;
    let minLng = 180.0;
    let maxLng = -180.0;

    validDiaries.forEach(diary => {
      const lat = typeof diary.latitude === 'number' ? diary.latitude : parseFloat(String(diary.latitude));
      const lng = typeof diary.longitude === 'number' ? diary.longitude : parseFloat(String(diary.longitude));

      if (!isNaN(lat) && !isNaN(lng)) {
        minLat = Math.min(minLat, lat);
        maxLat = Math.max(maxLat, lat);
        minLng = Math.min(minLng, lng);
        maxLng = Math.max(maxLng, lng);
      }
    });

    return {
      minLat,
      maxLat,
      minLng,
      maxLng,
      centerLat: (minLat + maxLat) / 2,
      centerLng: (minLng + maxLng) / 2
    };
  }

  /**
   * 根据边界计算合适的缩放级别
   * @param bounds 边界信息
   * @returns 缩放级别
   */
  calculateZoomLevel(bounds: MapBounds): number {
    const latDiff = bounds.maxLat - bounds.minLat;
    const lngDiff = bounds.maxLng - bounds.minLng;

    // 添加边距，确保标记不会贴边(增加40%的边距)
    const paddingFactor = 1.4;
    const paddedLatDiff = latDiff * paddingFactor;
    const paddedLngDiff = lngDiff * paddingFactor;
    const maxDiff = Math.max(paddedLatDiff, paddedLngDiff);

    let zoom = 17.0;

    if (maxDiff <= 0.0001) {
      // 单点或极近距离
      zoom = 17.0;
    } else if (maxDiff <= 0.001) {
      // 社区级别
      zoom = 16.0;
    } else if (maxDiff <= 0.01) {
      // 街道级别
      zoom = 14.0;
    } else if (maxDiff <= 0.05) {
      // 区级别
      zoom = 12.0;
    } else if (maxDiff <= 0.2) {
      // 市级别
      zoom = 10.0;
    } else if (maxDiff <= 1.0) {
      // 大市/小省级别
      zoom = 8.0;
    } else if (maxDiff <= 3.0) {
      // 省级别
      zoom = 7.0;
    } else if (maxDiff <= 8.0) {
      // 跨省级别
      zoom = 5.5;
    } else if (maxDiff <= 15.0) {
      // 大跨度
      zoom = 4.5;
    } else {
      // 全国级别
      zoom = 4.0;
    }

    console.info(`[MapHelper] 计算缩放级别: maxDiff=${maxDiff.toFixed(4)}, zoom=${zoom}`);
    return zoom;
  }

  /**
   * 移动地图以适应所有日记点
   * @param map AMap实例
   * @param diaries 日记列表
   * @param animate 是否使用动画
   */
  fitMapToDiaries(map: AMap, diaries: Diary[], animate: boolean = false): void {
    const bounds = this.calculateBounds(diaries);
    if (!bounds) {
      // 没有有效坐标，使用默认中心点（中国中心）
      map.moveCamera(CameraUpdateFactory.newLatLngZoom(new LatLng(35.0, 110.0), 5.0));
      return;
    }

    const zoom = this.calculateZoomLevel(bounds);
    const center = new LatLng(bounds.centerLat, bounds.centerLng);

    if (animate) {
      map.animateCamera(CameraUpdateFactory.newLatLngZoom(center, zoom));
    } else {
      map.moveCamera(CameraUpdateFactory.newLatLngZoom(center, zoom));
    }

    console.info(`[MapHelper] 地图视角调整: center=(${bounds.centerLat.toFixed(4)}, ${bounds.centerLng.toFixed(4)}), zoom=${zoom}`);
  }

  /**
   * 为日记列表添加标记（按地点分组）
   * @param map AMap实例
   * @param diaries 日记列表
   * @param clickable 是否可点击
   * @param showInfoWindow 是否显示信息窗口
   * @returns 添加的标记数量
   */
  addDiaryMarkersGrouped(
    map: AMap,
    diaries: Diary[],
    clickable: boolean = true,
    showInfoWindow: boolean = false
  ): number {
    const validDiaries = this.filterDiariesWithLocation(diaries);
    if (validDiaries.length === 0) {
      return 0;
    }

    // 按地点分组
    const locationGroups = new Map<string, Diary[]>();
    validDiaries.forEach(diary => {
      const location = diary.location || '未知地点';
      if (!locationGroups.has(location)) {
        locationGroups.set(location, []);
      }
      locationGroups.get(location)!.push(diary);
    });

    let markerCount = 0;

    // 为每个地点添加一个标记（使用该地点最新的日记位置）
    locationGroups.forEach((groupDiaries, location) => {
      // 按时间排序，取最新的
      const sortedDiaries = groupDiaries.sort((a, b) =>
        new Date(b.created_at || '').getTime() - new Date(a.created_at || '').getTime()
      );
      const diary = sortedDiaries[0];

      const lat = typeof diary.latitude === 'number' ? diary.latitude : parseFloat(String(diary.latitude));
      const lng = typeof diary.longitude === 'number' ? diary.longitude : parseFloat(String(diary.longitude));

      if (!isNaN(lat) && !isNaN(lng) && lat !== 0 && lng !== 0) {
        const markerOptions = new MarkerOptions();
        markerOptions.setPosition(new LatLng(lat, lng));
        markerOptions.setTitle(location);

        // 如果有多条日记，在snippet中显示数量
        const snippet = groupDiaries.length > 1
          ? `共${groupDiaries.length}条日记`
          : (diary.content?.substring(0, 50) || '');
        markerOptions.setSnippet(snippet);

        // 设置标记图标
        markerOptions.setIcon(BitmapDescriptorFactory.defaultMarker());

        // 设置是否显示信息窗口
        markerOptions.setInfoWindowEnable(showInfoWindow);

        markerOptions.setClickable(clickable);
        markerOptions.setDraggable(false);
        markerOptions.setVisible(true);

        const marker = map.addMarker(markerOptions);
        if (marker) {
          markerCount++;
        }
      }
    });

    console.info(`[MapHelper] 添加了 ${markerCount} 个标记（共 ${locationGroups.size} 个地点）`);
    return markerCount;
  }

  /**
   * 为日记列表添加标记（每条日记一个标记）
   * @param map AMap实例
   * @param diaries 日记列表
   * @returns 添加的标记数量
   */
  addDiaryMarkersIndividual(map: AMap, diaries: Diary[]): number {
    const validDiaries = this.filterDiariesWithLocation(diaries);
    let markerCount = 0;

    validDiaries.forEach(diary => {
      const lat = typeof diary.latitude === 'number' ? diary.latitude : parseFloat(String(diary.latitude));
      const lng = typeof diary.longitude === 'number' ? diary.longitude : parseFloat(String(diary.longitude));

      if (!isNaN(lat) && !isNaN(lng) && lat !== 0 && lng !== 0) {
        const markerOptions = new MarkerOptions();
        markerOptions.setPosition(new LatLng(lat, lng));
        markerOptions.setTitle(diary.location || '');
        markerOptions.setIcon(BitmapDescriptorFactory.defaultMarker());
        markerOptions.setInfoWindowEnable(false);
        markerOptions.setClickable(false);
        markerOptions.setDraggable(false);
        markerOptions.setVisible(true);

        const marker = map.addMarker(markerOptions);
        if (marker) {
          markerCount++;
        }
      }
    });

    console.info(`[MapHelper] 添加了 ${markerCount} 个独立标记`);
    return markerCount;
  }

  /**
   * 清除地图上的所有覆盖物
   * @param map AMap实例
   * @param keepSettings 是否保留设置
   */
  clearMap(map: AMap, keepSettings: boolean = true): void {
    map.clear(keepSettings);
    console.info('[MapHelper] 地图已清除');
  }

  /**
   * 获取API Key
   */
  getApiKey(): string {
    return AMAP_KEY;
  }

  /**
   * 根据缩放级别获取聚合级别
   * @param zoom 当前缩放级别
   * @returns 聚合级别
   */
  getClusterLevelByZoom(zoom: number): ClusterLevel {
    if (zoom >= 14) {
      return ClusterLevel.LOCATION;  // 地点级别
    } else if (zoom >= 10) {
      return ClusterLevel.DISTRICT;  // 区/县级别
    } else if (zoom >= 7) {
      return ClusterLevel.CITY;      // 市级别
    } else {
      return ClusterLevel.PROVINCE;  // 省级别
    }
  }

  /**
   * 从地址中提取省份名称
   * @param address 完整地址
   * @returns 省份名称
   */
  extractProvince(address: string): string {
    if (!address) return '未知省份';
    
    // 匹配省/自治区/直辖市/特别行政区
    const provincePatterns = [
      /^(.+?省)/,
      /^(.+?自治区)/,
      /^(北京市|上海市|天津市|重庆市)/,
      /^(香港|澳门)/,
      /^(.+?特别行政区)/
    ];
    
    for (const pattern of provincePatterns) {
      const match = address.match(pattern);
      if (match) {
        return match[1];
      }
    }
    
    return '未知省份';
  }

  /**
   * 从地址中提取城市名称
   * @param address 完整地址
   * @returns 城市名称
   */
  extractCity(address: string): string {
    if (!address) return '未知城市';
    
    // 直辖市特殊处理
    if (/^(北京|上海|天津|重庆)/.test(address)) {
      const match = address.match(/^(北京|上海|天津|重庆)/);
      return match ? match[1] : '未知城市';
    }
    
    // 匹配市/地区/自治州/盟
    const cityPatterns = [
      /省(.+?市)/,
      /自治区(.+?市)/,
      /自治区(.+?盟)/,
      /自治区(.+?地区)/,
      /(.+?市)/
    ];
    
    for (const pattern of cityPatterns) {
      const match = address.match(pattern);
      if (match) {
        return match[1];
      }
    }
    
    return '未知城市';
  }

  /**
   * 从地址中提取区/县名称
   * @param address 完整地址
   * @returns 区/县名称
   */
  extractDistrict(address: string): string {
    if (!address) return '未知区县';
    
    // 匹配区/县/旗/市辖区
    const districtPatterns = [
      /市(.+?区)/,
      /市(.+?县)/,
      /盟(.+?旗)/,
      /地区(.+?县)/,
      /(.+?区)/,
      /(.+?县)/
    ];
    
    for (const pattern of districtPatterns) {
      const match = address.match(pattern);
      if (match) {
        return match[1];
      }
    }
    
    return '未知区县';
  }

  /**
   * 根据聚合级别对日记进行分组
   * @param diaries 日记列表
   * @param level 聚合级别
   * @returns 聚合标记信息列表
   */
  clusterDiaries(diaries: Diary[], level: ClusterLevel): ClusterMarkerInfo[] {
    const validDiaries = this.filterDiariesWithLocation(diaries);
    if (validDiaries.length === 0) {
      return [];
    }

    const groups = new Map<string, Diary[]>();

    validDiaries.forEach(diary => {
      let key: string;
      const address = diary.address || diary.location || '';

      switch (level) {
        case ClusterLevel.PROVINCE:
          key = this.extractProvince(address);
          break;
        case ClusterLevel.CITY:
          key = this.extractCity(address);
          break;
        case ClusterLevel.DISTRICT:
          key = this.extractDistrict(address);
          break;
        case ClusterLevel.LOCATION:
        default:
          key = diary.location || '未知地点';
          break;
      }

      if (!groups.has(key)) {
        groups.set(key, []);
      }
      groups.get(key)!.push(diary);
    });

    const result: ClusterMarkerInfo[] = [];

    groups.forEach((groupDiaries, name) => {
      // 计算中心点
      let totalLat = 0;
      let totalLng = 0;
      let count = 0;

      groupDiaries.forEach(diary => {
        const lat = typeof diary.latitude === 'number' ? diary.latitude : parseFloat(String(diary.latitude));
        const lng = typeof diary.longitude === 'number' ? diary.longitude : parseFloat(String(diary.longitude));
        if (!isNaN(lat) && !isNaN(lng)) {
          totalLat += lat;
          totalLng += lng;
          count++;
        }
      });

      if (count > 0) {
        result.push({
          level,
          name,
          diaries: groupDiaries,
          centerLat: totalLat / count,
          centerLng: totalLng / count,
          count: groupDiaries.length
        });
      }
    });

    console.info(`[MapHelper] 聚合完成: level=${level}, 分组数=${result.length}`);
    return result;
  }

  /**
   * 添加聚合标记
   * @param map AMap实例
   * @param clusters 聚合信息列表
   * @returns 添加的标记数量
   */
  addClusterMarkers(map: AMap, clusters: ClusterMarkerInfo[]): number {
    let markerCount = 0;

    clusters.forEach(cluster => {
      const markerOptions = new MarkerOptions();
      markerOptions.setPosition(new LatLng(cluster.centerLat, cluster.centerLng));
      markerOptions.setTitle(cluster.name);

      // 根据聚合级别设置不同的snippet
      let levelText = '';
      switch (cluster.level) {
        case ClusterLevel.PROVINCE:
          levelText = '省份';
          break;
        case ClusterLevel.CITY:
          levelText = '城市';
          break;
        case ClusterLevel.DISTRICT:
          levelText = '区县';
          break;
        default:
          levelText = '地点';
      }
      markerOptions.setSnippet(`${levelText} · 共${cluster.count}条日记`);

      markerOptions.setIcon(BitmapDescriptorFactory.defaultMarker());
      markerOptions.setInfoWindowEnable(false);
      markerOptions.setClickable(true);
      markerOptions.setDraggable(false);
      markerOptions.setVisible(true);

      const marker = map.addMarker(markerOptions);
      if (marker) {
        markerCount++;
      }
    });

    console.info(`[MapHelper] 添加了 ${markerCount} 个聚合标记`);
    return markerCount;
  }
}

// 导出单例实例
export const mapHelper = MapHelper.getInstance();
