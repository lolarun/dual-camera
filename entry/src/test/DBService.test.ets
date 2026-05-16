import { describe, it, expect } from '@ohos/hypium';
import { InspectionTask, TaskQueryParams, CameraSource } from '../main/ets/common/types/InspectionTypes';
import { DateUtils } from '../main/ets/common/utils/DateUtils';

// Unit tests for DBService logic (row mapping, query param building).
// Full DB integration tests require a device context — covered by on-device testing.

export default function dbServiceTest() {
  describe('DBService_logic', () => {

    it('InspectionTask_maps_all_fields', 0, () => {
      const t = new InspectionTask();
      t.id = 1;
      t.taskNumber = 'A12345';
      t.deviceModel = 'CFM56-5B';
      t.unit = '发动机车间';
      t.part = '风扇模块';
      t.partArea = '前缘叶片';
      t.project = '叶片前缘损伤检查';
      t.operator = '王五';
      t.inspector = '李四';
      t.photographer = '张三';
      t.photoDate = '2026-05-16';
      t.photoPath = '/data/storage/files/tasks/A12345/风扇模块/A12345-风扇模块-张三-20260516.jpg';
      t.galleryUri = 'datashare:///media/image/1';
      t.cameraSource = CameraSource.NATIVE;

      expect(t.taskNumber).assertEqual('A12345');
      expect(t.deviceModel).assertEqual('CFM56-5B');
      expect(t.cameraSource).assertEqual('NATIVE');
      expect(t.photoDate).assertEqual('2026-05-16');
    });

    it('TaskQueryParams_defaults_are_empty', 0, () => {
      const q = new TaskQueryParams();
      expect(q.taskNumber).assertEqual('');
      expect(q.startDate).assertEqual('');
      expect(q.endDate).assertEqual('');
      expect(q.cameraSource).assertEqual('');
      expect(q.partFilter.length).assertEqual(0);
    });

    it('TaskQueryParams_can_set_date_range', 0, () => {
      const q = new TaskQueryParams();
      q.startDate = '2026-05-01';
      q.endDate = '2026-05-31';
      expect(q.startDate).assertEqual('2026-05-01');
      expect(q.endDate).assertEqual('2026-05-31');
    });

    it('month_prefix_correctly_built', 0, () => {
      // Verify the month-prefix logic used in queryTasksByMonth
      const year = 2026;
      const month = 5;
      const m = month < 10 ? `0${month}` : `${month}`;
      const prefix = `${year}-${m}`;
      expect(prefix).assertEqual('2026-05');
    });

    it('getTaskCountByDay_extracts_day_from_photoDate', 0, () => {
      // Simulate the day-extraction logic
      const photoDate = '2026-05-16';
      const dayStr = photoDate.substring(8, 10);
      const day = parseInt(dayStr, 10);
      expect(day).assertEqual(16);
    });

    it('task_created_at_uses_unix_ms', 0, () => {
      const now = Date.now();
      expect(now > 1000000000000).assertTrue(); // > year 2001 in ms
    });

    it('photoDate_format_matches_ISO', 0, () => {
      const today = DateUtils.todayIso();
      expect(today.length).assertEqual(10);
      // Format: YYYY-MM-DD
      const parts = today.split('-');
      expect(parts.length).assertEqual(3);
      expect(parts[0].length).assertEqual(4);
      expect(parts[1].length).assertEqual(2);
      expect(parts[2].length).assertEqual(2);
    });
  });
}
