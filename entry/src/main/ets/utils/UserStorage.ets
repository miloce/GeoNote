import preferences from '@ohos.data.preferences';
import { User } from '../model/UserModel';

/**
 * 用户数据存储工具类
 */
export class UserStorage {
  private static readonly PREFERENCES_NAME = 'user_preferences';
  private static readonly USER_KEY = 'current_user';

  /**
   * 保存用户信息
   * @param user 用户对象
   */
  static async saveUser(user: User): Promise<void> {
    try {
      const context = getContext();
      const prefs = await preferences.getPreferences(context, UserStorage.PREFERENCES_NAME);

      // 将用户对象转换为JSON字符串
      const userJson = JSON.stringify(user);
      await prefs.put(UserStorage.USER_KEY, userJson);
      await prefs.flush();

      console.log('[UserStorage] 用户信息已保存:', user.username);
    } catch (error) {
      console.error('[UserStorage] 保存用户信息失败:', error);
      throw new Error(`保存用户信息失败: ${error}`);
    }
  }

  /**
   * 获取用户信息
   * @returns Promise<User | null> 用户对象或null
   */
  static async getUser(): Promise<User | null> {
    try {
      const context = getContext();
      const prefs = await preferences.getPreferences(context, UserStorage.PREFERENCES_NAME);

      const userJson = await prefs.get(UserStorage.USER_KEY, '') as string;

      if (userJson) {
        const user = JSON.parse(userJson) as User;
        console.log('[UserStorage] 获取用户信息成功:', user.username);
        return user;
      } else {
        console.log('[UserStorage] 未找到用户信息');
        return null;
      }
    } catch (error) {
      console.error('[UserStorage] 获取用户信息失败:', error);
      return null;
    }
  }

  /**
   * 清除用户信息（登出）
   */
  static async clearUser(): Promise<void> {
    try {
      const context = getContext();
      const prefs = await preferences.getPreferences(context, UserStorage.PREFERENCES_NAME);

      await prefs.delete(UserStorage.USER_KEY);
      await prefs.flush();

      console.log('[UserStorage] 用户信息已清除');
    } catch (error) {
      console.error('[UserStorage] 清除用户信息失败:', error);
      throw new Error(`清除用户信息失败: ${error}`);
    }
  }

  /**
   * 检查是否已登录
   * @returns Promise<boolean> 是否已登录
   */
  static async isLoggedIn(): Promise<boolean> {
    const user = await UserStorage.getUser();
    return user !== null;
  }
}
