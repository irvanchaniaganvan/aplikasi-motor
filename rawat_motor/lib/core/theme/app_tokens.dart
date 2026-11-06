import 'package:flutter/material.dart';

/// Sumber tunggal untuk keputusan visual Rawatin.
///
/// Widget tidak boleh menulis warna, ikon, radius, atau jarak mentah.
/// Warna status juga tersedia lewat [RawatinColors] agar nanti mudah
/// ditukar saat dark mode ditambahkan.
abstract final class AppPalette {
  // Netral: modern, clean, dan breathable
  static const ink = Color(0xFF0F172A);
  static const inkSoft = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const canvas = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF1F5F9);
  static const line = Color(0xFFE2E8F0);

  // Brand motorsport: racing red berenergi tapi proper & clean, dengan aksen telemetry amber
  static const primary = Color(0xFFDC2626);
  static const primaryBright = Color(0xFFEF4444);
  static const primaryDark = Color(0xFFB91C1C);
  static const primarySoft = Color(0xFFFEE2E2);
  static const accent = Color(0xFFF59E0B);
  static const accentSoft = Color(0xFFFEF3C7);
  static const onAccent = Color(0xFF451A03);

  // Status semantik: jernih dan berstandar desain modern
  static const safe = Color(0xFF059669);
  static const safeSoft = Color(0xFFECFDF5);
  static const soon = Color(0xFFD97706);
  static const soonSoft = Color(0xFFFFFBEB);
  static const due = Color(0xFFDC2626);
  static const dueSoft = Color(0xFFFEF2F2);
  static const check = Color(0xFF2563EB);
  static const checkSoft = Color(0xFFEFF6FF);

  // Netral tambahan
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const shadow = Color(0x0C0F172A);
  static const checkered = Color(0xFF1E293B);
}

const displayFontFamily = 'Rajdhani';
const bodyFontFamily = 'Barlow';

abstract final class AppType {
  // Angka odometer dan metrik tetap memakai font display bergaya digital TFT cluster
  static const km = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 54,
    height: 0.95,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const metric = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 22,
    height: 1.0,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Teks antarmuka, kartu, dan tombol memakai font body yang rapi, bersih, dan mudah dibaca
  static const cardTitle = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 16.5,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const eyebrow = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 10.5,
    height: 1.2,
    letterSpacing: 1.1,
    fontWeight: FontWeight.w700,
  );
  static const button = TextStyle(
    fontFamily: bodyFontFamily,
    fontSize: 14.5,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w600,
  );
}

abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const screen = 20.0;
}

abstract final class AppRadii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 260);
  static const odometer = Duration(milliseconds: 700);
}

/// Semua ikon berasal dari satu set rounded agar bobot visual konsisten.
abstract final class AppIcons {
  static const home = Icons.home_rounded;
  static const history = Icons.history_rounded;
  static const settings = Icons.settings_rounded;
  static const vehicle = Icons.two_wheeler_rounded;
  static const speed = Icons.speed_rounded;
  static const add = Icons.add_rounded;
  static const check = Icons.check_rounded;
  static const verified = Icons.verified_rounded;
  static const due = Icons.priority_high_rounded;
  static const soon = Icons.schedule_rounded;
  static const needsCheck = Icons.help_rounded;
  static const record = Icons.add_task_rounded;
  static const wrench = Icons.build_rounded;
  static const tune = Icons.tune_rounded;
  static const calendar = Icons.calendar_month_rounded;
  static const chevronDown = Icons.expand_more_rounded;
  static const chevronUp = Icons.expand_less_rounded;
  static const arrowForward = Icons.arrow_forward_rounded;
  static const edit = Icons.edit_rounded;
  static const delete = Icons.delete_outline_rounded;
  static const person = Icons.person_rounded;
  static const mail = Icons.mail_rounded;
  static const lock = Icons.lock_rounded;
  static const search = Icons.search_rounded;
  static const category = Icons.category_rounded;
  static const cooling = Icons.ac_unit_rounded;
  static const brake = Icons.disc_full_rounded;
  static const oil = Icons.oil_barrel_rounded;
  static const sparkPlug = Icons.bolt_rounded;
  static const tire = Icons.tire_repair_rounded;
  static const belt = Icons.link_rounded;
  static const chain = Icons.settings_suggest_rounded;
  static const airFilter = Icons.air_rounded;
  static const battery = Icons.battery_charging_full_rounded;
  static const tip = Icons.lightbulb_rounded;
  static const info = Icons.info_rounded;
  static const infoOutline = Icons.info_outline_rounded;
  static const warning = Icons.warning_amber_rounded;
  static const sparkle = Icons.auto_awesome_rounded;
  static const checkCircleOutline = Icons.check_circle_outline_rounded;
  static const viewModule = Icons.view_module_rounded;
  static const directionsBike = Icons.directions_bike_rounded;
  static const inbox = Icons.inbox_rounded;
  static const play = Icons.play_arrow_rounded;
  static const grid = Icons.grid_view_rounded;
  static const checkCircle = Icons.check_circle_rounded;
  static const flag = Icons.sports_score_rounded;
  static const visibility = Icons.visibility_rounded;
  static const send = Icons.send_rounded;
  static const refresh = Icons.refresh_rounded;
  static const restart = Icons.restart_alt_rounded;
  static const arrowBack = Icons.arrow_back_rounded;
}
