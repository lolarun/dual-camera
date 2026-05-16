// All data model classes for the inspection photo app.
// ArkTS strict mode: use classes with explicit defaults, no object literals.

export enum CameraSource {
  NATIVE = 'NATIVE',
  BORESCOPE = 'BORESCOPE',
}

export enum TaskStatus {
  DRAFT = 'DRAFT',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
}

export class FormData {
  deviceModel: string = '';
  taskNumber: string = '';
  unit: string = '';
  part: string = '';
  partArea: string = '';
  project: string = '';
  operator: string = '';
  inspector: string = '';
  photographer: string = '';
  photoDate: string = '';  // ISO date "YYYY-MM-DD"
}

export class InspectionTask {
  id: number = 0;
  taskNumber: string = '';
  deviceModel: string = '';
  unit: string = '';
  part: string = '';
  partArea: string = '';
  project: string = '';
  operator: string = '';
  inspector: string = '';
  photographer: string = '';
  photoDate: string = '';
  photoPath: string = '';
  galleryUri: string = '';
  cameraSource: string = CameraSource.NATIVE;
  status: string = TaskStatus.COMPLETED;
  createdAt: string = '';
}

export class PhotoRecord {
  id: number = 0;
  taskNumber: string = '';
  photoPath: string = '';
  galleryUri: string = '';
  cameraSource: string = CameraSource.NATIVE;
  hasPip: boolean = false;
  timestamp: string = '';
  displayTime: string = '';
}

export class TaskQueryParams {
  taskNumber: string = '';
  partFilter: string[] = [];
  cameraSource: string = '';
  startDate: string = '';
  endDate: string = '';
}

export class MonthSummary {
  year: number = 0;
  month: number = 0;
  taskCount: number = 0;
  photoCount: number = 0;
  workDays: number = 0;
}

export class DayTaskSummary {
  date: string = '';
  taskCount: number = 0;
  photoCount: number = 0;
  tasks: InspectionTask[] = [];
}

export class EllipseData {
  centerX: number = 0;
  centerY: number = 0;
  radiusX: number = 0;
  radiusY: number = 0;
  rotation: number = 0;
}

export class CaptureResult {
  backImageBytes: ArrayBuffer = new ArrayBuffer(0);
  frontImageBytes: ArrayBuffer | null = null;
  cameraSource: string = CameraSource.NATIVE;
  timestamp: string = '';
}

export class SaveResult {
  sandboxPath: string = '';
  galleryUri: string = '';
  taskId: number = 0;
}
