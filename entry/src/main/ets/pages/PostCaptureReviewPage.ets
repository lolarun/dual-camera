import { router } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppColors, AppFontSize, AppSize, AppSpacing } from '../common/constants/DesignTokens';
import { FormData, InspectionTask, CameraSource } from '../common/types/InspectionTypes';
import { AppButton } from '../components/AppButton';
import { ProgressOverlay } from '../components/ProgressOverlay';
import { ToastNotification } from '../components/ToastNotification';
import { ImageCompositionService } from '../services/ImageCompositionService';
import { MediaLibraryService } from '../services/MediaLibraryService';
import { DBService } from '../services/DBService';
import { PreferencesService } from '../services/PreferencesService';
import { CameraService } from '../services/CameraService';
import { FileUtils } from '../common/utils/FileUtils';
import { DateUtils } from '../common/utils/DateUtils';

@Entry
@Component
struct PostCaptureReviewPage {
  @State previewPixelMap: image.PixelMap | null = null;
  @State isComposing: boolean = true;
  @State isSaving: boolean = false;
  @State saveProgress: number = 0;
  @State toastMessage: string = '';
  @State toastType: string = 'success';
  @State showToast: boolean = false;
  @State composeFailed: boolean = false;

  private formData: FormData = new FormData();
  private cameraSource: string = CameraSource.NATIVE;
  private timestamp: string = '';
  private filename: string = '';

  aboutToAppear(): void {
    this.parseRouteParams();
    this.filename = FileUtils.buildFilename(
      this.formData.taskNumber,
      this.formData.part,
      this.formData.photographer,
      new Date(this.formData.photoDate)
    );
    this.startComposition();
  }

  private parseRouteParams(): void {
    const params = router.getParams() as Record<string, string>;
    if (params === null) { return; }

    const json = params['formDataJson'];
    if (json !== undefined && json.length > 0) {
      try {
        const parsed = JSON.parse(json) as Record<string, string>;
        this.formData.deviceModel  = typeof parsed['deviceModel']  === 'string' ? parsed['deviceModel']  : '';
        this.formData.taskNumber   = typeof parsed['taskNumber']   === 'string' ? parsed['taskNumber']   : '';
        this.formData.unit         = typeof parsed['unit']         === 'string' ? parsed['unit']         : '';
        this.formData.part         = typeof parsed['part']         === 'string' ? parsed['part']         : '';
        this.formData.partArea     = typeof parsed['partArea']     === 'string' ? parsed['partArea']     : '';
        this.formData.project      = typeof parsed['project']      === 'string' ? parsed['project']      : '';
        this.formData.operator     = typeof parsed['operator']     === 'string' ? parsed['operator']     : '';
        this.formData.inspector    = typeof parsed['inspector']    === 'string' ? parsed['inspector']    : '';
        this.formData.photographer = typeof parsed['photographer'] === 'string' ? parsed['photographer'] : '';
        this.formData.photoDate    = typeof parsed['photoDate']    === 'string' ? parsed['photoDate']    : '';
      } catch (err) {
        console.error('PostCaptureReviewPage: failed to parse formData');
      }
    }

    const src = params['cameraSource'];
    if (src !== undefined) { this.cameraSource = src; }
    const ts = params['timestamp'];
    if (ts !== undefined) { this.timestamp = ts; }
  }

  private async startComposition(): Promise<void> {
    this.isComposing = true;
    this.composeFailed = false;
    try {
      const backBuffer  = CameraService.getLastBackBuffer();
      const frontBuffer: ArrayBuffer | null = CameraService.getLastFrontBuffer().byteLength > 0
        ? CameraService.getLastFrontBuffer()
        : null;

      const pixelMap = await ImageCompositionService.composePreview(
        backBuffer, frontBuffer, this.formData
      );
      this.previewPixelMap = pixelMap;
    } catch (err) {
      const e = err as BusinessError;
      console.error(`PostCaptureReviewPage: composition failed ${e.message}`);
      this.composeFailed = true;
    } finally {
      this.isComposing = false;
    }
  }

  private async savePhoto(): Promise<void> {
    if (this.isSaving) { return; }
    this.isSaving = true;
    this.saveProgress = 0;

    try {
      const context = getContext(this) as common.UIAbilityContext;

      // Compose final JPEG
      this.saveProgress = 10;
      const backBuffer  = CameraService.getLastBackBuffer();
      const frontBuffer: ArrayBuffer | null = CameraService.getLastFrontBuffer().byteLength > 0
        ? CameraService.getLastFrontBuffer()
        : null;
      const composedBuffer = await ImageCompositionService.composeImage(
        backBuffer, frontBuffer, this.formData
      );

      this.saveProgress = 40;

      // Dual save
      const saveResult = await MediaLibraryService.dualSave(context, this.formData, composedBuffer);
      this.saveProgress = 80;

      // Record in DB
      const task = new InspectionTask();
      task.taskNumber   = this.formData.taskNumber;
      task.deviceModel  = this.formData.deviceModel;
      task.unit         = this.formData.unit;
      task.part         = this.formData.part;
      task.partArea     = this.formData.partArea;
      task.project      = this.formData.project;
      task.operator     = this.formData.operator;
      task.inspector    = this.formData.inspector;
      task.photographer = this.formData.photographer;
      task.photoDate    = this.formData.photoDate;
      task.photoPath    = saveResult.sandboxPath;
      task.galleryUri   = saveResult.galleryUri;
      task.cameraSource = this.cameraSource;
      task.createdAt    = DateUtils.todayIso();
      await DBService.getInstance().insertTask(task);

      this.saveProgress = 90;

      // Persist last-used names
      await PreferencesService.getInstance().setLastInspector(this.formData.inspector);
      await PreferencesService.getInstance().setLastPhotographer(this.formData.photographer);
      await PreferencesService.getInstance().clearDraft();

      this.saveProgress = 100;

      this.toastMessage = `已保存 · 任务 ${this.formData.taskNumber}`;
      this.toastType    = 'success';
      this.showToast    = true;

      // Navigate to history after 2s
      setTimeout(() => {
        router.replaceUrl({ url: 'pages/HistoryListPage' });
      }, 2000);
    } catch (err) {
      const e = err as BusinessError;
      console.error(`PostCaptureReviewPage: save failed ${e.message}`);
      this.toastMessage = '保存失败，请检查存储空间';
      this.toastType    = 'error';
      this.showToast    = true;
    } finally {
      this.isSaving = false;
    }
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

          Text('拍摄确认')
            .fontSize(AppFontSize.SectionHeader)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TextPrimary)

          Blank()
        }
        .width('100%')
        .height(AppSize.TopBarHeight)
        .padding({ left: AppSpacing.XS })
        .backgroundColor(AppColors.Surface)
        .borderWidth({ bottom: 1 })
        .borderColor(AppColors.Border)
        .borderStyle(BorderStyle.Solid)
        .alignItems(VerticalAlign.Center)

        // Composed image preview
        Column() {
          if (this.previewPixelMap !== null) {
            Image(this.previewPixelMap)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
          } else if (!this.isComposing && this.composeFailed) {
            Column() {
              Text('合成失败')
                .fontSize(AppFontSize.Body)
                .fontColor(AppColors.Danger)
              AppButton({
                label: '重试',
                variant: 'primary',
                onAction: () => { this.startComposition(); },
              })
              .margin({ top: AppSpacing.SM })
            }
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(Color.Black)

        // Filename label
        Text(this.filename)
          .fontSize(AppFontSize.Body)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TextPrimary)
          .padding({ left: AppSpacing.SM, top: AppSpacing.XS, bottom: AppSpacing.XS })
          .width('100%')
          .backgroundColor(AppColors.Surface)

        // Bottom actions
        Row() {
          AppButton({
            label: '重拍',
            variant: 'secondary',
            onAction: () => { router.back(); },
          })
          .layoutWeight(2)
          .margin({ right: AppSpacing.SM })

          AppButton({
            label: this.isSaving ? `正在保存 ${this.saveProgress}%` : '保存到相册',
            variant: this.isSaving ? 'disabled' : 'success',
            btnSize: 'large',
            onAction: () => { this.savePhoto(); },
          })
          .layoutWeight(3)
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

      // Composition progress overlay
      ProgressOverlay({
        visible: this.isComposing,
        message: '合成照片中...',
      })

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
