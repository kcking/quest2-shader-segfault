Minimal-ish reproduction of quest2 shader compiler segfault. This is mostly copied from the [vulkan openxr example](https://github.com/Ralith/openxrs/blob/master/openxr/examples/vulkan.rs).

It could also be tested by compiling `failing_shader.spv` as a vertex shader with entry point `vertex_fn`.

`failing_shader.spv` was compiled from `failing_shader.wgsl` using [`naga`](https://github.com/gfx-rs/naga).

`failing_shader.wgsl` is a post-preprocessing [bevy shader](https://github.com/bevyengine/bevy/blob/main/crates/bevy_pbr/src/render/depth.wgsl) for drawing shadows.
