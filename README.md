# utils.bzl
skylark utils for packaging tasks

Some handy functions for common packaging tasks for Skylark based buildsystems eg. Buck and Bazel.

## extract(rule, path)

extracts file from a given rule

### example

```python
load('//:utils.bzl', 'extract')

genrule(
  name = 'gen',
  out = 'out',
  cmd = 'mkdir $OUT && touch $OUT/foo.h && touch $OUT/foo.cpp'
)

cxx_library(
  name = 'foo',
  srcs = [extract(':gen', 'foo.cpp')]
  exported_headers = {
    'foo.h' : extract(':gen', 'foo.h')
  }
)
```

## extractFolder(rule, path)

```python
genrule(
  name = 'gen',
  out = 'out',
  cmd = 'mkdir -p $OUT/include/foo && touch $OUT/include/foo/foo.h && touch $OUT/include/foo/bar.h'
)

prebuilt_cxx_library(
  name = 'foo',
  header_only = True,
  header_dirs = [
    extractFolder(':gen', 'include')
  ]
)
```

## pkgconfig(name, find, search)

generates a `prebuilt_cxx_library` using pkgconfig.

*find* specifies the pkgconfig library name. 
As per convention it will look for `*.pc`

*search* specifies the searchPath. It can be a macro, relative or absolute paths.

We advise against using absolute paths eg. `/usr/lib` to fetch system-libraries as this will make builds irreproducible.


### example

```python

genrule(
  name = 'gen',
  out = 'out',
  cmd = '...'
)

pkgconfig(
  name = 'mylib',
  find = 'mylib-c'
  search = '$(location :gen)/lib/pkgconfig'
)
```

## cmake(name, srcs,  prefix = 'ROOT', options = [], targets = [])

creates a wrapper for cmake builds.

*srcs* all files required for cmake to run. 
The more precise you are the better as it will improve unnecessary rebuilts.

*prefix* defines the prefix that will be used when an `install` is performed.
The install folder can then be used for `extract`ing indidual files and folders.

*options* extra cmake options that will be supplied to the cmake configure call.

*targets* set of build targets. 
No build is performed if not specified. 
This comes handy if you only need the generated `config.h`.

A common target is `install` that will create a distributatble version of the library.


### Examples

```python
cmake(
  name = 'config',
  srcs = glob(['CMakeLists.txt', 'version.cpp.in', 'src/**/*.cpp'])  
)

cxx_library(
  name = 'lib',
  header_namespace = '',
  srcs = glob(['srcs/**/*.cpp']) + [extract(':config', 'version.cpp')],
  exported_headers = subdir_glob([
    ('include', '**/*.h')
  ])
)
```



```python

cmake(
  name = 'xerces-cmake',
  prefix = 'dist',
  targets = ['install'],
  srcs = glob([
    'cmake/**',
    'config/**',
    'doc/**',
    'src/**',
    'samples/**',
    'scripts/**',
    'tools/**',
    'tests/**',
    '*.txt',
    '*.in',
    '*.ac'
  ])
)

prebuilt_cxx_library(
  name = 'xerces',
  header_namespace = '',
  preferred_linkage = 'shared',
  shared_lib = extract(':xerces-cmake', 'dist/lib/libxerces-c.so'),
  header_dirs = [ 
    extractFolder(':xerces-cmake', 'dist/include')
  ],
)


pkgconfig(
  name = 'xerces',
  find = 'xerces-c',
  search = '$(location :xerces-cmake)/dist/lib/pkgconfig'
)

cxx_binary(
  name = 'count',
  srcs = ['samples/src/DOMCount/DOMCount.cpp'],
  headers = {'DOMCount.hpp': 'samples/src/DOMCount/DOMCount.hpp'},
  deps = [':xerces']
)

```



