import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppColors, AppFontSize, AppSize, AppSpacing } from '../common/constants/DesignTokens';
import { InspectionTask, CameraSource } from '../common/types/InspectionTypes';
import { AppButton } from '../components/AppButton';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { ToastNotification } from '../components/ToastNotification';
import { DBService } from '../services/DBService';

@Entry
@Component
struct TaskPhotoDetailPage {
  @State task: InspectionTask = new InspectionTask();
  @State isLoaded: boolean = false;
  @State isMultiSelect: boolean = false;
  @State selectedIds: number[] = [];
  @State toastMessage: string = '';
  @State toastType: string = 'success';
  @State showToast: boolean = false;
  @State previewImageUri: string = '';
  @State showPreview: boolean = false;

  private taskId: number = 0;

  private deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '删除照片记录',
      message: '确定要删除此任务的照片记录吗？',
      confirmText: '删除',
      cancelText: '取消',
      destructive: true,
      onConfirm: () => { this.deleteTask(); },
      onCancel:  () => {},
    }),
    autoCancel: true,
  });

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== null) {
      const id = params['taskId'];
      if (id !== undefined) {
        this.taskId = parseInt(id);
        this.loadTask();
      }
    }
  }

  private async loadTask(): Promise<void> {
    try {
      const result = await DBService.getInstance().getTaskById(this.taskId);
      if (result !== null) {
        this.task     = result;
        this.isLoaded = true;
      }
    } catch (err) {
      const e = err as BusinessError;
      console.error(`TaskPhotoDetailPage: loadTask failed ${e.message}`);
    }
  }

  private async deleteTask(): Promise<void> {
    try {
      await DBService.getInstance().deleteTasks([this.taskId]);
      this.toastMessage = '已删除任务记录';
      this.toastType    = 'success';
      this.showToast    = true;
      setTimeout(() => { router.back(); }, 1500);
    } catch (err) {
      const e = err as BusinessError;
      console.error(`TaskPhotoDetailPage: delete failed ${e.message}`);
      this.toastMessage = '删除失败，请重试';
      this.toastType    = 'error';
      this.showToast    = true;
    }
  }

  private buildMetadataRows(): string[][] {
    return [
      ['任务号', this.task.taskNumber],
      ['机型信息', this.task.deviceModel],
      ['单位', this.task.unit],
      ['部位', this.task.part],
      ['部位区域', this.task.partArea],
      ['照相对应项目', this.task.project],
      ['操作者', this.task.operator],
      ['检验员', this.task.inspector],
      ['照相人', this.task.photographer],
      ['照相日期', this.task.photoDate],
    ];
  }

  build() {
    Stack() {
      Column() {
        // Top bar
        Row() {
          Text('← 返回')
            .fontSize(AppFontSize.Body)
            .fontColor(AppColors.Primary)
            .height(AppSize.MinTouchTarget)
            .padding({ left: AppSpacing.XS, right: AppSpacing.SM })
            .onClick(() => { router.back(); })

          Text(`任务 ${this.task.taskNumber}`)
            .fontSize(AppFontSize.SectionHeader)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TextPrimary)

          Blank()

          // Delete button
          Text('删除')
            .fontSize(AppFontSize.Body)
            .fontColor(AppColors.Danger)
            .height(AppSize.MinTouchTarget)
            .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
            .onClick(() => { this.deleteDialogController.open(); })
        }
        .width('100%')
        .height(AppSize.TopBarHeight)
        .padding({ left: AppSpacing.XS })
        .backgroundColor(AppColors.Surface)
        .borderWidth({ bottom: 1 })
        .borderColor(AppColors.Border)
        .borderStyle(BorderStyle.Solid)
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Column() {
            // Metadata card
            Column() {
              Text('任务信息')
                .fontSize(AppFontSize.SectionHeader)
                .fontWeight(FontWeight.Medium)
                .fontColor(AppColors.TextPrimary)
                .width('100%')
                .margin({ bottom: AppSpacing.SM })

              Grid() {
                ForEach(this.buildMetadataRows(), (row: string[]) => {
                  GridItem() {
                    Column() {
                      Text(row[0])
                        .fontSize(AppFontSize.Helper)
                        .fontColor(AppColors.TextSecondary)
                        .margin({ bottom: 2 })
                      Text(row[1].length > 0 ? row[1] : '—')
                        .fontSize(AppFontSize.Body)
                        .fontColor(AppColors.TextPrimary)
                        .fontWeight(FontWeight.Medium)
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Start)
                    .padding(AppSpacing.XS)
                  }
                })
              }
              .columnsTemplate('1fr 1fr')
              .columnsGap(AppSpacing.SM)
              .rowsGap(AppSpacing.SM)
              .width('100%')

              // Camera source badge
              Row() {
                Text(this.task.cameraSource === CameraSource.BORESCOPE ? '孔探设备拍摄' : '原生摄像头拍摄')
                  .fontSize(AppFontSize.Helper)
                  .fontColor(AppColors.Primary)
                  .padding({ left: 10, right: 10 })
                  .height(24)
                  .borderRadius(12)
                  .backgroundColor(AppColors.BadgeBlueBg)
              }
              .width('100%')
              .margin({ top: AppSpacing.SM })
            }
            .width('100%')
            .padding(AppSpacing.MD)
            .backgroundColor(AppColors.Surface)
            .borderRadius(AppSize.BorderRadiusLarge)
            .border({ width: 1, color: AppColors.Border, style: BorderStyle.Solid })
            .margin({ bottom: AppSpacing.SM })
            .alignItems(HorizontalAlign.Start)

            // Photo section
            Column() {
              Row() {
                Text('拍摄照片')
                  .fontSize(AppFontSize.SectionHeader)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppColors.TextPrimary)
              }
              .width('100%')
              .margin({ bottom: AppSpacing.SM })

              if (this.task.galleryUri.length > 0) {
                Grid() {
                  GridItem() {
                    Stack() {
                      Image(this.task.galleryUri)
                        .width('100%')
                        .height(AppSize.ThumbnailDetail)
                        .objectFit(ImageFit.Cover)
                        .borderRadius(AppSize.BorderRadius)
                        .onClick(() => {
                          this.previewImageUri = this.task.galleryUri;
                          this.showPreview     = true;
                        })

                      // Time overlay
                      Text(this.task.photoDate)
                        .fontSize(AppFontSize.Tag)
                        .fontColor(AppColors.Surface)
                        .padding({ left: 4, right: 4, top: 2, bottom: 2 })
                        .backgroundColor('rgba(0,0,0,0.5)')
                        .borderRadius(4)
                        .position({ x: 4, y: 4 })
                    }
                    .width('100%')
                    .height(AppSize.ThumbnailDetail)
                  }
                }
                .columnsTemplate('1fr 1fr 1fr')
                .columnsGap(AppSpacing.XS)
                .rowsGap(AppSpacing.XS)
                .width('100%')
              } else {
                Column() {
                  Text('暂无照片')
                    .fontSize(AppFontSize.Body)
                    .fontColor(AppColors.TextDisabled)
                }
                .width('100%')
                .height(120)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .borderRadius(AppSize.BorderRadius)
                .border({ width: 1, color: AppColors.Border, style: BorderStyle.Dashed })
              }
            }
            .width('100%')
            .padding(AppSpacing.MD)
            .backgroundColor(AppColors.Surface)
            .borderRadius(AppSize.BorderRadiusLarge)
            .border({ width: 1, color: AppColors.Border, style: BorderStyle.Solid })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(AppSpacing.SM)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')

        // Bottom action bar
        Row() {
          AppButton({
            label: '导出全部',
            variant: 'primary',
            onAction: () => {
              this.toastMessage = '导出功能开发中';
              this.toastType    = 'warning';
              this.showToast    = true;
            },
          })
          .layoutWeight(1)
        }
        .width('100%')
        .height(AppSize.BottomBarHeight)
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
        .backgroundColor(AppColors.Surface)
        .borderWidth({ top: 1 })
        .borderColor(AppColors.Border)
        .borderStyle(BorderStyle.Solid)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.Background)

      // Full-screen preview
      if (this.showPreview) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(Color.Black)
            .onClick(() => { this.showPreview = false; })

          Image(this.previewImageUri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .onClick(() => { this.showPreview = false; })
        }
        .width('100%')
        .height('100%')
      }

      // Toast
      if (this.showToast) {
        ToastNotification({
          message: this.toastMessage,
          toastType: this.toastType === 'error' ? 'error' : 'success',
          visible: true,
          onDismiss: () => { this.showToast = false; },
        })
        .position({ x: '10%', y: '85%' })
      }
    }
    .width('100%')
    .height('100%')
  }
}
