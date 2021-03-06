require "sentry-ruby"
require "open3"

module SentryMethods
  def with_sentry
    yield
  rescue => error
    Sentry.capture_exception(error)
    raise error
  end

  # 外部コマンドを実行し、失敗したら標準出力と標準エラーを付与してSentryに送信する
  #
  # @param command [String]
  #
  # @return コマンド実行時の標準出力
  #
  # @raise RuntimeError 外部コマンドが失敗した
  def system_with_sentry(command)
    stdout, stderr, status = Open3.capture3(command)

    unless status.success?
      Sentry.set_extras(
        stdout: stdout,
        stderr: stderr,
      )
      File.write("/tmp/system_with_sentry_stderr.log", "wb") do |f|
        f.write(stderr)
      end
      File.write("/tmp/system_with_sentry_stdout.log", "wb") do |f|
        f.write(stdout)
      end
      raise "`#{command}` is failed"
    end

    stdout
  end
end
