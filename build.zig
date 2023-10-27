const std = @import("std");

// TODO: coverage
const show_coverage = false;
const debug_print_build_info = false;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // CppUTest Framework
    const libcpputest = build_cpputest(b, target);
    b.installArtifact(libcpputest);

    // UnitTest
    const exe = b.addExecutable(.{
        .name = "CppUTestExamples",
        .target = target,
        .optimize = optimize,
    });

    exe.step.dependOn(&libcpputest.step);

    exe.linkLibC();
    exe.linkLibCpp();
    exe.linkLibrary(libcpputest);
    exe.addIncludePath(.{ .path = "include" });
    exe.addIncludePath(.{ .path = "examples/ApplicationLib" });
    exe.addIncludePath(.{ .path = "examples/AllTests" });

    // CPPUTEST_USE_GCOV, -lgcov
    exe.addCSourceFiles( &.{
        // the "application" to be put under test
        "examples/ApplicationLib/CircularBuffer.cpp",
        "examples/ApplicationLib/EventDispatcher.cpp",
        "examples/ApplicationLib/hello.c",
        "examples/ApplicationLib/Printer.cpp",

        // unit test cource code
        "examples/AllTests/AllTests.cpp",
        "examples/AllTests/CircularBufferTest.cpp",
        "examples/AllTests/EventDispatcherTest.cpp",
        "examples/AllTests/FEDemoTest.cpp",
        "examples/AllTests/HelloTest.cpp",
        "examples/AllTests/MockDocumentationTest.cpp",
        "examples/AllTests/PrinterTest.cpp",
    }, &.{
        "--coverage",

        // `--coverage` equivalent to the following (?):
        // "-fprofile-arcs",
        // "-ftest-coverage",
    });

    b.installArtifact(exe);

    if (debug_print_build_info) print_build_info(exe);


    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- -c -v <arg3> <argn>`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the example unit test");
    run_step.dependOn(&run_cmd.step);
}

fn build_cpputest(b: *std.Build, libtarget: std.zig.CrossTarget) *std.Build.CompileStep {
    const lib = b.addStaticLibrary(.{
        .name = "cpputest",
        .target = libtarget,
        .optimize = std.builtin.Mode.ReleaseSafe,
    });

    lib.linkLibCpp();
    lib.strip = true;

    lib.addIncludePath(.{ .path = "include"});

    if (debug_print_build_info) print_build_info(lib);

    const t = lib.target_info.target;

    lib.addCSourceFiles(
        &.{
            // CppUTest
            "src/CppUTest/CommandLineArguments.cpp",
            "src/CppUTest/CommandLineTestRunner.cpp",
            "src/CppUTest/JUnitTestOutput.cpp",
            "src/CppUTest/TeamCityTestOutput.cpp",
            "src/CppUTest/MemoryLeakDetector.cpp",
            "src/CppUTest/MemoryLeakWarningPlugin.cpp",
            "src/CppUTest/SimpleMutex.cpp",
            "src/CppUTest/SimpleString.cpp",
            "src/CppUTest/SimpleStringInternalCache.cpp",
            "src/CppUTest/TestFailure.cpp",
            "src/CppUTest/TestFilter.cpp",
            "src/CppUTest/TestHarness_c.cpp",
            "src/CppUTest/TestMemoryAllocator.cpp",
            "src/CppUTest/TestOutput.cpp",
            "src/CppUTest/TestPlugin.cpp",
            "src/CppUTest/TestRegistry.cpp",
            "src/CppUTest/TestResult.cpp",
            "src/CppUTest/TestTestingFixture.cpp",
            "src/CppUTest/Utest.cpp",

            // CppUTestExt
            "src/CppUTestExt/CodeMemoryReportFormatter.cpp",
            "src/CppUTestExt/GTest.cpp",
            "src/CppUTestExt/IEEE754ExceptionsPlugin.cpp",
            "src/CppUTestExt/MemoryReportAllocator.cpp",
            "src/CppUTestExt/MemoryReporterPlugin.cpp",
            "src/CppUTestExt/MemoryReportFormatter.cpp",
            "src/CppUTestExt/MockActualCall.cpp",
            "src/CppUTestExt/MockExpectedCall.cpp",
            "src/CppUTestExt/MockExpectedCallsList.cpp",
            "src/CppUTestExt/MockFailure.cpp",
            "src/CppUTestExt/MockNamedValue.cpp",
            "src/CppUTestExt/MockSupport.cpp",
            "src/CppUTestExt/MockSupportPlugin.cpp",
            "src/CppUTestExt/MockSupport_c.cpp",
            "src/CppUTestExt/OrderedTest.cpp",
        }, &.{
            "-Werror"
        });

    lib.addCSourceFiles(
        switch(t.os.tag) {
            .windows => &.{ "src/Platforms/Dos/UtestPlatform.cpp" },
            .linux, .macos => &.{ "src/Platforms/Gcc/UtestPlatform.cpp" },
            else => unreachable, // @panic("can only support Windows or Linux")
        }, &.{});

    return lib;
}

fn print_build_info(lib: *std.Build.CompileStep) void {
    // tested:
    // -Dtarget=x86-windows-gnu
    // -Dtarget=x86-linux-musl

    // untested:
    //  -Dtarget=aarch64-linux-musl
    //  -Dtarget=aarch64-macos-none
    //  -Dtarget=x86-macos-none
    std.debug.print("{s}:\n", .{lib.name});

    const t = lib.target_info.target;
    std.debug.print("  os/target: {}\n", .{t.os.tag});

    // -Doptimize=ReleaseFast
    // -Doptimize=ReleaseSafe
    std.debug.print("  release-mode: {}\n", .{lib.optimize});

}