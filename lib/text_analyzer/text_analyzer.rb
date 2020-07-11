class TextAnalyzer
  attr_reader :words_frequency_storage

  def initialize(data_storage = {})
    @words_frequency_storage = data_storage
  end

  def count_words_frequency(text)
    words_array = generate_words_array(text)

    words_array.each do |word|
      words_frequency_storage[word.to_sym] ||= 0
      words_frequency_storage[word.to_sym] += 1
    end

    words_frequency_storage
  end

  private

  def self.redis
    @redis = Redis.new
  end

  def generate_words_array(text)
    tokenizer_options = {
      punctuation: :none, # Removes all punctuation from the result.
      numbers: :none, # Removes all tokens that include a number from the result (including Roman numerals)
      remove_emoji: :true, # remove any emoji tokens
      remove_urls: :true, # remove any urls
      remove_emails: :true, # remove any emails
      remove_domains: :true, # remove any domains
      hashtags: :keep_and_clean, # remove the hastag prefix
      mentions: :keep_and_clean, # remove the @ prefix
      clean: true, # remove some special characters
      classic_filter: true, # removes dots from acronyms and 's from the end of tokens
      downcase: true, # downcase tokens
      minimum_length: 2, # remove any tokens less than 3 characters
      expand_contractions: true
    }

    tokenizer = PragmaticTokenizer::Tokenizer.new(tokenizer_options)
    tokenizer.tokenize(text)
  end
end