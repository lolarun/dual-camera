---
name: harmony-media-library
description: Saving photos to system gallery, creating user albums, querying existing photos using PhotoAccessHelper. Trigger phrases: "save to album", "save to gallery", "PhotoAccessHelper", "user album", "photo library", "query photos", "export photos", "mediaLibrary".
---

# When to Use This Skill

Example trigger prompts:
- "Save the watermarked photo to the gallery"
- "Create a folder for task A12345 in the album"
- "Query all photos saved today"
- "Export selected photos as a batch"

---

# IMPORTANT: Use PhotoAccessHelper, Not mediaLibrary

`@ohos.multimedia.mediaLibrary` is **deprecated** in HarmonyOS Next.
Always use `@kit.MediaLibraryKit` (PhotoAccessHelper).

```typescript
import { photoAccessHelper } from "@kit.MediaLibraryKit";
```

---

# Required Permissions

Declare in `module.json5`:

```json5
"requestPermissions": [
  { "name": "ohos.permission.READ_IMAGEVIDEO" },
  { "name": "ohos.permission.WRITE_IMAGEVIDEO" }
]
```

**Note:** Both are **restricted permissions** for App Store distribution.
For internal/enterprise sideloaded apps (which this project is), they work
without special application. The user will still see a runtime permission
dialog.

Request at runtime:

```typescript
import { abilityAccessCtrl, Permissions } from "@kit.AbilityKit";

async requestPhotoPermissions(context: common.UIAbilityContext): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  const perms: Permissions[] = [
    "ohos.permission.READ_IMAGEVIDEO",
    "ohos.permission.WRITE_IMAGEVIDEO"
  ];
  const result = await atManager.requestPermissionsFromUser(context, perms);
  return result.authResults.every(
    r => r === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
  );
}
```

---

# Save a Photo to the System Gallery

```typescript
async savePhotoToGallery(
  context: common.UIAbilityContext,
  jpegBuffer: ArrayBuffer,
  displayName: string  // e.g. "A12345-右侧发动机-张三.jpg"
): Promise<string> {
  const helper = photoAccessHelper.getPhotoAccessHelper(context);

  // Create asset (returns URI of the new asset)
  const assetUri = await helper.createAsset(
    photoAccessHelper.PhotoType.IMAGE,
    "jpg",
    {
      title: displayName.replace(".jpg", ""),
      displayName: displayName
    }
  );

  // Write JPEG bytes to the asset
  const file = await fs.open(assetUri, fs.OpenMode.READ_WRITE);
  await fs.write(file.fd, jpegBuffer);
  await fs.close(file.fd);

  return assetUri;
}
```

---

# Create a User Album

```typescript
async createOrGetAlbum(
  context: common.UIAbilityContext,
  albumName: string  // e.g. "巡检任务-A12345"
): Promise<photoAccessHelper.Album> {
  const helper = photoAccessHelper.getPhotoAccessHelper(context);

  // Try to find existing album
  const fetchOptions: photoAccessHelper.FetchOptions = {
    fetchColumns: [],
    predicates: new dataSharePredicates.DataSharePredicates()
      .equalTo(photoAccessHelper.AlbumKeys.ALBUM_NAME, albumName)
  };
  const albumFetchResult = await helper.getAlbums(
    photoAccessHelper.AlbumType.USER,
    photoAccessHelper.AlbumSubtype.USER_GENERIC,
    fetchOptions
  );

  if (albumFetchResult.getCount() > 0) {
    return await albumFetchResult.getFirstObject();
  }

  // Create new album
  const changeRequest = new photoAccessHelper.MediaAlbumChangeRequest(
    photoAccessHelper.AlbumType.USER,
    photoAccessHelper.AlbumSubtype.USER_GENERIC
  );
  changeRequest.setAlbumName(albumName);
  await helper.applyChanges(changeRequest);

  // Fetch again to return the created album
  const newResult = await helper.getAlbums(
    photoAccessHelper.AlbumType.USER,
    photoAccessHelper.AlbumSubtype.USER_GENERIC,
    fetchOptions
  );
  return await newResult.getFirstObject();
}
```

---

# Add Photo to Album

```typescript
async addPhotoToAlbum(
  context: common.UIAbilityContext,
  assetUri: string,
  album: photoAccessHelper.Album
): Promise<void> {
  const helper = photoAccessHelper.getPhotoAccessHelper(context);

  // Fetch the asset object by URI
  const assetFetch = await helper.getAssets({
    fetchColumns: [],
    predicates: new dataSharePredicates.DataSharePredicates()
      .equalTo(photoAccessHelper.PhotoKeys.URI, assetUri)
  });
  const asset = await assetFetch.getFirstObject();

  // Add to album via change request
  const changeRequest = new photoAccessHelper.MediaAlbumChangeRequest(album);
  changeRequest.addAssets([asset]);
  await helper.applyChanges(changeRequest);
}
```

---

# Query Photos by Task Number

```typescript
async queryPhotosByTask(
  context: common.UIAbilityContext,
  taskNumber: string
): Promise<photoAccessHelper.PhotoAsset[]> {
  const helper = photoAccessHelper.getPhotoAccessHelper(context);

  const fetchOptions: photoAccessHelper.FetchOptions = {
    fetchColumns: [
      photoAccessHelper.PhotoKeys.URI,
      photoAccessHelper.PhotoKeys.DISPLAY_NAME,
      photoAccessHelper.PhotoKeys.DATE_ADDED,
      photoAccessHelper.PhotoKeys.TITLE,
    ],
    predicates: new dataSharePredicates.DataSharePredicates()
      .contains(photoAccessHelper.PhotoKeys.DISPLAY_NAME, taskNumber)
      .orderByDesc(photoAccessHelper.PhotoKeys.DATE_ADDED)
  };

  const fetchResult = await helper.getAssets(fetchOptions);
  const assets: photoAccessHelper.PhotoAsset[] = [];
  for (let i = 0; i < fetchResult.getCount(); i++) {
    assets.push(await fetchResult.getObjectByPosition(i));
  }
  return assets;
}
```

---

# HARD LIMIT: Gallery Albums Are FLAT

HarmonyOS gallery does **NOT** support nested folder hierarchies.
User albums are flat — you cannot create `巡检/A12345/右侧发动机/`.

**Recommended dual-write strategy:**

```
① sandbox (hierarchical) → context.filesDir/tasks/A12345/engine/photo.jpg
   Used by the app for: structured browsing, export, watermark source

② system gallery (flat) → Album "巡检任务-A12345"
   Used by: system gallery app, sharing, inspector review
```

Both writes happen after the user taps "保存到相册". The sandbox copy is
the authoritative source; the gallery copy is for visibility.

---

# Recommended Filename Convention

```
{taskNumber}-{part}-{photographer}.jpg
Example: A12345-右侧发动机-张三.jpg

For the TITLE field (searchable, no extension):
A12345-右侧发动机-张三
```
