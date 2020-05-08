require 'io/wait'
require 'io/console'

# Markers
COMPUTER_MARKER = 'X'
HUMAN_MARKER = 'O'
CURSOR_MARKER = '‾'

# Positions
HEADING_POSITION = [1, 1]
GAME_NUMBER_POSITION = [1, 14]
STATS_POSITION = [1, 20]
MESSAGE_POSITION1 = [3, 1]
MESSAGE_POSITION2 = [4, 1]
WARNING_POSITION = [5, 1]

class MoveOutOfBoundsError < StandardError; end

class Display
  # ANSI escape codes
  # Movement
  UP_ARROW = "\e[A"
  DOWN_ARROW = "\e[B"
  RIGHT_ARROW = "\e[C"
  LEFT_ARROW = "\e[D"
  # Properties
  WARNING_COLOR = "\u001b[36m" # cyan
  SCORE_COLOR = "\u001b[36m" # cyan
  HIGHLIGHT = "\e[1m"
  ALL_PROPERTIES_OFF = "\e[0m"
  # Other
  CTRL_C = "\u0003"

  # Other escape codes
  CARRIAGE_RETURN = "\r"
  LINE_FEED = "\n"

  # Initial line coordinates before board offset
  HORIZONTAL1 = { start: [4, 1], stop: [4, 13] }
  HORIZONTAL2 = { start: [8, 1], stop: [8, 13] }
  VERTICAL1 = { start: [1, 5], stop: [11, 5] }
  VERTICAL2 = { start: [1, 9], stop: [11, 9] }
  BOARD_OFFSET = [6, 2] # [y, x] offset from upper left corner

  # pass in false flag for testing
  def initialize(terminal_setup = true)
    prepare_terminal if terminal_setup
    establish_line_coordinates
    @center = calculate_center
    @square_coordinates = calculate_square_coordinates
    @cursor_coordinates = calculate_cursor_coordinates
    @warning_visible = nil
    @cursor_position = 0
    @points = { heading: HEADING_POSITION, message_line1: MESSAGE_POSITION1,
                message_line2: MESSAGE_POSITION2, warning: WARNING_POSITION,
                game_number: GAME_NUMBER_POSITION, stats: STATS_POSITION }
  end

  def prepare_terminal
    STDIN.raw!
    STDIN.echo = false
    hide_terminal_cursor
    clear_screen
  end

  def hide_terminal_cursor
    STDOUT.write "\e[?25l"
  end

  def show_terminal_cursor
    STDOUT.write "\e[?25h"
  end

  def new_game
    clear_all_squares
    hide_selection_cursor
    clear :stats
  end

  def clear_to_end_of_line
    STDOUT.write "\u001b[K"
  end

  def clear_screen
    STDOUT.write "\u001b[2J" # clear screen
    STDOUT.write "\u001b[0;0H" # set cursor to home position
  end

  def show_turn(turn)
    case turn
    when :human
      print_message 'Your move?'
      print_message '(Arrow keys to move cursor and Enter to select)',
                    :message_line2
    when :computer
      print_message 'Computer\'s move'
      clear :message_line2
    end
  end

  def continue_match?
    input = input_char('Continue match? (y/n)', %w(y n), :message_line2)
    input == 'y'
  end

  def mark_square(index, marker)
    move_to_point(*@square_coordinates[index])
    print_marker(marker)
  end

  def print_marker(marker)
    print marker == :computer ? COMPUTER_MARKER : HUMAN_MARKER
  end

  def input_char(prompt, options, message_line = :message_line1)
    print_message prompt, message_line

    loop do
      entered = STDIN.getch.downcase
      exit(1) if entered == CTRL_C
      if !options || options.include?(entered)
        clear message_line, :warning
        return entered
      end

      print_warning "Please enter #{prettier_print(options)}"
    end
  end

  def show_welcome
    draw_board
    print_message 'TIC-TAC-TOE', :heading
    print_message 'Welcome to unbeatable tic-tac-toe. ' \
                  'This is a 5-game match.'
    input_char 'The best you can do is tie (sorry). ' \
               'Press any key to continue.', nil, :message_line2
  end

  def goodbye(game_number)
    pre_message = game_number == 5 ? 'Good match! ' : ''
    print_message pre_message + 'Thanks for playing.'
    input_char 'Press x to exit.', ['x'], :message_line2
  end

  def show_game_number(game_number)
    go_to :game_number
    print "Game #{game_number}"
  end

  def show_stats(ties, human_wins, computer_wins)
    go_to :stats
    print " —— Match stats: Human:"
    print_score_color human_wins
    print " Computer:"
    print_score_color computer_wins
    print " Ties:"
    print_score_color ties
  end

  def print_message(text, line = :message_line1)
    go_to line
    clear line
    print text
  end

  def print_warning(text)
    go_to :warning
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

  def print_score_color(text)
    STDOUT.write SCORE_COLOR
    print text
    STDOUT.write ALL_PROPERTIES_OFF
  end

  def save_terminal_cursor_position
    STDOUT.write "\u001b[s"
  end

  def restore_terminal_cursor_position
    STDOUT.write "\u001b[u"
  end

  def clear(*fields)
    fields.each do |field|
      save_terminal_cursor_position
      go_to(field)
      clear_to_end_of_line
      @warning_visible = false if field == :warning
      restore_terminal_cursor_position
    end
  end

  def go_to(field)
    move_to_point(*@points[field])
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

  def show_outcome(winner)
    message = winner ? "#{winner.to_s.capitalize} wins!" : 'Tie!'

    print_message message
  end

  def retrieve_first_player_selection
    human_first = input_char('Would you like to go first? (y/n)',
                             %w(y n))
    move_cursor(4)
    return :human if human_first == 'y'

    :computer
  end

  def retrieve_human_move
    retrieve_move_selection
    clear :warning if @warning_visible
    @cursor_position
  end

  def retrieve_move_selection
    loop do
      begin
        retrieve_keypress
        break if selection_made?

        process_arrow_keys
      rescue MoveOutOfBoundsError
        print_warning 'Sorry, can\'t move cursor there'
      end
    end
  end

  def selection_made?
    [LINE_FEED, CARRIAGE_RETURN].include? @selection_input
  end

  def retrieve_keypress
    @selection_input = STDIN.getch
    exit(1) if @selection_input == CTRL_C
    @selection_input << STDIN.getch while STDIN.ready?
  end

  def process_arrow_keys
    case @selection_input
    when UP_ARROW then cursor_up
    when DOWN_ARROW then cursor_down
    when RIGHT_ARROW then cursor_right
    when LEFT_ARROW then cursor_left
    else
      print_warning 'Only arrow keys and Enter accepted as input'
    end
  end

  def invalid_move
    print_warning "Sorry, that move is taken"
  end

  def move_cursor(new_cursor_position)
    hide_selection_cursor
    clear :warning if @warning_visible
    @cursor_position = new_cursor_position
    move_to_point(*@cursor_coordinates[@cursor_position])
    show_selection_cursor
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

  def hide_selection_cursor
    move_to_point(*@cursor_coordinates[@cursor_position])
    print ' '
  end

  def clear_all_squares
    0.upto 8 do |index|
      move_to_point(*@square_coordinates[index])
      print ' '
    end
  end

  def show_selection_cursor
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

  def establish_line_coordinates
    @horizontal1 = HORIZONTAL1
    @horizontal2 = HORIZONTAL2
    @vertical1 = VERTICAL1
    @vertical2 = VERTICAL2

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

  def draw_board
    @coords_drawn = []
    [@horizontal1, @horizontal2,
     @vertical1, @vertical2].each do |coord_pair|
      Line.new(coord_pair, @coords_drawn).draw
      sleep 0.1
    end
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

  def move_to_point(y_coord, x_coord)
    STDOUT.write "\u001b[#{y_coord};#{x_coord}H"
  end

  def close
    STDIN.cooked!
    STDIN.echo = true
    show_terminal_cursor
    clear_screen
  end
end

class Line
  def initialize(coord_pair, coords_drawn)
    @start_y = coord_pair[:start].first
    @start_x = coord_pair[:start].last
    @stop_y = coord_pair[:stop].first
    @stop_x = coord_pair[:stop].last
    @coords_drawn = coords_drawn
  end

  def draw
    move_to_start
    horizontal? ? draw_horizontal_line : draw_vertical_line
  end

  def move_to_start
    move_to_point(@start_y, @start_x)
  end

  def move_to_point(y_coord, x_coord)
    STDOUT.write "\u001b[#{y_coord};#{x_coord}H"
  end

  def draw_horizontal_line
    @start_x.upto(@stop_x) do |x|
      point_coords = [@start_y, x]
      print intersection?(point_coords) ? '┼' : '─'

      @coords_drawn << [@start_y, x]
    end
  end

  def draw_vertical_line
    @start_y.upto(@stop_y) do |y|
      point_coords = [y, @start_x]
      print intersection?(point_coords) ? '┼' : '│'

      @coords_drawn << [y, @start_x]
      position_cursor_below
    end
  end

  def position_cursor_below
    down = "\u001b[1B"
    left = "\u001b[1D"
    STDOUT.write down + left
  end

  def intersection?(point_coords)
    @coords_drawn.include? point_coords
  end

  def horizontal?
    @start_y == @stop_y
  end
end
