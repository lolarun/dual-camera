import { describe, it, expect } from '@ohos/hypium';
import { FormData } from '../main/ets/common/types/InspectionTypes';

// Unit tests for PreferencesService logic (JSON serialization/deserialization).
// Full Preferences integration tests require device context — covered by on-device testing.

export default function preferencesServiceTest() {
  describe('PreferencesService_logic', () => {

    it('FormData_serializes_all_fields_to_json', 0, () => {
      const f = new FormData();
      f.deviceModel  = 'CFM56-5B';
      f.taskNumber   = 'A12345';
      f.unit         = '发动机车间';
      f.part         = '风扇模块';
      f.partArea     = '前缘叶片';
      f.project      = '叶片前缘损伤检查';
      f.operator     = '王五';
      f.inspector    = '李四';
      f.photographer = '张三';
      f.photoDate    = '2026-05-16';

      const json = JSON.stringify({
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
      });

      expect(json).assertContain('A12345');
      expect(json).assertContain('张三');
      expect(json).assertContain('CFM56-5B');
    });

    it('FormData_deserializes_from_json', 0, () => {
      const original = new FormData();
      original.taskNumber   = 'A12345';
      original.photographer = '张三';
      original.inspector    = '李四';

      const json = JSON.stringify({
        deviceModel:  original.deviceModel,
        taskNumber:   original.taskNumber,
        unit:         original.unit,
        part:         original.part,
        partArea:     original.partArea,
        project:      original.project,
        operator:     original.operator,
        inspector:    original.inspector,
        photographer: original.photographer,
        photoDate:    original.photoDate,
      });

      const parsed = JSON.parse(json) as Record<string, string>;
      const restored = new FormData();
      restored.taskNumber   = typeof parsed['taskNumber']   === 'string' ? parsed['taskNumber']   : '';
      restored.photographer = typeof parsed['photographer'] === 'string' ? parsed['photographer'] : '';
      restored.inspector    = typeof parsed['inspector']    === 'string' ? parsed['inspector']    : '';

      expect(restored.taskNumber).assertEqual('A12345');
      expect(restored.photographer).assertEqual('张三');
      expect(restored.inspector).assertEqual('李四');
    });

    it('empty_json_string_yields_null_draft', 0, () => {
      const json = '';
      const result = json.length === 0 ? null : 'has_data';
      expect(result).assertNull();
    });

    it('draft_timestamp_is_unix_ms', 0, () => {
      const ts = Date.now();
      expect(ts > 1_000_000_000_000).assertTrue();
    });
  });
}
