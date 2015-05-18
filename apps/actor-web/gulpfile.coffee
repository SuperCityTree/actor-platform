argv = require('yargs').argv
assign = require 'lodash.assign'
autoprefixer = require 'gulp-autoprefixer'
browserify = require 'browserify'
buffer = require 'vinyl-buffer'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
connect = require 'gulp-connect'
gulp = require 'gulp'
gutil = require 'gulp-util'
gulpif = require 'gulp-if'
minifycss = require 'gulp-minify-css'
sass = require 'gulp-sass'
source = require 'vinyl-source-stream'
sourcemaps = require 'gulp-sourcemaps'
reactify = require 'reactify'
uglify = require 'gulp-uglify'
usemin = require 'gulp-usemin'
watchify = require 'watchify'

gulp.task 'coffee', ->
  gulp.src ['./app/**/*.coffee']
    .pipe sourcemaps.init()
      .pipe coffee({ bare: true }).on('error', gutil.log)
      .pipe uglify()
      .pipe concat 'app-coffee.js'
    .pipe sourcemaps.write './'
    .pipe gulp.dest './dist/assets/js/'
    .pipe connect.reload()


opts = assign({}, watchify.args, {
  entries: 'app/main.js',
  extensions: 'jsx',
  debug: !argv.production
})

bundler = browserify(opts)
bundler.transform(reactify)

jsBundleFile = 'app-js.js'

gulp.task 'browserify', ->
  watcher = watchify(bundler)

  watcher.on 'update', ->
    updateStart = Date.now()
    console.log('Browserify started')
    watcher.bundle()
      .pipe(source(jsBundleFile))
        ## uglify
      .pipe(gulp.dest('./dist/assets/js'))
      .pipe(connect.reload())
    console.log('Browserify ended', (Date.now() - updateStart) + 'ms')
  .bundle()
  .pipe(source(jsBundleFile))
  .pipe(gulp.dest('./dist/assets/js'))
  .pipe(connect.reload())

gulp.task 'sass', ->
  gulp.src ['./app/**/*.scss']
    .pipe sourcemaps.init()
      .pipe sass().on('error', gutil.log)
      .pipe autoprefixer()
      .pipe concat 'styles.css'
      .pipe minifycss()
    .pipe sourcemaps.write './'
    .pipe gulp.dest './dist/assets/css/'
    .pipe connect.reload()

gulp.task 'html', ->
  gulp.src ['./app/**/*.html']
    .pipe gulp.dest './dist/app/'
    .pipe connect.reload()
  gulp.src ['./index.html']
    .pipe gulp.dest './dist/'
    .pipe connect.reload()


gulp.task 'watch', ['server'], ->
  gulp.watch ['./app/**/*.coffee'], ['coffee']
  gulp.watch ['./app/**/*.scss'], ['sass']
  gulp.watch ['./index.html', './app/**/*.html'], ['html']

gulp.task 'assets', ->
  gulp.src ['./assets/**/*']
    .pipe gulp.dest './dist/assets/'
  gulp.src ['./ActorMessenger/**/*.js']
    .pipe gulp.dest './dist/ActorMessenger/'
  gulp.src ['./bower_components/angular/angular.js']
    .pipe gulp.dest './dist/assets/js'

gulp.task 'usemin', ->
  gulp.src ['./index.html']
    .pipe usemin
      js: [
        sourcemaps.init {loadMaps: true}
        'concat'
        uglify()
        sourcemaps.write './'
      ]
      css: [autoprefixer(), minifycss()]
    .pipe gulp.dest './dist/'
    .pipe connect.reload()

gulp.task 'server', ->
  connect.server
    port: 3000
    root: ['./dist/', './']
    livereload: true

gulp.task 'build', ['assets', 'coffee', 'browserify', 'sass', 'html', 'usemin']

gulp.task 'build:dev', ['assets', 'coffee', 'browserify', 'sass', 'html']

gulp.task 'dev', ['build:dev', 'server', 'watch']

gulp.task 'default', ['build']
