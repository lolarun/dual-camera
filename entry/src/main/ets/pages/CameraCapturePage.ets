import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppColors, AppFontSize, AppSize, AppSpacing } from '../common/constants/DesignTokens';
import { FormData, CaptureResult, CameraSource, EllipseData } from '../common/types/InspectionTypes';
import { AppButton } from '../components/AppButton';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { ToastNotification } from '../components/ToastNotification';
import { UsbStatusBanner } from '../components/UsbStatusBanner';
import { CameraService } from '../services/CameraService';
import { UsbDetectionService } from '../services/UsbDetectionService';
import { DateUtils } from '../common/utils/DateUtils';

@Entry
@Component
struct CameraCapturePage {
  @State isCapturing: boolean = false;
  @State usbConnected: boolean = false;
  @State showUsbBanner: boolean = false;
  @State useBorescope: boolean = false;
  @State showGrid: boolean = false;
  @State toastMessage: string = '';
  @State showToast: boolean = false;
  @State lastThumbnailUri: string = '';
  @State ellipseList: EllipseData[] = [];

  private overlaySettings: RenderingContextSettings = new RenderingContextSettings(true);
  private overlayCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.overlaySettings);

  private formData: FormData = new FormData();
  private ellipseDataJson: string = '';
  private cameraInitialized: boolean = false;
  private bannerTimer: number = -1;
  private usbCallback: (connected: boolean) => void = (connected: boolean) => {
    this.usbConnected = connected;
    if (!connected && this.useBorescope) {
      this.useBorescope = false;
      this.showToastMessage('孔探设备已断开，已切换至原生摄像头');
    }
    this.showUsbBanner = true;
    if (this.bannerTimer >= 0) {
      clearTimeout(this.bannerTimer);
    }
    this.bannerTimer = setTimeout(() => {
      this.showUsbBanner = false;
    }, 3000);
  };

  private mainController: XComponentController = new XComponentController();
  private pipController: XComponentController = new XComponentController();

  private disconnectDialogController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '孔探设备已断开',
      message: '孔探设备连接中断，已自动切换至原生后摄模式，可继续拍摄。',
      confirmText: '继续拍摄',
      cancelText: '返回',
      onConfirm: () => {},
      onCancel:  () => { router.back(); },
    }),
    autoCancel: false,
  });

  aboutToAppear(): void {
    this.parseRouteParams();
    this.usbConnected = UsbDetectionService.getInstance().isConnected();
    UsbDetectionService.getInstance().addCallback(this.usbCallback);
  }

  aboutToDisappear(): void {
    UsbDetectionService.getInstance().removeCallback(this.usbCallback);
    if (this.bannerTimer >= 0) {
      clearTimeout(this.bannerTimer);
    }
    this.releaseCamera();
  }

  private parseRouteParams(): void {
    const params = router.getParams() as Record<string, string>;
    if (params === null) {
      return;
    }
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
        console.error('CameraCapturePage: failed to parse formData');
      }
    }
    const ellipseJson = params['ellipseDataJson'];
    if (ellipseJson !== undefined && ellipseJson.length > 0) {
      this.ellipseDataJson = ellipseJson;
      try {
        const arr = JSON.parse(ellipseJson) as Array<Record<string, number>>;
        this.ellipseList = arr.map((item: Record<string, number>) => {
          const e = new EllipseData();
          e.centerX  = typeof item['centerX']  === 'number' ? item['centerX']  : 0;
          e.centerY  = typeof item['centerY']  === 'number' ? item['centerY']  : 0;
          e.radiusX  = typeof item['radiusX']  === 'number' ? item['radiusX']  : 0;
          e.radiusY  = typeof item['radiusY']  === 'number' ? item['radiusY']  : 0;
          e.rotation = typeof item['rotation'] === 'number' ? item['rotation'] : 0;
          return e;
        });
      } catch (err) {
        console.error('CameraCapturePage: failed to parse ellipseData');
      }
    }
  }

  private drawEllipseOverlay(): void {
    const ctx = this.overlayCtx;
    ctx.clearRect(0, 0, ctx.width, ctx.height);
    for (let i = 0; i < this.ellipseList.length; i++) {
      const e = this.ellipseList[i];
      ctx.save();
      ctx.beginPath();
      ctx.ellipse(e.centerX, e.centerY, e.radiusX, e.radiusY, e.rotation, 0, Math.PI * 2);
      ctx.fillStyle   = 'rgba(255,107,107,0.25)';
      ctx.fill();
      ctx.strokeStyle = '#FF6B6B';
      ctx.lineWidth   = 3;
      ctx.stroke();
      ctx.restore();
    }
  }

  private async initCamera(surfaceId: string): Promise<void> {
    if (this.cameraInitialized) {
      return;
    }
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const pipSurfaceId = CameraService.getInstance().isDualCameraSupported()
        ? this.pipController.getXComponentSurfaceId()
        : undefined;
      await CameraService.getInstance().initCamera(context, surfaceId, pipSurfaceId);
      this.cameraInitialized = true;
    } catch (err) {
      const e = err as BusinessError;
      console.error(`CameraCapturePage: initCamera failed ${e.message}`);
      this.showToastMessage('相机初始化失败，请重试');
    }
  }

  private releaseCamera(): void {
    if (this.cameraInitialized) {
      CameraService.getInstance().release().catch((err: BusinessError) => {
        console.error(`CameraCapturePage: releaseCamera failed ${err.message}`);
      });
      this.cameraInitialized = false;
    }
  }

  private async capture(): Promise<void> {
    if (this.isCapturing || !this.cameraInitialized) {
      return;
    }
    this.isCapturing = true;
    try {
      const backBuffer = await CameraService.getInstance().capture();
      const result = new CaptureResult();
      result.backImageBytes  = backBuffer;
      result.frontImageBytes = null;
      result.cameraSource    = this.useBorescope ? CameraSource.BORESCOPE : CameraSource.NATIVE;
      result.timestamp       = DateUtils.todayIso();

      router.pushUrl({
        url: 'pages/PostCaptureReviewPage',
        params: {
          formDataJson:    JSON.stringify({
            deviceModel:  this.formData.deviceModel,
            taskNumber:   this.formData.taskNumber,
            unit:         this.formData.unit,
            part:         this.formData.part,
            partArea:     this.formData.partArea,
            project:      this.formData.project,
            operator:     this.formData.operator,
            inspector:    this.formData.inspector,
            photographer: this.formData.photographer,
            photoDate:    this.formData.photoDate,
          }),
          cameraSource:    result.cameraSource,
          timestamp:       result.timestamp,
        },
      });
    } catch (err) {
      const e = err as BusinessError;
      console.error(`CameraCapturePage: capture failed ${e.message}`);
      this.showToastMessage('拍照失败，请重试');
    } finally {
      this.isCapturing = false;
    }
  }

  private showToastMessage(msg: string): void {
    this.toastMessage = msg;
    this.showToast = true;
    setTimeout(() => {
      this.showToast = false;
    }, 3000);
  }

  build() {
    Stack() {
      // Back camera preview
      XComponent({
        id: 'camera-main',
        type: XComponentType.SURFACE,
        controller: this.mainController,
      })
      .width('100%')
      .height('100%')
      .onLoad(() => {
        const surfaceId = this.mainController.getXComponentSurfaceId();
        this.initCamera(surfaceId);
      })
      .onDestroy(() => {
        this.releaseCamera();
      })

      // Ellipse annotation overlay
      if (this.ellipseList.length > 0) {
        Canvas(this.overlayCtx)
          .width('100%')
          .height('100%')
          .onReady(() => { this.drawEllipseOverlay(); })
      }

      // Grid overlay
      if (this.showGrid) {
        Column() {
          Row() {
            Divider().vertical(false).color('rgba(255,255,255,0.3)')
          }.layoutWeight(1)
          Row() {
            Divider().vertical(false).color('rgba(255,255,255,0.3)')
          }.layoutWeight(1)
        }
        .width('100%')
        .height('100%')
      }

      // Top bar
      Row() {
        Text('← 返回')
          .fontSize(AppFontSize.Body)
          .fontColor(AppColors.Surface)
          .height(AppSize.MinTouchTarget)
          .padding({ left: AppSpacing.XS, right: AppSpacing.SM })
          .onClick(() => { router.back(); })

        Blank()

        // Task info
        Text(`${this.formData.taskNumber} · ${this.formData.part}`)
          .fontSize(AppFontSize.Body)
          .fontColor(AppColors.Surface)
          .fontWeight(FontWeight.Medium)

        Blank()

        // Camera source selector
        Row() {
          Text('原生后摄')
            .fontSize(AppFontSize.Helper)
            .fontColor(!this.useBorescope ? AppColors.Surface : AppColors.TextFaded)
            .padding({ left: 12, right: 12 })
            .height(36)
            .borderRadius({ topLeft: 18, bottomLeft: 18 })
            .backgroundColor(!this.useBorescope ? AppColors.Primary : 'rgba(255,255,255,0.15)')
            .onClick(() => { this.useBorescope = false; })

          Text('孔探')
            .fontSize(AppFontSize.Helper)
            .fontColor(this.useBorescope ? AppColors.Surface : (this.usbConnected ? AppColors.TextSecondary : AppColors.TextFaded))
            .padding({ left: 12, right: 12 })
            .height(36)
            .borderRadius({ topRight: 18, bottomRight: 18 })
            .backgroundColor(this.useBorescope ? AppColors.Primary : 'rgba(255,255,255,0.15)')
            .onClick(() => {
              if (this.usbConnected) {
                this.useBorescope = true;
              }
            })
        }
        .margin({ right: AppSpacing.SM })
      }
      .width('100%')
      .height(AppSize.TopBarHeight)
      .padding({ left: AppSpacing.XS })
      .backgroundColor(AppColors.OverlayDark)
      .alignItems(VerticalAlign.Center)
      .position({ x: 0, y: 0 })

      // USB banner
      if (this.showUsbBanner) {
        UsbStatusBanner({ connected: this.usbConnected, visible: true })
          .margin({ left: AppSpacing.SM, right: AppSpacing.SM })
          .position({ x: AppSpacing.SM, y: AppSize.TopBarHeight + AppSpacing.XS })
      }

      // PIP window (top-left)
      if (CameraService.getInstance().isDualCameraSupported()) {
        XComponent({
          id: 'camera-pip',
          type: XComponentType.SURFACE,
          controller: this.pipController,
        })
        .width(AppSize.PipWidth)
        .height(AppSize.PipHeight)
        .borderRadius(12)
        .border({ width: 2, color: AppColors.Surface, style: BorderStyle.Solid })
        .position({ x: AppSpacing.SM, y: AppSize.TopBarHeight + AppSpacing.SM })
      } else {
        // Placeholder PIP
        Column() {
          Text('孔探预览')
            .fontSize(AppFontSize.Helper)
            .fontColor(AppColors.TextFaded)
        }
        .width(AppSize.PipWidth)
        .height(AppSize.PipHeight)
        .borderRadius(12)
        .border({ width: 2, color: AppColors.TextFaded, style: BorderStyle.Dashed })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .position({ x: AppSpacing.SM, y: AppSize.TopBarHeight + AppSpacing.SM })
      }

      // Bottom bar
      Row() {
        // Last thumbnail
        Column() {
          if (this.lastThumbnailUri.length > 0) {
            Image(this.lastThumbnailUri)
              .width(AppSize.ThumbnailSmall)
              .height(AppSize.ThumbnailSmall)
              .borderRadius(AppSize.BorderRadius)
              .objectFit(ImageFit.Cover)
          } else {
            Column()
              .width(AppSize.ThumbnailSmall)
              .height(AppSize.ThumbnailSmall)
              .borderRadius(AppSize.BorderRadius)
              .backgroundColor('rgba(255,255,255,0.1)')
          }
        }
        .width(100)
        .alignItems(HorizontalAlign.Center)

        Blank()

        // Capture button
        Stack() {
          Circle()
            .width(AppSize.CaptureButtonDiameter)
            .height(AppSize.CaptureButtonDiameter)
            .fill(AppColors.Surface)
            .stroke(AppColors.Surface)
            .strokeWidth(3)

          if (this.isCapturing) {
            LoadingProgress()
              .color(AppColors.Primary)
              .width(40)
              .height(40)
          }
        }
        .width(AppSize.CaptureButtonDiameter)
        .height(AppSize.CaptureButtonDiameter)
        .scale(this.isCapturing ? { x: 0.94, y: 0.94 } : { x: 1, y: 1 })
        .onClick(() => { this.capture(); })

        Blank()

        // Right controls
        Column() {
          Text(this.showGrid ? '⊞' : '⊟')
            .fontSize(AppFontSize.SectionHeader)
            .fontColor(AppColors.Surface)
            .height(AppSize.MinTouchTarget)
            .width(AppSize.MinTouchTarget)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.showGrid = !this.showGrid; })
        }
        .width(100)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height(AppSize.BottomBarHeight)
      .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
      .backgroundColor(AppColors.OverlayDark)
      .alignItems(VerticalAlign.Center)
      .position({ x: 0, y: '100%' })
      .translate({ y: -AppSize.BottomBarHeight })

      // Helper text above bottom bar
      Text('拍摄后将自动添加水印')
        .fontSize(AppFontSize.Helper)
        .fontColor('rgba(255,255,255,0.7)')
        .textAlign(TextAlign.Center)
        .width('100%')
        .position({ x: 0, y: '100%' })
        .translate({ y: -(AppSize.BottomBarHeight + 28) })

      // Toast
      if (this.showToast) {
        ToastNotification({
          message: this.toastMessage,
          toastType: 'warning',
          visible: true,
          onDismiss: () => { this.showToast = false; },
        })
        .position({ x: '10%', y: '85%' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
