class RedisFrequencyStore
  attr_reader :store_key

  def initialize(store_key)
    @store_key = store_key
  end

  def count
    redis.hlen(store_key)
  end

  def clear
    redis.del(store_key)
  end

  def increment(word_name)
    redis.hincrby(store_key, word_name, 1)
  end

  def each_slice(keys_count, &block)
    hash = {}

    redis.hscan_each(store_key, count: keys_count) do |(word, count)|
      hash[word] = count.to_i

      if hash.count >= keys_count
        block.call(hash)
        hash = {}
      end
    end

    block.call(hash) if hash.present?
  end

  private
  def redis
    @redis ||= Redis.new
  end
end