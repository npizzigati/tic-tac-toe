require 'minitest/autorun'
require 'stringio'
require 'pry'
require_relative '../lib/tic_tac_toe.rb'

class LineTest < Minitest::Test
  def setup
    Line.class_variable_set :@@coords_drawn, []
  end

  def teardown
    # STDIN.cooked!
  end

  def test_draw_horizontal_line
    coord_pair = TTTDisplay::HORIZONTAL1
    horizontal_line = Line.new(coord_pair)
    assert_output(/─/) { horizontal_line.draw}
  end

  def test_draw_vertical_line
    coord_pair = TTTDisplay::VERTICAL1
    vertical_line = Line.new(coord_pair)
    assert_output(/│/) { vertical_line.draw }
  end
end

class DisplayTest < Minitest::Test
  def setup
    Line.class_variable_set :@@coords_drawn, []
  end

  def teardown
  end

  def test_draw_two_vertical_lines
    display = TTTDisplay.new
    assert_output(/│.+│/) { display.draw_lines }
  end

  def test_intersections
    display = TTTDisplay.new
    assert_output(/┼/) { display.draw_lines }
  end
end

class BoardTest < Minitest::Test
  def setup
    @display = TTTDisplay.new
    @board = TTTBoard.new(@display)
    @computer = Computer.new(@board)
  end

  def test_available_moves
    expected = (0..8).to_a
    actual = @board.available_moves
    assert_equal(expected, actual)
  end
end

class HumanTest < Minitest::Test
  def setup
    @display = TTTDisplay.new
    @board = TTTBoard.new(@display)
    @human = Human.new(@board, @display)
  end

  def test_valid_move?
    @board.positions = [:X, nil, nil, nil, nil, nil, nil, nil, nil]
    @human.instance_variable_set :@move, 0
    expected = false
    actual = @human.valid_move?
    assert_equal expected, actual
  end
end

class ComputerTest < Minitest::Test
  COMPUTER_MARKER = :X
  def setup
    @display = TTTDisplay.new
    @board = TTTBoard.new(@display)
    @board.positions = [nil, nil, :X, :X, :O, :O, nil, :O, :X]
    @computer = Computer.new(@board)
  end

  def test_computer_selects_best_move
    @computer.move
    expected = [nil, :X, :X, :X, :O, :O, nil, :O, :X]
    actual = @board.positions
    assert_equal expected, actual
  end

  def test_computer_makes_move
    @computer.move
    assert_includes(@board.positions, COMPUTER_MARKER)
  end
end

class MinimaxShortTreeTest < Minitest::Test
  def setup
    @board = [nil, nil, :X, :X, :O, :O, nil, :O, :X]
    @tree = Node.new(@board, nil)
  end

  def test_first_node_has_3_child_nodes
    expected = 3
    actual = @tree.children.size
    assert_equal expected, actual
  end

  def test_score_node
    minimax = Minimax.new
    minimax.score_node(@tree)
  end

  # def test_first_node_has_9_children
  #   minimax = Minimax.new
  #   expected = 9
  #   actual = minimax.tree.children.size
  #   assert_equal expected, actual
  # end

end
