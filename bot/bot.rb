#!/usr/bin/env ruby

# Purpose: Provide simple bot for #archlinuxvn
# Author : Anh K. Huynh <@archlinuxvn>
# License: Fair license
# Date   : 2012 April 05
# NOTE   : the initial code is based on Cinch example

require 'rubygems'
require 'cinch'
require 'uri'
require 'open-uri'

BOT_NAME = "archl0n0xvn"

########################################################################
#                              HELPERS                                 #
########################################################################

# Global variable
# FIXME: flush the CACHE after sometime. Otherwise, the system would run
# FIXME: out of the memory :) Check with garbage collection.
BOT_CACHE      = {}
BOT_CACHE_TIME = 600 # 600 seconds aka 10 minutes

# First event: old val. in the past : expired, allow
# Next  event: now - old > PERM     : expired, allow
# Next  event: now - old < PERM     : not expired, not allowed
def _cache_expired?(section, key)
  now = Time.now
  BOT_CACHE[section]      ||= {}
  if not BOT_CACHE[section][key]
    BOT_CACHE[section][key] = now
    true
  elsif now - BOT_CACHE[section][key] > BOT_CACHE_TIME
    BOT_CACHE[section][key] = now
    true
  else
    false
  end
end

# Provide a simple command , example
# botname: tinyrul <your_url>. The bot will reply to the author
# a tiny version of your URL. HTTP and HTTPS only.
def tinyurl(url)
  url = open("http://tinyurl.com/api-create.php?url=#{URI.escape(url)}").read
  url == "Error" ? nil : url
rescue OpenURI::HTTPError
  nil
end

########################################################################
#                               PLUGINS                                #
########################################################################

class UserMonitor
  include Cinch::Plugin

  listen_to :connect, method: :on_connect
  listen_to :online,  method: :on_online
  #listen_to :offline, method: :on_offline

  # def on_offline(m, user)
  #   @bot.loggers.info "I miss my master :("
  # end

  def on_connect(m)
    User(m.user.nick).monitor
  end

  # Say hello when someone has logged in
  def on_online(m, user)
    user.send "Hello #{m.user.nick}"
  end
end

# Say another hello to follow a previous Hello message
# If A says Hi to B, the bot also says Hi to B (unless B is the bot itself)
class Hello
  include Cinch::Plugin

  listen_to :message

  set(:help => "Say Hello if someone says hello to someone else")

  def listen(m)
    text = nil
    if gs = m.message.match(/^hello[\t ,]*([^\t ]+)/i)
      text = gs[1]
    elsif gs = m.message.match(/^([^ ]: hello)/i)
      text = gs[1]
    end

    return unless text

    if text.match(BOT_NAME)
      m.reply "Hello, #{m.user.nick}" if _cache_expired(:hello, m.user.nick)
    else
      m.reply "Hello, #{text}" if _cache_expired?(:hello, text)
    end
  end
end

# Provice command !tinyurl
class TinyURL
  include Cinch::Plugin

  set :help => "Make a shorten version of an URL. Syntax: `!tinyurl <long URL>`. To send the output to someone, try `!give <someone> tinyurl <long URL>`. KNOWN BUG(S): The plugin doesn't work correctly if your URL has some special characters."

  match /tinyurl (https?:\/\/[^ ]+)/, :method => :simple_form

  def simple_form(m, url)
    if url_ = tinyurl(url)
      m.reply "#{url_} <- #{url.slice(0, 20)}"
    end
  end
end

# Micesslaneous commands to interact with Arch wiki, forum,...
class Give
  include Cinch::Plugin

  set :help => "Give something to someone. Syntax: `!give <someone> <section> <arguments>`. <section> may be `wiki`, `tinyurl`, `some`. For <some>, there are some predefined messages: `thanks`, `shit`, `hugs`, `kiss`, `helps`."

  match /give ([^ ]+) ([^ ]+)(.*)/, :method => :give_something

  def give_something(m, someone, section, args)
    args.strip!
    someone = "#{m.user.nick}" if %{me /me}.include?(someone)

    text = case section
    when "wiki" then
      wiki = args.gsub(" ", "%20")
      wiki ? "https://wiki.archlinux.org/index.php/Special:Search/#{wiki}" : nil
    when "tinyurl" then
      tinyurl(args)
    when "some"
      case args
        when "thanks" then "thank you very much"
        when "shit"   then "oh, you ... s^ck"
        when "hugs"   then "oh, let me hold you tight"
        when "kiss"   then "kiss you a thousand times"
        when "helps"  then "you wanna try google instead"
        else
          if m.user.nick == someone
            "sorry #{someone}. I have nothing good for you"
          else
            "you've got some #{args} from #{m.user.nick}"
          end
      end
    else
      ""
    end

    if text
      if not text.empty?
        m.reply "#{someone}: #{text}"
      else
        m.reply "#{m.user.nick}: nothing to give to #{someone}"
      end
    end
  end
end

# Provide basic commands
class Info
  include Cinch::Plugin

  set(:help => "Provide basic information about ArchLinuxVn. Syntax: `!info <section>`. <section> may be: `home`, `list`, `repo`, `botsrc` or empty. If you want to find helps about the bot, try `!bot help` instead.")

  match /info (.+)/,  :method => :bot_info

  def bot_info(m, section)
    text = case section
      when "home"   then "http://archlinuxvn.tuxfamily.org/"
      when "list"   then "http://groups.google.com/group/archlinuxvn"
      when "repo"   then "http://github.com/archlinuxvn/"
      when "botsrc" then "http://github.com/archlinuxvn/irclog/"
      else nil
    end
    m.reply "#{m.user.nick}: #{text}" if text
  end
end

# Provide basic sensor :)
class Sensor
  include Cinch::Plugin

  set :help => "Send warning if user says bad words. After the warning is sent, the bot will record the event's time and it will not report again within #{BOT_CACHE_TIME} seconds. So... you are safe to say anything you want in #{BOT_CACHE_TIME} seconds without bothering the bot :D. BUG: if your nick match the pattern '#{BOT_NAME}', the bot will simply ignore anything you say. This is a KNOWN bug, so it is't funny if you are trying to trick the bot this way :)"

  listen_to :message

  def listen(m)
    # FIXME: some user can use the BOT_NAME to trick the bot
    return if m.user.nick.match(BOT_NAME)
    badwords = m.message.split.reject{|w| not w.match(/\b(vcl|wtf|sh[1i]t|f.ck|d[e3]k|clgt)\b/i)}
    badwords = badwords.uniq.sort
    m.reply "#{m.user.nick}: take it easy. don't say #{badwords.join(", ")}" if not badwords.empty? and _cache_expired?(:sensor, m.user.nick)
  end
end

class Bot
  include Cinch::Plugin

  set :help => "Query bot information. Syntax: !bot <section>, where section is: help, uptime, uname. You can also check the connection between you and the bot by the !ping command."

  match /bot ([^ ]+)(.*)/, :method => :give_bot_info
  match /ping/,            :method => :ping_pong
  match /help$/,           :method => :help_user

  def help_user(m)
    m.reply "#{m.user.nick}: try `/help` or `!help <plugin_name>`. The first command is the builtin command of your IRC client. The later will query the bot. If you are not sure, you may start with `!help bot` or `!bot help`."
  end

  def ping_pong(m)
    m.reply "#{m.user.nick}: pong"
  end

  def give_bot_info(m, cmd, args)
    text = case cmd
      when "uptime"   then %x{uptime}.strip
      when "uname"    then %x{uname -a}.strip
      when "help"     then "Commands are provided by plugins. " <<
                            "To send command, use `!command`. " <<
                            "To get help message, type `!help <plugin name in lowercase>` " <<
                            "Available plugins: Hello, TinyUrl, Give, Bot, Sensor, Info. " <<
                            "To test the development bot, join #archlinuxvn_bot_devel. " <<
                            "To fix the bot's behavior, visit http://github.com/archlinuxvn/irclog."
      else nil
    end
    m.reply "#{m.user.nick}: #{text}" if text
  end
end

########################################################################
#                               MAIN BOT                               #
########################################################################

channels = Array.new(ARGV).map{|p| "##{p}"}
channels.uniq!

if channels.empty?
  STDERR.write(":: Error: You must specify at least on channel at command line.\n")
  exit 1
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.port = 6697
    c.channels = channels
    c.nick = c.user = c.realname = BOT_NAME
    c.prefix = /^!/
    c.ssl.use = true
    c.plugins.plugins = [
        Hello,
        Sensor,
        UserMonitor,
        TinyURL,
        Info,
        Give,
        Bot,
      ]
  end
end

bot.start
