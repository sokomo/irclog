# Purpose  : A simple betting game
# Author   : ArchLinuxvn
# Developer: sokomo
# License  : GPLv2
# Date     : 2013 December 21st

class Btbot
  include Cinch::Plugin

  set :help => "Play Bet game with the bot. To start the game, type `!btbot <number> [<score>] [<ratio>]`, where `<number>` is a number in the range from 0 to 1000. The bot will randomly choose a random betting number and random midle number to find the winner. The rule is: The number is most near to the midle number is the winner. The winner will get/lost a random number of nutshells (5, 10 or 15) multiply with the ratio. You can also give a bet number, and ratio, for example `!btbot 400 50 2`. The score should not excess 200 and ratio should not excess 5."

  match /btbot ([^[:space:]]+) ([[:space:]]+[0-9]+) ([[:space:]]+[0-9]+)?\b/,  :method => :btbot_play

  def btbot_play(m, betnumber, mscore, ratio)
    return unless _cache_expired?(:btbot, "#{m.user.nick}", :cache_time => 10)

    if betnumber
      betnumber = betnumber.strip.to_i.abs
      if betnumber > 1000
        m.reply "#{m.user.nick}: You can't exceed the betting number."
        return
      end 
    end

    if mscore
      mscore = mscore.strip.to_i.abs
    end

    if ratio
      ratio = ratio.strip.to_i.abs
      if ratio > 5
        m.reply "#{m.user.nick}: You can't exceed the ratio greater than 5."
        return
      end
    end

    bot_number = rand(1001);

    if betnumber > bot_number
      bot_mid_number = rand(betnumber + 1 - bot_number) + bot_number
    elsif betnumber < bot_number
      bot_mid_number = rand(bot_number + 1 - betnumber) + betnumber
    else
      bot_mid_number = -1
    end

    diff_user_num = (betnumber - bot_mid_number).abs
    diff_bot_num = (bot_number - bot_mid_number).abs

    nutshell, ret = \
    Btbot::_win?(diff_bot_num - diff_user_num, mscore, ratio)
    
    bot_nutshell_give!(:masterbank, m.user.nick, nutshell, :allow_doubt => true, :reason => "btbot_play")
    m.reply "#{m.user.nick}: #{ret}. Got #{nutshell}. Now have #{bot_score!(m.user.nick, 0)} nutshell(s)"
  end

  class << self
    # Return [score, message]
    # Score > 0: Win, get a positive number of nutshells (up to 3)
    # Score < 0: Loose, get a negative number of nutshells (up to 2)
    # Mscore: nil or the amount that user bet
    def _win?(score, mscore = nil, multiply = nil)
      mscore = 5 * (1+rand(3)) if not mscore or mscore == 0
      multiply = 1 if not multiply or multiply == 0
      mscore = mscore * multiply
      if score > 0
        [mscore, "You win"]
      elsif score < 0
        [- mscore, "You loose"]
      else
        [0, "Draw"]
      end
    end
  end
end
