# Purpose  : Very simple cron support
# Author   : ArchLinuxvn
# Developer: Anh K. Huynh
# License  : GPLv2
# Date     : 2013 feb 23nd

class Cron
  include Cinch::Plugin

  listen_to :message

  set(:help => "Simple cron support for channel.")

  def initialize(*args)
    super
    @counter = 0
  end

  def listen(m)
    @counter += 1

    # Saving bot configuration every 50 messages + 10 minutes cache
    if @counter % 50 == 0
      if _cache_expired?(:bot, "ConfigAutoSave", :cache_time => 600)
        ret = bot_rc_save!
        m.reply "!!! (cron) #{ret}"
      end
    end

    # reset the counter, avoid possibly overflow issue?
    if @counter % 1000 == 0
      @counter = 1
    end
  end
end
