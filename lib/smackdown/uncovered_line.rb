module Smackdown
  class UncoveredLine
    attr_reader :line_num, :line_content

    def initialize(line_num, line_content)
      @line_num = line_num
      @line_content = line_content
    end
  end
end
