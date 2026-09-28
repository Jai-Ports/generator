#import "Basic";
Gizmo :: #import "imguizmo";

main :: () {
    Gizmo.initialize_program();
    translation := float32.[1, -2, 3];
    rotation := float32.[0, 0, 0];
    scale := float32.[2, 3, 4];
    matrix: [16] float32;
    Gizmo.recompose_matrix_from_components(translation.data, rotation.data, scale.data, matrix.data);
    assert(matrix[0] == 2 && matrix[5] == 3 && matrix[10] == 4 && matrix[15] == 1);
    assert(matrix[12] == 1 && matrix[13] == -2 && matrix[14] == 3);
    extracted_translation: [3] float32;
    extracted_rotation: [3] float32;
    extracted_scale: [3] float32;
    Gizmo.decompose_matrix_to_components(matrix.data, extracted_translation.data,
                                         extracted_rotation.data, extracted_scale.data);
    for index: 0..2 {
        assert(extracted_translation[index] == translation[index]);
        assert(extracted_scale[index] == scale[index]);
    }
    print("ImGuizmo matrix smoke verification passed\n");
}
