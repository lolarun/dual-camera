import { describe, it, expect } from '@ohos/hypium';
import {
  FormData,
  InspectionTask,
  PhotoRecord,
  CameraSource,
  TaskStatus,
  EllipseData,
  TaskQueryParams,
} from '../main/ets/common/types/InspectionTypes';

export default function inspectionTypesTest() {
  describe('InspectionTypes', () => {

    it('FormData_instantiates_with_empty_defaults', 0, () => {
      const f = new FormData();
      expect(f.deviceModel).assertEqual('');
      expect(f.taskNumber).assertEqual('');
      expect(f.unit).assertEqual('');
      expect(f.part).assertEqual('');
      expect(f.partArea).assertEqual('');
      expect(f.project).assertEqual('');
      expect(f.operator).assertEqual('');
      expect(f.inspector).assertEqual('');
      expect(f.photographer).assertEqual('');
      expect(f.photoDate).assertEqual('');
    });

    it('FormData_fields_are_assignable', 0, () => {
      const f = new FormData();
      f.taskNumber = 'A12345';
      f.photographer = '张三';
      expect(f.taskNumber).assertEqual('A12345');
      expect(f.photographer).assertEqual('张三');
    });

    it('InspectionTask_instantiates_with_defaults', 0, () => {
      const t = new InspectionTask();
      expect(t.id).assertEqual(0);
      expect(t.taskNumber).assertEqual('');
      expect(t.cameraSource).assertEqual(CameraSource.NATIVE);
      expect(t.status).assertEqual(TaskStatus.COMPLETED);
    });

    it('PhotoRecord_instantiates_with_defaults', 0, () => {
      const p = new PhotoRecord();
      expect(p.id).assertEqual(0);
      expect(p.hasPip).assertFalse();
      expect(p.cameraSource).assertEqual(CameraSource.NATIVE);
    });

    it('CameraSource_enum_values_are_strings', 0, () => {
      expect(CameraSource.NATIVE).assertEqual('NATIVE');
      expect(CameraSource.BORESCOPE).assertEqual('BORESCOPE');
    });

    it('TaskStatus_enum_values_are_strings', 0, () => {
      expect(TaskStatus.DRAFT).assertEqual('DRAFT');
      expect(TaskStatus.IN_PROGRESS).assertEqual('IN_PROGRESS');
      expect(TaskStatus.COMPLETED).assertEqual('COMPLETED');
    });

    it('EllipseData_instantiates_with_zero_defaults', 0, () => {
      const e = new EllipseData();
      expect(e.centerX).assertEqual(0);
      expect(e.centerY).assertEqual(0);
      expect(e.radiusX).assertEqual(0);
      expect(e.radiusY).assertEqual(0);
      expect(e.rotation).assertEqual(0);
    });

    it('TaskQueryParams_instantiates_with_empty_defaults', 0, () => {
      const q = new TaskQueryParams();
      expect(q.taskNumber).assertEqual('');
      expect(q.cameraSource).assertEqual('');
      expect(q.partFilter.length).assertEqual(0);
    });
  });
}
