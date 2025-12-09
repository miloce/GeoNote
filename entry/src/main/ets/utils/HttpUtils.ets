import http from '@ohos.net.http';

/**
 * HTTP工具类 - 用于与后端API通信
 */
export class HttpUtils {
  // API基础URL
  private static readonly BASE_URL = 'https://note.luozhinet.com/api.php';
  
  /**
   * 发送POST请求
   * @param url 请求URL（如果为空则使用BASE_URL）
   * @param data 请求数据
   * @returns Promise<string> 响应数据
   */
  static async httpRequestPost(url: string, data: Object): Promise<string> {
    return new Promise((resolve, reject) => {
      // 创建HTTP请求
      const httpRequest = http.createHttp();
      
      // 使用基础URL或自定义URL
      const requestUrl = url || HttpUtils.BASE_URL;
      
      console.log('[HttpUtils] 发送POST请求:', requestUrl);
      console.log('[HttpUtils] 请求数据:', JSON.stringify(data));
      
      // 发送请求
      httpRequest.request(
        requestUrl,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
          },
          extraData: data,
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 60000,
          readTimeout: 60000,
        },
        (err, data) => {
          if (!err) {
            if (data.responseCode === 200) {
              const result = data.result as string;
              console.log('[HttpUtils] 请求成功，响应数据:', result.substring(0, 200));
              resolve(result);
            } else {
              console.error('[HttpUtils] 请求失败，状态码:', data.responseCode);
              reject(new Error(`HTTP ${data.responseCode}: ${data.result}`));
            }
          } else {
            console.error('[HttpUtils] 请求错误:', JSON.stringify(err));
            reject(err);
          }
          
          // 销毁请求
          httpRequest.destroy();
        }
      );
    });
  }
  
  /**
   * 发送GET请求
   * @param url 请求URL（如果为空则使用BASE_URL）
   * @param params 查询参数
   * @returns Promise<string> 响应数据
   */
  static async httpRequestGet(url: string, params?: Record<string, string>): Promise<string> {
    return new Promise((resolve, reject) => {
      // 创建HTTP请求
      const httpRequest = http.createHttp();
      
      // 使用基础URL或自定义URL
      let requestUrl = url || HttpUtils.BASE_URL;
      
      // 添加查询参数
      if (params) {
        const queryString = Object.keys(params)
          .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
          .join('&');
        requestUrl += (requestUrl.includes('?') ? '&' : '?') + queryString;
      }
      
      console.log('[HttpUtils] 发送GET请求:', requestUrl);
      
      // 发送请求
      httpRequest.request(
        requestUrl,
        {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json',
          },
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 60000,
          readTimeout: 60000,
        },
        (err, data) => {
          if (!err) {
            if (data.responseCode === 200) {
              const result = data.result as string;
              console.log('[HttpUtils] 请求成功，响应数据:', result.substring(0, 200));
              resolve(result);
            } else {
              console.error('[HttpUtils] 请求失败，状态码:', data.responseCode);
              reject(new Error(`HTTP ${data.responseCode}: ${data.result}`));
            }
          } else {
            console.error('[HttpUtils] 请求错误:', JSON.stringify(err));
            reject(err);
          }
          
          // 销毁请求
          httpRequest.destroy();
        }
      );
    });
  }
}
