import { router } from '@kit.ArkUI';
import { AppColors, AppFontSize, AppSize, AppSpacing } from '../common/constants/DesignTokens';
import {
  DEVICE_MODELS,
  UNITS,
  PARTS_BY_MODEL,
  PART_AREAS_BY_PART,
  PROJECTS_BY_AREA,
} from '../common/constants/FormConstants';
import { FormData } from '../common/types/InspectionTypes';
import { AppButton } from '../components/AppButton';
import { AppInput } from '../components/AppInput';
import { AppDropdown } from '../components/AppDropdown';
import { ConfirmDialog } from '../components/ConfirmDialog';
import { PreferencesService } from '../services/PreferencesService';
import { DateUtils } from '../common/utils/DateUtils';
import { FileUtils } from '../common/utils/FileUtils';

@Entry
@Component
struct MetadataFormPage {
  @State deviceModel: string = '';
  @State taskNumber: string = '';
  @State unit: string = '';
  @State part: string = '';
  @State partArea: string = '';
  @State project: string = '';
  @State operator: string = '';
  @State inspector: string = '';
  @State photographer: string = '';
  @State photoDate: string = '';
  @State taskNumberError: string = '';
  @State draftSavedText: string = '';
  @State isDirty: boolean = false;

  private autoSaveTimer: number = -1;

  private confirmBackController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '保存草稿？',
      message: '您的填写内容将以草稿形式保存，下次打开可继续编辑。',
      confirmText: '保存草稿',
      cancelText: '不保存',
      onConfirm: () => { this.saveDraftAndGoBack(); },
      onCancel:  () => { this.clearDraftAndGoBack(); },
    }),
    autoCancel: false,
  });

  private confirmResetController: CustomDialogController = new CustomDialogController({
    builder: ConfirmDialog({
      title: '重置表单',
      message: '确定要清空所有填写内容吗？',
      confirmText: '确认重置',
      cancelText: '取消',
      destructive: true,
      onConfirm: () => { this.resetForm(); },
      onCancel:  () => {},
    }),
    autoCancel: true,
  });

  aboutToAppear(): void {
    this.photoDate = DateUtils.todayIso();
    this.loadPrefilledValues();
    this.loadDraftIfAvailable();
    this.startAutoSave();
  }

  aboutToDisappear(): void {
    if (this.autoSaveTimer >= 0) {
      clearInterval(this.autoSaveTimer);
    }
  }

  onBackPress(): boolean {
    if (this.isDirty) {
      this.confirmBackController.open();
    } else {
      router.back();
    }
    return true;
  }

  private async loadPrefilledValues(): Promise<void> {
    try {
      const savedInspector    = await PreferencesService.getInstance().getLastInspector();
      const savedPhotographer = await PreferencesService.getInstance().getLastPhotographer();
      if (savedInspector.length > 0 && this.inspector.length === 0) {
        this.inspector = savedInspector;
      }
      if (savedPhotographer.length > 0 && this.photographer.length === 0) {
        this.photographer = savedPhotographer;
      }
    } catch (err) {
      console.error('MetadataFormPage: loadPrefilledValues failed');
    }
  }

  private async loadDraftIfAvailable(): Promise<void> {
    try {
      const draft = await PreferencesService.getInstance().loadDraft();
      if (draft === null) {
        return;
      }
      this.deviceModel  = draft.deviceModel;
      this.taskNumber   = draft.taskNumber;
      this.unit         = draft.unit;
      this.part         = draft.part;
      this.partArea     = draft.partArea;
      this.project      = draft.project;
      this.operator     = draft.operator;
      if (draft.inspector.length > 0)    { this.inspector    = draft.inspector; }
      if (draft.photographer.length > 0) { this.photographer = draft.photographer; }
      if (draft.photoDate.length > 0)    { this.photoDate    = draft.photoDate; }
      const ts = await PreferencesService.getInstance().getDraftTimestamp();
      this.draftSavedText = `已加载草稿 · ${DateUtils.getRelativeTime(new Date(ts))}`;
      this.isDirty = false;
    } catch (err) {
      console.error('MetadataFormPage: loadDraft failed');
    }
  }

  private startAutoSave(): void {
    this.autoSaveTimer = setInterval(() => {
      if (this.isDirty) {
        this.doSaveDraft();
      }
    }, 30000);
  }

  private buildFormData(): FormData {
    const f = new FormData();
    f.deviceModel  = this.deviceModel;
    f.taskNumber   = this.taskNumber;
    f.unit         = this.unit;
    f.part         = this.part;
    f.partArea     = this.partArea;
    f.project      = this.project;
    f.operator     = this.operator;
    f.inspector    = this.inspector;
    f.photographer = this.photographer;
    f.photoDate    = this.photoDate;
    return f;
  }

  private async doSaveDraft(): Promise<void> {
    try {
      await PreferencesService.getInstance().saveDraft(this.buildFormData());
      this.draftSavedText = '已自动保存草稿 · 刚刚';
    } catch (err) {
      console.error('MetadataFormPage: saveDraft failed');
    }
  }

  private async saveDraftAndGoBack(): Promise<void> {
    await this.doSaveDraft();
    router.back();
  }

  private async clearDraftAndGoBack(): Promise<void> {
    try {
      await PreferencesService.getInstance().clearDraft();
    } catch (err) {
      console.error('MetadataFormPage: clearDraft failed');
    }
    router.back();
  }

  private resetForm(): void {
    this.deviceModel     = '';
    this.taskNumber      = '';
    this.unit            = '';
    this.part            = '';
    this.partArea        = '';
    this.project         = '';
    this.operator        = '';
    this.inspector       = '';
    this.photographer    = '';
    this.photoDate       = DateUtils.todayIso();
    this.taskNumberError = '';
    this.isDirty         = false;
  }

  private isFormValid(): boolean {
    return this.deviceModel.length > 0
      && FileUtils.validateTaskNumber(this.taskNumber)
      && this.unit.length > 0
      && this.part.length > 0
      && this.operator.length > 0
      && this.inspector.length > 0
      && this.photographer.length > 0
      && this.photoDate.length > 0;
  }

  private getPartOptions(): string[] {
    if (this.deviceModel.length === 0) { return []; }
    const parts = PARTS_BY_MODEL.get(this.deviceModel);
    return parts !== undefined ? parts : [];
  }

  private getPartAreaOptions(): string[] {
    if (this.part.length === 0) { return []; }
    const areas = PART_AREAS_BY_PART.get(this.part);
    return areas !== undefined ? areas : [];
  }

  private getProjectOptions(): string[] {
    if (this.partArea.length === 0) { return []; }
    const projects = PROJECTS_BY_AREA.get(this.partArea);
    return projects !== undefined ? projects : [];
  }

  private showDatePicker(): void {
    const parts = this.photoDate.split('-');
    const year  = parts.length >= 1 ? parseInt(parts[0]) : new Date().getFullYear();
    const month = parts.length >= 2 ? parseInt(parts[1]) - 1 : new Date().getMonth();
    const day   = parts.length >= 3 ? parseInt(parts[2]) : new Date().getDate();
    DatePickerDialog.show({
      start:    new Date('2020-01-01'),
      end:      new Date('2030-12-31'),
      selected: new Date(year, month, day),
      lunar:    false,
      onAccept: (value: DatePickerResult) => {
        const y  = value.year  !== undefined ? value.year  : new Date().getFullYear();
        const m  = (value.month !== undefined ? value.month : new Date().getMonth()) + 1;
        const d  = value.day   !== undefined ? value.day   : new Date().getDate();
        const mm = m < 10 ? `0${m}` : `${m}`;
        const dd = d < 10 ? `0${d}` : `${d}`;
        this.photoDate = `${y}-${mm}-${dd}`;
        this.isDirty   = true;
      },
    });
  }

  private navigateToNext(): void {
    const f = this.buildFormData();
    router.pushUrl({
      url: 'pages/EllipseDrawPage',
      params: {
        formDataJson: JSON.stringify({
          deviceModel:  f.deviceModel,
          taskNumber:   f.taskNumber,
          unit:         f.unit,
          part:         f.part,
          partArea:     f.partArea,
          project:      f.project,
          operator:     f.operator,
          inspector:    f.inspector,
          photographer: f.photographer,
          photoDate:    f.photoDate,
        }),
      },
    });
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
          .onClick(() => {
            if (this.isDirty) {
              this.confirmBackController.open();
            } else {
              router.back();
            }
          })

        Text('相片标示信息输入')
          .fontSize(AppFontSize.SectionHeader)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TextPrimary)

        Blank()

        if (this.draftSavedText.length > 0) {
          Text(this.draftSavedText)
            .fontSize(AppFontSize.Helper)
            .fontColor(AppColors.TextSecondary)
            .margin({ right: AppSpacing.SM })
        }
      }
      .width('100%')
      .height(AppSize.TopBarHeight)
      .padding({ left: AppSpacing.XS, right: AppSpacing.XS })
      .backgroundColor(AppColors.Surface)
      .borderWidth({ bottom: 1 })
      .borderColor(AppColors.Border)
      .borderStyle(BorderStyle.Solid)
      .alignItems(VerticalAlign.Center)

      // 2-column content
      Row() {
        // Left column: scrollable form (60%)
        Scroll() {
          Column() {
            AppDropdown({
              label: '机型信息',
              value: this.deviceModel,
              options: DEVICE_MODELS,
              required: true,
              onSelect: (val: string) => {
                this.deviceModel = val;
                this.part        = '';
                this.partArea    = '';
                this.project     = '';
                this.isDirty     = true;
              },
            })
            .margin({ bottom: AppSpacing.SM })

            AppInput({
              label: '任务号',
              value: this.taskNumber,
              placeholder: '如 A12345',
              errorMessage: this.taskNumberError,
              required: true,
              onValueChange: (val: string) => {
                this.taskNumber      = val;
                this.taskNumberError = (val.length > 0 && !FileUtils.validateTaskNumber(val))
                  ? '格式：大写字母 + 4-6 位数字，如 A12345'
                  : '';
                this.isDirty = true;
              },
            })
            .margin({ bottom: AppSpacing.SM })

            AppDropdown({
              label: '单位',
              value: this.unit,
              options: UNITS,
              required: true,
              onSelect: (val: string) => {
                this.unit    = val;
                this.isDirty = true;
              },
            })
            .margin({ bottom: AppSpacing.SM })

            AppDropdown({
              label: '部位',
              value: this.part,
              options: this.getPartOptions(),
              disabled: this.deviceModel.length === 0,
              required: true,
              helperText: this.deviceModel.length === 0 ? '请先选择机型信息' : '',
              onSelect: (val: string) => {
                this.part     = val;
                this.partArea = '';
                this.project  = '';
                this.isDirty  = true;
              },
            })
            .margin({ bottom: AppSpacing.SM })

            AppDropdown({
              label: '部位区域',
              value: this.partArea,
              options: this.getPartAreaOptions(),
              disabled: this.part.length === 0,
              helperText: this.part.length === 0 ? '请先选择部位' : '',
              onSelect: (val: string) => {
                this.partArea = val;
                this.project  = '';
                this.isDirty  = true;
              },
            })
            .margin({ bottom: AppSpacing.SM })

            AppDropdown({
              label: '照相对应项目',
              value: this.project,
              options: this.getProjectOptions(),
              disabled: this.partArea.length === 0,
              helperText: this.partArea.length === 0 ? '请先选择部位区域' : '',
              onSelect: (val: string) => {
                this.project = val;
                this.isDirty = true;
              },
            })
            .margin({ bottom: AppSpacing.SM })

            AppInput({
              label: '操作者',
              value: this.operator,
              placeholder: '请输入操作者姓名',
              required: true,
              onValueChange: (val: string) => {
                this.operator = val;
                this.isDirty  = true;
              },
            })
            .margin({ bottom: AppSpacing.SM })

            AppInput({
              label: '检验员',
              value: this.inspector,
              placeholder: '请输入检验员姓名',
              required: true,
              onValueChange: (val: string) => {
                this.inspector = val;
                this.isDirty   = true;
              },
            })
            .margin({ bottom: AppSpacing.SM })

            AppInput({
              label: '照相人',
              value: this.photographer,
              placeholder: '请输入照相人姓名',
              required: true,
              onValueChange: (val: string) => {
                this.photographer = val;
                this.isDirty      = true;
              },
            })
            .margin({ bottom: AppSpacing.SM })

            // Field 10: date picker
            Column() {
              Row() {
                Text('照相日期')
                  .fontSize(AppFontSize.FormLabel)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppColors.TextPrimary)
                Text(' *')
                  .fontSize(AppFontSize.FormLabel)
                  .fontColor(AppColors.Danger)
              }
              .width('100%')
              .margin({ bottom: AppSpacing.XS })

              Row() {
                Text(this.photoDate.length > 0 ? this.photoDate : '请选择日期')
                  .fontSize(AppFontSize.Body)
                  .fontColor(this.photoDate.length > 0 ? AppColors.TextPrimary : AppColors.TextDisabled)
                  .layoutWeight(1)
                Text('▸')
                  .fontSize(AppFontSize.Helper)
                  .fontColor(AppColors.TextSecondary)
              }
              .height(AppSize.InputHeight)
              .width('100%')
              .padding({ left: 12, right: 12 })
              .borderRadius(AppSize.BorderRadius)
              .border({ width: 1, color: AppColors.Border, style: BorderStyle.Solid })
              .backgroundColor(AppColors.Surface)
              .onClick(() => { this.showDatePicker(); })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: AppSpacing.LG })
          }
          .width('100%')
          .padding(AppSpacing.SM)
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(6)
        .height('100%')
        .scrollBar(BarState.Auto)

        Divider()
          .vertical(true)
          .height('100%')
          .color(AppColors.Border)

        // Right column: reference image placeholder (40%)
        Column() {
          Text('参考图片')
            .fontSize(AppFontSize.SectionHeader)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TextPrimary)
            .margin({ bottom: AppSpacing.SM })

          Column() {
            Text('📷')
              .fontSize(48)
              .margin({ bottom: AppSpacing.SM })
            Text('下一步可在图片上圈画照相点位置')
              .fontSize(AppFontSize.Body)
              .fontColor(AppColors.TextSecondary)
              .textAlign(TextAlign.Center)
          }
          .layoutWeight(1)
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .borderRadius(AppSize.BorderRadiusLarge)
          .border({ width: 2, color: AppColors.Border, style: BorderStyle.Dashed })
          .backgroundColor(AppColors.Background)
        }
        .layoutWeight(4)
        .height('100%')
        .padding(AppSpacing.SM)
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')

      // Bottom action bar
      Row() {
        AppButton({
          label: '重置',
          variant: 'secondary',
          onAction: () => { this.confirmResetController.open(); },
        })
        .layoutWeight(1)
        .margin({ right: AppSpacing.SM })

        AppButton({
          label: '下一步：圈画照相点',
          variant: this.isFormValid() ? 'primary' : 'disabled',
          btnSize: 'large',
          onAction: () => {
            if (this.isFormValid()) {
              this.navigateToNext();
            }
          },
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
  }
}
