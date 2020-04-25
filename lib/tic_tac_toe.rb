require 'io/wait'
require 'io/console'
require 'pry'

HUMAN_MARKER = "O"
COMPUTER_MARKER = "X"
CURSOR_MARKER = '‾'

class MoveOutOfBoundsError < StandardError; end

module Screen
  extend self

  HIDE_CURSOR = "\e[?25l"
  SHOW_CURSOR = "\e[?25h"

  def hide_cursor
    $stdout.write HIDE_CURSOR
  end

  def show_cursor
    $stdout.write SHOW_CURSOR
  end

  def clear_screen
    print "\u001b[2J" # clear screen
    print "\u001b[0;0H" # set cursor to home position
  end
end

class TTTBoard
  attr_reader :positions
  # position layout
  # 1 | 2 | 3
  # 4 | 5 | 6
  # 7 | 8 | 9

  def mark_position(move, marker)
    @positions[move] = marker
    @display.mark_move(move, marker)
  end

  def initialize(display)
    @display = display
    @positions = (1..9).zip([''] * 9).to_h
  end
end

class TTTDisplay

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

  # Other special characters
  ENTER = "\r"
  LINE_FEED = "\n"

  def initialize
    Screen.clear_screen
    @center = calculate_center
    @marker_coordinates = calculate_marker_coordinates
    @cursor_coordinates = calculate_cursor_coordinates
    @cursor_position = 5
  end

  def mark_move(move, marker)
    move_to_point(*@marker_coordinates[move])
    print marker
  end

  def retrieve_human_move
    retrieve_move_selection
    @cursor_position
  end

  def retrieve_move_selection
    loop do
      input = STDIN.getch
      break if input == CTRL_C

      input << STDIN.getch while STDIN.ready?
      begin
        case input
        when UP_ARROW then cursor_up
        when DOWN_ARROW then cursor_down
        when RIGHT_ARROW then cursor_right
        when LEFT_ARROW then cursor_left
        when ENTER, LINE_FEED then return
        end
      rescue MoveOutOfBoundsError
        print "!"
      end
    end
  end

  def invalid_move
    print "Invalid move"
  end

  def move_cursor(new_cursor_position)
    erase_current_cursor
    @cursor_position = new_cursor_position
    move_to_point(*@cursor_coordinates[@cursor_position])
    insert_cursor_marker
  end

  def cursor_up
    raise MoveOutOfBoundsError if @cursor_position < 4
    new_cursor_position = @cursor_position - 3
    move_cursor(new_cursor_position)
  end

  def cursor_down
    raise MoveOutOfBoundsError if @cursor_position > 6
    new_cursor_position = @cursor_position + 3
    move_cursor(new_cursor_position)
  end

  def cursor_right
    raise MoveOutOfBoundsError if [3, 6, 9].include? @cursor_position
    new_cursor_position = @cursor_position + 1
    move_cursor(new_cursor_position)
  end

  def cursor_left
    raise MoveOutOfBoundsError if [1, 4, 7].include? @cursor_position
    new_cursor_position = @cursor_position - 1
    move_cursor(new_cursor_position)
  end

  def erase_current_cursor
    move_to_point(*@cursor_coordinates[@cursor_position])
    print ' '
  end

  def insert_cursor_marker
    $stdout.write HIGHLIGHT
    print CURSOR_MARKER
    $stdout.write ALL_PROPERTIES_OFF
  end

  def calculate_marker_coordinates
    y_offset, x_offset = *calculate_distances_between_points
    ctr_y, ctr_x = *@center

    { 1 => [ctr_y - y_offset, ctr_x - x_offset], 2 => [ctr_y - y_offset, ctr_x],
      3 => [ctr_y - y_offset, ctr_x + x_offset], 4 => [ctr_y, ctr_x - x_offset],
      5 => [ctr_y, ctr_x], 6 => [ctr_y, ctr_x + x_offset],
      7 => [ctr_y + y_offset, ctr_x - x_offset], 8 => [ctr_y + y_offset, ctr_x],
      9 => [ctr_y + y_offset, ctr_x + x_offset] }
  end

  def calculate_cursor_coordinates
    cursor_coordinates = {}
    1.upto 9 do |position|
      y_cursor = @marker_coordinates[position].first + 1
      x_cursor = @marker_coordinates[position].last
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

  def draw_lines
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
    $stdout.write "\u001b[#{y};#{x}H"
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
    $stdout.write "\u001b[#{y};#{x}H"
  end

  def draw_horizontal_line
    @start_x.upto(@stop_x) do |x|
      point_coords = [@start_y, x]
      if point_at_intersection? point_coords
        print '┼'
      else
        print '─'
      end
      @@coords_drawn << [@start_y, x]
    end
  end

  def draw_vertical_line
    @start_y.upto(@stop_y) do |y|
      point_coords = [y, @start_x]
      if point_at_intersection? point_coords
        print '┼'
      else
        print '│'
      end
      position_cursor_below
      @@coords_drawn << [y, @start_x]
    end
  end

  def position_cursor_below
    down = "\u001b[1B"
    left = "\u001b[1D"
    $stdout.write down + left
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

class Player

end

class Human < Player
  def initialize(board, display)
    @marker = HUMAN_MARKER
    @board = board
    @display = display
    @move = nil
  end

  def retrieve_move
    loop do
      @move = @display.retrieve_human_move
      break if valid_move?

      @display.invalid_move
    end
    @board.mark_position(@move, @marker)
  end

  def valid_move?
    board_empty_at_position?
  end

  def board_empty_at_position?
    @board.positions[@move] = ''
  end
end

class TTTGame
  def initialize
    @display = TTTDisplay.new
    @board = TTTBoard.new(@display)
    @human = Human.new(@board, @display)
  end

  def quit
    # Screen.clear_screen
    STDIN.cooked!
    STDIN.echo = true
    Screen.show_cursor
    exit
  end

  def play
    @display.draw_lines
    @human.retrieve_move
  end
end

if __FILE__ == $PROGRAM_NAME
  # begin
  #   STDIN.raw!
  #   STDIN.echo = false
  #   game = TTTGame.new
  #   game.play
  #   sleep 5
  # ensure
  #   game.quit
  # end
  begin
    Screen.hide_cursor
    STDIN.raw!
    STDIN.echo = false
    game = TTTGame.new
    game.play
  ensure
    game.quit
  end
end
