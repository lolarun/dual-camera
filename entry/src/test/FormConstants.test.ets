import { describe, it, expect } from '@ohos/hypium';
import {
  DEVICE_MODELS,
  UNITS,
  PARTS_BY_MODEL,
  PART_AREAS_BY_PART,
  PROJECTS_BY_AREA,
} from '../main/ets/common/constants/FormConstants';

export default function formConstantsTest() {
  describe('FormConstants', () => {

    it('DEVICE_MODELS_has_entries', 0, () => {
      expect(DEVICE_MODELS.length > 0).assertTrue();
    });

    it('UNITS_has_entries', 0, () => {
      expect(UNITS.length > 0).assertTrue();
    });

    it('PARTS_BY_MODEL_has_entry_for_each_device_model', 0, () => {
      for (const model of DEVICE_MODELS) {
        const parts = PARTS_BY_MODEL.get(model);
        expect(parts !== undefined).assertTrue();
        if (parts !== undefined) {
          expect(parts.length > 0).assertTrue();
        }
      }
    });

    it('PART_AREAS_BY_PART_has_entry_for_each_part', 0, () => {
      PARTS_BY_MODEL.forEach((parts: string[]) => {
        for (const part of parts) {
          const areas = PART_AREAS_BY_PART.get(part);
          expect(areas !== undefined).assertTrue();
          if (areas !== undefined) {
            expect(areas.length > 0).assertTrue();
          }
        }
      });
    });

    it('PROJECTS_BY_AREA_has_entry_for_at_least_some_areas', 0, () => {
      let count = 0;
      PROJECTS_BY_AREA.forEach((projects: string[]) => {
        if (projects.length > 0) {
          count++;
        }
      });
      expect(count > 0).assertTrue();
    });

    it('no_device_model_is_empty_string', 0, () => {
      for (const model of DEVICE_MODELS) {
        expect(model.length > 0).assertTrue();
      }
    });

    it('no_unit_is_empty_string', 0, () => {
      for (const unit of UNITS) {
        expect(unit.length > 0).assertTrue();
      }
    });
  });
}
