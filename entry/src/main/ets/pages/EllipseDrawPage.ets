import { router } from '@kit.ArkUI';
import { AppColors, AppFontSize, AppSize, AppSpacing } from '../common/constants/DesignTokens';
import { EllipseData, FormData } from '../common/types/InspectionTypes';
import { AppButton } from '../components/AppButton';
import { ConfirmDialog } from '../components/ConfirmDialog';

@Entry
@Component
struct EllipseDrawPage {
  @State hasEllipse: boolean = false;
  @State canUndo: boolean = false;
  @State canRedo: boolean = false;

  private formDataJson: string = '';
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private canvasWidth: number = 0;
  private canvasHeight: number = 0;
  private touchStartX: number = 0;
  private touchStartY: number = 0;
  private isDrawing: boolean = false;

  private currentEllipse: EllipseData | null = null;
  private ellipseStack: EllipseData[] = [];
  private redoStack: EllipseData[] = [];

  private confirmDiscardController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '放弃修改？',
      message: '已绘制的圈画内容将不会保存。',
      confirmText: '放弃',
      cancelText: '继续绘制',
      destructive: true,
      onConfirm: () => { router.back(); },
      onCancel:  () => {},
    }),
    autoCancel: true,
  });

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== null && params['formDataJson'] !== undefined) {
      this.formDataJson = params['formDataJson'];
    }
  }

  private handleTouch(event: TouchEvent): void {
    const touch = event.touches[0];
    if (touch === undefined) {
      return;
    }
    if (event.type === TouchType.Down) {
      this.touchStartX = touch.x;
      this.touchStartY = touch.y;
      this.isDrawing   = true;
      this.redoStack   = [];
      this.canRedo     = false;
    } else if (event.type === TouchType.Move && this.isDrawing) {
      const cx = (this.touchStartX + touch.x) / 2;
      const cy = (this.touchStartY + touch.y) / 2;
      const rx = Math.abs(touch.x - this.touchStartX) / 2;
      const ry = Math.abs(touch.y - this.touchStartY) / 2;
      if (rx > 4 && ry > 4) {
        const e = new EllipseData();
        e.centerX = cx;
        e.centerY = cy;
        e.radiusX = rx;
        e.radiusY = ry;
        this.currentEllipse = e;
        this.drawAll();
      }
    } else if (event.type === TouchType.Up && this.isDrawing) {
      this.isDrawing = false;
      if (this.currentEllipse !== null) {
        this.ellipseStack.push(this.currentEllipse);
        this.currentEllipse = null;
        this.hasEllipse = true;
        this.canUndo    = true;
        this.drawAll();
      }
    }
  }

  private undo(): void {
    if (this.ellipseStack.length === 0) {
      return;
    }
    const last = this.ellipseStack.pop();
    if (last !== undefined) {
      this.redoStack.push(last);
    }
    this.hasEllipse = this.ellipseStack.length > 0;
    this.canUndo    = this.ellipseStack.length > 0;
    this.canRedo    = true;
    this.drawAll();
  }

  private redo(): void {
    if (this.redoStack.length === 0) {
      return;
    }
    const next = this.redoStack.pop();
    if (next !== undefined) {
      this.ellipseStack.push(next);
    }
    this.hasEllipse = true;
    this.canUndo    = true;
    this.canRedo    = this.redoStack.length > 0;
    this.drawAll();
  }

  private drawAll(): void {
    const ctx = this.canvasContext;
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    // Draw grid background (reference image placeholder)
    ctx.fillStyle = '#E8ECF0';
    ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);

    // Placeholder label
    ctx.fillStyle = AppColors.TextDisabled;
    ctx.font = `${AppFontSize.Body}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.fillText('参考图片区域', this.canvasWidth / 2, this.canvasHeight / 2);

    // Draw all committed ellipses
    for (let i = 0; i < this.ellipseStack.length; i++) {
      this.drawEllipse(this.ellipseStack[i], i === this.ellipseStack.length - 1);
    }

    // Draw the current in-progress ellipse
    if (this.currentEllipse !== null) {
      this.drawEllipse(this.currentEllipse, false);
    }
  }

  private drawEllipse(e: EllipseData, isLatest: boolean): void {
    const ctx = this.canvasContext;
    ctx.save();
    ctx.beginPath();
    ctx.ellipse(e.centerX, e.centerY, Math.max(e.radiusX, 1), Math.max(e.radiusY, 1), 0, 0, Math.PI * 2);
    ctx.fillStyle = isLatest ? 'rgba(255, 107, 107, 0.25)' : 'rgba(255, 107, 107, 0.15)';
    ctx.fill();
    ctx.strokeStyle = '#FF6B6B';
    ctx.lineWidth = isLatest ? 3 : 2;
    ctx.stroke();
    ctx.restore();
  }

  private navigateToCamera(): void {
    router.pushUrl({
      url: 'pages/CameraCapturePage',
      params: {
        formDataJson:    this.formDataJson,
        ellipseDataJson: JSON.stringify(this.ellipseStack),
      },
    });
  }

  build() {
    Stack() {
      // Canvas fills entire screen
      Canvas(this.canvasContext)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.canvasWidth  = this.canvasContext.width;
          this.canvasHeight = this.canvasContext.height;
          this.drawAll();
        })
        .onTouch((event: TouchEvent) => {
          this.handleTouch(event);
        })

      // Top bar (translucent dark)
      Column() {
        Row() {
          // Back
          Text('← 返回')
            .fontSize(AppFontSize.Body)
            .fontColor(AppColors.Surface)
            .height(AppSize.MinTouchTarget)
            .padding({ left: AppSpacing.XS, right: AppSpacing.SM })
            .onClick(() => {
              if (this.hasEllipse) {
                this.confirmDiscardController.open();
              } else {
                router.back();
              }
            })

          Blank()

          // Instruction text
          Text('拖动绘制红色椭圆圈出照相点')
            .fontSize(AppFontSize.Body)
            .fontColor(AppColors.Surface)
            .fontWeight(FontWeight.Medium)

          Blank()

          // Undo
          Text('撤销')
            .fontSize(AppFontSize.Body)
            .fontColor(this.canUndo ? AppColors.Surface : AppColors.TextFaded)
            .height(AppSize.MinTouchTarget)
            .padding({ left: AppSpacing.SM, right: AppSpacing.XS })
            .onClick(() => { if (this.canUndo) { this.undo(); } })

          // Redo
          Text('重做')
            .fontSize(AppFontSize.Body)
            .fontColor(this.canRedo ? AppColors.Surface : AppColors.TextFaded)
            .height(AppSize.MinTouchTarget)
            .padding({ left: AppSpacing.XS, right: AppSpacing.SM })
            .onClick(() => { if (this.canRedo) { this.redo(); } })

          // Done
          AppButton({
            label: '完成',
            variant: this.hasEllipse ? 'primary' : 'disabled',
            onAction: () => {
              if (this.hasEllipse) {
                this.navigateToCamera();
              }
            },
          })
          .margin({ left: AppSpacing.XS, right: AppSpacing.XS })
        }
        .width('100%')
        .height(AppSize.TopBarHeight)
        .padding({ left: AppSpacing.XS, right: AppSpacing.XS })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .backgroundColor(AppColors.OverlayDark)
      .alignItems(HorizontalAlign.Start)

      // Bottom helper hint
      Row() {
        Text('提示：可多次调整椭圆位置和大小，最后一个椭圆将用于标注')
          .fontSize(AppFontSize.Helper)
          .fontColor(AppColors.Surface)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(48)
      .backgroundColor(AppColors.OverlayDark)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .position({ x: 0, y: '100%' })
      .translate({ y: -48 })
    }
    .width('100%')
    .height('100%')
  }
}
