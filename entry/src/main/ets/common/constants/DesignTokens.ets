// Design system tokens — single source of truth for colors, typography, spacing

export class AppColors {
  static readonly Primary: string = '#0066CC';
  static readonly PrimaryDark: string = '#004C99';
  static readonly Success: string = '#00A870';
  static readonly Warning: string = '#FF9500';
  static readonly Danger: string = '#D93025';
  static readonly Background: string = '#F5F7FA';
  static readonly Surface: string = '#FFFFFF';
  static readonly Border: string = '#DCE0E6';
  static readonly BorderLight: string = '#ECEEF2';
  static readonly TextPrimary: string = '#1A1A1A';
  static readonly TextSecondary: string = '#666666';
  static readonly TextDisabled: string = '#999999';
  static readonly TextFaded: string = '#C0C4CC';
  static readonly OverlayDark: string = 'rgba(0,0,0,0.72)';
  static readonly DisabledBg: string = '#E0E0E0';
  static readonly InputDisabledBg: string = '#F0F0F0';
  static readonly ErrorBgSubtle: string = '#FFFBF9';
  static readonly TagBg: string = '#F0F2F5';
  static readonly BadgeBlueBg: string = '#E6F0FB';
  static readonly BadgeBlueText: string = '#0066CC';
  static readonly WeekendStripe1: string = '#F5F7FA';
  static readonly WeekendStripe2: string = '#FAFBFC';
}

export class AppFontSize {
  static readonly PageTitle: number = 28;
  static readonly SectionHeader: number = 22;
  static readonly Body: number = 18;
  static readonly FormLabel: number = 18;
  static readonly ButtonText: number = 20;
  static readonly Helper: number = 16;
  static readonly Watermark: number = 12;
  static readonly Tag: number = 14;
  static readonly CalendarDate: number = 22;
  static readonly CalendarBadge: number = 16;
  static readonly OverlayTime: number = 14;
}

export class AppSpacing {
  static readonly XS: number = 8;
  static readonly SM: number = 16;
  static readonly MD: number = 24;
  static readonly LG: number = 32;
  static readonly XL: number = 48;
}

export class AppSize {
  static readonly ButtonHeight: number = 56;
  static readonly ButtonHeightLarge: number = 72;
  static readonly InputHeight: number = 56;
  static readonly TopBarHeight: number = 64;
  static readonly BottomBarHeight: number = 72;
  static readonly CaptureButtonDiameter: number = 96;
  static readonly PipWidth: number = 240;
  static readonly PipHeight: number = 160;
  static readonly MinTouchTarget: number = 56;
  static readonly BorderRadius: number = 8;
  static readonly BorderRadiusLarge: number = 12;
  static readonly IconSize: number = 24;
  static readonly ThumbnailSmall: number = 56;
  static readonly ThumbnailHistory: number = 200;
  static readonly ThumbnailDetail: number = 150;
  static readonly CalendarCellWidth: number = 100;
  static readonly CalendarCellHeight: number = 90;
  static readonly FilterPanelWidth: number = 320;
  static readonly ToastHeight: number = 56;
  static readonly ModalWidth: number = 480;
  static readonly UsbIndicatorSize: number = 24;
}

export class AppBorderWidth {
  static readonly Default: number = 1;
  static readonly Focused: number = 2;
  static readonly Today: number = 2;
  static readonly PipBorder: number = 2;
}
