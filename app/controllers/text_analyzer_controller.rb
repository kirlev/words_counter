class TextAnalyzerController < ApplicationController
  skip_before_action :verify_authenticity_token

  rescue_from ActiveModel::ValidationError do |exception|
    render json: { error: exception.message }, status: :bad_request
  end

  def analyze
    respond_to do |format|
      format.json do
        text_processor = TextProcessorService.new(source_type: params[:source_type],
                                                  source: params[:source])
        text_processor.process

        head :accepted
      end
    end
  end
end
