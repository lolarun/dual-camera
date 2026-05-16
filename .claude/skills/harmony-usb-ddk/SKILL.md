---
name: harmony-usb-ddk
description: USB external devices for HarmonyOS — borescopes, USB cameras, external peripherals connected via USB-C. Trigger phrases: "USB camera", "borescope", "USB device", "external camera", "USB-C peripheral", "UVC", "USB DDK", "孔探", "connect USB", "hot-plug USB".
---

# When to Use This Skill

Example trigger prompts:
- "How do I connect the borescope via USB?"
- "Detect when the USB camera is plugged in"
- "Show borescope preview instead of the native camera"
- "Handle borescope disconnect during capture"
- "Is the borescope connected?"

---

# Critical: Camera Kit Does NOT See USB Cameras

HarmonyOS Camera Kit (`@kit.CameraKit`) enumerates **native** cameras only
(front, back, front-wide, etc.). USB cameras, including industrial borescopes
connected via USB-C, are **NOT** visible as `CameraDevice` objects.

---

# Three Integration Paths (Choose One)

## Path A — Vendor HarmonyOS SDK ✅ Best

If the borescope manufacturer provides a HarmonyOS Next SDK:

1. Install it via ohpm: `ohpm install @vendor/borescope-sdk`
2. Follow the vendor's API to get a `SurfaceId` for preview
3. Connect that surface to an `XComponent` in your UI

**Always check for a vendor SDK first.** It handles UVC, firmware quirks,
and device compatibility.

## Path B — Third-Party ohpm UVC Library ⚠️ Middle Ground

```bash
ohpm install @ohos/uvc_camera   # check ohpm.openharmony.cn for current package
```

Provides a higher-level API over USB DDK. Community-maintained; audit before
production use.

## Path C — Raw USB DDK 🔴 High Cost

Implementing UVC protocol from scratch over USB DDK requires:
- Native C/C++ code via NDK
- UVC descriptor parsing
- Isochronous USB transfers for video stream
- Codec pipeline for MJPEG/YUV decoding

Estimated cost: 2–4 engineer-weeks. Only choose this if A and B are not viable.

---

# USB Detection (Common to All Paths)

## Permission

Declare in `module.json5`:
```json5
"requestPermissions": [
  { "name": "ohos.permission.ACCESS_DDK_USB" }
]
```

## Detect Connected USB Devices

```typescript
import { usbManager } from "@kit.BasicServicesKit";

function listUsbDevices(): usbManager.USBDevice[] {
  return usbManager.getDevices();
}

function isBorescopeConnected(): boolean {
  const devices = usbManager.getDevices();
  // Filter by vendor ID / product ID if known, or by device class
  // USB class 0x0E = Video / UVC
  return devices.some(d => d.configs.some(c =>
    c.interfaces.some(i => i.clazz === 0x0E)
  ));
}
```

## Hot-Plug Events

```typescript
import { commonEventManager } from "@kit.BasicServicesKit";

class UsbHotplugListener {
  private subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [
      commonEventManager.Support.COMMON_EVENT_USB_DEVICE_ATTACHED,
      commonEventManager.Support.COMMON_EVENT_USB_DEVICE_DETACHED,
    ]
  };
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;

  async start(
    onAttached: (device: usbManager.USBDevice) => void,
    onDetached: () => void
  ): Promise<void> {
    this.subscriber = await commonEventManager.createSubscriber(this.subscribeInfo);
    commonEventManager.subscribe(this.subscriber, (err, data) => {
      if (data.event === commonEventManager.Support.COMMON_EVENT_USB_DEVICE_ATTACHED) {
        const connected = isBorescopeConnected();
        if (connected) onAttached(usbManager.getDevices()[0]);
      } else {
        onDetached();
      }
    });
  }

  async stop(): Promise<void> {
    if (this.subscriber !== null) {
      await commonEventManager.unsubscribe(this.subscriber);
    }
  }
}
```

## Use in Camera Page Component

```typescript
@Entry @Component
struct CameraPage {
  @State borescopeConnected: boolean = false;
  private hotplugListener = new UsbHotplugListener();

  aboutToAppear(): void {
    this.borescopeConnected = isBorescopeConnected();
    this.hotplugListener.start(
      (_device) => {
        this.borescopeConnected = true;
        this.showBanner("孔探设备已连接");
      },
      () => {
        this.borescopeConnected = false;
        this.showBanner("孔探设备已断开，已切换至原生后摄");
        this.switchToNativeCamera();
      }
    );
  }

  aboutToDisappear(): void {
    this.hotplugListener.stop();
  }
}
```

---

# Runtime Permission Grant for Specific Device

HarmonyOS requires the user to explicitly grant access to a specific USB device
(similar to Android's USB permission dialog):

```typescript
async requestUsbDevicePermission(device: usbManager.USBDevice): Promise<boolean> {
  const hasPermission = usbManager.hasRight(device.name);
  if (hasPermission) return true;

  return new Promise((resolve) => {
    usbManager.requestRight(device.name).then((granted) => {
      resolve(granted);
    });
  });
}
```

---

# UI State for Borescope Connection

The camera source segmented control should reflect connection state:

| State | "原生后摄" tab | "孔探" tab |
|---|---|---|
| Borescope connected | Selectable | Selectable ✓ |
| Borescope disconnected | Selectable ✓ (default) | Disabled, tooltip: "请连接孔探设备" |
| Connecting (transitioning) | Show spinner | — |

When borescope disconnects during capture:
1. Show modal: "孔探设备已断开，已切换至原生后摄。重新连接后可切回。"
2. Automatically switch camera source to native
3. Do NOT interrupt capture in progress

---

# Borescope Auto-Reconnect

```typescript
private reconnectTimer: number = -1;

onBorescopeDetached(): void {
  this.borescopeConnected = false;
  // Try reconnect for 30 seconds after detach
  this.reconnectTimer = setInterval(() => {
    if (isBorescopeConnected()) {
      clearInterval(this.reconnectTimer);
      this.borescopeConnected = true;
      this.showBanner("孔探设备已重新连接");
    }
  }, 2000);

  // Give up after 30 seconds
  setTimeout(() => clearInterval(this.reconnectTimer), 30000);
}
```

---

# Vendor ID Reference

If you know the borescope model, hardcode vendor/product ID checks:

```typescript
// Example — replace with actual VID/PID of your borescope model
const KNOWN_BORESCOPES: Array<{ vendorId: number; productId: number }> = [
  { vendorId: 0x1234, productId: 0x5678 },  // Model XYZ
];

function isBorescopeDevice(device: usbManager.USBDevice): boolean {
  return KNOWN_BORESCOPES.some(
    b => b.vendorId === device.vendorId && b.productId === device.productId
  );
}
```
