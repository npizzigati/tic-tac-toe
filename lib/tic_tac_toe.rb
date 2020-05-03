require 'pry'


require_relative 'minimax.rb'
require_relative 'display.rb'

class Board
  WINNING_LINES = [0, 1, 2], [3, 4, 5], [6, 7, 8], # horizontal
                   [0, 3, 6], [1, 4, 7], [2, 5, 8], # vertical
                   [0, 4, 8], [2, 4, 6] # diagonal

  include Enumerable

  # Allow Minimax methods to read/write @squares array directly
  attr_accessor :squares

  def initialize(display = nil) # nil flag used for minimax boards
    @display = display
    # board array indices
    # 0 | 1 | 2
    # 3 | 4 | 5
    # 6 | 7 | 8
    @squares = Array.new(9) { :empty }
  end

  def each(&block) 
    @squares.each(&block)
  end

  def []=(index, marker)
    @squares[index] = marker
    @display.mark_square(index, marker) if @display
  end

  def [](index)
    @squares[index]
  end

  def full?
    @squares.index(:empty).nil?
  end

  # Try to make this method clearer
  def determine_winner
    WINNING_LINES.each do |line|
      line_of_markers = replace_indices_with_markers(line)
      return line_of_markers.first if line_of_markers.uniq.size == 1
    end
    nil
  end

  def replace_indices_with_markers(line)
    line.map do |index|
      marker_at_index = @squares[index]
      marker_at_index if [:human, :computer].include? marker_at_index
    end
  end
end

class Computer
  def initialize(board)
    @board = board
  end

  def move
    pause_briefly
    index = retrieve_minimax_move
    @board[index] = :computer
  end

  def retrieve_minimax_move
    tree = Minimax.new.create_tree(@board)
    best_child_board = tree.children.max do |a, b|
      a.score <=> b.score 
    end

    delta(best_child_board)
  end

  def delta(best_child_board)
    @board.each_with_index do |square, index|
      return index if best_child_board[index] != square
    end
  end

  def pause_briefly
    sleep 0.5
  end
end

class Human
  def initialize(board, display)
    @board = board
    @display = display
  end

  def move
    square = nil
    loop do 
      square = @display.retrieve_human_move
      break if valid?(square)

      @display.invalid_move
    end

    @board[square] = :human
  end
end

def valid?(move)
  move != nil && @board[move] == :empty
end

class TTTGame
  def initialize
    @display = Display.new
    @board = Board.new(@display)
    @human = Human.new(@board, @display)
    @computer = Computer.new(@board)
    @turn = nil
  end

  def close_display
    @display.close
  end

  def play_match
    play_individual_game
  end

  def play_individual_game
    @display.draw_initial_board
    loop do
      next_turn
      @display.show_turn(@turn)
      @turn == :human ? @human.move : @computer.move
      break if @board.full?
      #display everything from here: Try to remove display from human
      #and board classes
    end
  end

  def next_turn
    @turn = if @turn
              @turn == :human ? :computer : :human
            else
              human_goes_first? ? :human : :computer
            end
  end

  def human_goes_first?
    a = @display.retrieve_goes_first_selection == :human
    return a
  end
end

if __FILE__ == $PROGRAM_NAME
  begin
    game = TTTGame.new
    game.play_match
  ensure
    game.close_display
  end
end
