// Date formatting and calculation utilities.

export class DateUtils {
  // Returns "YYYYMMDD" for use in filenames
  static formatCompact(date: Date): string {
    const y = date.getFullYear().toString();
    const m = DateUtils.pad2(date.getMonth() + 1);
    const d = DateUtils.pad2(date.getDate());
    return `${y}${m}${d}`;
  }

  // Returns "YYYY-MM-DD" ISO format for DB storage
  static formatIso(date: Date): string {
    const y = date.getFullYear().toString();
    const m = DateUtils.pad2(date.getMonth() + 1);
    const d = DateUtils.pad2(date.getDate());
    return `${y}-${m}-${d}`;
  }

  // Returns "2026年5月16日" display format
  static formatDisplay(date: Date): string {
    const y = date.getFullYear();
    const m = date.getMonth() + 1;
    const d = date.getDate();
    return `${y}年${m}月${d}日`;
  }

  // Returns "5月16日" short display
  static formatShortDisplay(date: Date): string {
    const m = date.getMonth() + 1;
    const d = date.getDate();
    return `${m}月${d}日`;
  }

  // Returns "2026年5月" month-year label
  static formatMonthYear(year: number, month: number): string {
    return `${year}年${month}月`;
  }

  // Returns relative time string for draft auto-save indicator
  static getRelativeTime(pastDate: Date): string {
    const now = new Date();
    const diffMs = now.getTime() - pastDate.getTime();
    const diffSeconds = Math.floor(diffMs / 1000);
    const diffMinutes = Math.floor(diffSeconds / 60);
    const diffHours = Math.floor(diffMinutes / 60);

    if (diffSeconds < 60) {
      return '刚刚';
    } else if (diffMinutes < 60) {
      return `${diffMinutes}分钟前`;
    } else if (diffHours < 24) {
      return `${diffHours}小时前`;
    } else {
      return DateUtils.formatDisplay(pastDate);
    }
  }

  // Returns weekday name in Chinese (1=周一, 7=周日)
  static getWeekdayName(date: Date): string {
    const weekdays: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays[date.getDay()];
  }

  // Returns number of days in a given month (1-indexed month)
  static getMonthDays(year: number, month: number): number {
    return new Date(year, month, 0).getDate();
  }

  // Returns the day-of-week (0=Sun) for the first day of the month
  static getFirstDayOfWeek(year: number, month: number): number {
    return new Date(year, month - 1, 1).getDay();
  }

  // Returns true if two ISO date strings represent the same calendar day
  static isSameDay(isoDate1: string, isoDate2: string): boolean {
    return isoDate1.substring(0, 10) === isoDate2.substring(0, 10);
  }

  // Returns true if year/month matches today
  static isCurrentMonth(year: number, month: number): boolean {
    const now = new Date();
    return now.getFullYear() === year && (now.getMonth() + 1) === month;
  }

  // Returns today as ISO string
  static todayIso(): string {
    return DateUtils.formatIso(new Date());
  }

  // Returns "HH:MM" time string
  static formatTime(date: Date): string {
    const h = DateUtils.pad2(date.getHours());
    const m = DateUtils.pad2(date.getMinutes());
    return `${h}:${m}`;
  }

  private static pad2(n: number): string {
    return n < 10 ? `0${n}` : n.toString();
  }
}
