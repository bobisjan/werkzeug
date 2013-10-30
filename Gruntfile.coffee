module.exports = (grunt) ->
  bowerDir = '.bower_components'
  closureLibDir = bowerDir + '/closure-library'

  appDirs = [
    closureLibDir
    'var/wzk'
  ]

  coffeeFiles = [
    'wzk/**/*.coffee'
  ]

  appCompiledOutputPath =
    'var/app.js'

  depsPath =
    'var/wzk/deps.js'

  # from closure base.js dir to app root dir
  depsPrefix = '../'

  getCoffeeConfig = (filepath = coffeeFiles) ->
    [
      expand: true
      src: filepath
      dest: 'var/'
      ext: '.js'
    ]

  grunt.initConfig

    clean:
      all:
        options:
          force: true
        src: [
          'var/wzk/**/*.js'
        ]

    coffee:
      all:
        options:
          bare: true
        files: [
          expand: true
          src: coffeeFiles
          dest: 'var/'
          ext: '.js'
        ]

    coffee2closure:
      all:
        files: [
          expand: true
          src: 'var/wzk/**/*.js'
          ext: '.js'
        ]

    esteDeps:
      all:
        options:
          depsWriterPath: closureLibDir + '/closure/bin/build/depswriter.py'
          outputFile: depsPath
          prefix: depsPrefix
          root: appDirs

    esteBuilder:
      options:
        closureBuilderPath: closureLibDir+ '/closure/bin/build/closurebuilder.py'
        compilerPath: bowerDir + '/closure-compiler/compiler.jar'
        # needs Java 1.7+, see http://goo.gl/iS3o6
        fastCompilation: true
        root: '<%= esteDeps.all.options.root %>'
        depsPath: '<%= esteDeps.all.options.outputFile %>'
        compilerFlags: if grunt.option('stage') == 'debug' then [
          '--output_wrapper="(function(){%output%})();"'
          '--compilation_level="ADVANCED_OPTIMIZATIONS"'
          '--warning_level="VERBOSE"'
          '--define=goog.DEBUG=true'
          '--debug=true'
          '--formatting="PRETTY_PRINT"'
        ]
        else [
            '--output_wrapper="(function(){%output%})();"'
            '--compilation_level="ADVANCED_OPTIMIZATIONS"'
            '--warning_level="VERBOSE"'
            '--define=goog.DEBUG=false'
          ]

      all:
        options:
          namespace: '*'
          outputFilePath: appCompiledOutputPath

    esteUnitTests:
      options:
        basePath: closureLibDir + '/closure/goog/base.js'
      all:
        options:
          depsPath: '<%= esteDeps.all.options.outputFile %>'
          prefix: '<%= esteDeps.all.options.prefix %>'
        src: [
          'var/wzk/**/*_test.js'
        ]

    esteWatch:
      options:
        dirs: [
          closureLibDir + '/**/'
          'wzk/**/'
          'var/wzk/**/'
        ]

      coffee: (filepath) ->
        config = getCoffeeConfig(filepath)
        grunt.config ['coffee', 'app', 'files'], config
        grunt.config ['coffee2closure', 'app', 'files'], config
        ['coffee:app', 'coffee2closure:app']

      js: (filepath) ->
        grunt.config ['esteDeps', 'all', 'src'], filepath
        grunt.config ['esteUnitTests', 'app', 'src'], filepath
        ['esteDeps:all', 'esteUnitTests:app']

    coffeelint:
      options:
        no_backticks:
          level: 'ignore'
        max_line_length:
          level: 'ignore'
        line_endings:
          value: 'unix'
          level: 'error'
        no_empty_param_list:
          level: 'warn'
      all:
        files: [
          expand: true
          src: coffeeFiles
          ext: '.js'
        ]

  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-este-watch'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-este'
  grunt.loadNpmTasks 'grunt-este-watch'

  grunt.registerTask 'build', 'Build app.', ->
    tasks = [
      "clean"
      "coffee"
      "coffee2closure"
      "coffeelint"
      "esteDeps"
      "esteUnitTests"
      "esteBuilder"
    ]
    grunt.task.run tasks

  grunt.registerTask 'run', 'Build app and run watchers.', ->
    tasks = [
      "clean"
      "coffee"
      "coffee2closure"
      "coffeelint"
      "esteDeps"
      "esteUnitTests"
      "esteWatch"
    ]
    grunt.task.run tasks

  grunt.registerTask 'default', 'run:app'

  grunt.registerTask 'test', 'build:app'
