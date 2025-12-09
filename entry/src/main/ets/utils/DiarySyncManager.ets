import { DiaryService } from '../services/DiaryService';
import { DiaryStorage } from './DiaryStorage';
import { Diary, OperationResult, CreateDiaryResult } from '../model/DiaryModel';

/**
 * 日记同步管理器
 */
export class DiarySyncManager {
  private static isSyncing = false;

  /**
   * 执行完整同步（上传本地未同步的日记，然后拉取云端更新）
   */
  static async fullSync(userId: number): Promise<OperationResult> {
    if (DiarySyncManager.isSyncing) {
      return { success: false, message: '正在同步中，请稍候' };
    }

    DiarySyncManager.isSyncing = true;
    console.info('[DiarySyncManager] 开始完整同步, 用户ID:', userId);

    try {
      // 1. 上传本地未同步的日记
      const uploadResult: OperationResult = await DiarySyncManager.uploadUnsyncedDiaries(userId);
      if (!uploadResult.success) {
        console.warn('[DiarySyncManager] 上传日记失败:', uploadResult.message);
      }

      // 2. 从云端拉取更新
      const lastSyncTime = await DiaryStorage.getLastSyncTime();
      const pullResult = await DiaryService.pullDiaries(userId, lastSyncTime || '');

      if (pullResult.success && pullResult.data) {
        // 3. 合并到本地
        await DiaryStorage.mergeDiaries(pullResult.data.diaries);
        
        // 4. 更新同步时间
        const now = new Date().toISOString();
        await DiaryStorage.saveLastSyncTime(now);

        console.info('[DiarySyncManager] 同步完成, 拉取数量:', pullResult.data.diaries.length);
        return {
          success: true,
          message: `同步成功，获取 ${pullResult.data.diaries.length} 条日记`
        };
      } else {
        return { success: false, message: pullResult.message || '同步失败' };
      }
    } catch (error) {
      console.error('[DiarySyncManager] 同步失败:', error);
      return { success: false, message: '同步失败: ' + error };
    } finally {
      DiarySyncManager.isSyncing = false;
    }
  }

  /**
   * 上传本地未同步的日记
   */
  static async uploadUnsyncedDiaries(userId: number): Promise<OperationResult> {
    try {
      const unsyncedDiaries = await DiaryStorage.getUnsyncedDiaries();
      
      if (unsyncedDiaries.length === 0) {
        console.info('[DiarySyncManager] 没有需要上传的日记');
        return { success: true, message: '没有需要上传的日记' };
      }

      console.info('[DiarySyncManager] 开始上传未同步日记, 数量:', unsyncedDiaries.length);

      // 批量同步到云端
      const syncResult = await DiaryService.syncDiaries(userId, unsyncedDiaries);

      if (syncResult.success && syncResult.data) {
        // 批量标记已同步的日记（一次性读取和保存，避免重复操作）
        const syncedIds: Array<number | string> = [];
        for (const diary of syncResult.data.diaries) {
          if (diary.id || diary.local_id) {
            syncedIds.push(diary.id || diary.local_id!);
          }
        }
        
        if (syncedIds.length > 0) {
          await DiaryStorage.markMultipleAsSynced(syncedIds);
        }

        console.info('[DiarySyncManager] 上传成功:', syncResult.data.synced_count);
        return {
          success: true,
          message: `成功上传 ${syncResult.data.synced_count} 条日记`
        };
      } else {
        return { success: false, message: syncResult.message || '上传失败' };
      }
    } catch (error) {
      console.error('[DiarySyncManager] 上传日记失败:', error);
      return { success: false, message: '上传失败: ' + error };
    }
  }

  /**
   * 创建日记并同步到云端
   */
  static async createAndSync(userId: number, diary: Diary): Promise<CreateDiaryResult> {
    try {
      // 1. 先保存到本地
      diary.synced = false;
      await DiaryStorage.addDiary(diary);

      // 2. 尝试同步到云端
      try {
        const result = await DiaryService.createDiary(userId, {
          title: diary.title,
          content: diary.content,
          location: diary.location,
          address: diary.address,
          latitude: diary.latitude,
          longitude: diary.longitude,
          weather: diary.weather,
          mood: diary.mood,
          images: diary.images,
          tags: diary.tags,
          is_public: diary.is_public
        });

        if (result.success && result.data) {
          // 更新本地日记为云端版本
          result.data.synced = true;
          await DiaryStorage.updateDiary(result.data);
          
          console.info('[DiarySyncManager] 创建并同步成功');
          return { success: true, message: '创建成功', diary: result.data };
        } else {
          console.warn('[DiarySyncManager] 同步到云端失败，已保存到本地');
          return { success: true, message: '已保存到本地，稍后将自动同步', diary: diary };
        }
      } catch (syncError) {
        console.warn('[DiarySyncManager] 同步到云端失败:', syncError);
        return { success: true, message: '已保存到本地，稍后将自动同步', diary: diary };
      }
    } catch (error) {
      console.error('[DiarySyncManager] 创建日记失败:', error);
      return { success: false, message: '创建失败: ' + error };
    }
  }

  /**
   * 更新日记并同步到云端
   */
  static async updateAndSync(diary: Diary): Promise<OperationResult> {
    try {
      // 1. 更新本地
      diary.synced = false;
      await DiaryStorage.updateDiary(diary);

      // 2. 如果有云端ID，尝试同步到云端
      if (diary.id) {
        try {
          const result = await DiaryService.updateDiary(diary.id, {
            title: diary.title,
            content: diary.content,
            location: diary.location,
            latitude: diary.latitude,
            longitude: diary.longitude,
            weather: diary.weather,
            mood: diary.mood,
            images: diary.images,
            tags: diary.tags,
            is_public: diary.is_public
          });

          if (result.success && result.data) {
            result.data.synced = true;
            await DiaryStorage.updateDiary(result.data);
            
            console.info('[DiarySyncManager] 更新并同步成功');
            return { success: true, message: '更新成功' };
          }
        } catch (syncError) {
          console.warn('[DiarySyncManager] 同步到云端失败:', syncError);
        }
      }

      return { success: true, message: '已保存到本地，稍后将自动同步' };
    } catch (error) {
      console.error('[DiarySyncManager] 更新日记失败:', error);
      return { success: false, message: '更新失败: ' + error };
    }
  }

  /**
   * 删除日记并同步到云端
   */
  static async deleteAndSync(diary: Diary): Promise<OperationResult> {
    try {
      // 1. 如果有云端ID，先删除云端
      if (diary.id) {
        try {
          await DiaryService.deleteDiary(diary.id);
          console.info('[DiarySyncManager] 云端删除成功');
        } catch (syncError) {
          console.warn('[DiarySyncManager] 云端删除失败:', syncError);
        }
      }

      // 2. 删除本地
      await DiaryStorage.deleteDiary(diary.id || diary.local_id!);
      
      console.info('[DiarySyncManager] 删除日记成功');
      return { success: true, message: '删除成功' };
    } catch (error) {
      console.error('[DiarySyncManager] 删除日记失败:', error);
      return { success: false, message: '删除失败: ' + error };
    }
  }

  /**
   * 检查是否正在同步
   */
  static isCurrentlySyncing(): boolean {
    return DiarySyncManager.isSyncing;
  }
}
