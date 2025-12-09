import { router, display } from '@kit.ArkUI';
import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter";
import { ColorTheme } from "../utils/colorTheme";
import { Diary } from '../model/DiaryModel';
import { DiaryStorage } from '../utils/DiaryStorage';
import promptAction from '@ohos.promptAction';

screenAdapter.designWidth = 375;

@Entry
@Component
export struct DiaryEdit {
  @State diaryId?: number | string = undefined;
  @State diary: Diary | null = null;
  @State isLoading: boolean = false;
  @State isSaving: boolean = false;
  
  // 编辑字段
  @State editLocation: string = '';
  @State editContent: string = '';
  @State contentLength: number = 0;
  
  private scrollController = new Scroller();
  // 响应式布局
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint();
  @State isLandscape: boolean = isCurrentLandscape();
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

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
    if (params && params['diaryId']) {
      this.diaryId = params['diaryId'] as number | string;
      await this.loadDiary();
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
      case 'md': return 24;
      case 'lg': return 32;
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
      case 'md': return '80%';
      case 'lg': return '60%';
      default: return '100%';
    }
  }

  async loadDiary() {
    if (!this.diaryId) {
      promptAction.showToast({ message: '日记ID无效' });
      router.back();
      return;
    }

    this.isLoading = true;
    try {
      const allDiaries = await DiaryStorage.getDiaries();
      this.diary = allDiaries.find(d => 
        d.id === this.diaryId || d.local_id === this.diaryId
      ) || null;

      if (this.diary) {
        // 初始化编辑字段
        this.editLocation = this.diary.location || '';
        this.editContent = this.diary.content || '';
        this.contentLength = this.editContent.length;
      } else {
        promptAction.showToast({ message: '未找到该日记' });
        router.back();
      }
    } catch (error) {
      console.error('[DiaryEdit] 加载日记失败:', error);
      promptAction.showToast({ message: '加载日记失败' });
      router.back();
    } finally {
      this.isLoading = false;
    }
  }

  async saveDiary() {
    if (!this.diary) {
      return;
    }

    // 验证必填字段
    if (!this.editLocation.trim() && !this.editContent.trim()) {
      promptAction.showToast({ message: '地点和内容至少填写一项' });
      return;
    }

    this.isSaving = true;
    try {
      // 更新日记对象 - ArkTS不支持对象展开，手动复制属性
      const updatedDiary: Diary = {
        id: this.diary.id,
        uuid: this.diary.uuid,
        user_id: this.diary.user_id,
        title: this.editLocation.trim() || '无标题',
        content: this.editContent.trim(),
        location: this.editLocation.trim(),
        latitude: this.diary.latitude,
        longitude: this.diary.longitude,
        weather: this.diary.weather,
        mood: this.diary.mood,
        images: this.diary.images,
        tags: this.diary.tags || [],
        is_public: this.diary.is_public,
        created_at: this.diary.created_at,
        updated_at: new Date().toISOString(),
        synced: false,
        local_id: this.diary.local_id
      };

      await DiaryStorage.updateDiary(updatedDiary);
      promptAction.showToast({ message: '保存成功' });
      
      // 返回上一页
      router.back();
    } catch (error) {
      console.error('[DiaryEdit] 保存日记失败:', error);
      promptAction.showToast({ message: '保存失败' });
    } finally {
      this.isSaving = false;
    }
  }

  async deleteDiary() {
    if (!this.diary) {
      return;
    }

    // 显示确认对话框
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这条日记吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF0000',
        action: async () => {
          try {
            const deleteId = this.diary!.id || this.diary!.local_id;
            if (deleteId) {
              await DiaryStorage.deleteDiary(deleteId);
              promptAction.showToast({ message: '删除成功' });
              router.back();
            }
          } catch (error) {
            console.error('[DiaryEdit] 删除日记失败:', error);
            promptAction.showToast({ message: '删除失败' });
          }
        }
      }
    });
  }

  formatDateTime(dateStr?: string): string {
    if (!dateStr) {
      return '';
    }
    try {
      const date = new Date(dateStr);
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      const hours = String(date.getHours()).padStart(2, '0');
      const minutes = String(date.getMinutes()).padStart(2, '0');
      return `${year}-${month}-${day} ${hours}:${minutes}`;
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

        Text('编辑日记')
          .fontSize(this.getFontSize(18))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 删除按钮
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize(this.getFontSize(22))
          .fontColor(['#FF0000'])
          .onClick(() => {
            this.deleteDiary();
          })
      }
      .width('100%')
      .height(this.getNavBarHeight())
      .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 44 })
      .backgroundColor(ColorTheme.getColor('cardBackground'))

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(this.getFontSize(40))
            .height(this.getFontSize(40))
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.diary) {
        Scroll(this.scrollController) {
          Column({ space: 20 }) {
            // 时间信息卡片
            Row() {
              SymbolGlyph($r('sys.symbol.clock'))
                .fontSize(this.getFontSize(16))
                .fontColor([ColorTheme.getColor('textMuted')])
              Text(this.formatDateTime(this.diary.created_at))
                .fontSize(this.getFontSize(13))
                .fontColor(ColorTheme.getColor('textMuted'))
                .margin({ left: 6 })
            }
            .width('100%')
            .padding(12)
            .backgroundColor(ColorTheme.getColor('cardBackground'))
            .borderRadius(10)

            // 地点输入卡片
            Column({ space: 10 }) {
              Row({ space: 6 }) {
                SymbolGlyph($r('sys.symbol.map_badge_local'))
                  .fontSize(this.getFontSize(16))
                  .fontColor(['#8D6E63'])
                Text('地点')
                  .fontSize(this.getFontSize(15))
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorTheme.getColor('textPrimary'))
              }
              
              TextInput({ text: this.editLocation, placeholder: '输入地点...' })
                .fontSize(this.getFontSize(15))
                .fontColor(ColorTheme.getColor('textPrimary'))
                .placeholderColor(ColorTheme.getColor('textMuted'))
                .backgroundColor(ColorTheme.getColor('pageBackground'))
                .borderRadius(10)
                .padding({ left: 14, right: 14, top: 12, bottom: 12 })
                .onChange((value: string) => {
                  this.editLocation = value;
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(ColorTheme.getColor('cardBackground'))
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)

            // 内容输入卡片
            Column({ space: 10 }) {
              Row() {
                Row({ space: 6 }) {
                  SymbolGlyph($r('sys.symbol.doc_text'))
                    .fontSize(this.getFontSize(16))
                    .fontColor(['#1E88E5'])
                  Text('内容')
                    .fontSize(this.getFontSize(15))
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ColorTheme.getColor('textPrimary'))
                }
                .layoutWeight(1)
                
                Text(`${this.contentLength}/100`)
                  .fontSize(this.getFontSize(12))
                  .fontColor(ColorTheme.getColor('textMuted'))
              }
              .width('100%')
              
              TextArea({ text: this.editContent, placeholder: '写下你的记录...' })
                .fontSize(this.getFontSize(14))
                .fontColor(ColorTheme.getColor('textPrimary'))
                .placeholderColor(ColorTheme.getColor('textMuted'))
                .backgroundColor(ColorTheme.getColor('pageBackground'))
                .borderRadius(10)
                .padding(14)
                .height(this.currentBreakpoint === 'lg' ? 260 : 180)
                .onChange((value: string) => {
                  if (value.length <= 100) {
                    this.editContent = value;
                    this.contentLength = value.length;
                  }
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(ColorTheme.getColor('cardBackground'))
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)

            // 保存按钮
            Button(this.isSaving ? '保存中...' : '保存修改')
              .width('100%')
              .height(50)
              .fontSize(this.getFontSize(16))
              .fontWeight(FontWeight.Medium)
              .fontColor('#5D4037')
              .backgroundColor('#FFE082')
              .borderRadius(25)
              .enabled(!this.isSaving)
              .onClick(() => {
                this.saveDiary();
              })
          }
          .width(this.getContentWidth())
          .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 16, bottom: 32 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ColorTheme.getColor('pageBackground'))
  }
}
