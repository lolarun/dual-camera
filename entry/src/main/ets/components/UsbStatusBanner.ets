import { AppColors, AppSize, AppFontSize, AppSpacing } from '../common/constants/DesignTokens';

@Component
export struct UsbStatusBanner {
  @Prop connected: boolean = false;
  @Prop visible: boolean = false;

  build() {
    if (this.visible) {
      Row() {
        Text(this.connected ? '●' : '●')
          .fontSize(AppFontSize.Helper)
          .fontColor(this.connected ? AppColors.Surface : AppColors.Surface)
          .margin({ right: AppSpacing.XS })

        Text(this.connected ? '孔探设备已连接' : '孔探设备已断开')
          .fontSize(AppFontSize.Body)
          .fontColor(AppColors.Surface)
          .fontWeight(FontWeight.Medium)
      }
      .height(AppSize.ButtonHeight)
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
      .backgroundColor(this.connected ? AppColors.Success : AppColors.Warning)
      .borderRadius(AppSize.BorderRadius)
      .width('100%')
    }
  }
}
