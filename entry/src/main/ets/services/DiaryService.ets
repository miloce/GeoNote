import http from '@ohos.net.http';
import {
  Diary,
  DiaryListResponse,
  DiaryDetailResponse,
  DiaryRequest,
  DiarySyncResponse,
  DeleteDiaryResponse
} from '../model/DiaryModel';

/**
 * HTTP请求选项接口
 */
interface HttpRequestOptions {
  method: http.RequestMethod;
  header: ESObject;
  extraData?: string;
  expectDataType: http.HttpDataType;
  connectTimeout: number;
  readTimeout: number;
}

/**
 * 日记服务 - 处理与后端API的交互
 */
export class DiaryService {
  // API基础URL - 根据实际部署修改
  private static readonly BASE_URL: string = 'https://note.luozhinet.com/api.php';
  
  /**
   * 发送HTTP请求
   */
  private static async sendRequest(url: string, method: http.RequestMethod, data?: ESObject): Promise<http.HttpResponse> {
    const httpRequest: http.HttpRequest = http.createHttp();
    
    try {
      const header: ESObject = { 'Content-Type': 'application/json' };
      const options: HttpRequestOptions = {
        method: method,
        header: header,
        extraData: data ? JSON.stringify(data) : undefined,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 60000,
        readTimeout: 60000
      };
      
      const response: http.HttpResponse = await httpRequest.request(url, options);
      return response;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 获取日记列表
   */
  static async getDiaries(userId: number, page: number, pageSize: number): Promise<DiaryListResponse> {
    try {
      const requestData: ESObject = {
        'action': 'get_diaries',
        'user_id': userId,
        'page': page,
        'page_size': pageSize
      };
      
      const response: http.HttpResponse = await DiaryService.sendRequest(
        DiaryService.BASE_URL,
        http.RequestMethod.POST,
        requestData
      );

      if (response.responseCode === 200) {
        const resultStr: string = response.result as string;
        const result: DiaryListResponse = JSON.parse(resultStr) as DiaryListResponse;
        return result;
      } else {
        throw new Error(`HTTP ${response.responseCode}`);
      }
    } catch (error) {
      console.error('[DiaryService] 获取日记列表失败:', error);
      throw new Error('获取日记列表失败');
    }
  }

  /**
   * 获取日记详情
   */
  static async getDiaryById(diaryId: number): Promise<DiaryDetailResponse> {
    try {
      const requestData: ESObject = {
        'action': 'get_diary',
        'diary_id': diaryId
      };
      
      const response: http.HttpResponse = await DiaryService.sendRequest(
        DiaryService.BASE_URL,
        http.RequestMethod.POST,
        requestData
      );

      if (response.responseCode === 200) {
        const resultStr: string = response.result as string;
        const result: DiaryDetailResponse = JSON.parse(resultStr) as DiaryDetailResponse;
        return result;
      } else {
        throw new Error(`HTTP ${response.responseCode}`);
      }
    } catch (error) {
      console.error('[DiaryService] 获取日记详情失败:', error);
      throw new Error('获取日记详情失败');
    }
  }

  /**
   * 创建日记
   */
  static async createDiary(userId: number, diary: DiaryRequest): Promise<DiaryDetailResponse> {
    try {
      const requestData: ESObject = {
        'action': 'create_diary',
        'user_id': userId,
        'title': diary.title,
        'content': diary.content,
        'location': diary.location,
        'address': diary.address,
        'latitude': diary.latitude,
        'longitude': diary.longitude,
        'weather': diary.weather,
        'mood': diary.mood,
        'images': diary.images,
        'tags': diary.tags,
        'is_public': diary.is_public
      };
      
      const response: http.HttpResponse = await DiaryService.sendRequest(
        DiaryService.BASE_URL,
        http.RequestMethod.POST,
        requestData
      );

      if (response.responseCode === 200) {
        const resultStr: string = response.result as string;
        const result: DiaryDetailResponse = JSON.parse(resultStr) as DiaryDetailResponse;
        return result;
      } else {
        throw new Error(`HTTP ${response.responseCode}`);
      }
    } catch (error) {
      console.error('[DiaryService] 创建日记失败:', error);
      throw new Error('创建日记失败');
    }
  }

  /**
   * 更新日记
   */
  static async updateDiary(diaryId: number, diary: DiaryRequest): Promise<DiaryDetailResponse> {
    try {
      const requestData: ESObject = {
        'action': 'update_diary',
        'diary_id': diaryId,
        'title': diary.title,
        'content': diary.content,
        'location': diary.location,
        'address': diary.address,
        'latitude': diary.latitude,
        'longitude': diary.longitude,
        'weather': diary.weather,
        'mood': diary.mood,
        'images': diary.images,
        'tags': diary.tags,
        'is_public': diary.is_public
      };
      
      const response: http.HttpResponse = await DiaryService.sendRequest(
        DiaryService.BASE_URL,
        http.RequestMethod.POST,
        requestData
      );

      if (response.responseCode === 200) {
        const resultStr: string = response.result as string;
        const result: DiaryDetailResponse = JSON.parse(resultStr) as DiaryDetailResponse;
        return result;
      } else {
        throw new Error(`HTTP ${response.responseCode}`);
      }
    } catch (error) {
      console.error('[DiaryService] 更新日记失败:', error);
      throw new Error('更新日记失败');
    }
  }

  /**
   * 删除日记
   */
  static async deleteDiary(diaryId: number): Promise<DeleteDiaryResponse> {
    try {
      const requestData: ESObject = {
        'action': 'delete_diary',
        'diary_id': diaryId
      };
      
      const response: http.HttpResponse = await DiaryService.sendRequest(
        DiaryService.BASE_URL,
        http.RequestMethod.POST,
        requestData
      );

      if (response.responseCode === 200) {
        const resultStr: string = response.result as string;
        const result: DeleteDiaryResponse = JSON.parse(resultStr) as DeleteDiaryResponse;
        return result;
      } else {
        throw new Error(`HTTP ${response.responseCode}`);
      }
    } catch (error) {
      console.error('[DiaryService] 删除日记失败:', error);
      throw new Error('删除日记失败');
    }
  }

  /**
   * 同步本地日记到云端
   */
  static async syncDiaries(userId: number, diaries: Diary[]): Promise<DiarySyncResponse> {
    try {
      const requestData: ESObject = {
        'action': 'sync_diaries',
        'user_id': userId,
        'diaries': diaries
      };
      
      const response: http.HttpResponse = await DiaryService.sendRequest(
        DiaryService.BASE_URL,
        http.RequestMethod.POST,
        requestData
      );

      if (response.responseCode === 200) {
        const resultStr: string = response.result as string;
        const result: DiarySyncResponse = JSON.parse(resultStr) as DiarySyncResponse;
        return result;
      } else {
        throw new Error(`HTTP ${response.responseCode}`);
      }
    } catch (error) {
      console.error('[DiaryService] 同步日记失败:', error);
      throw new Error('同步日记失败');
    }
  }

  /**
   * 从云端拉取日记
   */
  static async pullDiaries(userId: number, lastSyncTime: string): Promise<DiaryListResponse> {
    try {
      console.log('[DiaryService] pullDiaries - userId:', userId, 'lastSyncTime:', lastSyncTime);
      
      if (!userId || userId === 0) {
        console.error('[DiaryService] 无效的userId:', userId);
        throw new Error('用户ID无效');
      }
      
      const requestData: ESObject = {
        'action': 'pull_diaries',
        'user_id': userId,
        'last_sync_time': lastSyncTime
      };
      
      console.log('[DiaryService] 请求数据:', JSON.stringify(requestData));
      
      const response: http.HttpResponse = await DiaryService.sendRequest(
        DiaryService.BASE_URL,
        http.RequestMethod.POST,
        requestData
      );

      if (response.responseCode === 200) {
        const resultStr: string = response.result as string;
        const result: DiaryListResponse = JSON.parse(resultStr) as DiaryListResponse;
        return result;
      } else {
        throw new Error(`HTTP ${response.responseCode}`);
      }
    } catch (error) {
      console.error('[DiaryService] 拉取日记失败:', error);
      throw new Error('拉取日记失败');
    }
  }
}
