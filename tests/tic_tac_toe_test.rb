require 'minitest/autorun'
require 'stringio'
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

  def test_retrieve_human_move

  end
end
