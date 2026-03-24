require "puma/plugin"

class Fontawesome
end

Puma::Plugin.create do

  attr_reader :puma_pid, :fontawesome_pid, :log_writer

  def start(launcher)
    @log_writer = launcher.log_writer
    @puma_pid = $PROCESS_ID

    launcher.events.on_booted do

      @fontawesome_pid = fork do

        Thread.new { monitor_puma }

        begin
          # Set up signal handling for clean shutdown
          trap("INT") { exit 0 }
          trap("TERM") { exit 0 }

          require "fontawesome_subsetter"
          subsetter = FontawesomeSubsetter::Subsetter.new
          subsetter.build_watch
        rescue => e
          @log_writer.log "FontAwesome subsetter error: #{ e.message }"
          @log_writer.log e.backtrace.join("\n")
          exit 1
        end

      end

      in_background do

        monitor_fontawesome

      end

    end

    launcher.events.on_stopped { stop_fontawesome }
  end

  private

  def stop_fontawesome
    Process.waitpid(fontawesome_pid, Process::WNOHANG)
    log "Stopping FontAwesome..."
    Process.kill(:INT, fontawesome_pid) if fontawesome_pid
    Process.wait(fontawesome_pid)
  rescue Errno::ECHILD, Errno::ESRCH
  end

  def monitor_puma
    monitor(:puma_dead?, "Detected Puma has gone away, stopping FontAwesome...")
  end

  def monitor_fontawesome
    monitor(:fontawesome_dead?, "Detected FontAwesome has gone away, stopping Puma...")
  end

  def monitor(process_dead, message)
    loop do

      if send(process_dead)
        log message
        Process.kill(:INT, $PROCESS_ID)
        break
      end
      sleep 2

    end
  end

  def fontawesome_dead?
    Process.waitpid(fontawesome_pid, Process::WNOHANG)
    false
  rescue Errno::ECHILD, Errno::ESRCH
    true
  end

  def puma_dead?
    Process.ppid != puma_pid
  end

  def log(...)
    log_writer.log(...)
  end

end
