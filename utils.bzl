def extract(rule, path):
  name = 'extract-' + (
    rule.replace(':','') + '-' + 
    path
      .replace('/','-')
      .replace('.','-'))
    
  if not native.rule_exists(':'+name):
    filename = path.split('/')[-1]
    native.genrule(
      name = name,
      out = filename,
      cmd = 'cp $(location '+rule+')/'+ path +' $OUT')
    
  return ':'+name

def extractFolder(rule, path):
  name = 'extract-folder-' + (
    rule.replace(':','') + '-' + 
    path
      .replace('/','-')
      .replace('.','-'))
    
  if not native.rule_exists(':'+name):
    native.genrule(
      name = name,
      out = 'out',
      cmd = 'mkdir $OUT && cd $OUT && cp -r $(location '+rule+')/'+ path +'/. .')
    
  return ':'+name

def pkgconfig(name, find, search = None, visibility = []):
  env = 'PKG_CONFIG_PATH=' + search + ' ' if search else '' 

  native.genrule(
    name = name+'-flags',
    out = 'out.txt',
    cmd = env + 'pkg-config ' + find + ' --cflags > $OUT')

  native.genrule(
    name = name+'-linker',
    out = 'out.txt',
    cmd = env + 'pkg-config ' + find + ' --libs > $OUT')

  native.prebuilt_cxx_library(
    name = name,
    header_namespace = '',
      header_only = True,
      exported_preprocessor_flags = [
        '@$(location :'+name+'-flags)',
      ],
      exported_linker_flags = [
        '@$(location :'+name+'-linker)',
      ],
      visibility = visibility)


def cmake(name, srcs = [], options = [], targets = [], out = 'build', prefix = 'ROOT', jobs = 1): 
  native.genrule(
    name = name,
    srcs = srcs,
    out = out,
    cmd = ' && '.join([
      'mkdir $OUT $OUT/'+prefix,
      'cd $OUT',
      'cmake -DCMAKE_INSTALL_PREFIX:PATH=$OUT/' + prefix + ' '.join(options)+ ' $SRCDIR'] + 
      (['make -j'+ jobs + ' '.join(targets) ] if len(targets) else [])
    ))
