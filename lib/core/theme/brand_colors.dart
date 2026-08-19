import 'package:flutter/material.dart';

/// Canonical Barakali brand palette - the single source for these hex values.
/// The light theme seeds its `ColorScheme` from these (see `app/theme.dart`);
/// dark mode derives lightened, AA-safe variants there.
///
/// Use these constants directly ONLY for fills on **theme-independent** surfaces
/// - overlay pills that sit on a photo, map markers on always-light Google tiles
/// - where `theme.colorScheme.*` must NOT be used (it lightens in dark mode and
/// would put white text on a light fill, failing WCAG AA). For anything drawn on
/// a theme surface, use the `colorScheme` so it adapts to light/dark.
const kBrandGreen = Color(0xFF2D7D46);
const kBrandAmber = Color(0xFFD4A843);
const kBrandTerracotta = Color(0xFFC45B3A);
