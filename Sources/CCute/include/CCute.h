// Swift-facing shim over Cute Framework (CF), pinned in Vendor/cute_framework.
//
// Swift's clang importer drops C11 `_Generic` macros entirely, so every generic
// CF macro needs a concrete, typed `static inline` wrapper here.
//
// Audit of CF e4786898 (grep -l _Generic include/*.h finds these three headers):
//   cute_binding.h  - cf_binding_value / _value_raw / _pressed / _released / _sign /
//                     _consume_press / _consume_release / _set_deadzone_per, cf_destroy_binding.
//                     Wrapped below as cfs_<macro>_<button|axis|stick>.
//   cute_math.h     - cf_min, cf_max, cf_abs, cf_clamp, cf_clamp01, cf_add, cf_sub, cf_dot, cf_len,
//   cute_math3d.h     cf_lerp, ... These dispatch to typed CF_INLINE functions (cf_add_v2,
//                     cf_clamp_f, cf_len_v3, ...) that Swift imports directly. Call those.
//   Container macros (cf_array_*, cf_map_*, cf_string_*) are not _Generic but are also
//   unusable from Swift; Swift code uses Array, Dictionary and String instead.
#ifndef CCUTE_H
#define CCUTE_H

/* We link CF as a static library. Without this, CF's headers mark every symbol
 * __declspec(dllimport) on Windows and the link fails with "undefined symbol". */
#ifndef CF_STATIC
#define CF_STATIC 1
#endif

#include <cute.h>

#ifdef __cplusplus
extern "C" {
#endif

/* cf_binding_value */
static inline float cfs_binding_value_button(CF_ButtonBinding b) { return cf_button_binding_value(b); }
static inline float cfs_binding_value_axis(CF_AxisBinding a) { return cf_axis_binding_value(a); }
static inline CF_V2 cfs_binding_value_stick(CF_StickBinding s) { return cf_stick_binding_value(s); }

/* cf_binding_value_raw */
static inline float cfs_binding_value_raw_button(CF_ButtonBinding b) { return cf_button_binding_value_raw(b); }
static inline float cfs_binding_value_raw_axis(CF_AxisBinding a) { return cf_axis_binding_value_raw(a); }
static inline CF_V2 cfs_binding_value_raw_stick(CF_StickBinding s) { return cf_stick_binding_value_raw(s); }

/* cf_binding_pressed */
static inline bool cfs_binding_pressed_button(CF_ButtonBinding b) { return cf_button_binding_pressed(b); }
static inline bool cfs_binding_pressed_axis(CF_AxisBinding a) { return cf_axis_binding_pressed(a); }
static inline bool cfs_binding_pressed_stick(CF_StickBinding s) { return cf_stick_binding_pressed(s); }

/* cf_binding_released */
static inline bool cfs_binding_released_button(CF_ButtonBinding b) { return cf_button_binding_released(b); }
static inline bool cfs_binding_released_axis(CF_AxisBinding a) { return cf_axis_binding_released(a); }
static inline bool cfs_binding_released_stick(CF_StickBinding s) { return cf_stick_binding_released(s); }

/* cf_binding_sign */
static inline float cfs_binding_sign_button(CF_ButtonBinding b) { return cf_button_binding_sign(b); }
static inline float cfs_binding_sign_axis(CF_AxisBinding a) { return cf_axis_binding_sign(a); }
static inline CF_V2 cfs_binding_sign_stick(CF_StickBinding s) { return cf_stick_binding_sign(s); }

/* cf_binding_consume_press / cf_binding_consume_release */
static inline bool cfs_binding_consume_press_button(CF_ButtonBinding b) { return cf_button_binding_consume_press(b); }
static inline bool cfs_binding_consume_press_axis(CF_AxisBinding a) { return cf_axis_binding_consume_press(a); }
static inline bool cfs_binding_consume_press_stick(CF_StickBinding s) { return cf_stick_binding_consume_press(s); }
static inline bool cfs_binding_consume_release_button(CF_ButtonBinding b) { return cf_button_binding_consume_release(b); }
static inline bool cfs_binding_consume_release_axis(CF_AxisBinding a) { return cf_axis_binding_consume_release(a); }
static inline bool cfs_binding_consume_release_stick(CF_StickBinding s) { return cf_stick_binding_consume_release(s); }

/* cf_binding_set_deadzone_per */
static inline void cfs_binding_set_deadzone_button(CF_ButtonBinding b, float dz) { cf_button_binding_set_deadzone(b, dz); }
static inline void cfs_binding_set_deadzone_axis(CF_AxisBinding a, float dz) { cf_axis_binding_set_deadzone(a, dz); }

/* Convenience: the plain "is it held" query the demo uses. */
static inline bool cfs_binding_down_button(CF_ButtonBinding b) { return cf_button_binding_down(b); }

/* CF's frame-time globals are `extern float` variables; Swift 6 strict concurrency refuses
 * to read mutable globals directly, so expose them as functions. */
static inline float cfs_delta_time(void) { return CF_DELTA_TIME; }
static inline float cfs_delta_time_fixed(void) { return CF_DELTA_TIME_FIXED; }
static inline uint64_t cfs_ticks(void) { return CF_TICKS; }
static inline double cfs_seconds(void) { return CF_SECONDS; }

/* Host C helpers: things Swift 6 cannot express portably (mutable libc globals, macros). */
#include <stdio.h>
static inline void cfs_host_unbuffer_stdout(void) {
#ifdef _WIN32
  setvbuf(stdout, NULL, _IONBF, 0);
#else
  setvbuf(stdout, NULL, _IOLBF, 0);
#endif
}

/* cf_destroy_binding */
static inline void cfs_destroy_binding_button(CF_ButtonBinding b) { cf_destroy_button_binding(b); }
static inline void cfs_destroy_binding_axis(CF_AxisBinding a) { cf_destroy_axis_binding(a); }
static inline void cfs_destroy_binding_stick(CF_StickBinding s) { cf_destroy_stick_binding(s); }

#ifdef __cplusplus
}
#endif

#endif /* CCUTE_H */
