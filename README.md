Ruby SVG Vector Path Renderer
=============================

Proof-of-concept ruby project to draw .SVG `path` elements using Ruby.

Uses Jeremey Holland's [Savage](https://github.com/awebneck/savage) gem to parse
the vector data, Yihang Ho's [bezier](https://github.com/yihangho/bezier) gem to
plot the curves and the [gosu](https://github.com/gosu/gosu/wiki/ruby-Tutorial)
library to draw it all to the screen.

### To Use

Install the needed gems using `bundle install`, then run `svg_path_render.rb`.

#### Usage:

`svg_path_render.rb <[options]> <svg_filename>`

```
where [options] are:
  -w, --width=<i>           Window width (default: 640)
  -h, --height=<i>          Window height (default: 480)
  -c, --curve-points=<i>    Number of points to plot in curves (2-1000) (default: 5)
  -x, --x-scale=<f>         multiple X size by this number (default: 1.0)
  -y, --y-scale=<f>         multiple Y size by this number (default: 1.0)
  -s, --scale=<f>           multiple X and Y size by this number (default: 1.0)
  -o, --x-offset=<i>        offset X coordinates by this many pixels, positive or negative (default: 1)
  -f, --y-offset=<i>        offset y coordinates by this many pixels, positive or negative (default: 1)
  -d, --delay=<f>           Delay between redrawing (seconds) (default: 1.0)
  -e, --help                Show this message
```
