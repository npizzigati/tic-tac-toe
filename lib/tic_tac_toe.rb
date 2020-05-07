require_relative 'minimax.rb'
require_relative 'display.rb'

class Board
  WINNING_LINES = [0, 1, 2], [3, 4, 5], [6, 7, 8], # horizontal
                  [0, 3, 6], [1, 4, 7], [2, 5, 8], # vertical
                  [0, 4, 8], [2, 4, 6] # diagonal

  include Enumerable

  attr_accessor :squares
  attr_reader :latest_move

  def initialize
    # board array indices
    # 0 | 1 | 2
    # 3 | 4 | 5
    # 6 | 7 | 8
    @squares = Array.new(9) { :empty }
    @latest_move = nil
  end

  # def setup
  #   @squares = Array.new(9) { :empty }
  # end

  def each(&block)
    @squares.each(&block)
  end

  def []=(index, marker)
    @squares[index] = marker
    @latest_move = index
  end

  def [](index)
    @squares[index]
  end

  def delta(other_board)
    @squares.each_with_index do |square, index|
      return index if other_board[index] != square
    end
  end

  def winner
    @winner || determine_winner
  end

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

  def empty?
    @squares.uniq.size == 1
  end

  def full?
    @squares.index(:empty).nil?
  end

  def terminal_state?
    winner || full?
  end
end

class Player
  def initialize(board)
    register_board(board)
  end

  def register_board(board)
    @board = board
  end
end

class Computer < Player
  COMPUTER_MOVE_PAUSE = 0.6

  def initialize(board)
    super
  end

  def move
    move = if first_move?
             (0..8).to_a.sample
           else
             retrieve_minimax_move
           end
    # If the second move on the board is the computer's, this
    # is its first Minimax move, and the algorithm is bit slower,
    # so no need to pause
    sleep COMPUTER_MOVE_PAUSE unless second_move?
    @board[move] = :computer
  end

  def first_move?
    @board.empty?
  end

  def second_move?
    @board.count(:empty) == 8
  end

  def retrieve_minimax_move
    tree = Minimax.new.create_tree(@board)
    best_child_board = tree.children.max do |a, b|
      a.score <=> b.score
    end

    @board.delta(best_child_board)
  end
end

class Human < Player
  def initialize(board, display)
    super(board)
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
  move && @board[move] == :empty
end

class History
  def initialize
    @previous_boards = []
  end

  def <<(board)
    @previous_boards << board
  end

  def count_wins
    wins = @previous_boards.inject([]) do |accum, board|
      accum << board.winner
    end
    human_wins = wins.count(:human)
    computer_wins = wins.count(:computer)

    [human_wins, computer_wins]
  end
end

class TTTGame
  attr_reader :turn

  def initialize
    @display = Display.new
    @board = Board.new
    @human = Human.new(@board, @display)
    @computer = Computer.new(@board)
    @history = History.new
    @game_number = 1
  end

  def play_match
    @display.show_welcome
    loop do
      play_individual_game
      update_stats
      break if @game_number == 5 || !@display.continue_match?

      setup_new_game
    end
    @display.goodbye
  end

  def update_stats
    @history << @board
    human_wins, computer_wins = @history.count_wins
    ties = @game_number - (human_wins + computer_wins)
    @display.show_stats(ties, human_wins, computer_wins)
  end

  def setup_new_game
    @game_number += 1
    @board = Board.new
    [@human, @computer].each do |player|
      player.register_board(@board)
    end
    @display.new_game
  end

  def play_individual_game
    @display.show_game_number(@game_number)
    @turn = @display.retrieve_first_player_selection
    loop do
      @display.show_turn(turn)
      @turn == :human ? @human.move : @computer.move
      @display.mark_square(@board.latest_move, @turn)
      break if @board.terminal_state?

      @turn = switch_turn
    end
    @display.show_outcome(@board.winner)
  end

  def switch_turn
    @turn == :human ? :computer : :human
  end

  def close_display
    @display.close
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    game = TTTGame.new
    game.play_match
  ensure
    game.close_display
  end
end
