import { IAMapLocationListener, AMapLocationManagerImpl, AMapLocationOption } from '@amap/amap_lbs_location';
import { AMapPrivacyShowStatus, AMapPrivacyInfoStatus, AMapPrivacyAgreeStatus } from '@amap/amap_lbs_common';
import { AMapLocationReGeocodeLanguage, AMapLocationType } from '@amap/amap_lbs_location';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import geoLocationManager from '@ohos.geoLocationManager';
import bundleManager from '@ohos.bundle.bundleManager';
import { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';

const AMAP_KEY = "eeea05310fb64a33ac288adc22cb102e";

export interface LocationResult {
  latitude: number;
  longitude: number;
  address: string;
  poiName: string; 
  accuracy: number;
}

export class LocationManager {
  private static instance: LocationManager;
  private locationManager?: AMapLocationManagerImpl;
  private context: common.UIAbilityContext;

  private constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.initAMap();
  }

  static getInstance(context: common.UIAbilityContext): LocationManager {
    if (!LocationManager.instance) {
      LocationManager.instance = new LocationManager(context);
    }
    return LocationManager.instance;
  }

  private initAMap() {
    // 设置高德地图API Key
    AMapLocationManagerImpl.setApiKey(AMAP_KEY);
    
    // 设置隐私合规
    AMapLocationManagerImpl.updatePrivacyShow(
      AMapPrivacyShowStatus.DidShow,
      AMapPrivacyInfoStatus.DidContain,
      this.context
    );
    AMapLocationManagerImpl.updatePrivacyAgree(AMapPrivacyAgreeStatus.DidAgree, this.context);
    
    // 创建定位管理器
    this.locationManager = new AMapLocationManagerImpl(this.context);
  }

  /**
   * 检查定位权限
   */
  async checkPermissions(): Promise<boolean> {
    // 检查系统定位是否开启
    let locationEnabled = geoLocationManager.isLocationEnabled();
    if (!locationEnabled) {
      console.error('[LocationManager] 系统定位未开启');
      return false;
    }

    // 检查应用权限
    const permissions: Array<Permissions> = [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ];

    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    
    // 获取应用程序的accessTokenID
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`[LocationManager] Failed to get bundle info: ${err.message}`);
      return false;
    }

    // 检查权限
    for (let permission of permissions) {
      try {
        let grantStatus = await atManager.checkAccessToken(tokenId, permission);
        if (grantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          // 请求权限
          let permissionRequestResult = await atManager.requestPermissionsFromUser(this.context, permissions);
          let grantResults: Array<number> = permissionRequestResult.authResults;
          
          // 检查是否所有权限都被授予
          for (let result of grantResults) {
            if (result !== 0) {
              console.error('[LocationManager] 权限被拒绝');
              return false;
            }
          }
          break;
        }
      } catch (error) {
        let err: BusinessError = error as BusinessError;
        console.error(`[LocationManager] Failed to check permission: ${err.message}`);
        return false;
      }
    }

    return true;
  }

  /**
   * 获取当前位置（单次定位）
   */
  async getCurrentLocation(): Promise<LocationResult> {
    // 检查权限
    const hasPermission = await this.checkPermissions();
    if (!hasPermission) {
      throw new Error('定位权限未授予，请在设置中开启定位权限');
    }

    // 使用高德定位
    return await this.getAMapLocation();
  }

  /**
   * 使用高德地图定位
   */
  private async getAMapLocation(): Promise<LocationResult> {
    return new Promise<LocationResult>((resolve, reject) => {
      // 定位监听器
      let listener: IAMapLocationListener = {
        onLocationChanged: (location) => {
          console.info('[LocationManager] 高德定位成功:', JSON.stringify(location));
          
          const result: LocationResult = {
            latitude: location.latitude,
            longitude: location.longitude,
            address: location.reGeo?.desc || location.reGeo?.address || '',
            poiName: location.reGeo?.poiName || '',
            accuracy: location.accuracy
          };
          
          resolve(result);
        },
        onLocationError: (error) => {
          console.error('[LocationManager] 高德定位失败:', JSON.stringify(error));
          reject(new Error('高德定位失败: ' + JSON.stringify(error)));
        }
      };

      // 定位选项 - 优化配置以提高速度
      let options: AMapLocationOption = {
        priority: geoLocationManager.LocationRequestPriority.FIRST_FIX, // 快速定位优先
        scenario: geoLocationManager.LocationRequestScenario.UNSET, // 不设置特定场景
        maxAccuracy: 0, // 不限制精度，加快定位速度
        singleLocationTimeout: 10000, // 缩短超时时间到10秒
        allowsBackgroundLocationUpdates: false,
        locatingWithReGeocode: true, // 启用逆地理编码
        reGeocodeLanguage: AMapLocationReGeocodeLanguage.Chinese,
        isOffset: true // 使用国测局坐标
      };

      // 设置监听器和选项
      this.locationManager?.setLocationListener(AMapLocationType.Single, listener);
      this.locationManager?.setLocationOption(AMapLocationType.Single, options);
      
      // 请求单次定位
      this.locationManager?.requestSingleLocation();
    });
  }

  /**
   * 销毁定位管理器
   */
  destroy() {
    this.locationManager = undefined;
  }
}
