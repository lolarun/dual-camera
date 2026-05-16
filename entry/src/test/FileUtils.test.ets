import { describe, it, expect } from '@ohos/hypium';
import { FileUtils } from '../main/ets/common/utils/FileUtils';

export default function fileUtilsTest() {
  describe('FileUtils', () => {

    // Task number validation
    it('validateTaskNumber_valid_A12345', 0, () => {
      expect(FileUtils.validateTaskNumber('A12345')).assertTrue();
    });

    it('validateTaskNumber_valid_B123456', 0, () => {
      expect(FileUtils.validateTaskNumber('B123456')).assertTrue();
    });

    it('validateTaskNumber_invalid_too_short', 0, () => {
      expect(FileUtils.validateTaskNumber('A1234')).assertFalse();
    });

    it('validateTaskNumber_invalid_too_long', 0, () => {
      expect(FileUtils.validateTaskNumber('A1234567')).assertFalse();
    });

    it('validateTaskNumber_invalid_lowercase_letter', 0, () => {
      expect(FileUtils.validateTaskNumber('a12345')).assertFalse();
    });

    it('validateTaskNumber_invalid_no_letter', 0, () => {
      expect(FileUtils.validateTaskNumber('123456')).assertFalse();
    });

    it('validateTaskNumber_invalid_empty', 0, () => {
      expect(FileUtils.validateTaskNumber('')).assertFalse();
    });

    it('validateTaskNumber_invalid_special_chars', 0, () => {
      expect(FileUtils.validateTaskNumber('A-1234')).assertFalse();
    });

    // Filename building
    it('buildFilename_correct_format', 0, () => {
      const d = new Date(2026, 4, 16); // 2026-05-16
      const result = FileUtils.buildFilename('A12345', '风扇模块', '张三', d);
      expect(result).assertEqual('A12345-风扇模块-张三-20260516.jpg');
    });

    it('buildFilename_strips_spaces_from_photographer', 0, () => {
      const d = new Date(2026, 4, 16);
      const result = FileUtils.buildFilename('A12345', '风扇模块', '张 三', d);
      expect(result).assertContain('张三');
    });

    // Album name
    it('buildAlbumName_correct_format', 0, () => {
      expect(FileUtils.buildAlbumName('A12345')).assertEqual('巡检任务-A12345');
    });

    // Sandbox path
    it('buildSandboxPath_contains_task_and_part', 0, () => {
      const d = new Date(2026, 4, 16);
      const result = FileUtils.buildSandboxPath('/data/storage/files', 'A12345', '风扇模块', '张三', d);
      expect(result).assertContain('A12345');
      expect(result).assertContain('风扇模块');
      expect(result).assertContain('.jpg');
    });

    it('buildSandboxPath_starts_with_filesDir', 0, () => {
      const d = new Date(2026, 4, 16);
      const result = FileUtils.buildSandboxPath('/data/storage/files', 'A12345', '风扇模块', '张三', d);
      expect(result.startsWith('/data/storage/files/tasks/')).assertTrue();
    });

    // Helpers
    it('getFilename_extracts_from_path', 0, () => {
      expect(FileUtils.getFilename('/data/tasks/A12345/A12345-部位-张三-20260516.jpg'))
        .assertEqual('A12345-部位-张三-20260516.jpg');
    });

    it('getExtension_returns_jpg', 0, () => {
      expect(FileUtils.getExtension('photo.jpg')).assertEqual('jpg');
    });

    it('getExtension_empty_for_no_extension', 0, () => {
      expect(FileUtils.getExtension('photofile')).assertEqual('');
    });
  });
}
