# Purpose  : Provide command !tinyurl
# Author   : ArchLinuxvn
# Developer: Anh K. Huynh
# License  : Fair license
# Date     : 2012, Somedays (Michale Learns To Rock)

class TinyUrl
  include Cinch::Plugin

  set :help => "Make a shorten version of an URL. Syntax: `!tinyurl <long URL>`. To send the output to someone, try `!give <someone> tinyurl <long URL>`. KNOWN BUG(S): The plugin doesn't work correctly if your URL has some special characters."

  match /tinyurl (https?:\/\/[^ ]+)/, :method => :simple_form

  def simple_form(m, url)
    if url_ = tinyurl(url)
      m.reply "#{url_} <- #{url.slice(0, 20)}"
    end
  end
end
