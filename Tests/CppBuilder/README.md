# C++Builder header check

A small C++Builder console project that checks the `.hpp` files generated from the TaurusTLS sources. Run it after changing anything that affects what C++Builder sees, such as `{$EXTERNALSYM}`, `{$HPPEMIT}` or `{$NODEFINE}` directives, or public declarations.

## Why this exists

C++Builder code uses TaurusTLS through `.hpp` files that the Delphi compiler generates. Problems in them only show up when a C++ file includes them, which Delphi builds never do. Issue #241 was one example: the headers did not compile at all, and a C++Builder user found out after installing the packages.

## What it checks

The pre-build step, `GenerateHpp.bat`, regenerates the headers from `Source` for the selected platform. It uses the unit list of the run-time package, `Packages\d13\TaurusTLS_RT.dpk`, so new units are picked up automatically.

`HppCheck.cpp` then:

* includes the header of every unit in that package, so each one must compile
* checks, at compile time, that symbols C++Builder code needs are declared: component classes, Pascal-only aliases and helpers, OpenSSL types and entry points, and constants (whose values are compared with OpenSSL's)

Nothing is called, so the program does not link against TaurusTLS or Indy. It prints a line and exits with 0 when everything passes; any problem is a compile error.

## Running it

### In the IDE

Open `HppCheck.cbproj`, choose a platform (Win32, Win64 or Win64x) and build. If TwineCompile is installed, the IDE uses it automatically.

If your Indy is not the one installed with RAD Studio, set the variables described below under *Tools > Options > IDE > Environment Variables*.

### From the command line

```
build.bat [Win32|Win64|Win64x|all] [Debug|Release]
```

Run it from a RAD Studio Command Prompt, or from any prompt; it finds `rsvars.bat` itself. The default is `Win32 Debug`.

`build.bat` uses TwineCompile's `jtmake` when it is installed (on `PATH` or in its default folder), and MSBuild otherwise. Set `HPPCHECK_USE_MSBUILD=1` to use MSBuild anyway.

`GenerateHpp.bat` prints its errors as `GenerateHpp : error : ...`, which MSBuild and the IDE report as build errors. When you run it on its own in a console, errors are also shown in red; set `NO_COLOR` to turn that off.

## Which Indy is used

| Setting | Indy used |
|---|---|
| nothing | The Indy installed with RAD Studio |
| `INDY_PATH` | An Indy source checkout, compiled from source. This is the same variable the TaurusTLS package projects use. |
| `INDY_DCU` and `INDY_HPP` | Prebuilt Indy `.dcu` and `.hpp` folders. Both may contain `{platform}`, which is replaced by `Win32`, `Win64` or `Win64x`. |

For example, when RAD Studio's Indy has been moved into `Indy10` subfolders:

```
set INDY_DCU=C:\Program Files (x86)\Embarcadero\Studio\37.0\lib\{platform}\release\Indy10
set INDY_HPP=C:\Program Files (x86)\Embarcadero\Studio\37.0\include\windows\rtl\Indy10
build.bat all
```

## Link models

By default the headers are generated for the dynamic link model, where TaurusTLS loads OpenSSL at run time. This is TaurusTLS's default on Windows.

Set `HPPCHECK_STATIC=1` to check the static link model instead. On Windows that model can only be selected by editing `TaurusTLSCompilerDefines.inc` (a `-D` switch is not enough), so `GenerateHpp.bat` generates from a copy of `Source` with `OPENSSL_USE_SHARED_LIBRARY` switched on. Your working tree is not changed.

Other dcc options can be passed in `HPPCHECK_DCC_OPTIONS`.

## Without implicit namespace use

Each generated header ends with `using namespace` for its unit, so C++ code can use the names without qualifying them. Projects that define `DELPHIHEADER_NO_IMPLICIT_NAMESPACE_USE` turn that off, usually to avoid name clashes.

`HppCheck.cpp` compiles either way. When the define is set, the `no_implicit_namespace` block at the top brings each name the checks use into scope from its unit, for example `using Taurustlsheaders_ssl::SSL_CTX_new;`. So that build also checks that each name is declared in the unit where C++ code would look for it.

To check this case:

* In the IDE, add `DELPHIHEADER_NO_IMPLICIT_NAMESPACE_USE` to the project's conditional defines (*Project > Options > C++ (Shared Options) > Conditional defines*).
* From the command line, set it before running `build.bat`. MSBuild and TwineCompile both add it to the project's defines:

  ```
  set Defines=DELPHIHEADER_NO_IMPLICIT_NAMESPACE_USE
  build.bat all
  ```

## Adding checks

Add lines to `HppCheck.cpp`:

```cpp
REQUIRE_TYPE(PX509_STORE);                       // a type must be declared
REQUIRE_SYMBOL(SSL_CTX_new);                     // a routine or variable must be declared
static_assert(NID_sha256 == 672, "NID_sha256");  // a constant and its value
```

For each new name, also add a `using` line for it to the `no_implicit_namespace` block, naming the unit that declares it. Otherwise only the build without implicit namespace use fails.

Use names that exist in both link models, or the static build will fail. For example, the `Tsk_*_free` callback types are only declared in the dynamic model.

## Known issues

Some names are declared in two units: 163 constants (mostly `*_F_*` and `*_R_*` error codes declared both in a unit and in its `*err` unit), 9 types such as `PCONF` and `POSSL_PARAM`, and `ERR_load_CT_strings`. C++ reports an unqualified use of one of these as ambiguous. Qualify it with the unit namespace, as `HppCheck.cpp` does for `Taurustlsheaders_tls1::TLS1_2_VERSION`.

Including OpenSSL's own C headers in the same file as the TaurusTLS headers is not supported and is not checked here.

## Files

| File | Purpose |
|---|---|
| `HppCheck.cbproj` | The C++Builder project |
| `HppCheck.cpp` | The checks |
| `GenerateHpp.bat` | Pre-build step that generates the headers into `gen\<platform>` |
| `build.bat` | Command-line build and run |
