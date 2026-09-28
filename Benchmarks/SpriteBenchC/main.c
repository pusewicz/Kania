// C baseline for the Phase 0 draw-path benchmark. Benchmarks/SpriteBench is the Swift twin;
// both must run the same workload, so change them together.
//
// Usage: SpriteBenchC [--scene sprites|text] [--count N] [--frames N] [--warmup N] [--hidden 0|1]
//                     [--screenshot path]
// Prints one JSON line with per-frame CPU submission and whole-frame times in milliseconds.
#include <CCute.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define WIDTH 1280
#define HEIGHT 720
#define FIXED_DT (1.0f / 60.0f)

typedef struct Entity
{
	CF_Sprite sprite;
	CF_V2 velocity;
} Entity;

typedef struct Options
{
	const char* scene;
	int count;
	int frames;
	int warmup;
	const char* screenshot;
	bool hidden;
} Options;

static const char* s_animations[] = { "up", "side", "hold_down", "hold_side", "hold_up", "idle" };

static uint32_t s_rng = 1;

/* Deterministic LCG in [0, 1), shared with the Swift benchmark. */
static float rng_next(void)
{
	s_rng = s_rng * 1664525u + 1013904223u;
	return (float)(s_rng >> 8) / 16777216.0f;
}

/* Next random value in [lo, hi). */
static float rng_range(float lo, float hi)
{
	return lo + (hi - lo) * rng_next();
}

/* Parses `--name value` pairs, exiting on an unknown option. */
static Options parse_options(int argc, char* argv[])
{
	Options o = { "sprites", 10000, 600, 60, NULL, false };
	for (int i = 1; i + 1 < argc; i += 2) {
		if (!strcmp(argv[i], "--scene")) o.scene = argv[i + 1];
		else if (!strcmp(argv[i], "--count")) o.count = atoi(argv[i + 1]);
		else if (!strcmp(argv[i], "--frames")) o.frames = atoi(argv[i + 1]);
		else if (!strcmp(argv[i], "--warmup")) o.warmup = atoi(argv[i + 1]);
		else if (!strcmp(argv[i], "--screenshot")) o.screenshot = argv[i + 1];
		else if (!strcmp(argv[i], "--hidden")) o.hidden = atoi(argv[i + 1]) != 0;
		else { fprintf(stderr, "unknown option %s\n", argv[i]); exit(2); }
	}
	return o;
}

/* Fills `entities` with demo sprites, positions and velocities in the order the Swift benchmark uses. */
static void make_entities(Entity* entities, int count)
{
	CF_Sprite demo = cf_make_demo_sprite();
	for (int i = 0; i < count; ++i) {
		Entity* e = entities + i;
		e->sprite = demo;
		cf_sprite_play(&e->sprite, s_animations[i % 6]);
		/* Drawn one at a time: C leaves the evaluation order of initialiser arguments unspecified. */
		float px = rng_range(-WIDTH / 2, WIDTH / 2);
		float py = rng_range(-HEIGHT / 2, HEIGHT / 2);
		float vx = rng_range(-100, 100);
		float vy = rng_range(-100, 100);
		e->sprite.transform.p = cf_v2(px, py);
		e->velocity = cf_v2(vx, vy);
	}
}

/* Moves one fixed step, bounces off the window edges, advances the animation and draws each sprite. */
static void step_sprites(Entity* entities, int count)
{
	for (int i = 0; i < count; ++i) {
		Entity* e = entities + i;
		CF_V2 p = cf_add_v2(e->sprite.transform.p, cf_mul_v2_f(e->velocity, FIXED_DT));
		if (p.x < -WIDTH / 2 || p.x > WIDTH / 2) e->velocity.x = -e->velocity.x;
		if (p.y < -HEIGHT / 2 || p.y > HEIGHT / 2) e->velocity.y = -e->velocity.y;
		e->sprite.transform.p = p;
		cf_sprite_update(&e->sprite);
		cf_draw_sprite(&e->sprite);
	}
}

/* Formats and draws `count` labels in a grid. */
static void draw_labels(int count, int frame)
{
	char buf[64];
	int columns = 16;
	for (int i = 0; i < count; ++i) {
		snprintf(buf, sizeof(buf), "Entity %d hp %d", i, (frame + i) % 100);
		float x = -WIDTH / 2 + 8 + (float)(i % columns) * (WIDTH / columns);
		float y = HEIGHT / 2 - 16 - (float)((i / columns) % 44) * 16;
		cf_draw_text(buf, cf_v2(x, y), -1);
	}
}

/* Sum of all sprite positions: equal between C and Swift only if both ran the same simulation. */
static double position_checksum(const Entity* entities, int count)
{
	double sum = 0;
	for (int i = 0; i < count; ++i) sum += (double)entities[i].sprite.transform.p.x + (double)entities[i].sprite.transform.p.y;
	return sum;
}

/* qsort comparator for ascending doubles. */
static int compare_doubles(const void* a, const void* b)
{
	double x = *(const double*)a, y = *(const double*)b;
	return (x > y) - (x < y);
}

/* Prints `"name":{median,p95,mean}` for `samples`, sorting them in place. */
static void print_stats(const char* name, double* samples, int n)
{
	double sum = 0;
	for (int i = 0; i < n; ++i) sum += samples[i];
	qsort(samples, (size_t)n, sizeof(double), compare_doubles);
	int p95 = (int)((double)(n - 1) * 0.95 + 0.5);
	printf("\"%s\":{\"median\":%.4f,\"p95\":%.4f,\"mean\":%.4f}", name, samples[(n - 1) / 2], samples[p95], sum / n);
}

/* Renders the queued draw commands into an offscreen canvas and writes it to `path` as a PNG. */
static void write_screenshot(const char* path)
{
	CF_Canvas canvas = cf_make_canvas(cf_canvas_defaults(WIDTH, HEIGHT));
	cf_render_to(canvas, true);
	cf_app_draw_onto_screen(false);
	CF_Readback readback = cf_canvas_readback(canvas);
	while (!cf_readback_ready(readback)) {}
	CF_Image image = { WIDTH, HEIGHT, (CF_Pixel*)malloc(sizeof(CF_Pixel) * WIDTH * HEIGHT) };
	cf_readback_data(readback, image.pix, (int)sizeof(CF_Pixel) * WIDTH * HEIGHT);
	void* png = NULL;
	int png_size = 0;
	if (!cf_is_error(cf_image_save_png_to_memory(&image, &png, &png_size))) {
		FILE* fp = fopen(path, "wb");
		if (fp) { fwrite(png, 1, (size_t)png_size, fp); fclose(fp); }
		cf_free(png);
	}
	free(image.pix);
	cf_destroy_readback(readback);
	cf_destroy_canvas(canvas);
}

/* Runs the warmup and measured frames and prints one JSON line of results. */
int main(int argc, char* argv[])
{
	Options o = parse_options(argc, argv);
	bool sprites = !strcmp(o.scene, "sprites");
	CF_Result result = cf_make_app("SpriteBenchC", 0, 0, 0, WIDTH, HEIGHT, CF_APP_OPTIONS_WINDOW_POS_CENTERED_BIT | (o.hidden ? CF_APP_OPTIONS_HIDDEN_BIT : 0), argv[0]);
	if (cf_is_error(result)) return 1;
	bool immediate = cf_app_set_present_mode(CF_PRESENT_MODE_IMMEDIATE);

	Entity* entities = sprites ? (Entity*)calloc((size_t)o.count, sizeof(Entity)) : NULL;
	if (sprites) make_entities(entities, o.count);
	double* submit_ms = (double*)malloc(sizeof(double) * (size_t)o.frames);
	double* frame_ms = (double*)malloc(sizeof(double) * (size_t)o.frames);
	double freq = (double)cf_get_tick_frequency();

	for (int f = 0; f < o.warmup + o.frames; ++f) {
		uint64_t t0 = cf_get_ticks();
		cf_app_update(NULL);
		uint64_t t1 = cf_get_ticks();
		if (sprites) step_sprites(entities, o.count);
		else draw_labels(o.count, f);
		uint64_t t2 = cf_get_ticks();
		cf_app_draw_onto_screen(true);
		uint64_t t3 = cf_get_ticks();
		if (f >= o.warmup) {
			submit_ms[f - o.warmup] = (double)(t2 - t1) / freq * 1000.0;
			frame_ms[f - o.warmup] = (double)(t3 - t0) / freq * 1000.0;
		}
	}
	if (o.screenshot) {
		cf_app_update(NULL);
		if (sprites) step_sprites(entities, o.count);
		else draw_labels(o.count, 0);
		write_screenshot(o.screenshot);
	}

	double checksum = sprites ? position_checksum(entities, o.count) : 0;
	printf("{\"impl\":\"c\",\"scene\":\"%s\",\"count\":%d,\"frames\":%d,\"immediate\":%s,\"checksum\":%.3f,", o.scene, o.count, o.frames, immediate ? "true" : "false", checksum);
	print_stats("submit_ms", submit_ms, o.frames);
	printf(",");
	print_stats("frame_ms", frame_ms, o.frames);
	printf("}\n");

	free(submit_ms);
	free(frame_ms);
	free(entities);
	cf_destroy_app();
	return 0;
}
