import { camera } from '@kit.CameraKit';
import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class CameraService {
  private static instance: CameraService | null = null;
  private cameraManager: camera.CameraManager | null = null;
  private backCameraInput: camera.CameraInput | null = null;
  private previewOutput: camera.PreviewOutput | null = null;
  private photoOutput: camera.PhotoOutput | null = null;
  private session: camera.PhotoSession | null = null;
  private imageReceiver: image.ImageReceiver | null = null;
  private boroscopeConnected: boolean = false;

  private constructor() {}

  static getInstance(): CameraService {
    if (CameraService.instance === null) {
      CameraService.instance = new CameraService();
    }
    return CameraService.instance;
  }

  async initCamera(
    context: common.UIAbilityContext,
    surfaceId: string,
    pipSurfaceId?: string
  ): Promise<void> {
    const mgr = camera.getCameraManager(context);
    this.cameraManager = mgr;

    const devices = mgr.getSupportedCameras();
    const backDevices = devices.filter(
      d => d.cameraPosition === camera.CameraPosition.CAMERA_POSITION_BACK
    );

    if (backDevices.length === 0) {
      throw new Error('CameraService: no back camera found');
    }

    const backDevice = backDevices[0];

    // Create back camera input
    this.backCameraInput = await mgr.createCameraInput(backDevice);
    await this.backCameraInput.open();

    // Preview output
    const backProfiles = mgr.getSupportedOutputCapability(backDevice, camera.SceneMode.NORMAL_PHOTO);
    const previewProfile = backProfiles.previewProfiles[0];
    this.previewOutput = await mgr.createPreviewOutput(previewProfile, surfaceId);

    // Photo output via ImageReceiver
    const imageReceiver = image.createImageReceiver(
      { width: 4096, height: 3072 },
      image.ImageFormat.JPEG,
      3
    );
    this.imageReceiver = imageReceiver;
    const photoSurfaceId = await imageReceiver.getReceivingSurfaceId();
    const photoProfile = backProfiles.photoProfiles[0];
    this.photoOutput = await mgr.createPhotoOutput(photoProfile, photoSurfaceId);

    // Create NORMAL_PHOTO session
    const session = await mgr.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
    this.session = session;

    await session.beginConfig();
    await session.addInput(this.backCameraInput);
    await session.addOutput(this.previewOutput);
    await session.addOutput(this.photoOutput);
    await session.commitConfig();
    await session.start();
  }

  capture(): Promise<ArrayBuffer> {
    return new Promise<ArrayBuffer>((resolve, reject) => {
      if (this.imageReceiver === null || this.photoOutput === null) {
        reject(new Error('CameraService: not initialized'));
        return;
      }

      const receiver = this.imageReceiver;

      receiver.on('imageArrival', async () => {
        try {
          const img = await receiver.readNextImage();
          const component = await img.getComponent(image.ComponentType.JPEG);
          const buffer: ArrayBuffer = component.byteBuffer!;
          await img.release();
          resolve(buffer);
        } catch (err) {
          reject(err);
        }
      });

      const captureSettings: camera.PhotoCaptureSetting = {
        quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,
        rotation: camera.ImageRotation.ROTATION_0,
      };
      this.photoOutput!.capture(captureSettings).catch((err: BusinessError) => {
        reject(err);
      });
    });
  }

  async release(): Promise<void> {
    try {
      if (this.session !== null) {
        await this.session.stop();
        await this.session.release();
        this.session = null;
      }
      if (this.backCameraInput !== null) {
        await this.backCameraInput.close();
        this.backCameraInput = null;
      }
      if (this.previewOutput !== null) {
        await this.previewOutput.release();
        this.previewOutput = null;
      }
      if (this.photoOutput !== null) {
        await this.photoOutput.release();
        this.photoOutput = null;
      }
      if (this.imageReceiver !== null) {
        this.imageReceiver.release();
        this.imageReceiver = null;
      }
    } catch (err) {
      const e = err as BusinessError;
      console.error(`CameraService.release error: ${e.message}`);
    }
  }

  isDualCameraSupported(): boolean {
    return false;
  }

  isBoroscopeConnected(): boolean {
    return this.boroscopeConnected;
  }

  setBoroscopeConnected(connected: boolean): void {
    this.boroscopeConnected = connected;
  }
}
