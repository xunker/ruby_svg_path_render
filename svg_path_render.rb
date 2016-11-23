#!/usr/bin/env ruby

require 'gosu'    # drawing to the screen
require 'bezier'  # plotting curves
require 'savage'  # parsing svg vector data
require 'trollop' # command line arguments

class GameWindow < Gosu::Window
  # Show mouse cursor
  def needs_cursor?
    true
  end

  def initialize(filename: nil, paths_data:[], opts:{})
    super opts[:width], opts[:height], false
    self.caption = filename || "SVG Path Parser"

    @bezier_points = opts[:curve_points]
    @bezier_points = 2 if @bezier_points < 2
    @bezier_points = 1000 if @bezier_points > 1000

    # defaults
    @x_multiplier = opts[:x_scale]
    @y_multiplier = opts[:y_scale]
    if opts[:scale] != 1.0
      @x_multiplier = opts[:scale]
      @y_multiplier = opts[:scale]
    end

    @x_offset = opts[:x_offset]
    @y_offset = opts[:y_offset]

    @delay = opts[:delay]

    @paths = paths_data.map{|path_data| Savage::Parser.parse path_data}

  end

  def button_down(id)
    case id
    when Gosu::KbEscape
      close  # exit on press of escape key
    end
  end

  def update
    if @first_loop_pased.nil?
      # so we don't get the delay on the first loop
      @first_loop_pased = true
    else
      sleep(@delay) # framerate hack to keep the screen from needlessly updating.
    end
  end

  def draw
    @current_x = 0
    @current_y = 0

    # Draw lines connecting from the last point of the previous command to the
    # first point of the current command?
    @join_sections = true

    @paths.each do |path|
      path.subpaths.each do |subpath|

        subpath_initial_x = @current_x
        subpath_initial_y = @current_y

        subpath.commands.each do |command|
          puts "current_x: #{@current_x}, current_y: #{@current_y}"
          cmd_a = command.to_a
          puts cmd_a.inspect
          cmd = cmd_a.shift

          print "(#{cmd}) "
          case cmd
          when 'M'
            puts 'Absolute move'

            @current_x = cmd_a.first
            @current_y = cmd_a.last

            subpath_initial_x = @current_x
            subpath_initial_y = @current_y
          when 'm'
            puts 'Relative move'

            @current_x += cmd_a.first
            @current_y += cmd_a.last

            subpath_initial_x = @current_x
            subpath_initial_y = @current_y
          when 'Z','z'
            puts 'Closepath'

            draw_line(@current_x, @current_y, subpath_initial_x, subpath_initial_y)
          when 'C', 'S' # TODO shorthand bezier support
            if cmd =~ /s/i
              puts 'Absolute shorthand bézier (absolute cubic bézier)'
            else
              puts 'Absolute cubic bézier'
            end

            coords = cmd_a.each_slice(2).map{|s|s}

            draw_line(@current_x, @current_y, coords.first.first, coords.first.last) if @join_sections

            points = coords.map{|x,y| Bezier::Point.new(x,y)}
            bezier = Bezier::Bezier.new(*points)
            previous_x = nil
            previous_y = nil
            bezier.run(@bezier_points).each do |point|
              if previous_x.nil? || previous_y.nil?
                # Do nothing here because we're going to join this point to the next line segment
                # draw_point point.x, point.y
              else
                draw_line previous_x, previous_y, point.x, point.y
              end
              previous_x = point.x
              previous_y = point.y
            end

            @current_x = coords.last.first
            @current_y = coords.last.last
          when 'c', 's' # TODO shorthand bezier support
            if cmd =~ /s/i
              puts 'Relative shorthand bézier (relative cubic bézier)'
            else
              puts 'Relative cubic bézier'
            end

            coords = cmd_a.each_slice(2).map{|s|s}

            draw_line(@current_x, @current_y, @current_x+coords.first.first, @current_y+coords.first.last) if @join_sections

            points = coords.map{|x,y| Bezier::Point.new(x,y)}
            bezier = Bezier::Bezier.new(*points)
            previous_x = nil
            previous_y = nil
            bezier.run(@bezier_points).each do |point|
              if previous_x.nil? || previous_y.nil?
                # Do nothing here because we're going to join this point to the next line segment
                # draw_point @current_x+point.x, @current_y+point.y
              else
                draw_line @current_x+previous_x, @current_y+previous_y, @current_x+point.x, @current_y+point.y
              end
              previous_x = point.x
              previous_y = point.y
            end

            @current_x += coords.last.first
            @current_y += coords.last.last
          when 'L'
            puts 'Absolute lineto'
            # TODO support polylines
            last_x = cmd_a[-2].to_f
            last_y = cmd_a[-1].to_f
            draw_line(@current_x, @current_y, last_x, last_y)

            @current_x = last_x
            @current_y = last_y
          when 'l'
            puts 'Relative lineto'
            # TODO support polylines
            last_x = cmd_a[-2].to_f
            last_y = cmd_a[-1].to_f
            draw_line(@current_x, @current_y, @current_x+last_x, @current_y+last_y)

            @current_x += last_x
            @current_y += last_y
          when 'H'
            puts 'Absolute horizontal lineto'
            draw_line(@current_x, @current_y, cmd_a.last.to_f, @current_y)

            @current_x = cmd_a.last.to_f
          when 'h'
            puts 'Relative horizontal lineto'
            draw_line(@current_x, @current_y, @current_x+cmd_a.last.to_f, @current_y)

            @current_x += cmd_a.last.to_f
          when 'V'
            puts 'Absolute vertical lineto'
            draw_line(@current_x, @current_y, @current_x, cmd_a.last.to_f)

            @current_y = cmd_a.last.to_f
          when 'v'
            puts 'Relative vertical lineto'
            draw_line(@current_x, @current_y, @current_x, @current_y+cmd_a.last.to_f)

            @current_y += cmd_a.last.to_f
          else
            raise "Unknown command #{cmd.inspect}"
          end
        end
      end
      puts "-"*80
    end
    puts "="*80

    # # Uncomment below to play with dynamic, animated scaling.
    #
    # @adj ||= 0.01
    #
    # @x_multiplier = @x_multiplier.to_f + @adj
    # @y_multiplier = @y_multiplier.to_f + @adj
    #
    # self.caption = @x_multiplier.to_s
    # if @x_multiplier > 2.5
    #   @adj = -0.01
    # end
    #
    # if @x_multiplier <= 0.25
    #   @adj = 0.01
    # end

    # # Uncomment below to animate how the number of points on each bezier
    # # effects the rendered product.
    #
    # @adj ||= 1
    # @bezier_points += @adj
    #
    # self.caption = @bezier_points.to_s
    # if @bezier_points > 10
    #   @adj = -1
    # end
    #
    # if @bezier_points <= 2
    #   @adj = 1
    # end

  end

  def draw_point(x,y)
    Gosu::draw_line (x+@x_offset)*@x_multiplier, (y+@y_offset)*@y_multiplier, Gosu::Color::WHITE, ((x+@x_offset)*@x_multiplier)+1, (y+@y_offset)*@y_multiplier, Gosu::Color::WHITE
  end
  def draw_line(x1,y1,x2,y2)
    Gosu::draw_line (x1+@x_offset)*@x_multiplier, (y1+@y_offset)*@y_multiplier, Gosu::Color::WHITE, (x2+@x_offset)*@x_multiplier, (y2+@y_offset)*@y_multiplier, Gosu::Color::WHITE
  end
end

opts = Trollop::options do
  banner <<-EOS
Render SVG Vector data using Ruby

Usage:
       svg_path_render.rb <[options]> <svg_filename>

where [options] are:
EOS
  opt :width, 'Window width', default: 640
  opt :height, 'Window height', default: 480
  opt :curve_points, "Number of points to plot in curves (2-1000)", type: :integer, default: 5
  opt :x_scale, "multiple X size by this number", type: :float, default: 1.0
  opt :y_scale, "multiple Y size by this number", type: :float, default: 1.0
  opt :scale, "multiple X and Y size by this number", type: :float, default: 1.0
  opt :x_offset, "offset X coordinates by this many pixels, positive or negative", default: 1
  opt :y_offset, "offset y coordinates by this many pixels, positive or negative", default: 1
  opt :delay, "Delay between redrawing (seconds)", type: :float, default: 1.0
end

filename = ARGV[0]
Trollop::die "Must pass filename" unless filename.to_s.length > 0
Trollop::die "File #{filename.inspect} not found" unless File.exist?(filename)

contents = File.open(filename).read
contents.gsub!(/\r/, '')
contents.gsub!(/\n/, '')
contents.gsub!(/\t/, '')
contents.gsub!(/\<path/, "\n<path")
paths_data = contents.split("\n").select{|e| e =~ /^\<path/}.map{|content|
  if matches = content.match(/\<path.*\s+d=\"(.+)\"/)
    matches[1]
  end
}.compact

Trollop::die "Could not find any vector paths in #{filename.inspect}." if paths_data.size == 0

window = GameWindow.new(filename: filename, paths_data: paths_data, opts: opts)
window.show
