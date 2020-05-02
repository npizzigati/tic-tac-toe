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
  WINNING_LINES = [0, 1, 2], [3, 4, 5], [6, 7, 8], # horizontal
                   [0, 3, 6], [1, 4, 7], [2, 5, 8], # vertical
                   [0, 4, 8], [2, 4, 6] # diagonal

  # attr_accessor :squares, :marker, :score, :children
  attr_accessor :score

  attr_reader :winner, :children, :board

  def initialize(board, marker)
    @board = board
    @marker = marker
    @winner = determine_winner
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
    0.upto(8) do |idx|
      if move_available?(idx)
        @children << Node.new(child_board(idx),
                             other_marker)
      end
    end
  end

  def move_available?(idx)
    @board[idx].nil?
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
    @winner || tie?
  end

  def child_board(idx)
    @board[0...idx] +
      [other_marker] +
      @board[(idx + 1)..-1]
  end

  def determine_winner
    WINNING_LINES.each do |line|
      line_of_markers = replace_indices_with_markers(line)
      return line_of_markers.first if line_of_markers.uniq.size == 1
    end
    nil
  end

  def replace_indices_with_markers(line)
    line.map { |index| @board[index] }
  end

  def tie?
    @board.find_index(nil).nil? # All moves taken
  end

  def other_marker
    return :computer if @marker == :human || @marker.nil?

    :human
  end
end
