class Word < ApplicationRecord
  def self.bulk_create_or_add(words_count)
    values = build_values_string(words_count)
    query = generate_bulk_upsert_query(values)

    ActiveRecord::Base.connection.execute(query)
  end

  private

  def self.build_values_string(words_count)
    values = words_count.map do |word, count|
      escaped_word = word.to_s.gsub("'","''")
      "('#{escaped_word}', #{count})"
    end

    values.join(",")
  end

  # *upsert_all* supports only replacing the value not adding to existing value so I could not use it
  def self.generate_bulk_upsert_query(values)
    %Q{INSERT INTO words(name, count) VALUES #{values}
ON CONFLICT (name) DO UPDATE SET count = "count" + excluded."count"
    }
  end
end
