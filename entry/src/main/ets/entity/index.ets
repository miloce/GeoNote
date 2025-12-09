
export interface PixArkUIInterface {
  width?: number;
  height?: number;
  left?: number;
  clip?: boolean;
  top?: number;
  backgroundImage?: ResourceStr;
  fillPaints?: gradient[],
  componentId: string;
  name?: string;
  borderLeftWeight?: number;
  borderRightWeight?: number;
  borderTopWeight?: number;
  borderBottomWeight?: number;
  strokeWeight?: number;
  BLCRadius?: number;
  BRCRadius?: number;
  TLCRadius?: number;
  TRCRadius?: number;
  cornerRadius?: number;
  borderColor?: string;
  nodeText?: string;
  fontColor?: string;
  fontFamily?: string;
  fontWeight?: string;
  fontSize?: number;
  textAlign?: number;
  lineHeight?: string;
  letterSpacing?: string;
  decoration?: number;
  visibility?: Visibility;
  autoLayoutByParent?: boolean;
  maxLines?: number;
  angle?: number;
  opacity?: number;
  conflictInteractionIds?: string[];
  onClick?: Function;
  onMouse?: Function;
  pathString?: string;
  componentNormName?: string;
}

interface linearGradient {
  angle?: string | number;
  direction?: GradientDirection;
  colors: [
    ResourceColor,
    number
  ][];
  repeating?: boolean;

}

interface radialGradient {
  center: number[],
  radius: number,
  colors:[ResourceColor,
    number][]
}

export interface gradient {
  linearGradient?: linearGradient;
  radialGradient?:radialGradient;
  backgroundImage?: ResourceStr;
  backgroundImageSize?: ImageSize;
  backgroundColor?: string;
}
