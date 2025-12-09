import preferences from '@ohos.data.preferences';

/**
 * 应用设置数据
 */
export interface AppSettings {
  notificationEnabled: boolean;
  autoSyncEnabled: boolean;
  locationEnabled: boolean;
}

/**
 * 设置存储工具类
 */
export class SettingsStorage {
  private static readonly PREFERENCES_NAME = 'app_settings';
  private static readonly SETTINGS_KEY = 'app_settings_data';

  // 默认设置
  private static readonly DEFAULT_SETTINGS: AppSettings = {
    notificationEnabled: true,
    autoSyncEnabled: true,
    locationEnabled: true
  };

  /**
   * 保存设置
   * @param settings 设置对象
   */
  static async saveSettings(settings: AppSettings): Promise<void> {
    try {
      const context = getContext();
      const prefs = await preferences.getPreferences(context, SettingsStorage.PREFERENCES_NAME);

      const settingsJson = JSON.stringify(settings);
      await prefs.put(SettingsStorage.SETTINGS_KEY, settingsJson);
      await prefs.flush();

      console.log('[SettingsStorage] 设置已保存:', settingsJson);
    } catch (error) {
      console.error('[SettingsStorage] 保存设置失败:', error);
    }
  }

  /**
   * 获取设置
   * @returns Promise<AppSettings> 设置对象
   */
  static async getSettings(): Promise<AppSettings> {
    try {
      const context = getContext();
      const prefs = await preferences.getPreferences(context, SettingsStorage.PREFERENCES_NAME);

      const settingsJson = await prefs.get(SettingsStorage.SETTINGS_KEY, '') as string;

      if (settingsJson) {
        const settings = JSON.parse(settingsJson) as AppSettings;
        console.log('[SettingsStorage] 获取设置成功:', settingsJson);
        return settings;
      } else {
        console.log('[SettingsStorage] 未找到设置，使用默认值');
        // 保存默认设置
        await SettingsStorage.saveSettings(SettingsStorage.DEFAULT_SETTINGS);
        return SettingsStorage.DEFAULT_SETTINGS;
      }
    } catch (error) {
      console.error('[SettingsStorage] 获取设置失败:', error);
      return SettingsStorage.DEFAULT_SETTINGS;
    }
  }

  /**
   * 更新单个设置项
   * @param key 设置键
   * @param value 设置值
   */
  static async updateSetting(key: keyof AppSettings, value: boolean): Promise<void> {
    try {
      const settings = await SettingsStorage.getSettings();
      // 根据key更新对应的设置项
      if (key === 'notificationEnabled') {
        settings.notificationEnabled = value;
      } else if (key === 'autoSyncEnabled') {
        settings.autoSyncEnabled = value;
      } else if (key === 'locationEnabled') {
        settings.locationEnabled = value;
      }
      await SettingsStorage.saveSettings(settings);
      console.log(`[SettingsStorage] 更新设置 ${key} = ${value}`);
    } catch (error) {
      console.error('[SettingsStorage] 更新设置失败:', error);
    }
  }

  /**
   * 重置为默认设置
   */
  static async resetSettings(): Promise<void> {
    try {
      await SettingsStorage.saveSettings(SettingsStorage.DEFAULT_SETTINGS);
      console.log('[SettingsStorage] 设置已重置为默认值');
    } catch (error) {
      console.error('[SettingsStorage] 重置设置失败:', error);
    }
  }

  /**
   * 清除所有设置
   */
  static async clearSettings(): Promise<void> {
    try {
      const context = getContext();
      const prefs = await preferences.getPreferences(context, SettingsStorage.PREFERENCES_NAME);
      await prefs.clear();
      await prefs.flush();
      console.log('[SettingsStorage] 所有设置已清除');
    } catch (error) {
      console.error('[SettingsStorage] 清除设置失败:', error);
    }
  }
}
