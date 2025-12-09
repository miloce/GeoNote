import preferences from '@ohos.data.preferences';
import { Diary } from '../model/DiaryModel';

/**
 * 日记本地存储工具类
 * 支持多用户数据隔离
 */
export class DiaryStorage {
  private static readonly STORE_NAME = 'diary_store';
  private static readonly KEY_DIARIES = 'diaries'; // 已废弃，保留用于迁移
  private static readonly KEY_LAST_SYNC = 'last_sync_time'; // 已废弃，保留用于迁移
  private static readonly KEY_CURRENT_USER_ID = 'current_user_id'; // 当前用户ID
  private static store: preferences.Preferences | null = null;
  private static currentUserId: number = 0; // 当前用户ID缓存

  /**
   * 获取当前用户的日记存储key
   */
  private static getUserDiariesKey(userId: number): string {
    return `diaries_user_${userId}`;
  }

  /**
   * 获取当前用户的同步时间key
   */
  private static getUserSyncTimeKey(userId: number): string {
    return `last_sync_time_user_${userId}`;
  }

  /**
   * 设置当前用户ID
   */
  static async setCurrentUserId(userId: number): Promise<void> {
    try {
      DiaryStorage.currentUserId = userId;
      const store: preferences.Preferences = await DiaryStorage.getStore();
      await store.put(DiaryStorage.KEY_CURRENT_USER_ID, userId);
      await store.flush();
      console.info('[DiaryStorage] 设置当前用户ID:', userId);
    } catch (error) {
      console.error('[DiaryStorage] 设置当前用户ID失败:', error);
    }
  }

  /**
   * 获取当前用户ID
   */
  static async getCurrentUserId(): Promise<number> {
    if (DiaryStorage.currentUserId > 0) {
      return DiaryStorage.currentUserId;
    }
    try {
      const store: preferences.Preferences = await DiaryStorage.getStore();
      const userId = await store.get(DiaryStorage.KEY_CURRENT_USER_ID, 0) as number;
      DiaryStorage.currentUserId = userId;
      return userId;
    } catch (error) {
      console.error('[DiaryStorage] 获取当前用户ID失败:', error);
      return 0;
    }
  }

  /**
   * 初始化存储
   */
  private static async getStore(): Promise<preferences.Preferences> {
    if (DiaryStorage.store) {
      return DiaryStorage.store;
    }
    
    try {
      DiaryStorage.store = await preferences.getPreferences(getContext(), DiaryStorage.STORE_NAME);
      return DiaryStorage.store;
    } catch (error) {
      console.error('[DiaryStorage] 初始化存储失败:', error);
      throw new Error('初始化存储失败');
    }
  }

  /**
   * 保存日记列表到本地（按用户隔离）
   */
  static async saveDiaries(diaries: Diary[]): Promise<void> {
    try {
      const userId = await DiaryStorage.getCurrentUserId();
      if (userId === 0) {
        console.warn('[DiaryStorage] 未设置用户ID，无法保存日记');
        return;
      }
      const store: preferences.Preferences = await DiaryStorage.getStore();
      const key = DiaryStorage.getUserDiariesKey(userId);
      await store.put(key, JSON.stringify(diaries));
      await store.flush();
      console.info(`[DiaryStorage] 保存用户${userId}的日记列表成功, 数量:`, diaries.length);
    } catch (error) {
      console.error('[DiaryStorage] 保存日记列表失败:', error);
      throw new Error('保存日记列表失败');
    }
  }

  /**
   * 从本地获取日记列表（按用户隔离）
   */
  static async getDiaries(): Promise<Diary[]> {
    try {
      const userId = await DiaryStorage.getCurrentUserId();
      if (userId === 0) {
        console.warn('[DiaryStorage] 未设置用户ID，返回空列表');
        return [];
      }
      const store: preferences.Preferences = await DiaryStorage.getStore();
      const key = DiaryStorage.getUserDiariesKey(userId);
      const data: preferences.ValueType = await store.get(key, '[]');
      const diaries: Diary[] = JSON.parse(data as string) as Diary[];
      console.info(`[DiaryStorage] 获取用户${userId}的日记列表成功, 数量:`, diaries.length);
      return diaries;
    } catch (error) {
      console.error('[DiaryStorage] 获取日记列表失败:', error);
      return [];
    }
  }

  /**
   * 添加单条日记
   */
  static async addDiary(diary: Diary): Promise<void> {
    try {
      const diaries: Diary[] = await DiaryStorage.getDiaries();
      
      // 生成本地ID（如果没有）
      if (!diary.local_id) {
        diary.local_id = `local_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      }
      
      diaries.unshift(diary); // 添加到列表开头
      await DiaryStorage.saveDiaries(diaries);
      console.info('[DiaryStorage] 添加日记成功, ID:', diary.local_id);
    } catch (error) {
      console.error('[DiaryStorage] 添加日记失败:', error);
      throw new Error('添加日记失败');
    }
  }

  /**
   * 更新日记
   */
  static async updateDiary(diary: Diary): Promise<void> {
    try {
      const diaries: Diary[] = await DiaryStorage.getDiaries();
      const index: number = diaries.findIndex((d: Diary) => 
        (diary.id && d.id === diary.id) || 
        (diary.local_id && d.local_id === diary.local_id)
      );
      
      if (index !== -1) {
        // ArkTS不支持对象展开，手动复制属性
        const updatedDiary: Diary = diaries[index];
        if (diary.title !== undefined) updatedDiary.title = diary.title;
        if (diary.content !== undefined) updatedDiary.content = diary.content;
        if (diary.location !== undefined) updatedDiary.location = diary.location;
        if (diary.latitude !== undefined) updatedDiary.latitude = diary.latitude;
        if (diary.longitude !== undefined) updatedDiary.longitude = diary.longitude;
        if (diary.weather !== undefined) updatedDiary.weather = diary.weather;
        if (diary.mood !== undefined) updatedDiary.mood = diary.mood;
        if (diary.images !== undefined) updatedDiary.images = diary.images;
        if (diary.tags !== undefined) updatedDiary.tags = diary.tags;
        if (diary.is_public !== undefined) updatedDiary.is_public = diary.is_public;
        if (diary.synced !== undefined) updatedDiary.synced = diary.synced;
        diaries[index] = updatedDiary;
        await DiaryStorage.saveDiaries(diaries);
        console.info('[DiaryStorage] 更新日记成功');
      } else {
        console.warn('[DiaryStorage] 未找到要更新的日记');
      }
    } catch (error) {
      console.error('[DiaryStorage] 更新日记失败:', error);
      throw new Error('更新日记失败');
    }
  }

  /**
   * 删除日记
   */
  static async deleteDiary(diaryId: number | string): Promise<void> {
    try {
      const diaries: Diary[] = await DiaryStorage.getDiaries();
      const filteredDiaries: Diary[] = diaries.filter((d: Diary) => 
        d.id !== diaryId && d.local_id !== diaryId
      );
      
      await DiaryStorage.saveDiaries(filteredDiaries);
      console.info('[DiaryStorage] 删除日记成功');
    } catch (error) {
      console.error('[DiaryStorage] 删除日记失败:', error);
      throw new Error('删除日记失败');
    }
  }

  /**
   * 获取未同步的日记
   */
  static async getUnsyncedDiaries(): Promise<Diary[]> {
    try {
      const diaries: Diary[] = await DiaryStorage.getDiaries();
      return diaries.filter((d: Diary) => !d.synced);
    } catch (error) {
      console.error('[DiaryStorage] 获取未同步日记失败:', error);
      return [];
    }
  }

  /**
   * 标记日记为已同步
   */
  static async markAsSynced(diaryId: number | string): Promise<void> {
    try {
      const diaries: Diary[] = await DiaryStorage.getDiaries();
      const diary: Diary | undefined = diaries.find((d: Diary) => 
        d.id === diaryId || d.local_id === diaryId
      );
      
      if (diary) {
        diary.synced = true;
        await DiaryStorage.saveDiaries(diaries);
        console.info('[DiaryStorage] 标记日记为已同步');
      }
    } catch (error) {
      console.error('[DiaryStorage] 标记同步状态失败:', error);
      throw new Error('标记同步状态失败');
    }
  }

  /**
   * 批量标记多条日记为已同步（优化性能，一次读取和保存）
   */
  static async markMultipleAsSynced(diaryIds: Array<number | string>): Promise<void> {
    try {
      const diaries: Diary[] = await DiaryStorage.getDiaries();
      let markedCount = 0;
      
      for (const diary of diaries) {
        if (diaryIds.includes(diary.id!) || (diary.local_id && diaryIds.includes(diary.local_id))) {
          diary.synced = true;
          markedCount++;
        }
      }
      
      if (markedCount > 0) {
        await DiaryStorage.saveDiaries(diaries);
        console.info(`[DiaryStorage] 批量标记 ${markedCount} 条日记为已同步`);
      }
    } catch (error) {
      console.error('[DiaryStorage] 批量标记同步状态失败:', error);
      throw new Error('批量标记同步状态失败');
    }
  }

  /**
   * 保存最后同步时间（按用户隔离）
   */
  static async saveLastSyncTime(time: string): Promise<void> {
    try {
      const userId = await DiaryStorage.getCurrentUserId();
      if (userId === 0) {
        console.warn('[DiaryStorage] 未设置用户ID，无法保存同步时间');
        return;
      }
      const store: preferences.Preferences = await DiaryStorage.getStore();
      const key = DiaryStorage.getUserSyncTimeKey(userId);
      await store.put(key, time);
      await store.flush();
      console.info(`[DiaryStorage] 保存用户${userId}的同步时间成功:`, time);
    } catch (error) {
      console.error('[DiaryStorage] 保存同步时间失败:', error);
      throw new Error('保存同步时间失败');
    }
  }

  /**
   * 获取最后同步时间（按用户隔离）
   */
  static async getLastSyncTime(): Promise<string | null> {
    try {
      const userId = await DiaryStorage.getCurrentUserId();
      if (userId === 0) {
        console.warn('[DiaryStorage] 未设置用户ID，返回null');
        return null;
      }
      const store: preferences.Preferences = await DiaryStorage.getStore();
      const key = DiaryStorage.getUserSyncTimeKey(userId);
      const time: preferences.ValueType = await store.get(key, '');
      const timeStr: string = time as string;
      return timeStr || null;
    } catch (error) {
      console.error('[DiaryStorage] 获取同步时间失败:', error);
      return null;
    }
  }

  /**
   * 合并云端日记到本地（使用UUID去重）
   */
  static async mergeDiaries(cloudDiaries: Diary[]): Promise<void> {
    try {
      const localDiaries: Diary[] = await DiaryStorage.getDiaries();
      const mergedMap: Map<string, Diary> = new Map<string, Diary>();
      
      // 先添加本地日记（使用UUID作为key）
      localDiaries.forEach((diary: Diary) => {
        // 优先使用UUID，如果没有UUID则使用id或local_id（兼容旧数据）
        const key: string = diary.uuid || String(diary.id || diary.local_id || '');
        if (key) {
          mergedMap.set(key, diary);
        }
      });
      
      // 合并云端日记（云端优先，使用UUID去重）
      cloudDiaries.forEach((diary: Diary) => {
        const key: string = diary.uuid || String(diary.id || diary.local_id || '');
        if (key) {
          diary.synced = true;
          // 如果本地已有相同UUID的日记，用云端数据覆盖（云端是最新的）
          mergedMap.set(key, diary);
        }
      });
      
      const mergedDiaries: Diary[] = Array.from(mergedMap.values());
      
      console.info('[DiaryStorage] 合并前 - 本地:', localDiaries.length, '云端:', cloudDiaries.length, '合并后:', mergedDiaries.length);
      
      // 按创建时间倒序排序
      mergedDiaries.sort((a: Diary, b: Diary) => {
        const timeA: number = new Date(a.created_at || 0).getTime();
        const timeB: number = new Date(b.created_at || 0).getTime();
        return timeB - timeA;
      });
      
      await DiaryStorage.saveDiaries(mergedDiaries);
      console.info('[DiaryStorage] 合并日记成功, 总数:', mergedDiaries.length);
    } catch (error) {
      console.error('[DiaryStorage] 合并日记失败:', error);
      throw new Error('合并日记失败');
    }
  }

  /**
   * 清空当前用户的所有日记
   */
  static async clearAll(): Promise<void> {
    try {
      const userId = await DiaryStorage.getCurrentUserId();
      if (userId === 0) {
        console.warn('[DiaryStorage] 未设置用户ID，无法清空日记');
        return;
      }
      const store: preferences.Preferences = await DiaryStorage.getStore();
      const diariesKey = DiaryStorage.getUserDiariesKey(userId);
      const syncTimeKey = DiaryStorage.getUserSyncTimeKey(userId);
      await store.delete(diariesKey);
      await store.delete(syncTimeKey);
      await store.flush();
      console.info(`[DiaryStorage] 清空用户${userId}的所有日记成功`);
    } catch (error) {
      console.error('[DiaryStorage] 清空日记失败:', error);
      throw new Error('清空日记失败');
    }
  }

  /**
   * 切换用户时清理缓存
   */
  static async switchUser(newUserId: number): Promise<void> {
    try {
      await DiaryStorage.setCurrentUserId(newUserId);
      console.info(`[DiaryStorage] 切换到用户${newUserId}`);
    } catch (error) {
      console.error('[DiaryStorage] 切换用户失败:', error);
    }
  }
}
