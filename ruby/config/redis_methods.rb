require "redis"
require "connection_pool"
require "oj"

$redis = ConnectionPool::Wrapper.new(size: 32, timeout: 3) { Redis.new(host: ENV["REDIS_HOST"]) }

::Oj.default_options = { mode: :compat }

module RedisMethods
  # redisにあればredisから取得し、キャッシュになければブロック内の処理で取得しredisに保存するメソッド（Rails.cache.fetchと同様のメソッド）
  #
  # @param cache_key [String]
  # @param enabled [Boolean] キャッシュを有効にするかどうか
  # @param is_object [Boolean] String以外を保存するかどうか
  #
  # @yield キャッシュがなかった場合に実データを取得しにいくための処理
  # @yieldreturn [Object] redisに保存されるデータ
  #
  # @return [Object] redisに保存されるデータ
  def with_redis(cache_key, enabled: true, is_object: false)
    unless enabled
      return yield
    end

    cached_response = $redis.get(cache_key)
    if cached_response
      if is_object
        # return Marshal.load(cached_response)
        return Oj.load(cached_response)
      else
        return cached_response
      end
    end

    actual = yield

    if actual
      if is_object
        # data = Marshal.dump(actual)
        data = Oj.dump(actual)

        $redis.set(cache_key, data)
      else
        $redis.set(cache_key, actual)
      end
    end

    actual
  end

  def initialize_redis
    $redis.flushall

    # isuのimageをredisに保存
    rows = db.xquery("SELECT jia_user_id, jia_isu_uuid, image FROM isu")
    rows.each do |isu|
      save_isu_image_to_redis(
        jia_user_id: isu.fetch(:jia_user_id),
        jia_isu_uuid: isu.fetch(:jia_isu_uuid),
        image: isu.fetch(:image)
      )
    end

    rows = db.xquery("SELECT * FROM isu_condition")
    rows.each do |isu_condition|
      save_latest_isu_condition_to_redis(isu_condition)
    end
  end

  def clear_isu_graph_response_from_redis(jia_isu_uuid)
    keys = $redis.keys("generate_isu_graph_response:#{jia_isu_uuid}:*")
    $redis.del(*keys)
  end

  def save_isu_image_to_redis(jia_user_id:, jia_isu_uuid:, image:)
    cache_key = "isu-image-#{jia_user_id}-#{jia_isu_uuid}"
    data = { image: image }
    $redis.set(cache_key, data = Oj.dump(data))
  end

  def get_isu_image_from_redis(jia_user_id:, jia_isu_uuid:)
    cache_key = "isu-image-#{jia_user_id}-#{jia_isu_uuid}"
    data = $redis.get(cache_key)

    if data
      return Oj.load(data)["image"]
    end

    nil
  end

  def save_latest_isu_condition_to_redis(isu_condition)
    cache_key = "latest-isu-condition-#{isu_condition.fetch(:jia_isu_uuid)}"

    cache = $redis.get(cache_key)
    if cache
      current = Oj.load(cache)

      if isu_condition[:timestamp] >= current["timestamp"]
        conn.set(cache_key, Oj.dump(isu_condition))
      end

    end
  end

  def get_latest_isu_condition_from_redis(jia_isu_uuid)
    cache_key = "latest-isu-condition-#{jia_isu_uuid}"
    cache = $redis.get(cache_key)

    if cache
      Oj.load(cache).transform_keys(&:to_sym)
    end

    nil
  end
end
