import { AppColors, AppSize, AppFontSize, AppSpacing } from '../common/constants/DesignTokens';

export type ToastType = 'success' | 'error' | 'warning';

@Component
export struct ToastNotification {
  @Prop message: string = '';
  @Prop toastType: ToastType = 'success';
  @Prop actionText: string = '';
  @Prop visible: boolean = false;
  onAction: () => void = () => {};
  onDismiss: () => void = () => {};

  private autoTimer: number = -1;

  private getBgColor(): string {
    if (this.toastType === 'error') {
      return AppColors.Danger;
    }
    if (this.toastType === 'warning') {
      return AppColors.Warning;
    }
    return AppColors.Success;
  }

  aboutToAppear(): void {
    if (this.visible) {
      this.scheduleAutoDismiss();
    }
  }

  aboutToDisappear(): void {
    if (this.autoTimer >= 0) {
      clearTimeout(this.autoTimer);
    }
  }

  private scheduleAutoDismiss(): void {
    const delay = this.toastType === 'error' ? 5000 : 3000;
    this.autoTimer = setTimeout(() => {
      this.onDismiss();
    }, delay);
  }

  build() {
    if (this.visible) {
      Row() {
        Text(this.message)
          .fontSize(AppFontSize.Body)
          .fontColor(AppColors.Surface)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        if (this.actionText.length > 0) {
          Text(this.actionText)
            .fontSize(AppFontSize.Body)
            .fontColor(AppColors.Surface)
            .fontWeight(FontWeight.Bold)
            .margin({ left: AppSpacing.SM })
            .onClick(() => {
              this.onAction();
            })
        }
      }
      .height(AppSize.ToastHeight)
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
      .backgroundColor(this.getBgColor())
      .borderRadius(AppSize.BorderRadius)
      .width('80%')
    }
  }
}
