require 'pry'

require_relative 'minimax.rb'
require_relative 'display.rb'

class Board
  include Enumerable

  # attr_accessor :squares

  def initialize(display)
    @display = display
    # board array indices
    # 0 | 1 | 2
    # 3 | 4 | 5
    # 6 | 7 | 8
    @squares = Array.new(9) { nil }
  end

  def each(&block) 
    @squares.each(&block)
  end

  def []=(index, marker)
    @squares[index] = marker
    @display.mark(index, marker)
  end

  def [](index)
    @squares[index]
  end

  def full?
    @squares.index(nil).nil?
  end

  # def available_moves
  #   available = []
  #   @squares.each_with_index do |square, idx|
  #     available << idx if square.nil?
  #   end
  #   available
  # end
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
    best_child_board = tree.children.max { |a, b| a.score <=> b.score }
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
    move = nil
    until valid?(move)
      move = @display.retrieve_human_move
    end
    @board[move] = :human
  end
end

def valid?(move)
  move != nil && @board[move].nil?
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
