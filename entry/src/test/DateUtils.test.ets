import { describe, it, expect } from '@ohos/hypium';
import { DateUtils } from '../main/ets/common/utils/DateUtils';

export default function dateUtilsTest() {
  describe('DateUtils', () => {

    it('formatCompact_returns_YYYYMMDD', 0, () => {
      const d = new Date(2026, 4, 16); // May 16 2026
      expect(DateUtils.formatCompact(d)).assertEqual('20260516');
    });

    it('formatCompact_pads_single_digit_month_and_day', 0, () => {
      const d = new Date(2026, 0, 5); // Jan 5 2026
      expect(DateUtils.formatCompact(d)).assertEqual('20260105');
    });

    it('formatIso_returns_YYYY_MM_DD', 0, () => {
      const d = new Date(2026, 4, 16);
      expect(DateUtils.formatIso(d)).assertEqual('2026-05-16');
    });

    it('formatDisplay_returns_Chinese_date', 0, () => {
      const d = new Date(2026, 4, 16);
      expect(DateUtils.formatDisplay(d)).assertEqual('2026年5月16日');
    });

    it('formatShortDisplay_returns_month_day', 0, () => {
      const d = new Date(2026, 4, 16);
      expect(DateUtils.formatShortDisplay(d)).assertEqual('5月16日');
    });

    it('formatMonthYear_returns_year_month_label', 0, () => {
      expect(DateUtils.formatMonthYear(2026, 5)).assertEqual('2026年5月');
    });

    it('getRelativeTime_just_now_within_60s', 0, () => {
      const now = new Date();
      expect(DateUtils.getRelativeTime(now)).assertEqual('刚刚');
    });

    it('getRelativeTime_minutes_ago', 0, () => {
      const fiveMinAgo = new Date(Date.now() - 5 * 60 * 1000);
      expect(DateUtils.getRelativeTime(fiveMinAgo)).assertEqual('5分钟前');
    });

    it('getMonthDays_31_for_january', 0, () => {
      expect(DateUtils.getMonthDays(2026, 1)).assertEqual(31);
    });

    it('getMonthDays_28_for_non_leap_february', 0, () => {
      expect(DateUtils.getMonthDays(2026, 2)).assertEqual(28);
    });

    it('getMonthDays_29_for_leap_february', 0, () => {
      expect(DateUtils.getMonthDays(2024, 2)).assertEqual(29);
    });

    it('getMonthDays_30_for_april', 0, () => {
      expect(DateUtils.getMonthDays(2026, 4)).assertEqual(30);
    });

    it('isSameDay_true_for_same_date', 0, () => {
      expect(DateUtils.isSameDay('2026-05-16', '2026-05-16')).assertTrue();
    });

    it('isSameDay_false_for_different_dates', 0, () => {
      expect(DateUtils.isSameDay('2026-05-16', '2026-05-17')).assertFalse();
    });

    it('formatTime_returns_HH_MM', 0, () => {
      const d = new Date(2026, 4, 16, 9, 5, 0); // 09:05
      expect(DateUtils.formatTime(d)).assertEqual('09:05');
    });

    it('todayIso_returns_valid_date_string', 0, () => {
      const result = DateUtils.todayIso();
      expect(result.length).assertEqual(10);
      expect(result[4]).assertEqual('-');
      expect(result[7]).assertEqual('-');
    });
  });
}
