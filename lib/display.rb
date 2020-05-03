require 'io/wait'
require 'io/console'

# Configurable constants
COMPUTER_MARKER = 'X'
HUMAN_MARKER = 'O'

BOARD_OFFSET = [2, 2] # [y, x] offset from upper left corner


class MoveOutOfBoundsError < StandardError; end
class KeyboardInterruptError < StandardError; end

class Display
  # ANSI escape codes
  # Movement
  UP_ARROW = "\e[A"
  DOWN_ARROW = "\e[B"
  RIGHT_ARROW = "\e[C"
  LEFT_ARROW = "\e[D"
  # Properties
  WARNING_COLOR = "\u001b[36m" # cyan
  HIGHLIGHT = "\e[1m"
  ALL_PROPERTIES_OFF = "\e[0m"
  # Other
  CTRL_C = "\u0003"

  CURSOR_MARKER = '‾'
  CARRIAGE_RETURN = "\r"
  LINE_FEED = "\n"

  def initialize(terminal_setup = true) # pass in false flag for testing
    prepare_terminal if terminal_setup
    set_line_coordinates
    @center = calculate_center
    @square_coordinates = calculate_square_coordinates
    @cursor_coordinates = calculate_cursor_coordinates
    @input = nil
    @warning_visible = nil
    @cursor_position = 0
  end

  def set_line_coordinates
    @horizontal1 = { start: [4, 1], stop: [4, 13] }
    @horizontal2 = { start: [8, 1], stop: [8, 13] }
    @vertical1 = { start: [1, 5], stop: [11, 5] }
    @vertical2 = { start: [1, 9], stop: [11, 9] }

    [@horizontal1, @horizontal2,
     @vertical1, @vertical2].each do |coord_pair|
      apply_offset(coord_pair)
    end
  end

  def apply_offset(coord_pair)
    coord_pair.keys.each do |k| 
      coord_pair[k] = [coord_pair[k][0] + BOARD_OFFSET[0],
                       coord_pair[k][1] + BOARD_OFFSET[1]]
    end
  end

  def prepare_terminal
    STDIN.raw!
    STDIN.echo = false
    hide_cursor
    clear_screen
  end

  def hide_cursor
    STDOUT.write "\e[?25l"
  end

  def show_cursor
    STDOUT.write "\e[?25h"
  end

  def clear_line
    STDOUT.write "\u001b[2K" # clear line
  end

  def clear_screen
    STDOUT.write "\u001b[2J" # clear screen
    STDOUT.write "\u001b[0;0H" # set cursor to home position
  end

  def show_turn(turn)
    case turn
    when :human
      print_message 'Your move? (arrow keys to move cursor and Enter to select)'
    when :computer
      print_message 'Computer\'s move'
    end
  end

  def mark_square(index, marker)
    move_to_point(*@square_coordinates[index])
    print_marker(marker)
  end

  def print_marker(marker)
    print marker == :computer ? COMPUTER_MARKER : HUMAN_MARKER
  end

  def input_char(prompt, options=nil)
    print_message prompt
    loop do
      entered = STDIN.getch
      close if entered == "\u0003" # exit program on Ctrl-c
      if !options || options.include?(entered)
        clear :message, :warning
        return entered 
      end

      print_warning "Please enter #{prettier_print(options)}"
    end
  end

  def print_message(text)
    clear :message
    print text
  end

  def print_warning(text)
    clear :warning
    sleep 0.08
    print_warning_color text
    @warning_visible = true
  end

  def print_warning_color(text)
    STDOUT.write WARNING_COLOR
    print text
    STDOUT.write ALL_PROPERTIES_OFF
  end
           
  def clear(*lines)
    lines.each do |line|
      case line
      when :message
        move_to_point 1, 1
      when :warning
        move_to_point 2, 1
        @warning_visible = false
      end
      clear_line
    end
  end

  def prettier_print(options)
    options = options.map { |option| option == ' ' ? 'space' : option }
    case options.size
    when 1
      options[0]
    when 2
      "#{options[0]} or #{options[1]}"
    when 3..10
      options[0..-2].join(', ') + ' or ' + options[-1]
    end
  end

  def retrieve_goes_first_selection
    human_first = input_char('Would you like to go first? (y/n)',
                             %w(y n))
    return :human if human_first == 'y'

    :computer
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
        # add error for invalid selection key

      rescue MoveOutOfBoundsError, KeyboardInterruptError => e
        exit(1) if e.class == KeyboardInterruptError

        print_warning 'Sorry, can\'t move cursor there.'
      end
    end
  end

  def selection_made?
    [LINE_FEED, CARRIAGE_RETURN].include? @input
  end

  def retrieve_keypress
    @input = STDIN.getch
    exit(1) if @input == CTRL_C
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
    print_warning "Sorry, that move is taken."
  end

  def move_cursor(new_cursor_position)
    erase_cursor_marker
    @cursor_position = new_cursor_position
    move_to_point(*@cursor_coordinates[@cursor_position])
    insert_cursor_marker
  end

  # can I condense these methods?
  def cursor_up
    raise MoveOutOfBoundsError if @cursor_position < 3
    new_cursor_position = @cursor_position - 3
    clear :warning if @warning_visible
    move_cursor(new_cursor_position)
  end

  def cursor_down
    raise MoveOutOfBoundsError if @cursor_position > 5
    new_cursor_position = @cursor_position + 3
    clear :warning if @warning_visible
    move_cursor(new_cursor_position)
  end

  def cursor_right
    raise MoveOutOfBoundsError if [2, 5, 8].include? @cursor_position
    new_cursor_position = @cursor_position + 1
    clear :warning if @warning_visible
    move_cursor(new_cursor_position)
  end

  def cursor_left
    raise MoveOutOfBoundsError if [0, 3, 6].include? @cursor_position
    new_cursor_position = @cursor_position - 1
    clear :warning if @warning_visible
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
    y_dist, x_dist = *calculate_distances_between_points
    ctr_y, ctr_x = *@center

    { 0 => [ctr_y - y_dist, ctr_x - x_dist], 1 => [ctr_y - y_dist, ctr_x],
      2 => [ctr_y - y_dist, ctr_x + x_dist], 3 => [ctr_y, ctr_x - x_dist],
      4 => [ctr_y, ctr_x], 5 => [ctr_y, ctr_x + x_dist],
      6 => [ctr_y + y_dist, ctr_x - x_dist], 7 => [ctr_y + y_dist, ctr_x],
      8 => [ctr_y + y_dist, ctr_x + x_dist] }
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
    x_start = @horizontal1[:start][1]
    x_stop = @horizontal1[:stop][1]
    y_start = @vertical1[:start][0]
    y_stop = @vertical1[:stop][0]

    x_dist = ((x_stop - x_start + 1) / 3.0).round
    y_dist = ((y_stop - y_start + 1) / 3.0).round

    [y_dist, x_dist]
  end

  def draw_initial_board
    [@horizontal1, @horizontal2,
     @vertical1, @vertical2].each do |coord_pair|
      Line.new(coord_pair).draw
    end
    move_cursor(4)
  end

  def calculate_center
    center_y = (@horizontal1[:start][0] +
                 @horizontal2[:start][0]) / 2
    center_x = (@vertical1[:start][1] +
                 @vertical2[:start][1]) / 2
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
end
