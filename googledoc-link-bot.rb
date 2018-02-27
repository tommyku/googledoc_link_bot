# frozen_string_literal: true
require 'telegram/bot'
require 'envyable'
require 'uri'
require 'net/http'
require 'awesome_print'

Envyable.load(File.expand_path('env.yml', File.dirname( __FILE__)))

whitelist = ENV['WHITELIST']

def get_url(text)
  URI.extract(text, ['http', 'https'])[0] || ''
end

def handle_command(message)
  command, param = parse_command(message.text)
  case command
  when /\/start/i
    @bot.api.send_message(chat_id: message.chat.id, text: '咩呀?')
  end
end

def parse_command(text)
  text.split(' ', 2)
end

def is_command?(message)
  message[:entities].each do |val|
    return true if val[:type] == 'bot_command'
  end
  false
end

def handle_message(message)
  reply_text = '咩呀?'
  unless (long_url = get_url(message.text)).empty?
    google_form_uri = URI(ENV['GOOGLE_DOC_LINK']);
    respond = Net::HTTP.post_form(
      google_form_uri,
      ENV['GOOGLE_DOC_ENTRY'] => long_url
    )
    reply_text = "#{respond.code} #{respond.message}";
  end
  begin
    @bot.api.send_message(chat_id: message.chat.id, text: reply_text)
  rescue Telegram::Bot::Exceptions::ResponseError
    # do nothing
  end
end

Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
  @bot = bot
  @bot.listen do |message|
    user_id = message.from.id
    if !whitelist.include?(user_id.to_s)
      @bot.api.send_message(chat_id: message.chat.id, text: '唔比你用')
    else
      if is_command?(message)
        handle_command(message)
      else
        handle_message(message)
      end
    end
  end
end

