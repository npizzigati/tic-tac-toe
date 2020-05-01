require 'pry'

require_relative 'minimax.rb'
require_relative 'display.rb'

class Board
  attr_accessor :squares

  def initialize(display)
    @display = display
    # board array indices
    # 0 | 1 | 2
    # 3 | 4 | 5
    # 6 | 7 | 8
    @squares = Array.new(9) { nil }
  end

  def available_moves
    available = []
    @squares.each_with_index do |square, idx|
      available << idx if square.nil?
    end
    available
  end

  def mark_square(number, marker)
    @squares[number] = marker
    @display.mark_square(number, marker)
  end
end

class Computer
  def initialize(board)
    @board = board
  end

  def move
    pause_briefly
    @board.mark_square(retrieve_minimax_move, :computer)
  end

  def retrieve_minimax_move
    tree = Minimax.new.create_tree(@board.squares)
    best_child_board = tree.children.max { |a, b| a.score <=> b.score }.squares
    determine_delta(best_child_board)
  end

  def determine_delta(best_child_board)
    @board.squares.each_with_index do |square, square_number|
      return square_number if best_child_board[square_number] != square
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
    move = nil
    until valid?(move)
      move = @display.retrieve_human_move
    end
    @board.mark_square(move, :human)
  end
end

def valid?(move)
  move != nil && @board.squares[move].nil?
end

class TTTGame
  def initialize
    @display = Display.new
    @board = Board.new(@display)
    @human = Human.new(@board, @display)
    @computer = Computer.new(@board)
  end

  def close_display
    @display.close
  end

  def play
    @display.draw_initial_board
    4.times do
      @human.move
      @computer.move
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  begin
    game = TTTGame.new
    game.play
  ensure
    game.close_display
  end
end
