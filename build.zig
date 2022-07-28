const std = @import("std");
const print = std.debug.print;

fn build_single(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.Mode, test_all_step: *std.build.Step, exe_name: []const u8, root_src: []const u8, step_name: []const u8) void {
    const exe = b.addExecutable(exe_name, root_src);
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(step_name, exe_name);
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest(root_src);
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    test_all_step.dependOn(&exe_tests.step);
}

fn extractUnsigned(input: []const u8) ?u32 {
    var start: ?usize = null;
    var end: ?usize = null;
    for (input) |c, i| {
        if (start == null) {
            if (c >= '0' and c <= '9') {
                start = i;
            }
        } else if (c >= '0' and c <= '9') {
            end = i;
        } else {
            end = i;
            break;
        }
    }

    if (start != null and end != null) {
        return std.fmt.parseUnsigned(u32, input[start.?..end.?], 10) catch null;
    }

    return null;
}

fn strEndsWith(input: []const u8, match: []const u8) bool {
    if (input.len < match.len) {
        return false;
    }

    for (input[input.len - match.len ..]) |c, i| {
        if (c != match[i]) {
            return false;
        }
    }

    return true;
}

pub fn build(b: *std.build.Builder) !void {
    // Here we use an ArenaAllocator backed by a DirectAllocator because a build is a short-lived,
    // one shot program. We don't need to waste time freeing memory and finding places to squish
    // bytes into. So we free everything all at once at the very end.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const test_all_step = b.step("test", "Run all unit tests");

    {
        const dir_root = "./src/";
        var src_dir = try std.fs.cwd().openIterableDir(dir_root, .{});
        defer src_dir.close();

        var dir_iter = src_dir.iterate();
        var entry = try dir_iter.next();
        while (entry != null) : (entry = try dir_iter.next()) {
            if (!strEndsWith(entry.?.name, ".zig")) {
                continue;
            }

            const filepath = try std.mem.concat(allocator, u8, &[_][]const u8{
                dir_root,
                entry.?.name,
            });
            // defer allocator.free(filepath);  // No need to free in build.zig

            const step_n = extractUnsigned(entry.?.name);
            // print("Source {d}: {s}\n", .{ step_n, filepath });

            const step_name = if (step_n == null) entry.?.name else try std.fmt.allocPrint(allocator, "{d}", .{step_n});

            build_single(b, target, mode, test_all_step, entry.?.name, filepath, step_name);
        }
    }
}
