/**
 * 用户数据模型
 */
export interface User {
  id: number;
  username: string;
  email: string;
  nickname?: string;
  avatar?: string;
  huawei_union_id?: string;
  huawei_open_id?: string;
  status: string;
  last_login?: string;
  created_at: string;
  updated_at: string;
  has_password?: boolean;
  username_modified?: boolean;
  is_new_user?: boolean;
}

/**
 * 登录响应数据
 */
export interface LoginResponse {
  success: boolean;
  message: string;
  code: number;
  data: User;
}

/**
 * 注册响应数据
 */
export interface RegisterResponse {
  success: boolean;
  message: string;
  code: number;
  data: User;
}

/**
 * 通用API响应
 */
export interface ApiResponse<T = Record<string, string | number | boolean>> {
  success: boolean;
  message: string;
  code: number;
  data?: T;
  error_details?: Record<string, string | number | boolean>;
}
