import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { FormData } from '../common/types/InspectionTypes';

const PREFS_NAME = 'app_settings';

const KEY_LAST_INSPECTOR = 'last_inspector';
const KEY_LAST_PHOTOGRAPHER = 'last_photographer';
const KEY_FORM_DRAFT = 'form_draft_json';
const KEY_DRAFT_TIMESTAMP = 'draft_timestamp';

export class PreferencesService {
  private static instance: PreferencesService | null = null;
  private prefs: preferences.Preferences | null = null;

  private constructor() {}

  static getInstance(): PreferencesService {
    if (PreferencesService.instance === null) {
      PreferencesService.instance = new PreferencesService();
    }
    return PreferencesService.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.prefs !== null) {
      return;
    }
    try {
      this.prefs = await preferences.getPreferences(context, PREFS_NAME);
    } catch (err) {
      const e = err as BusinessError;
      console.error(`PreferencesService.init failed: ${e.code} ${e.message}`);
      throw new Error(`PreferencesService.init failed: ${e.code} ${e.message}`);
    }
  }

  async getLastInspector(): Promise<string> {
    const val = await this.prefs!.get(KEY_LAST_INSPECTOR, '');
    return val as string;
  }

  async setLastInspector(name: string): Promise<void> {
    await this.prefs!.put(KEY_LAST_INSPECTOR, name);
    await this.prefs!.flush();
  }

  async getLastPhotographer(): Promise<string> {
    const val = await this.prefs!.get(KEY_LAST_PHOTOGRAPHER, '');
    return val as string;
  }

  async setLastPhotographer(name: string): Promise<void> {
    await this.prefs!.put(KEY_LAST_PHOTOGRAPHER, name);
    await this.prefs!.flush();
  }

  async saveDraft(formData: FormData): Promise<void> {
    const json = JSON.stringify({
      deviceModel:  formData.deviceModel,
      taskNumber:   formData.taskNumber,
      unit:         formData.unit,
      part:         formData.part,
      partArea:     formData.partArea,
      project:      formData.project,
      operator:     formData.operator,
      inspector:    formData.inspector,
      photographer: formData.photographer,
      photoDate:    formData.photoDate,
    });
    await this.prefs!.put(KEY_FORM_DRAFT, json);
    await this.prefs!.put(KEY_DRAFT_TIMESTAMP, Date.now());
    await this.prefs!.flush();
  }

  async loadDraft(): Promise<FormData | null> {
    const raw = await this.prefs!.get(KEY_FORM_DRAFT, '');
    const json = raw as string;
    if (json.length === 0) {
      return null;
    }
    try {
      const parsed = JSON.parse(json) as Record<string, string>;
      const f = new FormData();
      f.deviceModel  = typeof parsed['deviceModel']  === 'string' ? parsed['deviceModel']  : '';
      f.taskNumber   = typeof parsed['taskNumber']   === 'string' ? parsed['taskNumber']   : '';
      f.unit         = typeof parsed['unit']         === 'string' ? parsed['unit']         : '';
      f.part         = typeof parsed['part']         === 'string' ? parsed['part']         : '';
      f.partArea     = typeof parsed['partArea']     === 'string' ? parsed['partArea']     : '';
      f.project      = typeof parsed['project']      === 'string' ? parsed['project']      : '';
      f.operator     = typeof parsed['operator']     === 'string' ? parsed['operator']     : '';
      f.inspector    = typeof parsed['inspector']    === 'string' ? parsed['inspector']    : '';
      f.photographer = typeof parsed['photographer'] === 'string' ? parsed['photographer'] : '';
      f.photoDate    = typeof parsed['photoDate']    === 'string' ? parsed['photoDate']    : '';
      return f;
    } catch (err) {
      console.error('PreferencesService.loadDraft parse error');
      return null;
    }
  }

  async clearDraft(): Promise<void> {
    await this.prefs!.delete(KEY_FORM_DRAFT);
    await this.prefs!.delete(KEY_DRAFT_TIMESTAMP);
    await this.prefs!.flush();
  }

  async getDraftTimestamp(): Promise<number> {
    const val = await this.prefs!.get(KEY_DRAFT_TIMESTAMP, 0);
    return val as number;
  }
}
