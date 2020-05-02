require 'io/wait'
require 'io/console'

class MoveOutOfBoundsError < StandardError; end
class KeyboardInterruptError < StandardError; end

class Display
  COMPUTER_MARKER = 'X'
  HUMAN_MARKER = 'O'
  CURSOR_MARKER = '‾'
  HIDE_CURSOR = "\e[?25l"
  SHOW_CURSOR = "\e[?25h"

  # Board lines
  HORIZONTAL1 = { start: [5, 10], stop: [5, 22] }
  HORIZONTAL2 = { start: [9, 10], stop: [9, 22] }
  VERTICAL1 = { start: [2, 14], stop: [12, 14] }
  VERTICAL2 = { start: [2, 18], stop: [12, 18] }

  # ANSI escape codes
  UP_ARROW = "\e[A"
  DOWN_ARROW = "\e[B"
  RIGHT_ARROW = "\e[C"
  LEFT_ARROW = "\e[D"
  HIGHLIGHT = "\e[1m"
  ALL_PROPERTIES_OFF = "\e[0m"
  CTRL_C = "\u0003"

  CARRIAGE_RETURN = "\r"
  LINE_FEED = "\n"

  def initialize(terminal_setup = true)
    prepare_terminal if terminal_setup
    @center = calculate_center
    @square_coordinates = calculate_square_coordinates
    @cursor_coordinates = calculate_cursor_coordinates
    @cursor_position = 4
    @input = nil
  end

  def prepare_terminal 
    STDIN.raw!
    STDIN.echo = false
    hide_cursor
    clear_screen
  end

  def hide_cursor
    STDOUT.write HIDE_CURSOR
  end

  def show_cursor
    STDOUT.write SHOW_CURSOR
  end

  def clear_screen
    STDOUT.write "\u001b[2J" # clear screen
    STDOUT.write "\u001b[0;0H" # set cursor to home position
  end
  
  def mark(number, marker)
    move_to_point(*@square_coordinates[number])
    print_marker(marker)
  end

  def print_marker(marker)
    print marker == :computer ? COMPUTER_MARKER : HUMAN_MARKER
  end

  def retrieve_human_move
    retrieve_move_selection
    @cursor_position
  end

  def retrieve_move_selection
    loop do
      begin
        retrieve_keypress
        process_arrow_keys
        break if selection_made?

      rescue MoveOutOfBoundsError, KeyboardInterruptError => e
        exit(1) if e.class == KeyboardInterruptError

        print '!'
      end
    end
  end

  def selection_made?
    [LINE_FEED, CARRIAGE_RETURN].include? @input
  end

  def retrieve_keypress
    @input = STDIN.getch
    raise KeyboardInterruptError if @input == CTRL_C
    @input << STDIN.getch while STDIN.ready?
  end

  def process_arrow_keys
    case @input
    when UP_ARROW then cursor_up
    when DOWN_ARROW then cursor_down
    when RIGHT_ARROW then cursor_right
    when LEFT_ARROW then cursor_left
    end
  end

  def invalid_move
    print "Invalid move"
  end

  def move_cursor(new_cursor_position)
    erase_cursor_marker
    @cursor_position = new_cursor_position
    move_to_point(*@cursor_coordinates[@cursor_position])
    insert_cursor_marker
  end

  def cursor_up
    raise MoveOutOfBoundsError if @cursor_position < 3
    new_cursor_position = @cursor_position - 3
    move_cursor(new_cursor_position)
  end

  def cursor_down
    raise MoveOutOfBoundsError if @cursor_position > 5
    new_cursor_position = @cursor_position + 3
    move_cursor(new_cursor_position)
  end

  def cursor_right
    raise MoveOutOfBoundsError if [2, 5, 8].include? @cursor_position
    new_cursor_position = @cursor_position + 1
    move_cursor(new_cursor_position)
  end

  def cursor_left
    raise MoveOutOfBoundsError if [0, 3, 6].include? @cursor_position
    new_cursor_position = @cursor_position - 1
    move_cursor(new_cursor_position)
  end

  def erase_cursor_marker
    move_to_point(*@cursor_coordinates[@cursor_position])
    print ' '
  end

  def insert_cursor_marker
    STDOUT.write HIGHLIGHT
    print CURSOR_MARKER
    STDOUT.write ALL_PROPERTIES_OFF
  end

  def calculate_square_coordinates
    y_offset, x_offset = *calculate_distances_between_points
    ctr_y, ctr_x = *@center

    { 0 => [ctr_y - y_offset, ctr_x - x_offset], 1 => [ctr_y - y_offset, ctr_x],
      2 => [ctr_y - y_offset, ctr_x + x_offset], 3 => [ctr_y, ctr_x - x_offset],
      4 => [ctr_y, ctr_x], 5 => [ctr_y, ctr_x + x_offset],
      6 => [ctr_y + y_offset, ctr_x - x_offset], 7 => [ctr_y + y_offset, ctr_x],
      8 => [ctr_y + y_offset, ctr_x + x_offset] }
  end

  def calculate_cursor_coordinates
    cursor_coordinates = {}
    0.upto 8 do |position|
      y_cursor = @square_coordinates[position].first + 1
      x_cursor = @square_coordinates[position].last
      cursor_coordinates[position] = [y_cursor, x_cursor]
    end

    cursor_coordinates
  end

  def calculate_distances_between_points
    x_start = HORIZONTAL1[:start][1]
    x_stop = HORIZONTAL1[:stop][1]
    y_start = VERTICAL1[:start][0]
    y_stop = VERTICAL1[:stop][0]

    x_dist = ((x_stop - x_start + 1) / 3.0).round
    y_dist = ((y_stop - y_start + 1) / 3.0).round

    [y_dist, x_dist]
  end

  def draw_initial_board
    line_coord_pairs = [HORIZONTAL1, HORIZONTAL2,
            VERTICAL1, VERTICAL2]

    line_coord_pairs.each do |line_coord_pair|
      Line.new(line_coord_pair).draw
    end
  end

  def calculate_center
    center_y = (HORIZONTAL1[:start][0] +
                 HORIZONTAL2[:start][0]) / 2
    center_x = (VERTICAL1[:start][1] +
                 VERTICAL2[:start][1]) / 2
    [center_y, center_x]
  end

  def move_to_center
    move_to_point(*@center)
  end

  def move_to_point(y, x)
    STDOUT.write "\u001b[#{y};#{x}H"
  end

  def close
    STDIN.cooked!
    STDIN.echo = true
    show_cursor
    clear_screen
  end
end

class Line
  @@coords_drawn = []

  def initialize(line_coord_pair)
    @start_y = line_coord_pair[:start].first
    @start_x = line_coord_pair[:start].last
    @stop_y = line_coord_pair[:stop].first
    @stop_x = line_coord_pair[:stop].last
  end

  def draw
    move_to_start
    horizontal? ? draw_horizontal_line : draw_vertical_line
  end

  def move_to_start
    move_to_point(@start_y, @start_x)
  end

  def move_to_point(y, x)
    STDOUT.write "\u001b[#{y};#{x}H"
  end

  def draw_horizontal_line
    @start_x.upto(@stop_x) do |x|
      point_coords = [@start_y, x]
      if point_at_intersection? point_coords
        print '┼'
      else
        print '─'
        @@coords_drawn << [@start_y, x]
      end
    end
  end

  def draw_vertical_line
    @start_y.upto(@stop_y) do |y|
      point_coords = [y, @start_x]
      if point_at_intersection? point_coords
        print '┼'
      else
        print '│'
        @@coords_drawn << [y, @start_x]
      end
      position_cursor_below
    end
  end

  def position_cursor_below
    down = "\u001b[1B"
    left = "\u001b[1D"
    STDOUT.write down + left
  end

  def point_at_intersection?(point_coords)
    @@coords_drawn.include? point_coords
  end

  def horizontal?
    @start_y == @stop_y
  end

  def vertical?
    @start_x == @stop_x
  end
end
