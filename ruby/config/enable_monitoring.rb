# NewRelic, Sentry, stackprofの一括有効＆一括無効を1ファイルのみで行うためのファイル
require "sentry-ruby"
require "stackprof"
require "sinatra"

require_relative "./nr_mysql2_client"

Sentry.init do |config|
  config.enabled_environments = %w[production development]
end

def enabled_stackprof_path?(env)
  return true

  # TODO: 個別指定の場合はsave_everyを小さくしないとdumpが保存されないので一緒に変更すること
  case env["REQUEST_METHOD"]
  when "GET"
    # case env["PATH_INFO"]
    # when %r{^/users/[0-9]+$}
    #   return true
    # end

  when "POST"
    # case env["PATH_INFO"]
    # when "/message"
    #   return true
    # end

  end

  false
end

# NOTE: 書くのをよく忘れるのでファイルをrequireした時点で自動でSentry::Rack::CaptureExceptionsとStackProf::Middlewareが適用されるようにする
class Sinatra::Base
  use Sentry::Rack::CaptureExceptions

  use StackProf::Middleware,
      mode: :cpu,
      interval: 1000,
      raw: true,
      save_every: 100,
      path: "tmp/stackprof/",
      # 特定のPATHのみstackprofを有効化する
      enabled: -> (env) { enabled_stackprof_path?(env) }
end

module Mysql2ClientQueryWithNewRelic
  def query(sql, *args)
    NRMysql2Client.with_newrelic(sql) do
      super
    end
  end
end

# アプリケーションコードを書き換えるのが面倒なのでファイルがrequireされた時点でMysql2::ClientでNewRelicが使われるようにする
class Mysql2::Client
  prepend Mysql2ClientQueryWithNewRelic
end
