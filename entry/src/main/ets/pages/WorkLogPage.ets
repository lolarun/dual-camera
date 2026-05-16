import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppColors, AppFontSize, AppSize, AppSpacing } from '../common/constants/DesignTokens';
import { InspectionTask, DayTaskSummary } from '../common/types/InspectionTypes';
import { DBService } from '../services/DBService';
import { DateUtils } from '../common/utils/DateUtils';

@Entry
@Component
struct WorkLogPage {
  @State year: number = new Date().getFullYear();
  @State month: number = new Date().getMonth() + 1;
  @State selectedDay: number = new Date().getDate();
  @State taskCountByDay: Map<number, number> = new Map();
  @State dayTasks: InspectionTask[] = [];
  @State monthTaskCount: number = 0;
  @State monthPhotoCount: number = 0;
  @State workDays: number = 0;

  aboutToAppear(): void {
    this.loadMonthData();
    this.loadDayData();
  }

  private async loadMonthData(): Promise<void> {
    try {
      const countMap = await DBService.getInstance().getTaskCountByDay(this.year, this.month);
      this.taskCountByDay = countMap;
      let total = 0;
      let days  = 0;
      countMap.forEach((count: number) => {
        total += count;
        days  += 1;
      });
      this.monthTaskCount = total;
      this.workDays       = days;
    } catch (err) {
      const e = err as BusinessError;
      console.error(`WorkLogPage: loadMonthData failed ${e.message}`);
    }
  }

  private async loadDayData(): Promise<void> {
    try {
      const isoDate = `${this.year}-${this.month < 10 ? '0' : ''}${this.month}-${this.selectedDay < 10 ? '0' : ''}${this.selectedDay}`;
      this.dayTasks = await DBService.getInstance().queryTasksByDate(isoDate);
    } catch (err) {
      const e = err as BusinessError;
      console.error(`WorkLogPage: loadDayData failed ${e.message}`);
    }
  }

  private prevMonth(): void {
    if (this.month === 1) {
      this.year  -= 1;
      this.month  = 12;
    } else {
      this.month -= 1;
    }
    this.selectedDay = 1;
    this.loadMonthData();
    this.loadDayData();
  }

  private nextMonth(): void {
    if (this.month === 12) {
      this.year  += 1;
      this.month  = 1;
    } else {
      this.month += 1;
    }
    this.selectedDay = 1;
    this.loadMonthData();
    this.loadDayData();
  }

  private goToday(): void {
    const now    = new Date();
    this.year    = now.getFullYear();
    this.month   = now.getMonth() + 1;
    this.selectedDay = now.getDate();
    this.loadMonthData();
    this.loadDayData();
  }

  private selectDay(day: number): void {
    this.selectedDay = day;
    this.loadDayData();
  }

  private buildCalendarCells(): number[] {
    const firstDow  = DateUtils.getFirstDayOfWeek(this.year, this.month); // 0=Sun
    // Shift so Monday=0
    const offset    = (firstDow + 6) % 7;
    const daysCount = DateUtils.getMonthDays(this.year, this.month);
    const cells: number[] = [];
    for (let i = 0; i < offset; i++) {
      cells.push(0);  // empty
    }
    for (let d = 1; d <= daysCount; d++) {
      cells.push(d);
    }
    return cells;
  }

  private isToday(day: number): boolean {
    const now = new Date();
    return now.getFullYear() === this.year
      && (now.getMonth() + 1) === this.month
      && now.getDate() === day;
  }

  private isWeekend(day: number): boolean {
    if (day === 0) { return false; }
    const dow = new Date(this.year, this.month - 1, day).getDay();
    return dow === 0 || dow === 6;
  }

  private getTaskCountForDay(day: number): number {
    const count = this.taskCountByDay.get(day);
    return count !== undefined ? count : 0;
  }

  build() {
    Column() {
      // Top bar
      Row() {
        Text('← 返回')
          .fontSize(AppFontSize.Body)
          .fontColor(AppColors.Primary)
          .height(AppSize.MinTouchTarget)
          .padding({ left: AppSpacing.XS, right: AppSpacing.SM })
          .onClick(() => { router.back(); })

        Text('工作记录')
          .fontSize(AppFontSize.SectionHeader)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TextPrimary)

        Blank()
      }
      .width('100%')
      .height(AppSize.TopBarHeight)
      .padding({ left: AppSpacing.XS })
      .backgroundColor(AppColors.Surface)
      .borderWidth({ bottom: 1 })
      .borderColor(AppColors.Border)
      .borderStyle(BorderStyle.Solid)
      .alignItems(VerticalAlign.Center)

      // 2-column layout
      Row() {
        // Left: calendar (60%)
        Column() {
          // Month navigation
          Row() {
            Text('◀')
              .fontSize(AppFontSize.SectionHeader)
              .fontColor(AppColors.Primary)
              .height(AppSize.MinTouchTarget)
              .width(AppSize.MinTouchTarget)
              .textAlign(TextAlign.Center)
              .onClick(() => { this.prevMonth(); })

            Blank()

            Text(DateUtils.formatMonthYear(this.year, this.month))
              .fontSize(AppFontSize.SectionHeader)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TextPrimary)

            Blank()

            Text('今天')
              .fontSize(AppFontSize.Body)
              .fontColor(AppColors.Primary)
              .height(AppSize.MinTouchTarget)
              .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
              .onClick(() => { this.goToday(); })

            Text('▶')
              .fontSize(AppFontSize.SectionHeader)
              .fontColor(AppColors.Primary)
              .height(AppSize.MinTouchTarget)
              .width(AppSize.MinTouchTarget)
              .textAlign(TextAlign.Center)
              .onClick(() => { this.nextMonth(); })
          }
          .width('100%')
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM, top: AppSpacing.SM })
          .alignItems(VerticalAlign.Center)

          // Weekday header
          Row() {
            ForEach(['一', '二', '三', '四', '五', '六', '日'], (weekday: string) => {
              Text(weekday)
                .fontSize(AppFontSize.Helper)
                .fontColor(AppColors.TextSecondary)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .height(36)
            })
          }
          .width('100%')
          .padding({ left: AppSpacing.XS, right: AppSpacing.XS })

          // Calendar grid
          Scroll() {
            Grid() {
              ForEach(this.buildCalendarCells(), (day: number) => {
                GridItem() {
                  if (day === 0) {
                    Column()
                      .width('100%')
                      .height(AppSize.CalendarCellHeight)
                  } else {
                    Column() {
                      Text(day.toString())
                        .fontSize(AppFontSize.CalendarDate)
                        .fontWeight(this.isToday(day) ? FontWeight.Bold : FontWeight.Normal)
                        .fontColor(
                          this.selectedDay === day
                            ? AppColors.Surface
                            : (this.isWeekend(day) ? AppColors.TextDisabled : AppColors.TextPrimary)
                        )

                      if (this.getTaskCountForDay(day) > 0) {
                        Text(`${this.getTaskCountForDay(day)} 任务`)
                          .fontSize(AppFontSize.CalendarBadge)
                          .fontColor(this.selectedDay === day ? AppColors.Surface : AppColors.BadgeBlueText)
                          .padding({ left: 6, right: 6 })
                          .height(20)
                          .borderRadius(10)
                          .backgroundColor(
                            this.selectedDay === day
                              ? 'rgba(255,255,255,0.3)'
                              : AppColors.BadgeBlueBg
                          )
                      }
                    }
                    .width('100%')
                    .height(AppSize.CalendarCellHeight)
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .borderRadius(AppSize.BorderRadius)
                    .border({
                      width: this.isToday(day) ? 2 : 1,
                      color: this.isToday(day) ? AppColors.Primary : AppColors.Border,
                      style: BorderStyle.Solid,
                    })
                    .backgroundColor(
                      this.selectedDay === day
                        ? AppColors.Primary
                        : (this.isWeekend(day) ? AppColors.WeekendStripe1 : AppColors.Surface)
                    )
                    .onClick(() => { this.selectDay(day); })
                  }
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
            .columnsGap(AppSpacing.XS)
            .rowsGap(AppSpacing.XS)
            .padding(AppSpacing.XS)
            .width('100%')
          }
          .layoutWeight(1)
          .width('100%')

          // Month stats
          Row() {
            Column() {
              Text(this.monthTaskCount.toString())
                .fontSize(AppFontSize.SectionHeader)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.Primary)
              Text('本月任务')
                .fontSize(AppFontSize.Helper)
                .fontColor(AppColors.TextSecondary)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text(this.workDays.toString())
                .fontSize(AppFontSize.SectionHeader)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.Primary)
              Text('工作天数')
                .fontSize(AppFontSize.Helper)
                .fontColor(AppColors.TextSecondary)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')
          .height(72)
          .backgroundColor(AppColors.Surface)
          .borderWidth({ top: 1 })
          .borderColor(AppColors.Border)
          .borderStyle(BorderStyle.Solid)
        }
        .layoutWeight(6)
        .height('100%')
        .backgroundColor(AppColors.Background)

        // Right: day detail (40%)
        Column() {
          // Day header
          Row() {
            Text(`${this.month}月${this.selectedDay}日`)
              .fontSize(AppFontSize.SectionHeader)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TextPrimary)

            Blank()

            Text(`共 ${this.dayTasks.length} 个任务`)
              .fontSize(AppFontSize.Helper)
              .fontColor(AppColors.TextSecondary)
          }
          .width('100%')
          .height(52)
          .padding({ left: AppSpacing.SM, right: AppSpacing.SM })
          .backgroundColor(AppColors.Surface)
          .borderWidth({ bottom: 1 })
          .borderColor(AppColors.Border)
          .borderStyle(BorderStyle.Solid)
          .alignItems(VerticalAlign.Center)

          if (this.dayTasks.length === 0) {
            Column() {
              Text('这天没有拍摄记录')
                .fontSize(AppFontSize.Body)
                .fontColor(AppColors.TextSecondary)
            }
            .layoutWeight(1)
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            Scroll() {
              Column() {
                ForEach(this.dayTasks, (task: InspectionTask) => {
                  Column() {
                    Row() {
                      Text(task.taskNumber)
                        .fontSize(AppFontSize.Body)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(AppColors.TextPrimary)
                        .layoutWeight(1)
                      Text(task.cameraSource === 'BORESCOPE' ? '孔' : '原')
                        .fontSize(AppFontSize.Tag)
                        .fontColor(AppColors.Primary)
                        .padding({ left: 6, right: 6 })
                        .height(20)
                        .borderRadius(10)
                        .backgroundColor(AppColors.BadgeBlueBg)
                    }
                    .width('100%')
                    .margin({ bottom: 4 })

                    Text(`${task.part} · ${task.partArea}`)
                      .fontSize(AppFontSize.Helper)
                      .fontColor(AppColors.TextSecondary)
                    Text(`照相人：${task.photographer}`)
                      .fontSize(AppFontSize.Helper)
                      .fontColor(AppColors.TextDisabled)
                      .margin({ top: 2 })
                  }
                  .width('100%')
                  .padding(AppSpacing.SM)
                  .backgroundColor(AppColors.Surface)
                  .borderRadius(AppSize.BorderRadius)
                  .border({ width: 1, color: AppColors.Border, style: BorderStyle.Solid })
                  .margin({ bottom: AppSpacing.XS })
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/TaskPhotoDetailPage',
                      params: { taskId: task.id.toString() },
                    });
                  })
                })
              }
              .width('100%')
              .padding(AppSpacing.SM)
              .alignItems(HorizontalAlign.Start)
            }
            .layoutWeight(1)
            .width('100%')
          }
        }
        .layoutWeight(4)
        .height('100%')
        .backgroundColor(AppColors.Background)
        .borderWidth({ left: 1 })
        .borderColor(AppColors.Border)
        .borderStyle(BorderStyle.Solid)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.Background)
  }
}
