# frozen_string_literal: true

# Освобождает TCP-порт перед bin/dev и bin/server (Linux ss, macOS lsof, Windows netstat).
module PortKiller
  module_function

  def free(port)
    port = port.to_i
    return if port <= 0

    if Gem.win_platform?
      free_windows(port)
    else
      free_unix(port)
    end
  end

  def free_windows(port)
    output = `netstat -ano 2>nul`
    return if output.nil? || output.empty?

    pids = output.each_line.filter_map do |line|
      next unless line.include?("LISTENING")
      next unless line.match?(/[:\.]#{port}\s/)

      line.split.last.to_i
    end
    pids.select(&:positive?).uniq.each { |pid| terminate(pid, port) }
  end

  def free_unix(port)
    output = `ss -tlnp 2>/dev/null | grep ":#{port} "`.strip
    unless output.empty?
      if output =~ /pid=(\d+)/
        return terminate(Regexp.last_match(1).to_i, port)
      end
    end

    `lsof -ti :#{port} 2>/dev/null`.split.map(&:to_i).select(&:positive?).uniq.each do |pid|
      terminate(pid, port)
    end
  end

  def terminate(old_pid, port)
    warn "=> Порт #{port} занят (PID #{old_pid}), завершаю старый процесс..."
    Process.kill("TERM", old_pid)
  rescue Errno::ESRCH, Errno::EPERM
    nil
  else
    sleep 1.5
    begin
      Process.kill(0, old_pid)
      Process.kill("KILL", old_pid)
    rescue Errno::ESRCH, Errno::EPERM
    end
    sleep 0.5
    warn "=> Порт #{port} освобождён."
  end
end
