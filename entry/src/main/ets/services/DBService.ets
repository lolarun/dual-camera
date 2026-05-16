import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { InspectionTask, TaskQueryParams, MonthSummary, DayTaskSummary } from '../common/types/InspectionTypes';

const DB_CONFIG: relationalStore.StoreConfig = {
  name: 'inspection.db',
  securityLevel: relationalStore.SecurityLevel.S1,
  encrypt: false,
};

const DB_VERSION = 1;

const ALL_COLUMNS: string[] = [
  'id', 'task_number', 'device_model', 'unit', 'part', 'part_area',
  'project', 'operator', 'inspector', 'photographer', 'photo_date',
  'photo_path', 'gallery_uri', 'camera_source', 'status', 'created_at',
];

export class DBService {
  private static instance: DBService | null = null;
  private store: relationalStore.RdbStore | null = null;

  private constructor() {}

  static getInstance(): DBService {
    if (DBService.instance === null) {
      DBService.instance = new DBService();
    }
    return DBService.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.store !== null) {
      return;
    }
    try {
      this.store = await relationalStore.getRdbStore(context, DB_CONFIG);
      await this.createTables();
      await this.checkAndMigrate();
    } catch (err) {
      const e = err as BusinessError;
      console.error(`DBService.init failed: ${e.code} ${e.message}`);
      throw new Error(`DBService.init failed: ${e.code} ${e.message}`);
    }
  }

  private async createTables(): Promise<void> {
    const sql = `
      CREATE TABLE IF NOT EXISTS inspection_task (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        task_number   TEXT    NOT NULL,
        device_model  TEXT    NOT NULL DEFAULT '',
        unit          TEXT    NOT NULL DEFAULT '',
        part          TEXT    NOT NULL DEFAULT '',
        part_area     TEXT    NOT NULL DEFAULT '',
        project       TEXT    NOT NULL DEFAULT '',
        operator      TEXT    NOT NULL DEFAULT '',
        inspector     TEXT    NOT NULL DEFAULT '',
        photographer  TEXT    NOT NULL DEFAULT '',
        photo_date    TEXT    NOT NULL DEFAULT '',
        photo_path    TEXT    NOT NULL DEFAULT '',
        gallery_uri   TEXT    NOT NULL DEFAULT '',
        camera_source TEXT    NOT NULL DEFAULT 'NATIVE',
        status        TEXT    NOT NULL DEFAULT 'COMPLETED',
        created_at    INTEGER NOT NULL DEFAULT 0
      )
    `;
    await this.store!.executeSql(sql);
  }

  private async checkAndMigrate(): Promise<void> {
    const cursor = await this.store!.querySql('PRAGMA user_version');
    cursor.goToNextRow();
    const version = cursor.getLong(0);
    cursor.close();
    if (version < DB_VERSION) {
      await this.store!.executeSql(`PRAGMA user_version = ${DB_VERSION}`);
    }
  }

  async insertTask(task: InspectionTask): Promise<number> {
    const bucket: relationalStore.ValuesBucket = {
      task_number:   task.taskNumber,
      device_model:  task.deviceModel,
      unit:          task.unit,
      part:          task.part,
      part_area:     task.partArea,
      project:       task.project,
      operator:      task.operator,
      inspector:     task.inspector,
      photographer:  task.photographer,
      photo_date:    task.photoDate,
      photo_path:    task.photoPath,
      gallery_uri:   task.galleryUri,
      camera_source: task.cameraSource,
      status:        task.status,
      created_at:    Date.now(),
    };
    const rowId = await this.store!.insert('inspection_task', bucket);
    return rowId;
  }

  async queryTasks(params?: TaskQueryParams): Promise<InspectionTask[]> {
    const predicates = new relationalStore.RdbPredicates('inspection_task');
    if (params !== undefined) {
      if (params.taskNumber.length > 0) {
        predicates.like('task_number', `%${params.taskNumber}%`);
      }
      if (params.startDate.length > 0) {
        predicates.and().greaterThanOrEqualTo('photo_date', params.startDate);
      }
      if (params.endDate.length > 0) {
        predicates.and().lessThanOrEqualTo('photo_date', params.endDate);
      }
      if (params.cameraSource.length > 0) {
        predicates.and().equalTo('camera_source', params.cameraSource);
      }
      if (params.partFilter.length > 0) {
        predicates.and().in('part', params.partFilter);
      }
    }
    predicates.orderByDesc('created_at');
    return this.runQuery(predicates);
  }

  async queryTasksByDate(isoDate: string): Promise<InspectionTask[]> {
    const predicates = new relationalStore.RdbPredicates('inspection_task');
    predicates.equalTo('photo_date', isoDate).orderByAsc('created_at');
    return this.runQuery(predicates);
  }

  async queryTasksByMonth(year: number, month: number): Promise<InspectionTask[]> {
    const m = month < 10 ? `0${month}` : `${month}`;
    const prefix = `${year}-${m}`;
    const predicates = new relationalStore.RdbPredicates('inspection_task');
    predicates.like('photo_date', `${prefix}%`).orderByAsc('photo_date');
    return this.runQuery(predicates);
  }

  async getTaskById(id: number): Promise<InspectionTask | null> {
    const predicates = new relationalStore.RdbPredicates('inspection_task');
    predicates.equalTo('id', id);
    const results = await this.runQuery(predicates);
    return results.length > 0 ? results[0] : null;
  }

  async deleteTask(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('inspection_task');
    predicates.equalTo('id', id);
    await this.store!.delete(predicates);
  }

  async deleteTasks(ids: number[]): Promise<void> {
    if (ids.length === 0) {
      return;
    }
    const strIds: string[] = ids.map((id: number) => id.toString());
    const predicates = new relationalStore.RdbPredicates('inspection_task');
    predicates.in('id', strIds);
    await this.store!.delete(predicates);
  }

  // Returns map of day (1-31) → task count, for calendar badge rendering
  async getTaskCountByDay(year: number, month: number): Promise<Map<number, number>> {
    const tasks = await this.queryTasksByMonth(year, month);
    const counts = new Map<number, number>();
    for (const task of tasks) {
      if (task.photoDate.length >= 10) {
        const dayStr = task.photoDate.substring(8, 10);
        const day = parseInt(dayStr, 10);
        const current = counts.get(day);
        counts.set(day, current !== undefined ? current + 1 : 1);
      }
    }
    return counts;
  }

  async getMonthSummary(year: number, month: number): Promise<MonthSummary> {
    const tasks = await this.queryTasksByMonth(year, month);
    const summary = new MonthSummary();
    summary.year = year;
    summary.month = month;
    summary.taskCount = tasks.length;
    summary.photoCount = tasks.length; // 1 photo per task record currently
    const workDaysSet = new Set<string>();
    for (const task of tasks) {
      if (task.photoDate.length >= 10) {
        workDaysSet.add(task.photoDate.substring(0, 10));
      }
    }
    summary.workDays = workDaysSet.size;
    return summary;
  }

  async getDayTaskSummary(isoDate: string): Promise<DayTaskSummary> {
    const tasks = await this.queryTasksByDate(isoDate);
    const summary = new DayTaskSummary();
    summary.date = isoDate;
    summary.tasks = tasks;
    summary.taskCount = tasks.length;
    summary.photoCount = tasks.length;
    return summary;
  }

  private async runQuery(predicates: relationalStore.RdbPredicates): Promise<InspectionTask[]> {
    const cursor = await this.store!.query(predicates, ALL_COLUMNS);
    const records: InspectionTask[] = [];
    while (cursor.goToNextRow()) {
      records.push(this.cursorToTask(cursor));
    }
    cursor.close();
    return records;
  }

  private cursorToTask(cursor: relationalStore.ResultSet): InspectionTask {
    const t = new InspectionTask();
    t.id           = cursor.getLong(cursor.getColumnIndex('id'));
    t.taskNumber   = cursor.getString(cursor.getColumnIndex('task_number'));
    t.deviceModel  = cursor.getString(cursor.getColumnIndex('device_model'));
    t.unit         = cursor.getString(cursor.getColumnIndex('unit'));
    t.part         = cursor.getString(cursor.getColumnIndex('part'));
    t.partArea     = cursor.getString(cursor.getColumnIndex('part_area'));
    t.project      = cursor.getString(cursor.getColumnIndex('project'));
    t.operator     = cursor.getString(cursor.getColumnIndex('operator'));
    t.inspector    = cursor.getString(cursor.getColumnIndex('inspector'));
    t.photographer = cursor.getString(cursor.getColumnIndex('photographer'));
    t.photoDate    = cursor.getString(cursor.getColumnIndex('photo_date'));
    t.photoPath    = cursor.getString(cursor.getColumnIndex('photo_path'));
    t.galleryUri   = cursor.getString(cursor.getColumnIndex('gallery_uri'));
    t.cameraSource = cursor.getString(cursor.getColumnIndex('camera_source'));
    t.status       = cursor.getString(cursor.getColumnIndex('status'));
    t.createdAt    = cursor.getLong(cursor.getColumnIndex('created_at')).toString();
    return t;
  }
}
