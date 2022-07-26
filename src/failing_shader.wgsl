struct View {
    view_proj: mat4x4<f32>,
    inverse_view_proj: mat4x4<f32>,
    view: mat4x4<f32>,
    inverse_view: mat4x4<f32>,
    projection: mat4x4<f32>,
    inverse_projection: mat4x4<f32>,
    world_position: vec3<f32>,
    width: f32,
    height: f32,
};

struct PointLight {
    // For point lights: the lower-right 2x2 values of the projection matrix [2][2] [2][3] [3][2] [3][3]
    // For spot lights: the direction (x,z), spot_scale and spot_offset
    light_custom_data: vec4<f32>,
    color_inverse_square_range: vec4<f32>,
    position_radius: vec4<f32>,
    // 'flags' is a bit field indicating various options. u32 is 32 bits so we have up to 32 options.
    flags: u32,
    shadow_depth_bias: f32,
    shadow_normal_bias: f32,
    spot_light_tan_angle: f32,
};

let POINT_LIGHT_FLAGS_SHADOWS_ENABLED_BIT: u32   = 1u;
let POINT_LIGHT_FLAGS_SPOT_LIGHT_Y_NEGATIVE: u32 = 2u;

struct DirectionalLight {
    view_projection: mat4x4<f32>,
    color: vec4<f32>,
    direction_to_light: vec3<f32>,
    // 'flags' is a bit field indicating various options. u32 is 32 bits so we have up to 32 options.
    flags: u32,
    shadow_depth_bias: f32,
    shadow_normal_bias: f32,
};

let DIRECTIONAL_LIGHT_FLAGS_SHADOWS_ENABLED_BIT: u32 = 1u;

struct Lights {
    // NOTE: this array size must be kept in sync with the constants defined bevy_pbr2/src/render/light.rs
    directional_lights: array<DirectionalLight, 1u>,
    ambient_color: vec4<f32>,
    // x/y/z dimensions and n_clusters in w
    cluster_dimensions: vec4<u32>,
    // xy are vec2<f32>(cluster_dimensions.xy) / vec2<f32>(view.width, view.height)
    //
    // For perspective projections:
    // z is cluster_dimensions.z / log(far / near)
    // w is cluster_dimensions.z * log(near) / log(far / near)
    //
    // For orthographic projections:
    // NOTE: near and far are +ve but -z is infront of the camera
    // z is -near
    // w is cluster_dimensions.z / (-far - -near)
    cluster_factors: vec4<f32>,
    n_directional_lights: u32,
    spot_light_shadowmap_offset: i32,
};

struct PointLights {
    data: array<PointLight>,
};
struct ClusterLightIndexLists {
    data: array<u32>,
};
struct ClusterOffsetsAndCounts {
    data: array<vec4<u32>>,
};

struct Mesh {
    model: mat4x4<f32>,
    inverse_transpose_model: mat4x4<f32>,
    // 'flags' is a bit field indicating various options. u32 is 32 bits so we have up to 32 options.
    flags: u32,
};


let MESH_FLAGS_SHADOW_RECEIVER_BIT: u32 = 1u;

@group(0) @binding(0)
var<uniform> view: View;

@group(1) @binding(0)
var<uniform> mesh: Mesh;


// NOTE: Bindings must come before functions that use them!

fn mesh_position_local_to_world(model: mat4x4<f32>, vertex_position: vec4<f32>) -> vec4<f32> {
    return model * vertex_position;
}

fn mesh_position_world_to_clip(world_position: vec4<f32>) -> vec4<f32> {
    return view.view_proj * world_position;
}

// NOTE: The intermediate world_position assignment is important
// for precision purposes when using the 'equals' depth comparison
// function.
fn mesh_position_local_to_clip(model: mat4x4<f32>, vertex_position: vec4<f32>) -> vec4<f32> {
    let world_position = mesh_position_local_to_world(model, vertex_position);
    return mesh_position_world_to_clip(world_position);
}

fn mesh_normal_local_to_world(vertex_normal: vec3<f32>) -> vec3<f32> {
    return mat3x3<f32>(
        mesh.inverse_transpose_model[0].xyz,
        mesh.inverse_transpose_model[1].xyz,
        mesh.inverse_transpose_model[2].xyz
    ) * vertex_normal;
}

fn mesh_tangent_local_to_world(model: mat4x4<f32>, vertex_tangent: vec4<f32>) -> vec4<f32> {
    return vec4<f32>(
        mat3x3<f32>(
            model[0].xyz,
            model[1].xyz,
            model[2].xyz
        ) * vertex_tangent.xyz,
        vertex_tangent.w
    );
}

struct Vertex {
    @location(0) position: vec3<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
};

@vertex
fn vertex_fn(vin: Vertex) -> VertexOutput {
    var vout: VertexOutput;
    let model = mesh.model;

    vout.clip_position = mesh_position_local_to_clip(model, vec4<f32>(vin.position, 1.0));
    return vout;
}

