import { commonEventManager } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';

export type UsbConnectionCallback = (connected: boolean) => void;

export class UsbDetectionService {
  private static instance: UsbDetectionService | null = null;
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  private connected: boolean = false;
  private callbacks: UsbConnectionCallback[] = [];

  private constructor() {}

  static getInstance(): UsbDetectionService {
    if (UsbDetectionService.instance === null) {
      UsbDetectionService.instance = new UsbDetectionService();
    }
    return UsbDetectionService.instance;
  }

  start(): void {
    if (this.subscriber !== null) {
      return;
    }
    const info: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        commonEventManager.Support.COMMON_EVENT_USB_DEVICE_ATTACHED,
        commonEventManager.Support.COMMON_EVENT_USB_DEVICE_DETACHED,
      ],
    };
    commonEventManager.createSubscriber(info).then(
      (sub: commonEventManager.CommonEventSubscriber) => {
        this.subscriber = sub;
        commonEventManager.subscribe(sub, (err: BusinessError, data: commonEventManager.CommonEventData) => {
          if (err.code !== 0) {
            return;
          }
          const isAttach = data.event === commonEventManager.Support.COMMON_EVENT_USB_DEVICE_ATTACHED;
          this.connected = isAttach;
          for (let i = 0; i < this.callbacks.length; i++) {
            this.callbacks[i](isAttach);
          }
        });
      }
    ).catch((err: BusinessError) => {
      console.error(`UsbDetectionService.start failed: ${err.message}`);
    });
  }

  stop(): void {
    if (this.subscriber !== null) {
      commonEventManager.unsubscribe(this.subscriber);
      this.subscriber = null;
    }
    this.callbacks = [];
  }

  isConnected(): boolean {
    return this.connected;
  }

  addCallback(cb: UsbConnectionCallback): void {
    this.callbacks.push(cb);
  }

  removeCallback(cb: UsbConnectionCallback): void {
    const idx = this.callbacks.indexOf(cb);
    if (idx >= 0) {
      this.callbacks.splice(idx, 1);
    }
  }
}
