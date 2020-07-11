class Word < ApplicationRecord
  def self.bulk_create_or_add(updated_by, words_count)
    values = build_values_string(updated_by, words_count)
    query = generate_bulk_upsert_query(values)

    ActiveRecord::Base.connection.execute(query)
  end

  private

  def self.build_values_string(updated_by, words_count)
    values = words_count.map do |word, count|
      escaped_word = word.to_s.gsub("'","''")
      "('#{escaped_word}', #{count}, '#{updated_by}')"
    end

    values.join(",")
  end

  # *upsert_all* supports only replacing the value not adding to existing value so I could not use it
  def self.generate_bulk_upsert_query(values)
    %Q{INSERT INTO words(name, count, updated_by) VALUES #{values}
ON CONFLICT (name) DO UPDATE SET
updated_by = excluded."updated_by",
count = CASE WHEN "updated_by" != excluded."updated_by" THEN "count" + excluded."count" ELSE "count" END
    }
  end
end
