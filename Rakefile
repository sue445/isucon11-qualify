# Requirements
# * ruby
# * curl
# * gh
#   * https://github.com/cli/cli
#   * gh auth login
#
# Usage
# * rake

# デプロイ先のサーバ
HOSTS = {
  host01: "18.181.130.91", # front, db, app(uploader)
  host02: "52.194.98.165",  # app(main)
  host03: "54.249.131.215", # app(main)
}

INITIALIZE_ENDPOINT = "https://isucondition.t.isucon.dev/initialize_from_local"

# デプロイ先のカレントディレクトリ
CURRENT_DIR = "/home/isucon/webapp"

# rubyアプリのディレクトリ
RUBY_APP_DIR = "/home/isucon/webapp/ruby"

# アプリのservice名
APP_SERVICE_NAME = "isucondition.ruby.service"

# デプロイを記録するissue
GITHUB_REPO     = "sue445/isucon11-qualify"
GITHUB_ISSUE_ID = 1

BUNDLE = "/home/isucon/local/ruby/bin/bundle"

def exec(ip_address, command, cwd: CURRENT_DIR)
  sh %Q(ssh isucon@#{ip_address} 'cd #{cwd} && #{command}')
end

namespace :deploy do
  HOSTS.each do |name, ip_address|
    desc "Deploy to #{name}"
    task name do
      puts "[deploy:#{name}] START"

      # common
      exec ip_address, "git pull --ff"

      exec ip_address, "sudo cp infra/systemd/#{APP_SERVICE_NAME} /etc/systemd/system/#{APP_SERVICE_NAME}"

      # systemdの更新後にdaemon-reloadする
      exec ip_address, "sudo systemctl daemon-reload"

      # TODO: 終了10分前にdisableすること！！！！！！
      exec ip_address, "sudo systemctl restart newrelic-infra"
      # exec ip_address, "sudo systemctl disable newrelic-infra"
      # exec ip_address, "sudo systemctl stop newrelic-infra"
      # exec ip_address, "sudo systemctl enable newrelic-infra"
      # exec ip_address, "sudo systemctl start newrelic-infra"

      # mysql
      case name
      when :host01
        exec ip_address, "sudo cp infra/mariadb/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf"
        exec ip_address, "sudo mysqld --verbose --help > /dev/null"
        exec ip_address, "sudo systemctl restart mariadb"
      else
        exec ip_address, "sudo systemctl stop mariadb"
      end

      # nginx
      case name
      when :host01
        exec ip_address, "sudo cp infra/nginx/nginx.conf /etc/nginx/nginx.conf"
        exec ip_address, "sudo nginx -t"
        exec ip_address, "sudo rm -f /var/log/nginx/*.log"
        exec ip_address, "sudo systemctl restart nginx"
      else
        exec ip_address, "sudo systemctl stop nginx"
      end

      # app
      case name
      when :host01, :host03
        exec ip_address, "#{BUNDLE} install --path vendor/bundle --jobs $(nproc)", cwd: RUBY_APP_DIR
        exec ip_address, "#{BUNDLE} config set --local path 'vendor/bundle'", cwd: RUBY_APP_DIR
        exec ip_address, "#{BUNDLE} config set --local jobs $(nproc)", cwd: RUBY_APP_DIR
        exec ip_address, "#{BUNDLE} install", cwd: RUBY_APP_DIR

        exec ip_address, "sudo systemctl stop #{APP_SERVICE_NAME}"
        exec ip_address, "sudo systemctl start #{APP_SERVICE_NAME}"
        exec ip_address, "sudo systemctl status #{APP_SERVICE_NAME}"
      else
        exec ip_address, "sudo systemctl stop #{APP_SERVICE_NAME}"
      end

      exec ip_address, "sudo rm -f /tmp/sql.log"
      exec ip_address, "rm -rf tmp/stackprof/*", cwd: RUBY_APP_DIR

      # memcached
      case name
      when :host01
        # exec ip_address, "sudo cp infra/memcached/memcached.conf /etc/memcached.conf"
        # exec ip_address, "sudo systemctl restart memcached"
      else
        # exec ip_address, "sudo systemctl stop memcached"
      end

      # redis
      case name
      when :host01
        # exec ip_address, "sudo cp infra/redis/redis.conf /etc/redis/redis.conf"
        # exec ip_address, "sudo systemctl restart redis"
      else
        # exec ip_address, "sudo systemctl stop redis-server"
      end

      # sidekiq
      case name
      when :host01
        # exec ip_address, "#{BUNDLE} install --path vendor/bundle --jobs $(nproc)", cwd: "#{CURRENT_DIR}/webapp/ruby"
        # exec ip_address, "sudo systemctl stop isutrain-sidekiq.service"
        # exec ip_address, "sudo systemctl start isutrain-sidekiq.service"
        # exec ip_address, "sudo systemctl status isutrain-sidekiq.service"
      else
        # exec ip_address, "sudo systemctl stop isutrain-sidekiq.service"
      end

      # docker-compose
      case name
      when :host01
        # exec ip_address, "docker-compose -f webapp/docker-compose.yml -f webapp/docker-compose.ruby.yml down"
        # exec ip_address, "docker-compose -f webapp/docker-compose.yml up -d --build"
      else
        # exec ip_address, "docker-compose -f webapp/docker-compose.yml -f webapp/docker-compose.ruby.yml down"
      end

      puts "[deploy:#{name}] END"
    end
  end
end

desc "Prepare for deploy"
task :setup do
  sh "git push"
end

desc "Deploy to all hosts"
multitask :deploy => HOSTS.keys.map { |name| "deploy:#{name}" }

desc "POST /initialize"
task :initialize do
  sh "curl --max-time 20 -X POST --retry 3 --fail #{INITIALIZE_ENDPOINT}"
end

desc "Record current commit to issue"
task :record do
  revision = `git rev-parse --short HEAD`.strip

  current_tag = [
    Time.now.strftime("%Y%m%d-%H%M%S"),
    `whoami`.strip
  ].join("-")

  message = ":rocket: Deployed #{revision} [#{current_tag}](https://github.com/#{GITHUB_REPO}/releases/tag/#{current_tag})"

  # 直前のリリースのtagを取得する
  before_tag = `git tag | tail -n 1`.strip

  unless before_tag.empty?
    message << " ([compare](https://github.com/#{GITHUB_REPO}/compare/#{before_tag}...#{current_tag}))"
  end

  sh "git tag -a #{current_tag} -m 'Release #{current_tag}'"
  sh "git push --tags"

  sh "gh issue comment --repo #{GITHUB_REPO} #{GITHUB_ISSUE_ID} --body '#{message}'"
end

task :all => [:setup, :deploy, :initialize, :record]

task :default => :all
