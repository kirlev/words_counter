class StringSourceProcessorJob < SourceProcessorJob
  def initialize(text)
    super
    @text = text
  end

  private

  def process_source
    text_analyzer.count_words_frequency(@text)
  end
end