/**
 * 日记数据模型
 */
export interface Diary {
  id?: number;           // 云端数据库ID
  uuid?: string;         // 唯一标识符（本地和云端通用，用于防重复）
  user_id: number;
  title: string;         // 标题（使用地点作为标题）
  content: string;       // 内容（可以为空字符串）
  location?: string;
  address?: string;      // 完整地址信息
  latitude?: number;
  longitude?: number;
  weather?: string;
  mood?: string;
  images?: string[];
  tags?: string[];
  is_public: boolean;
  created_at?: string;
  updated_at?: string;
  synced?: boolean;
  local_id?: string;     // 本地临时ID（已废弃，使用uuid替代）
}

/**
 * 日记列表数据
 */
export interface DiaryListData {
  diaries: Diary[];
  total: number;
  page: number;
  page_size: number;
}

/**
 * 日记列表响应
 */
export interface DiaryListResponse {
  success: boolean;
  message: string;
  code: number;
  data: DiaryListData;
}

/**
 * 日记详情响应
 */
export interface DiaryDetailResponse {
  success: boolean;
  message: string;
  code: number;
  data: Diary;
}

/**
 * 日记创建/更新请求
 */
export interface DiaryRequest {
  title: string;  // 标题（前端使用地点作为标题）
  content: string;  // 内容（可以为空字符串）
  location?: string;
  address?: string;  // 完整地址信息
  latitude?: number;
  longitude?: number;
  weather?: string;
  mood?: string;
  images?: string[];
  tags?: string[];
  is_public?: boolean;
}

/**
 * 日记同步数据
 */
export interface DiarySyncData {
  synced_count: number;
  failed_count: number;
  diaries: Diary[];
}

/**
 * 日记同步响应
 */
export interface DiarySyncResponse {
  success: boolean;
  message: string;
  code: number;
  data: DiarySyncData;
}

/**
 * 通用操作结果
 */
export interface OperationResult {
  success: boolean;
  message: string;
}

/**
 * 创建日记结果
 */
export interface CreateDiaryResult extends OperationResult {
  diary?: Diary;
}

/**
 * 删除日记响应
 */
export interface DeleteDiaryResponse {
  success: boolean;
  message: string;
  code?: number;
}
