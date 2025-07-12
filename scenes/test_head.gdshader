shader_type spatial;

uniform mat4 camera_transform;

void vertex() {
    // Simplificado: elimina rotación de la matriz modelo para que siempre mire a la cámara
    vec3 pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    vec3 cam_right = vec3(camera_transform[0][0], camera_transform[1][0], camera_transform[2][0]);
    vec3 cam_up = vec3(camera_transform[0][1], camera_transform[1][1], camera_transform[2][1]);

    vec3 offset = cam_right * VERTEX.x + cam_up * VERTEX.y;
    VERTEX = pos + offset;
}

void fragment() {
    ALBEDO = COLOR.rgb;
    ALPHA = COLOR.a;
}
