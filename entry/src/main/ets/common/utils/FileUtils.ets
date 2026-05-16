// File path building and task number validation utilities.

import { DateUtils } from './DateUtils';

export class FileUtils {
  // Task number format: one uppercase letter followed by 4-6 digits
  static validateTaskNumber(input: string): boolean {
    const pattern = /^[A-Z]\d{4,6}$/;
    return pattern.test(input);
  }

  // Builds the JPEG filename: {taskNumber}-{part}-{photographer}-{YYYYMMDD}.jpg
  static buildFilename(taskNumber: string, part: string, photographer: string, date: Date): string {
    const datePart = DateUtils.formatCompact(date);
    const safePart = part.replace(/\//g, '-').replace(/\s/g, '');
    const safePhotographer = photographer.replace(/\s/g, '');
    return `${taskNumber}-${safePart}-${safePhotographer}-${datePart}.jpg`;
  }

  // Builds the sandbox directory path for a task
  static buildSandboxDir(filesDir: string, taskNumber: string, part: string): string {
    const safePart = part.replace(/\//g, '-').replace(/\s/g, '');
    return `${filesDir}/tasks/${taskNumber}/${safePart}`;
  }

  // Builds the full sandbox file path
  static buildSandboxPath(filesDir: string, taskNumber: string, part: string, photographer: string, date: Date): string {
    const dir = FileUtils.buildSandboxDir(filesDir, taskNumber, part);
    const filename = FileUtils.buildFilename(taskNumber, part, photographer, date);
    return `${dir}/${filename}`;
  }

  // Builds the gallery album name
  static buildAlbumName(taskNumber: string): string {
    return `巡检任务-${taskNumber}`;
  }

  // Extracts filename from full path
  static getFilename(path: string): string {
    const idx = path.lastIndexOf('/');
    return idx >= 0 ? path.substring(idx + 1) : path;
  }

  // Extracts extension from filename (without dot)
  static getExtension(filename: string): string {
    const idx = filename.lastIndexOf('.');
    return idx >= 0 ? filename.substring(idx + 1).toLowerCase() : '';
  }
}
