
import { display } from '@kit.ArkUI';

interface ScreenInfo {
  width: number;
  height: number;
}

interface ScreenAdapter {
  designWidth: number;
  screenWidth: number;
  screenHeight: number;
  scale: number;
  toPx: (designPx: number) => number;
  toPy: (designPx: number) => number;
  updateScreenSize: () => void;
}

const getScreenInfo = (): ScreenInfo => {
  const displayInfo = display.getDefaultDisplaySync();
  const info: ScreenInfo = {
    width: displayInfo.width / displayInfo.densityPixels,
    height: displayInfo.height / displayInfo.densityPixels
  };
  return info;
};

export const screenAdapter: ScreenAdapter = {
  designWidth: 750,
  screenWidth: getScreenInfo().width,
  screenHeight: getScreenInfo().height,
  get scale() {
    return screenAdapter.screenWidth / screenAdapter.designWidth;
  },
  toPx(designPx: number) {
    return designPx * screenAdapter.scale;
  },
  toPy(designPy: number) {
    return designPy * screenAdapter.scale;
  },
  updateScreenSize() {
    const info = getScreenInfo();
    screenAdapter.screenWidth = info.width;
    screenAdapter.screenHeight = info.height;
  }
};

export const toPx = screenAdapter.toPx;

export const toPy = screenAdapter.toPy;

// 屏幕方向判断
export const isLandscape = (): boolean => {
  return screenAdapter.screenWidth > screenAdapter.screenHeight;
};

export const isPortrait = (): boolean => {
  return screenAdapter.screenWidth <= screenAdapter.screenHeight;
};

// 设备类型判断（基于较小边，适配横竖屏）
// 手机: 360vp, 折叠屏: 740vp, 平板: 800vp
export const isTablet = (): boolean => {
  const minSize = Math.min(screenAdapter.screenWidth, screenAdapter.screenHeight);
  return minSize >= 800; // 平板 ≥800vp
};

export const isFoldable = (): boolean => {
  const minSize = Math.min(screenAdapter.screenWidth, screenAdapter.screenHeight);
  return minSize >= 600 && minSize < 800; // 折叠屏 600-800vp
};

export const isPhone = (): boolean => {
  const minSize = Math.min(screenAdapter.screenWidth, screenAdapter.screenHeight);
  return minSize < 600; // 手机 <600vp
};

// 导出断点系统
export {
  BreakpointType,
  BreakpointConfig,
  BreakpointSystem,
  getBreakpointType,
  getCurrentBreakpoint,
  getCurrentScreenWidthVp,
  getCurrentScreenHeightVp,
  isCurrentLandscape,
  getValueByBreakpoint,
  responsiveSize,
  responsiveSpacing,
  responsiveFontScale,
  BREAKPOINT_XS_MAX,
  BREAKPOINT_SM_MAX,
  BREAKPOINT_MD_MAX
} from './BreakpointSystem';
