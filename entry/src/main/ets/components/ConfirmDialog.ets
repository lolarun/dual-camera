import { AppColors, AppSize, AppFontSize, AppSpacing } from '../common/constants/DesignTokens';
import { AppButton } from './AppButton';

@CustomDialog
export struct ConfirmDialog {
  controller: CustomDialogController = new CustomDialogController({ builder: ConfirmDialog() });
  @Prop title: string = '确认';
  @Prop message: string = '';
  @Prop confirmText: string = '确认';
  @Prop cancelText: string = '取消';
  @Prop destructive: boolean = false;
  onConfirm: () => void = () => {};
  onCancel: () => void = () => {};

  build() {
    Column() {
      // Title
      Text(this.title)
        .fontSize(AppFontSize.SectionHeader)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TextPrimary)
        .width('100%')
        .margin({ bottom: AppSpacing.SM })

      // Message
      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(AppFontSize.Body)
          .fontColor(AppColors.TextSecondary)
          .width('100%')
          .margin({ bottom: AppSpacing.MD })
      }

      // Action buttons
      Row() {
        AppButton({
          label: this.cancelText,
          variant: 'secondary',
          onAction: () => {
            this.controller.close();
            this.onCancel();
          },
        })
          .layoutWeight(1)
          .margin({ right: 12 })

        AppButton({
          label: this.confirmText,
          variant: this.destructive ? 'destructive' : 'primary',
          onAction: () => {
            this.controller.close();
            this.onConfirm();
          },
        })
          .layoutWeight(1)
      }
      .width('100%')
    }
    .padding(AppSpacing.MD)
    .width(AppSize.ModalWidth)
    .backgroundColor(AppColors.Surface)
    .borderRadius(AppSize.BorderRadiusLarge)
  }
}
