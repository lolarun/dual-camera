import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { dataSharePredicates } from '@kit.ArkData';
import fs from '@ohos.file.fs';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { FormData } from '../common/types/InspectionTypes';
import { FileUtils } from '../common/utils/FileUtils';

export class SaveResult {
  sandboxPath: string = '';
  galleryUri: string = '';
}

export class MediaLibraryService {
  static async saveToSandbox(
    filesDir: string,
    taskNumber: string,
    part: string,
    photographer: string,
    photoDate: string,
    imageBytes: ArrayBuffer
  ): Promise<string> {
    const date = new Date(photoDate);

    // Create parent directories level by level (no recursive mkdir support)
    const safePart = part.replace(/\//g, '-').replace(/\s/g, '');
    const tasksDir = `${filesDir}/tasks`;
    const taskDir  = `${tasksDir}/${taskNumber}`;
    const partDir  = `${taskDir}/${safePart}`;
    for (const dir of [tasksDir, taskDir, partDir]) {
      try { await fs.mkdir(dir); } catch (e) { /* already exists */ }
    }

    const sandboxPath = FileUtils.buildSandboxPath(filesDir, taskNumber, part, photographer, date);
    const file = await fs.open(
      sandboxPath,
      fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC
    );
    await fs.write(file.fd, imageBytes);
    await fs.close(file.fd);
    return sandboxPath;
  }

  static async saveToGallery(
    context: common.UIAbilityContext,
    imageBytes: ArrayBuffer,
    taskNumber: string,
    part: string,
    photographer: string,
    photoDate: string
  ): Promise<string> {
    const helper = photoAccessHelper.getPhotoAccessHelper(context);
    const date   = new Date(photoDate);
    const filename = FileUtils.buildFilename(taskNumber, part, photographer, date);
    const title  = filename.endsWith('.jpg')
      ? filename.substring(0, filename.length - 4)
      : filename;

    const assetUri = await helper.createAsset(
      photoAccessHelper.PhotoType.IMAGE,
      'jpg',
      { title: title }
    );

    const file = await fs.open(assetUri, fs.OpenMode.READ_WRITE);
    await fs.write(file.fd, imageBytes);
    await fs.close(file.fd);

    try {
      const albumName = FileUtils.buildAlbumName(taskNumber);
      const album = await MediaLibraryService.findAlbum(helper, albumName);
      await MediaLibraryService.addAssetToAlbum(helper, assetUri, album);
    } catch (err) {
      const e = err as BusinessError;
      console.error(`MediaLibraryService: album error ${e.message}`);
    }

    return assetUri;
  }

  static async dualSave(
    context: common.UIAbilityContext,
    metadata: FormData,
    imageBytes: ArrayBuffer
  ): Promise<SaveResult> {
    const sandboxPath = await MediaLibraryService.saveToSandbox(
      context.filesDir,
      metadata.taskNumber,
      metadata.part,
      metadata.photographer,
      metadata.photoDate,
      imageBytes
    );

    const galleryUri = await MediaLibraryService.saveToGallery(
      context,
      imageBytes,
      metadata.taskNumber,
      metadata.part,
      metadata.photographer,
      metadata.photoDate
    );

    const result = new SaveResult();
    result.sandboxPath = sandboxPath;
    result.galleryUri  = galleryUri;
    return result;
  }

  private static async findAlbum(
    helper: photoAccessHelper.PhotoAccessHelper,
    albumName: string
  ): Promise<photoAccessHelper.Album | null> {
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(photoAccessHelper.AlbumKeys.ALBUM_NAME, albumName);

    const fetchOptions: photoAccessHelper.FetchOptions = {
      fetchColumns: [],
      predicates: predicates,
    };

    const existing = await helper.getAlbums(
      photoAccessHelper.AlbumType.USER,
      photoAccessHelper.AlbumSubtype.USER_GENERIC,
      fetchOptions
    );

    if (existing.getCount() > 0) {
      return await existing.getFirstObject();
    }
    return null;
  }

  private static async addAssetToAlbum(
    helper: photoAccessHelper.PhotoAccessHelper,
    assetUri: string,
    album: photoAccessHelper.Album | null
  ): Promise<void> {
    if (album === null) { return; }

    const assetPredicates = new dataSharePredicates.DataSharePredicates();
    assetPredicates.equalTo(photoAccessHelper.PhotoKeys.URI, assetUri);

    const assetFetch = await helper.getAssets({
      fetchColumns: [],
      predicates: assetPredicates,
    });
    const asset = await assetFetch.getFirstObject();

    const addRequest = new photoAccessHelper.MediaAlbumChangeRequest(album);
    addRequest.addAssets([asset]);
    await helper.applyChanges(addRequest);
  }
}
