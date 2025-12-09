import { screenAdapter, toPx, toPy, BreakpointSystem, BreakpointType, getCurrentBreakpoint, isCurrentLandscape } from "../utils/screenAdapter"
import { ColorTheme } from "../utils/colorTheme";
import { router, display } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { HttpUtils } from '../utils/HttpUtils';
import { ApiResponse } from '../model/UserModel';
import { UserStorage } from '../utils/UserStorage';

screenAdapter.designWidth = 375;

interface FeedbackData {
  id?: number;
  title: string;
  content: string;
  type: string;
  status?: string;
  reply?: string;
  created_at?: string;
}

interface SubmitFeedbackRequest {
  action: string;
  user_id?: number;
  username?: string;
  email?: string;
  title: string;
  content: string;
  type: string;
}

interface MyFeedbacksRequest {
  action: string;
  user_id: number;
}

@Entry
@Component
export struct Feedback {
  @State feedbackType: string = 'general'
  @State title: string = ''
  @State content: string = ''
  @State isSubmitting: boolean = false
  @State myFeedbacks: FeedbackData[] = []
  @State showMyFeedbacks: boolean = false
  @State isLoadingFeedbacks: boolean = false
  // 响应式布局
  @State currentBreakpoint: BreakpointType = getCurrentBreakpoint();
  @State isLandscape: boolean = isCurrentLandscape();
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();

  aboutToAppear() {
    this.breakpointSystem.register((bp: BreakpointType) => {
      this.currentBreakpoint = bp;
      this.isLandscape = isCurrentLandscape();
    });
    display.on('change', () => {
      screenAdapter.updateScreenSize();
      this.currentBreakpoint = getCurrentBreakpoint();
      this.isLandscape = isCurrentLandscape();
    });
  }

  aboutToDisappear() {
    this.breakpointSystem.unregister();
    display.off('change');
  }

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
      case 'xs': return '92%';
      case 'sm': return '90%';
      case 'md': return '70%';
      case 'lg': return '50%';
      default: return '90%';
    }
  }

  build() {
    Column() {
      // 顶部导航栏 - 响应式
      Row() {
        Stack() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(this.getFontSize(24))
            .fontColor([ColorTheme.getColor('textPrimary')])
        }
        .width(24)
        .height(24)
        .onClick(() => router.back())

        Blank()

        Text('意见反馈')
          .fontSize(this.getFontSize(16))
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorTheme.getColor('textPrimary'))

        Blank()

        Row()
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(this.getNavBarHeight())
      .padding({ left: this.getSpacing(), right: this.getSpacing(), top: 44 })
      .backgroundColor(ColorTheme.getColor('cardBackground'))

      // Tab切换
      Row({ space: 0 }) {
        Button('提交反馈')
          .fontSize(this.getFontSize(15))
          .fontColor(this.showMyFeedbacks ? ColorTheme.getColor('textMuted') : ColorTheme.getColor('textLink'))
          .fontWeight(this.showMyFeedbacks ? FontWeight.Normal : FontWeight.Medium)
          .backgroundColor(ColorTheme.getColor('cardBackground'))
          .borderRadius(0)
          .layoutWeight(1)
          .height(this.currentBreakpoint === 'xs' ? 40 : 44)
          .onClick(() => {
            this.showMyFeedbacks = false;
          })

        Button('我的反馈')
          .fontSize(this.getFontSize(15))
          .fontColor(this.showMyFeedbacks ? ColorTheme.getColor('textLink') : ColorTheme.getColor('textMuted'))
          .fontWeight(this.showMyFeedbacks ? FontWeight.Medium : FontWeight.Normal)
          .backgroundColor(ColorTheme.getColor('cardBackground'))
          .borderRadius(0)
          .layoutWeight(1)
          .height(this.currentBreakpoint === 'xs' ? 40 : 44)
          .onClick(() => {
            if (!this.showMyFeedbacks) {
              this.loadMyFeedbacks();
            }
            this.showMyFeedbacks = true;
          })
      }
      .width('100%')
      .backgroundColor(ColorTheme.getColor('cardBackground'))
      .border({ width: { bottom: 1 }, color: ColorTheme.getColor('divider') })

      if (this.showMyFeedbacks) {
        this.buildMyFeedbacksList()
      } else {
        this.buildFeedbackForm()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorTheme.getColor('pageBackground'))
  }

  @Builder
  buildFeedbackForm() {
    Scroll() {
      Column({ space: this.getSpacing() }) {
        // 标题和描述
        Column({ space: 8 }) {
          Text('意见反馈')
            .fontSize(this.getFontSize(20))
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorTheme.getColor('textPrimary'))
            .margin({ top: 20 })

          Text('您的反馈对我们非常重要，我们会认真对待每一条建议')
            .fontSize(this.getFontSize(14))
            .fontColor(ColorTheme.getColor('textMuted'))
            .margin({ bottom: 16 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        // 反馈类型选择
        Column({ space: 8 }) {
          Text('反馈类型')
            .fontSize(this.getFontSize(16))
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTheme.getColor('textPrimary'))
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          Row({ space: 8 }) {
            Button('一般')
              .fontSize(this.getFontSize(14))
              .backgroundColor(this.feedbackType === 'general' ? ColorTheme.getColor('buttonPrimaryBg') : ColorTheme.getColor('cardBackground'))
              .fontColor(this.feedbackType === 'general' ? ColorTheme.getColor('buttonPrimaryText') : ColorTheme.getColor('textMuted'))
              .borderRadius(8)
              .layoutWeight(1)
              .height(this.currentBreakpoint === 'xs' ? 40 : 44)
              .onClick(() => { this.feedbackType = 'general'; })

            Button('Bug')
              .fontSize(this.getFontSize(14))
              .backgroundColor(this.feedbackType === 'bug' ? ColorTheme.getColor('buttonPrimaryBg') : ColorTheme.getColor('cardBackground'))
              .fontColor(this.feedbackType === 'bug' ? ColorTheme.getColor('buttonPrimaryText') : ColorTheme.getColor('textMuted'))
              .borderRadius(8)
              .layoutWeight(1)
              .height(this.currentBreakpoint === 'xs' ? 40 : 44)
              .onClick(() => { this.feedbackType = 'bug'; })

            Button('功能')
              .fontSize(this.getFontSize(14))
              .backgroundColor(this.feedbackType === 'feature' ? ColorTheme.getColor('buttonPrimaryBg') : ColorTheme.getColor('cardBackground'))
              .fontColor(this.feedbackType === 'feature' ? ColorTheme.getColor('buttonPrimaryText') : ColorTheme.getColor('textMuted'))
              .borderRadius(8)
              .layoutWeight(1)
              .height(this.currentBreakpoint === 'xs' ? 40 : 44)
              .onClick(() => { this.feedbackType = 'feature'; })

            Button('建议')
              .fontSize(this.getFontSize(14))
              .backgroundColor(this.feedbackType === 'suggestion' ? ColorTheme.getColor('buttonPrimaryBg') : ColorTheme.getColor('cardBackground'))
              .fontColor(this.feedbackType === 'suggestion' ? ColorTheme.getColor('buttonPrimaryText') : ColorTheme.getColor('textMuted'))
              .borderRadius(8)
              .layoutWeight(1)
              .height(this.currentBreakpoint === 'xs' ? 40 : 44)
              .onClick(() => { this.feedbackType = 'suggestion'; })
          }
          .width('100%')
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 标题输入
        Column({ space: 8 }) {
          Text('反馈标题')
            .fontSize(this.getFontSize(16))
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTheme.getColor('textPrimary'))
            .alignSelf(ItemAlign.Start)

          TextInput({ placeholder: '请输入反馈标题', text: this.title })
            .type(InputType.Normal)
            .width('100%')
            .height(this.currentBreakpoint === 'xs' ? 40 : 44)
            .backgroundColor(ColorTheme.getColor('cardBackground'))
            .fontColor(ColorTheme.getColor('textPrimary'))
            .borderRadius(8)
            .fontSize(this.getFontSize(14))
            .padding({ left: 12, right: 12 })
            .onChange((value: string) => { this.title = value; })
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 内容输入
        Column({ space: 8 }) {
          Text('反馈内容')
            .fontSize(this.getFontSize(16))
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTheme.getColor('textPrimary'))
            .alignSelf(ItemAlign.Start)

          TextArea({ placeholder: '请详细描述您的反馈内容...', text: this.content })
            .width('100%')
            .height(this.currentBreakpoint === 'lg' ? 200 : 150)
            .backgroundColor(ColorTheme.getColor('cardBackground'))
            .fontColor(ColorTheme.getColor('textPrimary'))
            .borderRadius(8)
            .fontSize(this.getFontSize(14))
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .maxLength(500)
            .onChange((value: string) => { this.content = value; })

          Text(`${this.content.length}/500`)
            .fontSize(this.getFontSize(12))
            .fontColor(ColorTheme.getColor('textMuted'))
            .alignSelf(ItemAlign.End)
            .margin({ top: 4 })
        }
        .width('100%')
        .margin({ bottom: 32 })

        // 提交按钮
        Button('提交反馈')
          .width('100%')
          .height(this.currentBreakpoint === 'xs' ? 44 : 48)
          .fontSize(this.getFontSize(16))
          .fontColor(ColorTheme.getColor('buttonPrimaryText'))
          .backgroundColor(ColorTheme.getColor('buttonPrimaryBg'))
          .borderRadius(24)
          .margin({ bottom: 20 })
          .enabled(!this.isSubmitting)
          .onClick(() => { this.handleSubmit(); })
      }
      .width(this.getContentWidth())
    }
    .layoutWeight(1)
    .width('100%')
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  buildMyFeedbacksList() {
    if (this.isLoadingFeedbacks) {
      Column() {
        LoadingProgress()
          .width(40)
          .height(40)
          .color(ColorTheme.getColor('buttonPrimaryBg'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.myFeedbacks.length === 0) {
      Column() {
        Text('暂无反馈记录')
          .fontSize(this.getFontSize(16))
          .fontColor(ColorTheme.getColor('textMuted'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      Scroll() {
        Column({ space: 0 }) {
          ForEach(this.myFeedbacks, (feedback: FeedbackData, index: number) => {
            this.buildFeedbackItem(feedback)
          }, (feedback: FeedbackData) => `${feedback.id}_${feedback.created_at}`)
        }
        .width(this.getContentWidth())
        .padding({ top: this.getSpacing(), bottom: this.getSpacing() })
      }
      .layoutWeight(1)
      .width('100%')
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
    }
  }

  @Builder
  buildFeedbackItem(feedback: FeedbackData) {
    Column({ space: 8 }) {
      Row() {
        Column({ space: 4 }) {
          Text(feedback.title)
            .fontSize(this.getFontSize(16))
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorTheme.getColor('textPrimary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Start)

          Text(feedback.content)
            .fontSize(this.getFontSize(14))
            .fontColor(ColorTheme.getColor('textMuted'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Start)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 4 }) {
          Text(this.getTypeText(feedback.type))
            .fontSize(this.getFontSize(12))
            .fontColor(ColorTheme.getColor('textLink'))
            .backgroundColor(ColorTheme.getColor('cardBackground'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(4)

          Text(this.getStatusText(feedback.status || 'pending'))
            .fontSize(this.getFontSize(12))
            .fontColor(ColorTheme.getColor('textMuted'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      if (feedback.reply) {
        Column() {
          Text('管理员回复：')
            .fontSize(this.getFontSize(12))
            .fontColor(ColorTheme.getColor('textLink'))
            .margin({ bottom: 4 })
            .alignSelf(ItemAlign.Start)

          Text(feedback.reply)
            .fontSize(this.getFontSize(14))
            .fontColor(ColorTheme.getColor('textPrimary'))
            .backgroundColor(ColorTheme.getColor('pageBackground'))
            .padding(12)
            .borderRadius(8)
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 8 })
      }

      Row() {
        Text(this.formatDateTime(feedback.created_at))
          .fontSize(this.getFontSize(12))
          .fontColor(ColorTheme.getColor('textMuted'))
          .textAlign(TextAlign.Start)

        Blank()
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .margin({ top: 4 })
    }
    .width('100%')
    .padding(this.getSpacing())
    .backgroundColor(ColorTheme.getColor('cardBackground'))
    .borderRadius(12)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 获取状态文本
   */
  getStatusText(status: string): string {
    const statusMap: Record<string, string> = {
      'pending': '待处理',
      'processing': '处理中',
      'reviewed': '已查阅',
      'resolved': '已解决',
      'closed': '已关闭'
    };
    return statusMap[status] || status;
  }

  /**
   * 获取状态颜色
   */
  getStatusColor(status: string): string {
    const colorMap: Record<string, string> = {
      'pending': '#f59e0b',
      'processing': '#3b82f6',
      'reviewed': '#8b5cf6',
      'resolved': '#10b981',
      'closed': '#6b7280'
    };
    return colorMap[status] || '#6b7280';
  }

  /**
   * 获取状态背景色
   */
  getStatusBgColor(status: string): string {
    const colorMap: Record<string, string> = {
      'pending': '#fef3c7',
      'processing': '#dbeafe',
      'reviewed': '#ede9fe',
      'resolved': '#d1fae5',
      'closed': '#f3f4f6'
    };
    return colorMap[status] || '#f3f4f6';
  }

  /**
   * 获取类型文本
   */
  getTypeText(type: string): string {
    const typeMap: Record<string, string> = {
      'general': '一般反馈',
      'bug': 'Bug报告',
      'feature': '功能建议',
      'suggestion': '其他建议'
    };
    return typeMap[type] || type;
  }

  /**
   * 格式化日期
   */
  formatDate(dateStr: string): string {
    try {
      const date = new Date(dateStr);
      return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate()
        .toString()
        .padStart(2, '0')}`;
    } catch {
      return dateStr;
    }
  }

  /**
   * 格式化日期时间
   */
  formatDateTime(dateStr?: string): string {
    if (!dateStr) {
      return '';
    }
    try {
      const date = new Date(dateStr);
      const year = date.getFullYear();
      const month = date.getMonth() + 1;
      const day = date.getDate();
      const hours = date.getHours();
      const minutes = date.getMinutes();

      const pad = (num: number): string => {
        return num < 10 ? `0${num}` : `${num}`;
      };

      return `${year}-${pad(month)}-${pad(day)} ${pad(hours)}:${pad(minutes)}`;
    } catch (e) {
      return dateStr;
    }
  }

  /**
   * 显示Toast
   */
  showToast(message: string) {
    promptAction.showToast({ message, duration: 2000 });
  }

  /**
   * 提交反馈
   */
  async handleSubmit() {
    if (this.title.trim() === '') {
      this.showToast('请输入反馈标题');
      return;
    }

    if (this.content.trim() === '') {
      this.showToast('请输入详细描述');
      return;
    }

    if (this.isSubmitting) {
      return;
    }

    try {
      this.isSubmitting = true;
      this.showToast('提交中...');
      const user = await UserStorage.getUser();
      const postData: SubmitFeedbackRequest = {
        action: 'submit_feedback',
        user_id: user?.id,
        username: user?.username,
        email: user?.email,
        title: this.title,
        content: this.content,
        type: this.feedbackType
      };
      const response = await HttpUtils.httpRequestPost('', postData);
      const result: ApiResponse = JSON.parse(response) as ApiResponse;

      if (result.success) {
        this.showToast('提交成功，感谢您的反馈！');
        // 清空表单
        this.title = '';
        this.content = '';
        this.feedbackType = 'general';
      } else {
        this.showToast(result.message || '提交失败');
      }
    } catch (error) {
      console.error('[Feedback] 提交失败:', error);
      this.showToast('提交失败，请稍后再试');
    } finally {
      this.isSubmitting = false;
    }
  }

  /**
   * 加载我的反馈
   */
  async loadMyFeedbacks() {
    try {
      this.isLoadingFeedbacks = true;
      const user = await UserStorage.getUser();

      if (!user) {
        this.showToast('请先登录');
        return;
      }
      const postData: MyFeedbacksRequest = {
        action: 'my_feedbacks',
        user_id: user.id
      };
      const response = await HttpUtils.httpRequestPost('', postData);

      const result: ApiResponse<FeedbackData[]> = JSON.parse(response) as ApiResponse<FeedbackData[]>;
      if (result.success && result.data) {
        this.myFeedbacks = result.data;
      }
    } catch (error) {
      console.error('[Feedback] 加载反馈列表失败:', error);
      this.showToast('加载失败，请稍后再试');
    } finally {
      this.isLoadingFeedbacks = false;
    }
  }
}
