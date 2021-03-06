require 'minitest/autorun'
require 'stringio'
require 'pry'

require_relative '../lib/tic_tac_toe.rb'

class LineTest < Minitest::Test
  def setup
    @display = Display.new(false)
  end

  def test_draw_horizontal_line
    coord_pair = @display.instance_variable_get :@horizontal1
    horizontal_line = Line.new(coord_pair, [])
    assert_output(/─/) { horizontal_line.draw}
  end

  def test_draw_vertical_line
    coord_pair = @display.instance_variable_get :@vertical1
    vertical_line = Line.new(coord_pair, [])
    assert_output(/│/) { vertical_line.draw }
  end
end

class DisplayTest < Minitest::Test
  def setup
    Line.class_variable_set :@@coords_drawn, []
  end

  def test_draw_two_vertical_lines
    display = Display.new(false)
    assert_output(/│.+│/) { display.draw_board }
  end

  def test_intersections
    display = Display.new(false)
    assert_output(/┼/) { display.draw_board }
  end
end

class BoardTest < Minitest::Test
  def setup
    @display = Display.new(false)
    @board = Board.new(@display)
    @computer = Computer.new(@board)
  end

  # def test_available_moves
  #   expected = (0..8).to_a
  #   actual = @board.available_moves
  #   assert_equal(expected, actual)
  # end
end

class HumanTest < Minitest::Test
  def setup
    @display = Display.new(false)
    @board = Board.new(@display)
    @human = Human.new(@board, @display)
  end
end

class ComputerTest < Minitest::Test
  def setup
    @board = Board.new
    @board.instance_variable_set :@squares, [:empty, :empty, :computer, :computer, :human, :human, :empty, :human, :computer]
    @computer = Computer.new(@board)
  end

  def test_computer_selects_best_move
    @computer.move
    expected = [:empty, :computer, :computer, :computer, :human, :human, :empty, :human, :computer]
    actual = @board.instance_variable_get :@squares
    assert_equal expected, actual
  end

  def test_computer_selects_best_move_2
    @board.instance_variable_set :@squares, [:computer, :empty, :empty, :empty, :human, :empty, :empty, :human, :empty]
    @computer.move
    expected = [:computer, :computer, :empty, :empty, :human, :empty, :empty, :human, :empty]
    actual = @board.instance_variable_get :@squares
    assert_equal expected, actual
  end

  def test_computer_selects_best_move_3
    @board.instance_variable_set :@squares, [:computer, :computer, :human, :empty, :human, :empty, :computer, :human, :empty]
    @computer.move
    expected = [:computer, :computer, :human, :computer, :human, :empty, :computer, :human, :empty]
    actual = @board.instance_variable_get :@squares
    assert_equal expected, actual
  end

  def test_computer_selects_best_move_4
    @board.instance_variable_set :@squares, [:computer, :human, :human, :computer, :empty, :human, :empty, :empty, :empty]
    @computer.move
    expected = [:computer, :human, :human, :computer, :empty, :human, :computer, :empty, :empty]
    actual = @board.instance_variable_get :@squares
    assert_equal expected, actual
  end

  def test_computer_makes_move
    @computer.move
    assert_includes(@board.instance_variable_get(:@squares), :computer)
  end
end

class MinimaxShortTreeTest < Minitest::Test
  def setup
    @board = Board.new
    @board.instance_variable_set :@squares, [:empty, :empty, :computer, :computer, :human, :human, :empty, :human, :computer]
    @tree = Node.new(@board, nil)
  end

  def test_first_node_has_3_child_nodes
    expected = 3
    actual = @tree.children.size
    assert_equal expected, actual
  end

  def test_score_tree
    minimax = Minimax.new
    minimax.score_tree(@tree)
    binding.pry
  end

  # def test_first_node_has_9_children
  #   minimax = Minimax.new
  #   expected = 9
  #   actual = minimax.tree.children.size
  #   assert_equal expected, actual
  # end

end
