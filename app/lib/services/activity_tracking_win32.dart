// Windows-only Win32 FFI helpers for activity tracking.
// This file imports dart:ffi and package:ffi — both compile on all platforms.
// All DynamicLibrary calls are guarded by Platform.isWindows at runtime.

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final class _LASTINPUTINFO extends Struct {
  @Uint32()
  external int cbSize;
  @Uint32()
  external int dwTime;
}

typedef _GetForegroundWindowNative = IntPtr Function();
typedef _GetForegroundWindowDart = int Function();
typedef _GetWindowTextWNative = Int32 Function(IntPtr hwnd, Pointer<Utf16> buf, Int32 max);
typedef _GetWindowTextWDart = int Function(int hwnd, Pointer<Utf16> buf, int max);
typedef _GetLastInputInfoNative = Bool Function(Pointer<_LASTINPUTINFO> info);
typedef _GetLastInputInfoDart = bool Function(Pointer<_LASTINPUTINFO> info);
typedef _GetTickCountNative = Uint32 Function();
typedef _GetTickCountDart = int Function();

class Win32ActivityHelper {
  static Win32ActivityHelper? _instance;
  static Win32ActivityHelper get instance => _instance ??= Win32ActivityHelper._();

  late final _GetForegroundWindowDart _getForegroundWindow;
  late final _GetWindowTextWDart _getWindowTextW;
  late final _GetLastInputInfoDart _getLastInputInfo;
  late final _GetTickCountDart _getTickCount;
  bool _ok = false;

  Win32ActivityHelper._() {
    if (!Platform.isWindows) return;
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      _getForegroundWindow = user32.lookupFunction<
          _GetForegroundWindowNative, _GetForegroundWindowDart>('GetForegroundWindow');
      _getWindowTextW = user32.lookupFunction<
          _GetWindowTextWNative, _GetWindowTextWDart>('GetWindowTextW');
      _getLastInputInfo = user32.lookupFunction<
          _GetLastInputInfoNative, _GetLastInputInfoDart>('GetLastInputInfo');
      _getTickCount = kernel32.lookupFunction<
          _GetTickCountNative, _GetTickCountDart>('GetTickCount');
      _ok = true;
    } catch (_) {}
  }

  /// Returns (windowTitle, idleMilliseconds). Returns null if unavailable.
  (String, int)? currentWindowAndIdle() {
    if (!_ok) return null;
    try {
      final hwnd = _getForegroundWindow();
      if (hwnd == 0) return ('', 0);

      final buf = calloc<Uint16>(512);
      try {
        final ptr = buf.cast<Utf16>();
        final len = _getWindowTextW(hwnd, ptr, 512);
        final title = len > 0 ? ptr.toDartString(length: len) : '';

        final lii = calloc<_LASTINPUTINFO>();
        try {
          lii.ref.cbSize = sizeOf<_LASTINPUTINFO>();
          final ok = _getLastInputInfo(lii);
          final idleMs = ok ? (_getTickCount() - lii.ref.dwTime) : 0;
          return (title, idleMs);
        } finally {
          calloc.free(lii);
        }
      } finally {
        calloc.free(buf);
      }
    } catch (_) {
      return null;
    }
  }
}
