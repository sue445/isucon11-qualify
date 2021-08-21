require "dalli"
require "connection_pool"

$memcached = ConnectionPool.new(size: 100, timeout: 5) { Dalli::Client.new("#{ENV["MEMCACHED_HOST"]}:11211", compress: true) }

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
      begin
        cached_response = conn.get(cache_key)
        return cached_response if cached_response
      rescue Dalli::RingError
      end

      actual = yield

      begin
        conn.set(cache_key, actual)
      rescue Dalli::RingError
      end

      actual
    end
  end

  def initialize_memcached
    $memcached.with do |conn|
      conn.flush
    end

    # isuのimageをmemcachedに保存
    rows = db.xquery("SELECT jia_user_id, jia_isu_uuid, image FROM isu")
    rows.each do |isu|
      save_isu_image_to_memcached(
        jia_user_id: isu.fetch(:jia_user_id),
        jia_isu_uuid: isu.fetch(:jia_isu_uuid),
        image: isu.fetch(:image)
      )
    end

    rows = db.xquery("SELECT * FROM isu_condition")
    rows.each do |isu_condition|
      save_latest_isu_condition_to_memcached(isu_condition)
    end
  end

  def save_isu_image_to_memcached(jia_user_id:, jia_isu_uuid:, image:)
    $memcached.with do |conn|
      cache_key = "isu-image-#{jia_user_id}-#{jia_isu_uuid}"
      conn.set(cache_key, image)
    end
  end

  def get_isu_image_from_memcached(jia_user_id:, jia_isu_uuid:)
    $memcached.with do |conn|
      cache_key = "isu-image-#{jia_user_id}-#{jia_isu_uuid}"
      conn.get(cache_key)
    end
  end

  def save_latest_isu_condition_to_memcached(isu_condition)
    $memcached.with do |conn|
      cache_key = "latest-isu-condition-#{isu_condition.fetch(:jia_isu_uuid)}"

      current = conn.get(cache_key)
      if !current || isu_condition[:timestamp] >= current[:timestamp]
        conn.set(cache_key, isu_condition)
      end
    end
  end

  def get_latest_isu_condition_from_memcached(jia_isu_uuid)
    $memcached.with do |conn|
      cache_key = "latest-isu-condition-#{jia_isu_uuid}"
      conn.get(cache_key)
    end
  end
end
