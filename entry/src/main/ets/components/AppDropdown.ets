import { AppColors, AppSize, AppFontSize, AppSpacing } from '../common/constants/DesignTokens';

@Component
export struct AppDropdown {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop options: string[] = [];
  @Prop placeholder: string = '请选择';
  @Prop disabled: boolean = false;
  @Prop required: boolean = false;
  @Prop helperText: string = '';
  onSelect: (value: string) => void = () => {};

  private showPicker(): void {
    if (this.disabled || this.options.length === 0) {
      return;
    }
    TextPickerDialog.show({
      range: this.options,
      selected: this.options.indexOf(this.value) >= 0 ? this.options.indexOf(this.value) : 0,
      onAccept: (result: TextPickerResult) => {
        const idx = result.index as number;
        if (idx >= 0 && idx < this.options.length) {
          this.onSelect(this.options[idx]);
        }
      },
    });
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

      // Trigger button (mimics input style)
      Row() {
        Text(this.value.length > 0 ? this.value : this.placeholder)
          .fontSize(AppFontSize.Body)
          .fontColor(this.value.length > 0 ? AppColors.TextPrimary : AppColors.TextDisabled)
          .layoutWeight(1)
        Text('▾')
          .fontSize(AppFontSize.Helper)
          .fontColor(this.disabled ? AppColors.TextDisabled : AppColors.TextSecondary)
      }
      .height(AppSize.InputHeight)
      .width('100%')
      .padding({ left: 12, right: 12 })
      .borderRadius(AppSize.BorderRadius)
      .border({
        width: 1,
        color: AppColors.Border,
        style: BorderStyle.Solid,
      })
      .backgroundColor(this.disabled ? AppColors.InputDisabledBg : AppColors.Surface)
      .onClick(() => {
        this.showPicker();
      })

      // Helper / disabled hint
      if (this.helperText.length > 0) {
        Text(this.helperText)
          .fontSize(AppFontSize.Helper)
          .fontColor(AppColors.TextDisabled)
          .width('100%')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
