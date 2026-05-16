import { AppColors, AppSize, AppFontSize, AppSpacing } from '../common/constants/DesignTokens';

@Component
export struct AppInput {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop placeholder: string = '';
  @Prop errorMessage: string = '';
  @Prop disabled: boolean = false;
  @Prop required: boolean = false;
  onValueChange: (value: string) => void = () => {};

  @State isFocused: boolean = false;

  private getBorderColor(): string {
    if (this.errorMessage.length > 0) {
      return AppColors.Danger;
    }
    if (this.isFocused) {
      return AppColors.Primary;
    }
    return AppColors.Border;
  }

  private getBorderWidth(): number {
    return (this.isFocused || this.errorMessage.length > 0) ? 2 : 1;
  }

  build() {
    Column() {
      // Label row
      Row() {
        Text(this.label)
          .fontSize(AppFontSize.FormLabel)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.disabled ? AppColors.TextDisabled : AppColors.TextPrimary)
        if (this.required) {
          Text(' *')
            .fontSize(AppFontSize.FormLabel)
            .fontColor(AppColors.Danger)
        }
      }
      .width('100%')
      .margin({ bottom: AppSpacing.XS })

      // Input field
      TextInput({ text: this.value, placeholder: this.placeholder })
        .height(AppSize.InputHeight)
        .width('100%')
        .borderRadius(AppSize.BorderRadius)
        .border({
          width: this.getBorderWidth(),
          color: this.getBorderColor(),
          style: BorderStyle.Solid,
        })
        .backgroundColor(this.disabled ? AppColors.InputDisabledBg : AppColors.Surface)
        .fontColor(AppColors.TextPrimary)
        .fontSize(AppFontSize.Body)
        .placeholderColor(AppColors.TextDisabled)
        .enabled(!this.disabled)
        .onFocus(() => {
          this.isFocused = true;
        })
        .onBlur(() => {
          this.isFocused = false;
        })
        .onChange((value: string) => {
          this.onValueChange(value);
        })

      // Error message
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(AppFontSize.Helper)
          .fontColor(AppColors.Danger)
          .width('100%')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
