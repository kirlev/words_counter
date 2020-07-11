class TextProcessorService
  include ActiveModel::Validations

  MAX_ALLOWED_STRING = 1000
  ALLOWED_SOURCE_TYPES = %w(string file_path url)

  attr_reader :source, :source_type

  validates_inclusion_of :source_type, in: ALLOWED_SOURCE_TYPES
  validates_presence_of :source, :source_type
  validates_length_of :source, maximum: MAX_ALLOWED_STRING, if: -> { source_type == 'string' }
  validates_format_of :source, with: URI.regexp, if: -> { source_type == 'url' }
  validate :file_exists?, if: -> { source_type == 'file_path' }

  def initialize(source_type:, source:)
    @source_type = source_type
    @source = source

    validate!
  end

  def process
    source_handler = source_handlers[source_type.to_sym]
    source_processing_job = source_handler.new(source)
    Delayed::Job.enqueue(source_processing_job, queue: source_type)

    Rails.logger.info("#{source_type} processing job is enqueued")
  rescue => exc
    Rails.logger.error("Failed to enqueue the source processing, source type: #{source_type}")
    raise exc
  end

  private

  def file_exists?
    unless (source && File.file?(source))
      errors.add :source, "Is an invalid file path!"
    end
  end

  def source_handlers
    {
      string: StringSourceProcessorJob,
      file_path: FileSourceProcessorJob,
      url: FileSourceProcessorJob,
    }
  end
end