/**
 * 响应式断点系统
 * 参考华为多设备响应式布局规范
 * 断点定义：
 * - xs: [0, 320)   折叠屏（折叠状态）
 * - sm: [320, 600) 手机
 * - md: [600, 840) 平板
 * - lg: [840, +∞)  大屏/车机
 */

import { display, mediaquery } from '@kit.ArkUI';

// 断点类型枚举
export type BreakpointType = 'xs' | 'sm' | 'md' | 'lg';

// 断点配置接口
export interface BreakpointConfig<T> {
  xs?: T;
  sm?: T;
  md?: T;
  lg?: T;
}

// 断点阈值常量
export const BREAKPOINT_XS_MAX = 320;
export const BREAKPOINT_SM_MAX = 600;
export const BREAKPOINT_MD_MAX = 840;

/**
 * 根据屏幕宽度获取当前断点类型
 * @param widthVp 屏幕宽度（vp）
 * @returns 断点类型
 */
export function getBreakpointType(widthVp: number): BreakpointType {
  if (widthVp < BREAKPOINT_XS_MAX) {
    return 'xs';
  } else if (widthVp < BREAKPOINT_SM_MAX) {
    return 'sm';
  } else if (widthVp < BREAKPOINT_MD_MAX) {
    return 'md';
  } else {
    return 'lg';
  }
}

/**
 * 获取当前屏幕宽度（vp）
 */
export function getCurrentScreenWidthVp(): number {
  const displayInfo = display.getDefaultDisplaySync();
  return displayInfo.width / displayInfo.densityPixels;
}

/**
 * 获取当前屏幕高度（vp）
 */
export function getCurrentScreenHeightVp(): number {
  const displayInfo = display.getDefaultDisplaySync();
  return displayInfo.height / displayInfo.densityPixels;
}

/**
 * 获取当前断点
 */
export function getCurrentBreakpoint(): BreakpointType {
  return getBreakpointType(getCurrentScreenWidthVp());
}

/**
 * 判断当前是否为横屏
 */
export function isCurrentLandscape(): boolean {
  return getCurrentScreenWidthVp() > getCurrentScreenHeightVp();
}

/**
 * 从配置中获取指定断点的值
 */
function getConfigValue<T>(config: BreakpointConfig<T>, bp: BreakpointType): T | undefined {
  switch (bp) {
    case 'xs':
      return config.xs;
    case 'sm':
      return config.sm;
    case 'md':
      return config.md;
    case 'lg':
      return config.lg;
    default:
      return undefined;
  }
}

/**
 * 根据断点获取对应值
 * @param config 断点配置
 * @param breakpoint 当前断点
 * @returns 对应断点的值，如果未配置则向下降级
 */
export function getValueByBreakpoint<T>(config: BreakpointConfig<T>, breakpoint: BreakpointType): T | undefined {
  // 优先返回当前断点的值
  const currentValue = getConfigValue(config, breakpoint);
  if (currentValue !== undefined) {
    return currentValue;
  }

  // 使用 switch 获取降级顺序
  let fallbacks: BreakpointType[] = [];
  switch (breakpoint) {
    case 'lg':
      fallbacks = ['md', 'sm', 'xs'];
      break;
    case 'md':
      fallbacks = ['sm', 'xs', 'lg'];
      break;
    case 'sm':
      fallbacks = ['xs', 'md', 'lg'];
      break;
    case 'xs':
      fallbacks = ['sm', 'md', 'lg'];
      break;
  }

  for (let i = 0; i < fallbacks.length; i++) {
    const value = getConfigValue(config, fallbacks[i]);
    if (value !== undefined) {
      return value;
    }
  }

  return undefined;
}

/**
 * 断点系统类 - 用于组件内监听断点变化
 */
export class BreakpointSystem {
  private smListener?: mediaquery.MediaQueryListener;
  private mdListener?: mediaquery.MediaQueryListener;
  private lgListener?: mediaquery.MediaQueryListener;
  private updateCallback?: (breakpoint: BreakpointType) => void;

  /**
   * 注册断点变化监听
   * @param callback 断点变化回调
   */
  register(callback: (breakpoint: BreakpointType) => void): void {
    this.updateCallback = callback;

    // sm断点: 320vp <= width < 600vp
    this.smListener = mediaquery.matchMediaSync('(320vp<=width<600vp)');
    this.smListener.on('change', (result: mediaquery.MediaQueryResult) => {
      if (result.matches) {
        this.updateCallback?.('sm');
      }
    });

    // md断点: 600vp <= width < 840vp
    this.mdListener = mediaquery.matchMediaSync('(600vp<=width<840vp)');
    this.mdListener.on('change', (result: mediaquery.MediaQueryResult) => {
      if (result.matches) {
        this.updateCallback?.('md');
      }
    });

    // lg断点: width >= 840vp
    this.lgListener = mediaquery.matchMediaSync('(840vp<=width)');
    this.lgListener.on('change', (result: mediaquery.MediaQueryResult) => {
      if (result.matches) {
        this.updateCallback?.('lg');
      }
    });

    // 初始化时触发一次
    callback(getCurrentBreakpoint());
  }

  /**
   * 注销断点监听
   */
  unregister(): void {
    this.smListener?.off('change');
    this.mdListener?.off('change');
    this.lgListener?.off('change');
    this.smListener = undefined;
    this.mdListener = undefined;
    this.lgListener = undefined;
    this.updateCallback = undefined;
  }
}

/**
 * 响应式尺寸计算
 * 根据不同断点返回不同的尺寸值
 */
export function responsiveSize(config: BreakpointConfig<number>, breakpoint: BreakpointType): number {
  return getValueByBreakpoint(config, breakpoint) ?? 0;
}

/**
 * 响应式间距
 */
export function responsiveSpacing(breakpoint: BreakpointType): number {
  const spacingConfig: BreakpointConfig<number> = {
    xs: 8,
    sm: 12,
    md: 16,
    lg: 24
  };
  return getValueByBreakpoint(spacingConfig, breakpoint) ?? 12;
}

/**
 * 响应式字体大小基数
 */
export function responsiveFontScale(breakpoint: BreakpointType): number {
  const scaleConfig: BreakpointConfig<number> = {
    xs: 0.85,
    sm: 1.0,
    md: 1.1,
    lg: 1.2
  };
  return getValueByBreakpoint(scaleConfig, breakpoint) ?? 1.0;
}
