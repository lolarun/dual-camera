import { AppColors, AppSize, AppFontSize } from '../common/constants/DesignTokens';

export type ButtonVariant = 'primary' | 'secondary' | 'destructive' | 'disabled' | 'success';
export type ButtonSize = 'normal' | 'large';

@Component
export struct AppButton {
  @Prop label: string = '';
  @Prop variant: ButtonVariant = 'primary';
  @Prop btnSize: ButtonSize = 'normal';
  @Prop fullWidth: boolean = true;
  onAction: () => void = () => {};

  private getBgColor(): string {
    if (this.variant === 'primary') {
      return AppColors.Primary;
    }
    if (this.variant === 'secondary') {
      return 'transparent';
    }
    if (this.variant === 'destructive') {
      return AppColors.Danger;
    }
    if (this.variant === 'success') {
      return AppColors.Success;
    }
    return AppColors.DisabledBg;
  }

  private getTextColor(): string {
    if (this.variant === 'secondary') {
      return AppColors.Primary;
    }
    if (this.variant === 'disabled') {
      return AppColors.TextDisabled;
    }
    return AppColors.Surface;
  }

  private getHeight(): number {
    return this.btnSize === 'large' ? AppSize.ButtonHeightLarge : AppSize.ButtonHeight;
  }

  build() {
    Button(this.label)
      .height(this.getHeight())
      .width(this.fullWidth ? '100%' : 'auto')
      .borderRadius(AppSize.BorderRadius)
      .backgroundColor(this.getBgColor())
      .fontColor(this.getTextColor())
      .fontSize(AppFontSize.ButtonText)
      .fontWeight(FontWeight.Medium)
      .border(this.variant === 'secondary' ? {
        width: 2,
        color: AppColors.Primary,
        style: BorderStyle.Solid,
      } : { width: 0 })
      .enabled(this.variant !== 'disabled')
      .onClick(() => {
        if (this.variant !== 'disabled') {
          this.onAction();
        }
      })
  }
}
