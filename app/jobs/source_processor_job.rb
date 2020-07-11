class SourceProcessorJob
  attr_reader :words_frequency, :job_id

  PERSISTED_BATCH_SIZE = 1000

  def initialize(*)
    @words_frequency = {}
    @job_id = SecureRandom.uuid
  end

  def perform
    Rails.logger.info("#{self.class.name} - processing...")
    process_source
    persist_words_frequency
    Rails.logger.info("#{self.class.name} - persisted #{words_frequency.count} words")
  rescue => exc
    Rails.logger.error("#{self.class.name} - processing failed. error: #{exc.message}")
    raise exc
  end

  private

  def persist_words_frequency
    Word.transaction do
      words_frequency.each_slice(PERSISTED_BATCH_SIZE) do |words_frequency_slice|
        Word.bulk_create_or_add(job_id, words_frequency_slice.to_h)
      end
    end
  end

  def text_analyzer
    @text_analyzer ||= TextAnalyzer.new(words_frequency)
  end
end