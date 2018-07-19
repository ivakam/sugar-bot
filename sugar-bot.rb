require 'discordrb'

bot = Discordrb::Bot.new token: '7qb2HRkc-7E7A-bUbKZzUlnNQgvmMVkQ', client_id: 469293171399196702

bot.message(with_text: 'Ping!') do |event|
  event.respond 'Pong!'
end

bot.run