const std = @import("std");
const wasm = @import("wasm");

const ByteVec = wasm.ByteVec;
const Engine = wasm.Engine;
const Store = wasm.Store;
const Module = wasm.Module;
const Instance = wasm.Instance;
const Extern = wasm.Extern;
const ExternVec = wasm.ExternVec;
const Trap = wasm.Trap;
const Func = wasm.Func;
const ImporttypeVec = wasm.ImporttypeVec;
const ExternType = wasm.ExternType;

pub const NamedExtern = extern struct {
    module: ByteVec,
    name: ByteVec,
    @"extern": *Extern,
};

pub const NamedExternVec = extern struct {
    size: usize,
    data: [*]?*NamedExtern,

    pub fn init(initial: []NamedExtern) NamedExternVec {
        var vec: NamedExternVec = undefined;
        wasmer_named_extern_vec_new(&vec, initial.len, initial.ptr);
        return vec;
    }

    pub fn initWithCapacity(size: usize) NamedExternVec {
        var vec: NamedExternVec = undefined;
        wasmer_named_extern_vec_new_uninitialized(&vec, size);
        return vec;
    }

    pub fn initEmpty() NamedExternVec {
        var vec: NamedExternVec = undefined;
        wasmer_named_extern_vec_new_empty(&vec);
        return vec;
    }

    pub fn deinit(self: *NamedExternVec) void {
        wasmer_named_extern_vec_delete(self);
    }

    // TODO: Copy

    extern "c" fn wasmer_named_extern_vec_new(?*NamedExternVec, usize, [*]?*NamedExtern) void;
    extern "c" fn wasmer_named_extern_vec_new_empty(?*NamedExternVec) void;
    extern "c" fn wasmer_named_extern_vec_new_uninitialized(?*NamedExternVec, usize) void;
    extern "c" fn wasmer_named_extern_vec_copy(?*NamedExternVec, ?*const NamedExternVec) void;
    extern "c" fn wasmer_named_extern_vec_delete(?*NamedExternVec) void;
};

pub const WasiConfig = opaque {
    /// Options to inherit when inherriting configs
    /// By default all is `true` as you often want to
    /// inherit everything rather than something specifically.
    const InheritOptions = struct {
        argv: bool = true,
        env: bool = true,
        std_in: bool = true,
        std_out: bool = true,
        std_err: bool = true,
    };

    pub fn init() !*WasiConfig {
        return wasi_config_new() orelse error.ConfigInit;
    }

    pub fn deinit(self: *WasiConfig) void {
        wasi_config_delete(self);
    }

    /// Allows to inherit the native environment into the current config.
    /// Inherits everything by default.
    pub fn inherit(self: *WasiConfig, options: InheritOptions) void {
        if (options.argv) self.inheritArgv();
        if (options.env) self.inheritEnv();
        if (options.std_in) self.inheritStdIn();
        if (options.std_out) self.inheritStdOut();
        if (options.std_err) self.inheritStdErr();
    }

    pub fn inheritArgv(self: *WasiConfig) void {
        _ = self;
        // wasi_config_inherit_argv(self);
    }

    pub fn inheritEnv(self: *WasiConfig) void {
        _ = self;
        // wasi_config_inherit_env(self);
    }

    pub fn inheritStdIn(self: *WasiConfig) void {
        wasi_config_inherit_stdin(self);
    }

    pub fn inheritStdOut(self: *WasiConfig) void {
        wasi_config_inherit_stdout(self);
    }

    pub fn inheritStdErr(self: *WasiConfig) void {
        wasi_config_inherit_stderr(self);
    }

    pub fn setEnv(self: *WasiConfig, key: []const u8, value: []const u8) void {
        wasi_config_env(self, key, value);
    }

    pub fn setArg(self: *WasiConfig, value: []const u8) void {
        wasi_config_arg(self, value);
    }

    pub fn mapDir(self: *WasiConfig, alias: []const u8, dir: []const u8) void {
        wasi_config_mapdir(self, alias, dir);
    }

    pub fn preopenDir(self: *WasiConfig, dir: []const u8) void {
        wasi_config_preopen_dir(self, dir);
    }

    extern "c" fn wasi_config_new() ?*WasiConfig;
    extern "c" fn wasi_config_delete(?*WasiConfig) void;

    extern "c" fn wasi_config_inherit_stdin(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_stdout(?*WasiConfig) void;
    extern "c" fn wasi_config_inherit_stderr(?*WasiConfig) void;

    extern "c" fn wasi_config_capture_stdout(?*WasiConfig) void;
    extern "c" fn wasi_config_capture_stderr(?*WasiConfig) void;

    extern "c" fn wasi_config_arg(?*WasiConfig, value: [*c]const u8) void;
    extern "c" fn wasi_config_env(?*WasiConfig, key: [*c]const u8, value: [*c]const u8) void;

    extern "c" fn wasi_config_mapdir(?*WasiConfig, alias: [*c]const u8, dir: [*c]const u8) void;
    extern "c" fn wasi_config_preopen_dir(?*WasiConfig, dir: [*c]const u8) void;
};

pub const WasiEnv = opaque {
    pub fn init(config: ?*WasiConfig) !*WasiEnv {
        return wasi_env_new(config) orelse error.EnvInit;
    }

    pub fn deinit(self: *WasiEnv) void {
        wasi_env_delete(self);
    }

    pub fn getImports(self: *WasiEnv, store: *Store, module: *Module) ExternVec {
        var imports: ExternVec = ExternVec.empty();
        wasi_get_imports(store, module, self, &imports);
        return imports;
    }

    pub fn getUnorderedImports(self: *WasiEnv, store: *Store, module: *Module) NamedExternVec {
        var imports: NamedExternVec = NamedExternVec.initEmpty();
        // TODO: error here
        _ = wasi_get_unordered_imports(store, module, self, &imports);
        return imports;
    }

    pub fn getStartFn(_: *WasiEnv, instance: *Instance) *Func {
        return wasi_get_start_function(instance);
    }

    extern "c" fn wasi_env_new(?*WasiConfig) ?*WasiEnv;
    extern "c" fn wasi_env_delete(?*WasiEnv) void;
    extern "c" fn wasi_env_read_stdout(?*WasiConfig, buffer: [*]u8, bufferSize: usize) isize;
    extern "c" fn wasi_env_read_stderr(?*WasiConfig, buffer: [*]u8, bufferSize: usize) isize;

    // TODO: Where do these live?
    extern "c" fn wasi_get_imports(store: *Store, module: *Module, wasi_env: *WasiEnv, imports: *ExternVec) void;
    extern "c" fn wasi_get_unordered_imports(store: *Store, module: *Module, wasi_env: *WasiEnv, imports: *NamedExternVec) bool;
    extern "c" fn wasi_get_start_function(instance: *Instance) *Func;
};

pub const ImportObject = struct {
    externs: std.StringHashMap(std.StringHashMap(*Extern)),
    allocator: *std.mem.Allocator,

    pub fn init(allocator: *std.mem.Allocator) ImportObject {
        return .{
            .allocator = allocator,
            .externs = std.StringHashMap(std.StringHashMap(*Extern)).init(allocator.*),
        };
    }

    pub fn deinit(_: *ImportObject) void {}

    pub fn register(self: *ImportObject, mod: []const u8, name: []const u8, ext: *Extern) !void {
        const fetched_hashmap = try self.externs.getOrPut(mod);

        if (!fetched_hashmap.found_existing) {
            fetched_hashmap.value_ptr.* = std.StringHashMap(*Extern).init(self.allocator.*);
        }

        try fetched_hashmap.value_ptr.*.put(name, ext);
    }

    pub fn registerModule(self: *ImportObject, store: *Store, mod: []const u8, comptime library: type) !void {
        // TODO: Error on non structs
        comptime var decls = @typeInfo(library).Struct.decls;

        inline for (decls) |decl| {
            if (decl.is_pub) {
                switch (@typeInfo(@TypeOf(@field(library, decl.name)))) {
                    .Fn => |_| {
                        const func = try Func.init(store, @field(library, decl.name));
                        try self.register(mod, decl.name, func.asExtern());
                    },
                    else => continue,
                }
            }
        }
    }

    pub fn registerUnorderedWasi(self: *ImportObject, wasi_import: NamedExternVec) !void {
        var idx: usize = 0;
        while (idx < wasi_import.size) : (idx += 1) {
            const ty = wasi_import.data[idx].?.@"extern";
            try self.register(wasi_import.data[idx].?.module.toSlice(), wasi_import.data[idx].?.name.toSlice(), ty);
        }
    }

    pub fn retrieve(self: *ImportObject, mod: []const u8, name: []const u8) !*Extern {
        const fetched_hashmap = self.externs.get(mod);

        if (fetched_hashmap) |map| {
            return map.get(name).?;
        }

        return error.FuncInit;
    }

    pub fn externsForImports(self: *ImportObject, named_imports: *ImporttypeVec) !ExternVec {
        var vec = ExternVec.initWithCapacity(named_imports.size);

        var idx: usize = 0;
        var ptr = vec.data;
        while (idx < named_imports.size) : (idx += 1) {
            const it = named_imports.data[idx].?;

            ptr.* = try self.retrieve(it.module.toSlice(), it.name.toSlice());
            ptr += 1;
        }

        return vec;
    }
};
