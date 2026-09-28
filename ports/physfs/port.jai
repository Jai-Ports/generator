physfs_port :: () -> Port_Spec {
    return .{
        name = "physfs",
        upstream_url = "https://github.com/icculus/physfs.git",
        upstream_commit = "ccffd00e1202a4fbd655f7c84171eee6182d9a53",
        upstream_label = "upstream/physfs",
        license_file = "LICENSE.txt",
        language = .C,
        standard = "gnu11",
        include_directories = string.["src"],
        compiler_flags = string.["-fwrapv", "-ffp-contract=off"],
        modules = Port_Module_Spec.[.{
            output_path = "",
            transpiler_prefix = "physfs",
            source_files = string.["src/physfs.c", "src/physfs_byteorder.c", "src/physfs_unicode.c", "src/physfs_platform_posix.c", "src/physfs_platform_unix.c", "src/physfs_archiver_7z.c", "src/physfs_archiver_csm.c", "src/physfs_archiver_dir.c", "src/physfs_archiver_grp.c", "src/physfs_archiver_hog.c", "src/physfs_archiver_iso9660.c", "src/physfs_archiver_lec3d.c", "src/physfs_archiver_mvl.c", "src/physfs_archiver_pod.c", "src/physfs_archiver_qpak.c", "src/physfs_archiver_rofs.c", "src/physfs_archiver_slb.c", "src/physfs_archiver_unpacked.c", "src/physfs_archiver_vdf.c", "src/physfs_archiver_wad.c", "src/physfs_archiver_zip.c"],
            defines = string.[],
            generated_entry = "cpp_transpiler_program.jai",
        }],
        output_url = "git@github.com:Jai-Ports/physfs.git",
        supported_target = "linux-x64",
    };
}
