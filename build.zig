const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const shared = b.addStaticLibrary(.{
        .name = "shared",
        .root_source_file = b.path("src/shared/shared.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(shared);

    for (0..6) |day| {
        for (0..2) |part| {
            const libName = try std.fmt.allocPrint(allocator, "day-{d}", .{day + 1});
            const partName = try std.fmt.allocPrint(allocator, "part{d}", .{part + 1});
            const execName = try std.fmt.allocPrint(allocator, "{s}-{s}", .{ libName, partName });
            const testName = try std.fmt.allocPrint(allocator, "test-{s}-{s}", .{ libName, partName });
            const sourceFile = try std.fmt.allocPrint(allocator, "src/{s}/{s}.zig", .{ libName, partName });

            defer allocator.free(libName);
            defer allocator.free(partName);
            defer allocator.free(execName);
            defer allocator.free(testName);
            defer allocator.free(sourceFile);

            const exe = b.addExecutable(.{
                .name = execName,
                .root_source_file = b.path(sourceFile),
                .target = target,
                .optimize = optimize,
            });

            b.installArtifact(exe);

            // This *creates* a Run step in the build graph, to be executed when another
            // step is evaluated that depends on it. The next line below will establish
            // such a dependency.
            const run_cmd = b.addRunArtifact(exe);

            // By making the run step depend on the install step, it will be run from the
            // installation directory rather than directly from within the cache directory.
            // This is not necessary, however, if the application depends on other installed
            // files, this ensures they will be present and in the expected location.
            run_cmd.step.dependOn(b.getInstallStep());

            // This creates a build step. It will be visible in the `zig build --help` menu,
            // and can be selected like this: `zig build run`
            // This will evaluate the `run` step rather than the default, which is "install".
            const run_step = b.step(execName, "");
            run_step.dependOn(&run_cmd.step);

            // Creates a step for unit testing. This only builds the test executable
            // but does not run it.
            const lib_unit_tests = b.addTest(.{
                .root_source_file = b.path(sourceFile),
                .target = target,
                .optimize = optimize,
            });

            const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

            // Similar to creating the run step earlier, this exposes a `test` step to
            // the `zig build --help` menu, providing a way for the user to request
            // running the unit tests.
            const test_step = b.step(testName, "");
            test_step.dependOn(&run_lib_unit_tests.step);
        }
    }

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/shared/shared.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
