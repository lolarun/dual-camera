import { router } from '@kit.ArkUI';
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';
import { AppColors, AppFontSize, AppSize, AppSpacing } from '../common/constants/DesignTokens';
import { AppButton } from '../components/AppButton';
import { UsbStatusBanner } from '../components/UsbStatusBanner';
import { PreferencesService } from '../services/PreferencesService';

@Entry
@Component
struct HomePage {
  @State inspectorName: string = '';
  @State usbConnected: boolean = false;
  @State showUsbBanner: boolean = false;
  @State storageLow: boolean = false;
  @State permissionGranted: boolean = false;

  private usbSubscriber: commonEventManager.CommonEventSubscriber | null = null;
  private bannerTimer: number = -1;

  aboutToAppear(): void {
    this.loadInspectorName();
    this.checkPermissions();
    this.subscribeUsbEvents();
  }

  aboutToDisappear(): void {
    if (this.usbSubscriber !== null) {
      commonEventManager.unsubscribe(this.usbSubscriber);
    }
    if (this.bannerTimer >= 0) {
      clearTimeout(this.bannerTimer);
    }
  }

  private loadInspectorName(): void {
    PreferencesService.getInstance().getLastInspector().then((name: string) => {
      if (name.length > 0) {
        this.inspectorName = name;
      }
    }).catch((err: BusinessError) => {
      console.error(`HomePage: loadInspectorName failed ${err.message}`);
    });
  }

  private checkPermissions(): void {
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const tokenId = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      ).appInfo.accessTokenId;
      const cameraStatus = atManager.checkAccessTokenSync(tokenId, 'ohos.permission.CAMERA');
      const readStatus = atManager.checkAccessTokenSync(tokenId, 'ohos.permission.READ_IMAGEVIDEO');
      this.permissionGranted = (cameraStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED &&
        readStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
      if (!this.permissionGranted) {
        this.requestPermissions(atManager);
      }
    } catch (err) {
      const e = err as BusinessError;
      console.error(`HomePage: checkPermissions failed ${e.message}`);
    }
  }

  private requestPermissions(atManager: abilityAccessCtrl.AtManager): void {
    const permissions: Permissions[] = [
      'ohos.permission.CAMERA' as Permissions,
      'ohos.permission.READ_IMAGEVIDEO' as Permissions,
      'ohos.permission.WRITE_IMAGEVIDEO' as Permissions,
    ];
    atManager.requestPermissionsFromUser(getContext(this), permissions).then(() => {
      this.permissionGranted = true;
    }).catch((err: BusinessError) => {
      console.error(`HomePage: requestPermissions failed ${err.message}`);
    });
  }

  private subscribeUsbEvents(): void {
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        commonEventManager.Support.COMMON_EVENT_USB_DEVICE_ATTACHED,
        commonEventManager.Support.COMMON_EVENT_USB_DEVICE_DETACHED,
      ],
    };
    commonEventManager.createSubscriber(subscribeInfo).then(
      (subscriber: commonEventManager.CommonEventSubscriber) => {
        this.usbSubscriber = subscriber;
        commonEventManager.subscribe(subscriber, (err: BusinessError, data: commonEventManager.CommonEventData) => {
          if (err.code !== 0) {
            return;
          }
          const attached = data.event === commonEventManager.Support.COMMON_EVENT_USB_DEVICE_ATTACHED;
          this.usbConnected = attached;
          this.showUsbBanner = true;
          if (this.bannerTimer >= 0) {
            clearTimeout(this.bannerTimer);
          }
          this.bannerTimer = setTimeout(() => {
            this.showUsbBanner = false;
          }, 3000);
        });
      }
    ).catch((err: BusinessError) => {
      console.error(`HomePage: subscribeUsbEvents failed ${err.message}`);
    });
  }

  build() {
    Stack() {
      // Page background
      Column() {
        // Top bar
        Row() {
          // Storage warning indicator (top-left)
          if (this.storageLow) {
            Row() {
              Text('⚠')
                .fontSize(AppFontSize.Helper)
                .fontColor(AppColors.Surface)
                .margin({ right: 4 })
              Text('存储空间不足')
                .fontSize(AppFontSize.Helper)
                .fontColor(AppColors.Surface)
            }
            .padding({ left: 12, right: 12 })
            .height(36)
            .backgroundColor(AppColors.Warning)
            .borderRadius(18)
          }

          Blank()

          // USB status indicator (top-right)
          Row() {
            Circle()
              .width(12)
              .height(12)
              .fill(this.usbConnected ? AppColors.Success : AppColors.TextDisabled)
              .margin({ right: 6 })
            Text(this.usbConnected ? '孔探' : '单机模式')
              .fontSize(AppFontSize.Tag)
              .fontColor(this.usbConnected ? AppColors.TextPrimary : AppColors.TextSecondary)
              .fontWeight(FontWeight.Medium)
          }
          .padding({ left: 12, right: 12 })
          .height(36)
          .backgroundColor(AppColors.TagBg)
          .borderRadius(18)
        }
        .width('100%')
        .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.SM })

        // USB banner
        if (this.showUsbBanner) {
          UsbStatusBanner({
            connected: this.usbConnected,
            visible: true,
          })
          .margin({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.XS })
        }

        // Main content — centered
        Column() {
          // App title
          Text('工业巡检拍照')
            .fontSize(AppFontSize.PageTitle)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TextPrimary)
            .margin({ bottom: AppSpacing.XL })

          // Primary CTA
          AppButton({
            label: '开始新任务',
            variant: 'primary',
            btnSize: 'large',
            fullWidth: true,
            onAction: () => {
              router.pushUrl({ url: 'pages/MetadataFormPage' });
            },
          })
          .margin({ bottom: AppSpacing.SM })

          // Secondary buttons
          AppButton({
            label: '历史记录',
            variant: 'secondary',
            btnSize: 'normal',
            fullWidth: true,
            onAction: () => {
              router.pushUrl({ url: 'pages/HistoryListPage' });
            },
          })
          .margin({ bottom: AppSpacing.SM })

          AppButton({
            label: '工作记录',
            variant: 'secondary',
            btnSize: 'normal',
            fullWidth: true,
            onAction: () => {
              router.pushUrl({ url: 'pages/WorkLogPage' });
            },
          })
        }
        .width(480)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // Footer
        Row() {
          Text('v1.0.0')
            .fontSize(AppFontSize.Helper)
            .fontColor(AppColors.TextDisabled)

          if (this.inspectorName.length > 0) {
            Text(`  ·  检验员：${this.inspectorName}`)
              .fontSize(AppFontSize.Helper)
              .fontColor(AppColors.TextDisabled)
          }
        }
        .padding({ bottom: AppSpacing.SM })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.Background)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
