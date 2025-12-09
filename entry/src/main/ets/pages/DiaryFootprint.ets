import { router, display } from '@kit.ArkUI';
import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import { Diary } from '../model/DiaryModel';
import { DiaryStorage } from '../utils/DiaryStorage';
import promptAction from '@ohos.promptAction';

screenAdapter.designWidth = 375;

@Entry
@Component
export struct DiaryFootprint {
  @State dateKey: string = '';
  @State dayDiaries: Diary[] = [];
  @State isLoading: boolean = false;
  private scrollController = new Scroller();
  // 响应式布局
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint();
  @State isLandscape: boolean = isCurrentLandscape();
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();
  // 地址颜色映射，保证相同地点使用同一颜色
  private locationColorMap: Map<string, string> = new Map<string, string>();

  async onPageShow() {
    // 从编辑页返回时重新加载数据
    if (this.dateKey) {
      await this.loadDiaries();
    }
  }

  async aboutToAppear() {
    // 注册断点监听
    this.breakpointSystem.register((bp: BreakpointType) => {
      this.currentBreakpoint = bp;
      this.isLandscape = isCurrentLandscape();
    });
    display.on('change', () => {
      screenAdapter.updateScreenSize();
      this.currentBreakpoint = getCurrentBreakpoint();
      this.isLandscape = isCurrentLandscape();
    });

    const params = router.getParams() as Record<string, Object>;
    if (params && params['dateKey']) {
      this.dateKey = params['dateKey'] as string;
      await this.loadDiaries();
    }
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
    display.off('change');
  }

  // 响应式尺寸方法
  getFontSize(base: number): number {
    const scale = this.currentBreakpoint === 'xs' ? 0.9 :
                  this.currentBreakpoint === 'lg' ? 1.15 :
                  this.currentBreakpoint === 'md' ? 1.1 : 1.0;
    return base * scale;
  }

  getSpacing(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 12;
      case 'sm': return 16;
      case 'md': return 20;
      case 'lg': return 24;
      default: return 16;
    }
  }

  getNavBarHeight(): number {
    switch (this.currentBreakpoint) {
      case 'xs': return 90;
      case 'sm': return 100;
      case 'md': return 110;
      case 'lg': return 120;
      default: return 100;
    }
  }

  getContentWidth(): string {
    switch (this.currentBreakpoint) {
      case 'xs': return '100%';
      case 'sm': return '100%';
      case 'md': return '85%';
      case 'lg': return '70%';
      default: return '100%';
    }
  }

  async loadDiaries() {
    this.isLoading = true;
    try {
      // 重新加载时重置颜色映射
      this.locationColorMap.clear();
      const allDiaries = await DiaryStorage.getDiaries();
      // 过滤出当天的日记
      this.dayDiaries = allDiaries.filter(diary => {
        const dKey = this.getDateKey(diary.created_at);
        return dKey === this.dateKey;
      }).sort((a, b) => {
        // 按时间倒序
        const timeA = new Date(a.created_at || 0).getTime();
        const timeB = new Date(b.created_at || 0).getTime();
        return timeB - timeA;
      });
    } catch (error) {
      console.error('[DiaryFootprint] 加载日记失败:', error);
      promptAction.showToast({ message: '加载详情失败' });
    } finally {
      this.isLoading = false;
    }
  }

  getDateKey(dateStr?: string): string {
    try {
      const date = dateStr ? new Date(dateStr) : new Date();
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    } catch (error) {
      return '';
    }
  }

  formatTime(dateStr?: string): string {
    if (!dateStr) {
      return '';
    }
    try {
      const date = new Date(dateStr);
      const hours = String(date.getHours()).padStart(2, '0');
      const minutes = String(date.getMinutes()).padStart(2, '0');
      return `${hours}:${minutes}`;
    } catch (e) {
      return '';
    }
  }

  build() {
    Column() {
      // 顶部导航栏 - 响应式
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(this.getFontSize(24))
          .fontColor([ColorTheme.getColor('textPrimary')])
          .onClick(() => {
            router.back();
          })

        Text(this.dateKey)
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 24 })
      }
      .width('100%')
      .height(this.getNavBarHeight())
      .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 44 })
      .backgroundColor(ColorTheme.getColor('cardBackground'))

      if (this.isLoading) {
        LoadingProgress()
          .width(this.getFontSize(40))
          .height(this.getFontSize(40))
          .margin({ top: 100 })
      } else if (this.dayDiaries.length === 0) {
        Column({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.doc_text_badge_magnifyingglass'))
            .fontSize(this.getFontSize(48))
            .fontColor([ColorTheme.getColor('textMuted')])
          Text('未找到相关记录')
            .fontSize(this.getFontSize(14))
            .fontColor(ColorTheme.getColor('textMuted'))
        }
        .width('100%')
        .margin({ top: 100 })
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll(this.scrollController) {
          Stack() {
            // 背景垂直线，贯穿所有节点
            Line()
              .width(2)
              .height('100%')
              .backgroundColor('#E0E0E0')
              .margin({ left: 16 })

            // 日记列表
            Column() {
              ForEach(this.dayDiaries, (diary: Diary, index: number) => {
                this.DiaryItem(diary, index)
              })
            }
          }
          .width(this.getContentWidth())
          .align(Alignment.TopStart)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: this.getSpacing(), right: this.getSpacing(), top: this.getSpacing(), bottom: this.getSpacing() })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ColorTheme.getColor('pageBackground'))
  }

  // 时间轴颜色数组
  private readonly TIME_COLORS = ['#8D6E63', '#1E88E5', '#26A69A', '#FFA726', '#AB47BC', '#EF5350'];

  getCurrentColor(index: number): string {
    return this.getDiaryColor(index);
  }

  getPrevColor(index: number): string {
    return index === 0 ? '#E0E0E0' : this.getDiaryColor(index - 1);
  }

  private getDiaryColor(index: number): string {
    const diary = this.dayDiaries[index];
    const rawLocation = (diary?.location || '').trim();
    if (rawLocation.length > 0) {
      const cached = this.locationColorMap.get(rawLocation);
      if (cached) {
        return cached;
      }
      const color = this.TIME_COLORS[this.locationColorMap.size % this.TIME_COLORS.length];
      this.locationColorMap.set(rawLocation, color);
      return color;
    }
    // 无地点则按索引色，保持区分
    return this.TIME_COLORS[index % this.TIME_COLORS.length];
  }

  @Builder
  DiaryItem(diary: Diary, index: number) {
    Row({ space: 12 }) {
      // 1. 左侧圆点，居中覆盖在垂直线上
      Column() {
        Circle({ width: 10, height: 10 })
          .fill(this.getCurrentColor(index))
      }
      .width(32)
      .alignItems(HorizontalAlign.Center)

      // 2. 右侧内容卡片
      Column({ space: 8 }) {
        // 时间和地点行
        Row({ space: 8 }) {
          // 时间
          Text(this.formatTime(diary.created_at))
            .fontSize(this.getFontSize(12))
            .fontColor(ColorTheme.getColor('textMuted'))
            .fontWeight(FontWeight.Medium)

          // 地点
          if (diary.location) {
            Row({ space: 4 }) {
              SymbolGlyph($r('sys.symbol.local_fill'))
                .fontSize(this.getFontSize(12))
                .fontColor([this.getCurrentColor(index)])
              Text(diary.location)
                .fontSize(this.getFontSize(12))
                .fontColor(ColorTheme.getColor('textPrimary'))
                .fontWeight(FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .layoutWeight(1)
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 内容
        if (diary.content) {
          Text(diary.content)
            .fontSize(this.getFontSize(13))
            .fontColor(ColorTheme.getColor('textMuted'))
            .lineHeight(this.getFontSize(20))
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }

        // 图片
        if (diary.images && diary.images.length > 0) {
          Image(diary.images[0])
            .width('100%')
            .height(120)
            .borderRadius(10)
            .objectFit(ImageFit.Cover)
        }
      }
      .layoutWeight(1)
      .padding(12)
      .backgroundColor(ColorTheme.getColor('cardBackground'))
      .borderRadius(12)
      .border({ width: 1, color: ColorTheme.getColor('divider') })
      .onClick(() => {
        const diaryId = diary.id || diary.local_id;
        if (diaryId) {
          router.pushUrl({
            url: 'pages/DiaryEdit',
            params: { diaryId: diaryId }
          }).catch((err: Error) => {
            console.error('[DiaryFootprint] 跳转编辑页失败:', err);
            promptAction.showToast({ message: '打开编辑页失败' });
          });
        }
      })
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .margin({ bottom: 12 })
  }
}