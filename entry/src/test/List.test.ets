import localUnitTest from './LocalUnit.test';
import dateUtilsTest from './DateUtils.test';
import fileUtilsTest from './FileUtils.test';
import formConstantsTest from './FormConstants.test';
import inspectionTypesTest from './InspectionTypes.test';
import dbServiceTest from './DBService.test';
import preferencesServiceTest from './PreferencesService.test';

export default function testsuite() {
  localUnitTest();
  dateUtilsTest();
  fileUtilsTest();
  formConstantsTest();
  inspectionTypesTest();
  dbServiceTest();
  preferencesServiceTest();
}
