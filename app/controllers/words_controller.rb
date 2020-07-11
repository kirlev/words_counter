class WordsController < ApplicationController
  def show
    word_name = params[:name]
    @word = Word.find_by(name: word_name)

    render json: { word: word_name, count: @word&.count || 0 }
  end
end
