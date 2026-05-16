---
name: harmony-storage
description: Local data persistence for HarmonyOS — SQLite via RelationalStore, key-value via Preferences, schema migration, singleton DB service. Trigger phrases: "database", "SQLite", "local storage", "persist data", "save task", "query records", "Preferences", "RelationalStore", "RDB", "store data locally".
---

# When to Use This Skill

Example trigger prompts:
- "Save the inspection task to the local database"
- "Query all tasks from the past 30 days"
- "Store the current user setting (last inspector name)"
- "Add a new column to the existing schema"
- "Initialize the database on app launch"

---

# Import

```typescript
import { relationalStore } from "@kit.ArkData";
import { preferences } from "@kit.ArkData";
import { common } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";
```

---

# RelationalStore (SQLite) — Structured Data

## Database Configuration

```typescript
const DB_CONFIG: relationalStore.StoreConfig = {
  name: "inspection.db",          // filename under context.databaseDir
  securityLevel: relationalStore.SecurityLevel.S1,
  encrypt: false,                 // set true if PII data
};
```

## Singleton DBService Pattern

**Never call `getRdbStore` on every query — open once, reuse everywhere.**

```typescript
class DBService {
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
    if (this.store !== null) return;  // already initialized
    this.store = await relationalStore.getRdbStore(context, DB_CONFIG);
    await this.createTables();
  }

  private async createTables(): Promise<void> {
    const sql = `
      CREATE TABLE IF NOT EXISTS inspection_task (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        task_number    TEXT NOT NULL,
        device_model   TEXT NOT NULL,
        unit           TEXT NOT NULL,
        part           TEXT NOT NULL,
        part_area      TEXT NOT NULL DEFAULT '',
        project        TEXT NOT NULL DEFAULT '',
        operator       TEXT NOT NULL,
        inspector      TEXT NOT NULL,
        photographer   TEXT NOT NULL,
        photo_date     TEXT NOT NULL,
        photo_path     TEXT NOT NULL DEFAULT '',
        gallery_uri    TEXT NOT NULL DEFAULT '',
        created_at     INTEGER NOT NULL
      )
    `;
    await this.store!.executeSql(sql);
  }

  async insertTask(task: InspectionTaskRecord): Promise<number> {
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
      created_at:    Date.now(),
    };
    const rowId = await this.store!.insert("inspection_task", bucket);
    return rowId;
  }

  async queryByDateRange(
    startMs: number,
    endMs: number
  ): Promise<InspectionTaskRecord[]> {
    const predicates = new relationalStore.RdbPredicates("inspection_task");
    predicates
      .greaterThanOrEqualTo("created_at", startMs)
      .and()
      .lessThanOrEqualTo("created_at", endMs)
      .orderByDesc("created_at");

    const cursor = await this.store!.query(predicates, [
      "id", "task_number", "device_model", "unit", "part",
      "part_area", "project", "operator", "inspector",
      "photographer", "photo_date", "photo_path", "gallery_uri", "created_at"
    ]);

    const records: InspectionTaskRecord[] = [];
    while (cursor.goToNextRow()) {
      records.push(this.cursorToRecord(cursor));
    }
    cursor.close();
    return records;
  }

  private cursorToRecord(
    cursor: relationalStore.ResultSet
  ): InspectionTaskRecord {
    const r = new InspectionTaskRecord();
    r.id           = cursor.getLong(cursor.getColumnIndex("id"));
    r.taskNumber   = cursor.getString(cursor.getColumnIndex("task_number"));
    r.deviceModel  = cursor.getString(cursor.getColumnIndex("device_model"));
    r.unit         = cursor.getString(cursor.getColumnIndex("unit"));
    r.part         = cursor.getString(cursor.getColumnIndex("part"));
    r.partArea     = cursor.getString(cursor.getColumnIndex("part_area"));
    r.project      = cursor.getString(cursor.getColumnIndex("project"));
    r.operator     = cursor.getString(cursor.getColumnIndex("operator"));
    r.inspector    = cursor.getString(cursor.getColumnIndex("inspector"));
    r.photographer = cursor.getString(cursor.getColumnIndex("photographer"));
    r.photoDate    = cursor.getString(cursor.getColumnIndex("photo_date"));
    r.photoPath    = cursor.getString(cursor.getColumnIndex("photo_path"));
    r.galleryUri   = cursor.getString(cursor.getColumnIndex("gallery_uri"));
    r.createdAt    = cursor.getLong(cursor.getColumnIndex("created_at"));
    return r;
  }
}
```

---

# Schema Migration

Handle via `onUpgrade` in StoreConfig:

```typescript
const DB_CONFIG: relationalStore.StoreConfig = {
  name: "inspection.db",
  securityLevel: relationalStore.SecurityLevel.S1,
  // Version bump triggers onUpgrade
};

// In getRdbStore callback — check version manually
async checkAndMigrate(store: relationalStore.RdbStore): Promise<void> {
  const versionResult = await store.querySql("PRAGMA user_version");
  versionResult.goToNextRow();
  const version = versionResult.getLong(0);
  versionResult.close();

  if (version < 2) {
    await store.executeSql(
      "ALTER TABLE inspection_task ADD COLUMN notes TEXT NOT NULL DEFAULT ''"
    );
    await store.executeSql("PRAGMA user_version = 2");
  }
}
```

---

# Preferences — Key-Value Settings

Use Preferences for lightweight settings (last user, toggle states, etc.).
Do NOT use for structured records — use RelationalStore for those.

```typescript
const PREFS_NAME = "app_settings";

class AppPreferences {
  private prefs: preferences.Preferences | null = null;

  async init(context: common.UIAbilityContext): Promise<void> {
    this.prefs = await preferences.getPreferences(context, PREFS_NAME);
  }

  async setLastPhotographer(name: string): Promise<void> {
    await this.prefs!.put("last_photographer", name);
    await this.prefs!.flush();
  }

  async getLastPhotographer(): Promise<string> {
    return (await this.prefs!.get("last_photographer", "")) as string;
  }

  async setLastInspector(name: string): Promise<void> {
    await this.prefs!.put("last_inspector", name);
    await this.prefs!.flush();
  }

  async getLastInspector(): Promise<string> {
    return (await this.prefs!.get("last_inspector", "")) as string;
  }
}
```

---

# Initialization in UIAbility

```typescript
// EntryAbility.ets
import { UIAbility } from "@kit.AbilityKit";

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    // Initialize DB and Preferences before any page loads
    await DBService.getInstance().init(this.context);
    await AppPreferences.getInstance().init(this.context);
  }
}
```

---

# Data Model Classes

```typescript
class InspectionTaskRecord {
  id: number = 0;
  taskNumber: string = "";
  deviceModel: string = "";
  unit: string = "";
  part: string = "";
  partArea: string = "";
  project: string = "";
  operator: string = "";
  inspector: string = "";
  photographer: string = "";
  photoDate: string = "";
  photoPath: string = "";   // sandbox path for hierarchical access
  galleryUri: string = "";  // system gallery URI
  createdAt: number = 0;    // Unix ms
}
```

---

# Sandbox File Paths

```typescript
// App-private hierarchical storage (NOT visible in gallery)
const baseDir = context.filesDir;
// e.g. /data/storage/el2/base/files/

// Recommended hierarchy for this project:
// context.filesDir/tasks/{taskNumber}/{part}/{filename}.jpg
function getPhotoSandboxPath(
  context: common.UIAbilityContext,
  taskNumber: string,
  part: string,
  filename: string
): string {
  return `${context.filesDir}/tasks/${taskNumber}/${part}/${filename}`;
}
```

Always create parent directories before writing:

```typescript
import { fs } from "@kit.CoreFileKit";
await fs.mkdir(parentDir, true);  // true = recursive
```
