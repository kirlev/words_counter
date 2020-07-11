class FileSourceProcessorJob < SourceProcessorJob
  LINES_BATCH_SIZE = 1000

  attr_reader :file_path

  def initialize(file_path)
    super
    @file_path = file_path
  end

  def process_source
    URI.open(file_path) do |file|
      file.each_line do |line|
        text_analyzer.count_words_frequency(line)
      end
    end
  end
end