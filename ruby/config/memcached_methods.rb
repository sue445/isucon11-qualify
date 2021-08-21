require "dalli"
require "connection_pool"

$memcached = ConnectionPool.new(size: 32, timeout: 5) { Dalli::Client.new("#{ENV["MEMCACHED_HOST"]}:11211", compress: true) }

module MemcachedMethods
  # memcachedにあればmemcachedから取得し、キャッシュになければブロック内の処理で取得しmemcachedに保存するメソッド（Rails.cache.fetchと同様のメソッド）
  #
  # @param cache_key [String]
  # @param enabled [Boolean] キャッシュを有効にするかどうか
  #
  # @yield キャッシュがなかった場合に実データを取得しにいくための処理
  # @yieldreturn [Object] redisに保存されるデータ
  #
  # @return [Object] memcachedに保存されるデータ
  def with_memcached(cache_key, enabled: true)
    unless enabled
      return yield
    end

    $memcached.with do |conn|
      cached_response = conn.get(cache_key)
      return cached_response if cached_response

      actual = yield

      conn.set(cache_key, actual)

      actual
    end
  end

  def initialize_memcached
  end

  def save_image_to_memcached

  end
end
