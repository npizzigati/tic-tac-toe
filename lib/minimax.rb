class Minimax
  def create_tree(board)
    node = Node.new(board, nil)
    score_node(node)
    node
  end

  def score_node(node, depth = 0)
    return node.score if node.score

    children_scores = []
    node.children.each do |child|
      children_scores << score_node(child, depth + 1)
    end
    node.score = if depth.even?
                   children_scores.max
                 else
                   children_scores.min
                 end
  end
end

class Node
  attr_accessor :score

  attr_reader :winner, :children, :board

  def initialize(board, marker)
    @board = board
    @marker = marker
    @winner = @board.determine_winner
    @children = []
    @score = nil
    if terminal_node?
      @score = assign_score
    else
      add_children
    end
  end

  def [](index)
    @board[index]
  end

  def add_children
    0.upto(8) do |index|
      if move_available?(index)
        @children << Node.new(child_board(index), other_marker)
      end
    end
  end

  def move_available?(index)
    @board[index] == :empty
  end

  def assign_score
    case @winner
    when :computer
      1
    when :human
      -1
    else
      0
    end
  end

  def terminal_node?
    @winner || @board.full?
  end

  def child_board(index)
    child_board = Board.new
    child_board.squares = @board.squares.dup
    child_board[index] = other_marker

    child_board
  end

  def other_marker
    return :computer if @marker == :human || @marker.nil?

    :human
  end
end
