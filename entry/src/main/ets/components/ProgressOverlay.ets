import { AppColors, AppFontSize, AppSpacing } from '../common/constants/DesignTokens';

@Component
export struct ProgressOverlay {
  @Prop message: string = '加载中...';
  @Prop visible: boolean = false;
  @Prop progress: number = -1; // -1 = indeterminate

  build() {
    if (this.visible) {
      Stack() {
        // Dark backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(AppColors.OverlayDark)

        // Centered card
        Column() {
          LoadingProgress()
            .color(AppColors.Primary)
            .width(56)
            .height(56)

          if (this.progress >= 0) {
            Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
              .width(200)
              .color(AppColors.Primary)
              .margin({ top: AppSpacing.SM })
          }

          Text(this.message)
            .fontSize(AppFontSize.Body)
            .fontColor(AppColors.TextPrimary)
            .margin({ top: AppSpacing.SM })
        }
        .padding(AppSpacing.MD)
        .backgroundColor(AppColors.Surface)
        .borderRadius(16)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
}
