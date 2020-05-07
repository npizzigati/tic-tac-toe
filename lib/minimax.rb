class Minimax
  def create_tree(board)
    node = Node.new(board, nil)
    score_tree(node)
    node
  end

  def score_tree(node, depth = 0)
    return node.score if node.score

    children_scores = []
    node.children.each do |child|
      children_scores << score_tree(child, depth + 1)
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
  attr_reader :children, :board

  def initialize(board, marker, depth = 9)
    @board = board
    @marker = marker
    @children = []
    @score = nil
    @depth = depth
    if @board.terminal_state?
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
        @children << Node.new(child_board(index), other_marker,
                              @depth - 1)
      end
    end
  end

  def move_available?(index)
    @board[index] == :empty
  end

  def assign_score
    case @board.winner
    when :computer
      1 * @depth
    when :human
      -1 * @depth
    else
      0
    end
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
