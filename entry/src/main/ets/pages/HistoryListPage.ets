import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppColors, AppFontSize, AppSize, AppSpacing } from '../common/constants/DesignTokens';
import { InspectionTask, TaskQueryParams, CameraSource } from '../common/types/InspectionTypes';
import { AppButton } from '../components/AppButton';
import { AppInput } from '../components/AppInput';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { ToastNotification } from '../components/ToastNotification';
import { DBService } from '../services/DBService';
import { DateUtils } from '../common/utils/DateUtils';

@Entry
@Component
struct HistoryListPage {
  @State tasks: InspectionTask[] = [];
  @State filteredTasks: InspectionTask[] = [];
  @State searchText: string = '';
  @State selectedPartFilter: string = '';
  @State selectedSource: string = 'all';
  @State isMultiSelect: boolean = false;
  @State selectedIds: number[] = [];
  @State toastMessage: string = '';
  @State toastType: string = 'success';
  @State showToast: boolean = false;
  @State isLoading: boolean = false;

  private debounceTimer: number = -1;

  private deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '删除照片',
      message: '确定要删除选中的照片记录吗？此操作无法撤销。',
      confirmText: '删除',
      cancelText: '取消',
      destructive: true,
      onConfirm: () => { this.deleteSelected(); },
      onCancel:  () => {},
    }),
    autoCancel: true,
  });

  aboutToAppear(): void {
    this.loadTasks();
  }

  private async loadTasks(): Promise<void> {
    this.isLoading = true;
    try {
      const params = new TaskQueryParams();
      if (this.searchText.length > 0) {
        params.taskNumber = this.searchText;
      }
      if (this.selectedPartFilter.length > 0) {
        params.partFilter = [this.selectedPartFilter];
      }
      if (this.selectedSource !== 'all') {
        params.cameraSource = this.selectedSource;
      }
      const result = await DBService.getInstance().queryTasks(params);
      this.tasks         = result;
      this.filteredTasks = result;
    } catch (err) {
      const e = err as BusinessError;
      console.error(`HistoryListPage: loadTasks failed ${e.message}`);
    } finally {
      this.isLoading = false;
    }
  }

  private scheduleReload(): void {
    if (this.debounceTimer >= 0) {
      clearTimeout(this.debounceTimer);
    }
    this.debounceTimer = setTimeout(() => {
      this.loadTasks();
    }, 300);
  }

  private toggleSelect(id: number): void {
    const idx = this.selectedIds.indexOf(id);
    if (idx >= 0) {
      this.selectedIds.splice(idx, 1);
    } else {
      this.selectedIds.push(id);
    }
    // Force re-render by reassigning
    this.selectedIds = [...this.selectedIds];
  }

  private selectAll(): void {
    this.selectedIds = this.filteredTasks.map(t => t.id);
  }

  private async deleteSelected(): Promise<void> {
    if (this.selectedIds.length === 0) { return; }
    try {
      await DBService.getInstance().deleteTasks(this.selectedIds);
      this.selectedIds    = [];
      this.isMultiSelect  = false;
      this.toastMessage   = '已删除选中记录';
      this.toastType      = 'success';
      this.showToast      = true;
      await this.loadTasks();
    } catch (err) {
      const e = err as BusinessError;
      console.error(`HistoryListPage: delete failed ${e.message}`);
      this.toastMessage = '删除失败，请重试';
      this.toastType    = 'error';
      this.showToast    = true;
    }
  }

  private getPartBadgeColor(source: string): string {
    return source === CameraSource.BORESCOPE ? AppColors.BadgeBlueBg : AppColors.TagBg;
  }

  build() {
    Column() {
      // Top bar
      Row() {
        Text('← 返回')
          .fontSize(AppFontSize.Body)
          .fontColor(AppColors.Primary)
          .height(AppSize.MinTouchTarget)
          .padding({ left: AppSpacing.XS, right: AppSpacing.SM })
          .onClick(() => { router.back(); })

        Text('历史记录')
          .fontSize(AppFontSize.SectionHeader)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TextPrimary)

        Blank()

        if (this.isMultiSelect) {
          Text(`已选 ${this.selectedIds.length} 张`)
            .fontSize(AppFontSize.Body)
            .fontColor(AppColors.TextSecondary)
            .margin({ right: AppSpacing.SM })
        }
      }
      .width('100%')
      .height(AppSize.TopBarHeight)
      .padding({ left: AppSpacing.XS })
      .backgroundColor(AppColors.Surface)
      .borderWidth({ bottom: 1 })
      .borderColor(AppColors.Border)
      .borderStyle(BorderStyle.Solid)
      .alignItems(VerticalAlign.Center)

      // 2-column layout
      Row() {
        // Left: filter panel
        Column() {
          Text('筛选')
            .fontSize(AppFontSize.SectionHeader)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TextPrimary)
            .width('100%')
            .margin({ bottom: AppSpacing.SM })

          AppInput({
            label: '任务号搜索',
            value: this.searchText,
            placeholder: '输入任务号',
            onValueChange: (val: string) => {
              this.searchText = val;
              this.scheduleReload();
            },
          })
          .margin({ bottom: AppSpacing.SM })

          // Camera source filter
          Text('拍摄来源')
            .fontSize(AppFontSize.FormLabel)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TextPrimary)
            .margin({ bottom: AppSpacing.XS })

          Column() {
            ForEach(['all', CameraSource.NATIVE, CameraSource.BORESCOPE], (source: string) => {
              Row() {
                Text(source === 'all' ? '全部' : (source === CameraSource.NATIVE ? '原生后摄' : '孔探设备'))
                  .fontSize(AppFontSize.Body)
                  .fontColor(this.selectedSource === source ? AppColors.Surface : AppColors.TextPrimary)
              }
              .width('100%')
              .height(44)
              .padding({ left: 12 })
              .borderRadius(AppSize.BorderRadius)
              .backgroundColor(this.selectedSource === source ? AppColors.Primary : 'transparent')
              .margin({ bottom: 4 })
              .onClick(() => {
                this.selectedSource = source;
                this.loadTasks();
              })
            })
          }
          .width('100%')
          .margin({ bottom: AppSpacing.SM })

          if (this.isMultiSelect) {
            AppButton({
              label: '全选',
              variant: 'secondary',
              onAction: () => { this.selectAll(); },
            })
            .margin({ bottom: AppSpacing.XS })

            AppButton({
              label: '取消',
              variant: 'secondary',
              onAction: () => {
                this.isMultiSelect = false;
                this.selectedIds   = [];
              },
            })
          }
        }
        .width(AppSize.FilterPanelWidth)
        .height('100%')
        .padding(AppSpacing.SM)
        .backgroundColor(AppColors.Surface)
        .borderWidth({ right: 1 })
        .borderColor(AppColors.Border)
        .borderStyle(BorderStyle.Solid)
        .alignItems(HorizontalAlign.Start)

        // Right: photo grid
        Column() {
          // Grid header
          Row() {
            Text(`共 ${this.filteredTasks.length} 条记录`)
              .fontSize(AppFontSize.Helper)
              .fontColor(AppColors.TextSecondary)
            Blank()
            if (!this.isMultiSelect) {
              Text('多选')
                .fontSize(AppFontSize.Body)
                .fontColor(AppColors.Primary)
                .height(AppSize.MinTouchTarget)
                .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
                .onClick(() => { this.isMultiSelect = true; })
            }
          }
          .width('100%')
          .height(44)
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM })

          if (this.filteredTasks.length === 0) {
            // Empty state
            Column() {
              Text('暂无拍摄记录')
                .fontSize(AppFontSize.Body)
                .fontColor(AppColors.TextSecondary)
              Text('点击首页"开始新任务"开始拍摄')
                .fontSize(AppFontSize.Helper)
                .fontColor(AppColors.TextDisabled)
                .margin({ top: AppSpacing.XS })
            }
            .layoutWeight(1)
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            // 4-column grid
            Scroll() {
              Grid() {
                ForEach(this.filteredTasks, (task: InspectionTask) => {
                  GridItem() {
                    Stack() {
                      // Thumbnail
                      if (task.galleryUri.length > 0) {
                        Image(task.galleryUri)
                          .width('100%')
                          .height(AppSize.ThumbnailHistory)
                          .objectFit(ImageFit.Cover)
                          .borderRadius(AppSize.BorderRadius)
                      } else {
                        Column()
                          .width('100%')
                          .height(AppSize.ThumbnailHistory)
                          .borderRadius(AppSize.BorderRadius)
                          .backgroundColor(AppColors.Border)
                      }

                      // Overlay info
                      Column() {
                        Blank()
                        Column() {
                          Text(task.taskNumber)
                            .fontSize(AppFontSize.Helper)
                            .fontColor(AppColors.Surface)
                            .fontWeight(FontWeight.Medium)
                          Text(task.part)
                            .fontSize(AppFontSize.Tag)
                            .fontColor('rgba(255,255,255,0.8)')
                        }
                        .width('100%')
                        .padding({ left: 6, right: 6, bottom: 4 })
                        .backgroundColor('rgba(0,0,0,0.5)')
                        .borderRadius({ bottomLeft: AppSize.BorderRadius, bottomRight: AppSize.BorderRadius })
                      }
                      .width('100%')
                      .height(AppSize.ThumbnailHistory)

                      // Multi-select checkbox
                      if (this.isMultiSelect) {
                        Column() {
                          Circle()
                            .width(24)
                            .height(24)
                            .fill(this.selectedIds.indexOf(task.id) >= 0 ? AppColors.Primary : 'rgba(255,255,255,0.6)')
                            .stroke(AppColors.Surface)
                            .strokeWidth(2)
                        }
                        .width(32)
                        .height(32)
                        .position({ x: 4, y: 4 })
                      }
                    }
                    .width('100%')
                    .height(AppSize.ThumbnailHistory)
                    .onClick(() => {
                      if (this.isMultiSelect) {
                        this.toggleSelect(task.id);
                      } else {
                        router.pushUrl({
                          url: 'pages/TaskPhotoDetailPage',
                          params: { taskId: task.id.toString() },
                        });
                      }
                    })
                  }
                })
              }
              .columnsTemplate('1fr 1fr 1fr 1fr')
              .columnsGap(AppSpacing.XS)
              .rowsGap(AppSpacing.XS)
              .padding(AppSpacing.SM)
              .width('100%')
            }
            .layoutWeight(1)
            .width('100%')
          }
        }
        .layoutWeight(1)
        .height('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')

      // Multi-select bottom bar
      if (this.isMultiSelect) {
        Row() {
          AppButton({
            label: `删除选中 (${this.selectedIds.length})`,
            variant: this.selectedIds.length > 0 ? 'destructive' : 'disabled',
            onAction: () => {
              if (this.selectedIds.length > 0) {
                this.deleteDialogController.open();
              }
            },
          })
          .layoutWeight(1)
          .margin({ right: AppSpacing.SM })

          AppButton({
            label: `导出选中 (${this.selectedIds.length})`,
            variant: this.selectedIds.length > 0 ? 'primary' : 'disabled',
            onAction: () => {
              // Export placeholder — future feature
              this.toastMessage = `导出功能开发中`;
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
    .backgroundColor(AppColors.Background)
  }
}
