const Builder = @import("std").build.Builder;

const for_wasm = true;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();

    const cflags = [_][]const u8{};

    const cfiles = [_][]const u8{
        "src/libAtomVM/externalterm.c",
        "src/libAtomVM/interop.c",
        "src/libAtomVM/bif.c",
        "src/libAtomVM/iff.c",
        "src/libAtomVM/dictionary.c",
        "src/libAtomVM/context.c",
        "src/libAtomVM/scheduler.c",
        "src/libAtomVM/memory.c",
        "src/libAtomVM/debug.c",
        "src/libAtomVM/port.c",
        "src/libAtomVM/term.c",
        "src/libAtomVM/globalcontext.c",
        "src/libAtomVM/valueshashtable.c",
        "src/libAtomVM/mailbox.c",
        "src/libAtomVM/module.c",
        "src/libAtomVM/atomshashtable.c",
        "src/libAtomVM/defaultatoms.c",
        "src/libAtomVM/network.c",
        "src/libAtomVM/nifs.c",
        "src/libAtomVM/avmpack.c",
        "src/libAtomVM/bitstring.c",
        "src/libAtomVM/atom.c",
        "src/libAtomVM/timer_wheel.c",
        //"src/platforms/generic_unix/socket_driver.c",
        //"src/platforms/generic_unix/network_driver.c",
        "src/platforms/generic_unix/mapped_file.c",
        "src/platforms/generic_unix/platform_defaultatoms.c",
        "src/platforms/wasm32/sys.c",
        "src/platforms/generic_unix/gpio_driver.c",
        "src/platforms/generic_unix/platform_nifs.c",
        "src/main.c",
    };

    if (for_wasm) {
        const lib = b.addStaticLibrary("AtomVMzig", "AtomVM.zig");

        lib.defineCMacro("__wasi__");
        lib.defineCMacro("_WASI_EMULATED_MMAN");
        lib.defineCMacro("_WASI_EMULATED_SIGNAL");

        // stolen from wasi-libc/sysroot/include after you run
        // make on the wasi-libc.
        lib.addSystemIncludeDir("src/platforms/wasm32/include");

        // stolen from wasi-libc/libc-top-half/musl/arch/generic.
        lib.addIncludeDir("src/platforms/wasm32/generic");
        lib.addIncludeDir("build/src/libAtomVM/");
        lib.addIncludeDir("src/libAtomVM/");
        lib.setBuildMode(mode);

        lib.setTarget(.{
            .cpu_arch = .wasm32,
            .os_tag = .freestanding,
            .abi = .none,
        });

        lib.strip = true;

        for (cfiles) |c_file| {
            lib.addCSourceFile(c_file, &cflags);
        }

        b.default_step.dependOn(&lib.step);

        b.installArtifact(lib);

    } else {

        const target = b.standardTargetOptions(.{});
        const exe = b.addExecutable("AtomVMzig", null);

        exe.linkSystemLibrary("c");

        // there are a couple of header files that are autogenerated by cmake that we need to
        // build in here.  Eventually we should figure out how to autogenerate those otherwise.
        exe.addIncludeDir("build/src/libAtomVM/");
        exe.addIncludeDir("src/libAtomVM/");
        exe.setBuildMode(mode);

        for (cfiles) |c_file| {
            exe.addCSourceFile(c_file, &cflags);
        }

        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());

        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);

    }
}
