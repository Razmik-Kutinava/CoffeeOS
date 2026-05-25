# frozen_string_literal: true

require "fileutils"
require "net/http"
require "uri"

require_relative "port_killer"

# Проверка /up и фоновый старт Rails для MCP и локальной разработки.
module DevServer
  module_function

  DEFAULT_PORT = 3001
  HEALTH_PATH = "/up"

  def port
    ENV.fetch("PORT", DEFAULT_PORT).to_i
  end

  def base_url
    "http://127.0.0.1:#{port}"
  end

  def healthy?(timeout: 2)
    uri = URI("#{base_url}#{HEALTH_PATH}")
    Net::HTTP.start(uri.host, uri.port, open_timeout: timeout, read_timeout: timeout) do |http|
      res = http.get(uri.path)
      res.is_a?(Net::HTTPSuccess)
    end
  rescue StandardError
    false
  end

  def ensure!(wait_seconds: 90, log: "log/dev-server.log")
    return base_url if healthy?

    warn "=> Rails на :#{port} не отвечает, запускаю..."
    PortKiller.free(port)
    start_background(log: log)
    deadline = Time.now + wait_seconds
    until healthy?
      raise "Сервер не поднялся за #{wait_seconds}s (#{base_url}#{HEALTH_PATH})" if Time.now >= deadline

      sleep 1
    end
    warn "=> Готово: #{base_url}"
    base_url
  end

  def start_background(log: "log/dev-server.log")
    app_root = File.expand_path("..", __dir__)
    log_path = File.join(app_root, log)
    FileUtils.mkdir_p(File.dirname(log_path))
    log_io = File.open(log_path, "a")
    log_io.sync = true
    log_io.puts "\n--- DevServer start #{Time.now.iso8601} ---"

    pid = Process.spawn(
      { "PORT" => port.to_s },
      Gem.ruby,
      File.join(app_root, "bin", "rails"),
      "server",
      "-p", port.to_s,
      "-b", "127.0.0.1",
      chdir: app_root,
      out: log_io,
      err: log_io
    )
    Process.detach(pid)
    pid
  end
end
