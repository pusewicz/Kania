// Swift port of CF's samples/hello_triangle.c: one mesh, one shader, drawn with the low-level
// graphics API. `--frames N` exits after N frames and `--screenshot path` saves the last one.
import CCute
import SpikeSupport

struct Vertex {
  var position: CF_V2
  var color: CF_Pixel
}

let vertexShader = """
  layout (location = 0) in vec2 in_pos;
  layout (location = 1) in vec4 in_col;

  layout (location = 0) out vec4 v_col;

  void main()
  {
    v_col = in_col;
    gl_Position = vec4(in_pos, 0, 1);
  }
  """

let fragmentShader = """
  layout(location = 0) in vec4 v_col;

  layout(location = 0) out vec4 result;

  void main()
  {
    result = v_col;
  }
  """

let options = SpikeOptions(allowed: ["frames", "screenshot"])
let frameLimit = options.int("frames", default: 0)
let screenshotPath = options.optionalString("screenshot")

let result = cf_make_app(
  "Hello Triangle", 0, 0, 0, 640, 480, CF_AppOptionFlags(CF_APP_OPTIONS_WINDOW_POS_CENTERED_BIT.rawValue),
  CommandLine.unsafeArgv[0])
guard !cf_is_error(result) else { fatalError("cf_make_app failed") }

var vertices = [
  Vertex(position: CF_V2(x: -1, y: -1), color: cf_pixel_red()),
  Vertex(position: CF_V2(x: 1, y: -1), color: cf_pixel_blue()),
  Vertex(position: CF_V2(x: 0, y: 1), color: cf_pixel_green()),
]

let mesh = "in_pos".withCString { position in
  "in_col".withCString { color in
    var attributes = [
      CF_VertexAttribute(
        name: position, format: CF_VERTEX_FORMAT_FLOAT2,
        offset: Int32(MemoryLayout<Vertex>.offset(of: \.position)!), per_instance: false),
      CF_VertexAttribute(
        name: color, format: CF_VERTEX_FORMAT_UBYTE4_NORM,
        offset: Int32(MemoryLayout<Vertex>.offset(of: \.color)!), per_instance: false),
    ]
    return cf_make_mesh(
      Int32(MemoryLayout<Vertex>.stride * vertices.count), &attributes, Int32(attributes.count),
      Int32(MemoryLayout<Vertex>.stride))
  }
}
cf_mesh_update_vertex_data(mesh, &vertices, Int32(vertices.count))

let material = cf_make_material()
let shader = cf_make_shader_from_source(vertexShader, fragmentShader)

var frame = 0
while cf_app_is_running() {
  cf_app_update(nil)
  frame += 1
  let lastFrame = frameLimit > 0 && frame >= frameLimit
  let offscreen = lastFrame && screenshotPath != nil ? cf_make_canvas(cf_canvas_defaults(640, 480)) : nil
  cf_apply_canvas(offscreen ?? cf_app_get_canvas(), true)
  cf_apply_mesh(mesh)
  cf_apply_shader(shader, material)
  cf_draw_elements()
  cf_app_draw_onto_screen(false)
  if let offscreen, let screenshotPath {
    savePNG(of: offscreen, width: 640, height: 480, to: screenshotPath)
    cf_destroy_canvas(offscreen)
  }
  if lastFrame { break }
}

cf_destroy_shader(shader)
cf_destroy_material(material)
cf_destroy_mesh(mesh)
cf_destroy_app()
