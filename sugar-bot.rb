require 'discordrb'
require 'rest-client'
require 'json'

bot = Discordrb::Commands::CommandBot.new token: 'NDY5MjkzMTcxMzk5MTk2NzAy.DjIH5w.v4l7T1MaCxbnmVJlJUO5tJmYpJo', prefix: '!'
fmAPIkey = 'cb7be8fb2f185dbb396dcd1b8c28b32d'
#RestClient.get 'http://localhost', :user_agent => "PorousBoat"

bot.command :PlasticLove do |event|
  event.respond 'https://i.kym-cdn.com/entries/icons/original/000/019/785/stopit.png'
end

bot.command :fm do |event|
    argArr = event.message.content.split(/\s+/)
    if argArr.length >= 1
        subCommand = argArr[1]
    end
    File.open('fmusers.dump') do |f|
        if File.zero?(f)
            @userList = {}
        else
            @userList = Marshal.load(f)
        end
    end
    if @userList != nil && @userList.has_value?(event.user.name)
        case subCommand
        when nil
            currentTrack = JSON.parse(RestClient.get 'http://ws.audioscrobbler.com/2.0/', {params: {method: 'user.getrecenttracks', user: @userList[event.user.name], limit: 1, api_key: fmAPIkey, format: 'json'}})
            #puts currentTrack
            albumCover = currentTrack['recenttracks']['track'][0]['image'][2]['#text']
            puts albumCover
            event.channel.send_embed do |embed|
                embed.thumbnail = Discordrb::Webhooks::EmbedImage.new(url: albumCover)
                embed.colour = '4286f4'
                embed.add_field(name: 'Title: ', value: currentTrack['recenttracks']['track'][0]['name'])
                embed.add_field(name: 'Artist: ', value: currentTrack['recenttracks']['track'][0]['artist']['#text'])
                embed.add_field(name: 'Album: ', value: currentTrack['recenttracks']['track'][0]['album']['#text'])
            end
        end
    elsif subCommand == 'setuser'
        puts "check 2"
        @userList[event.user.name] = argArr[2]
        File.open('fmusers.dump', 'w') do |f|
			Marshal.dump(@userList, f)
		end
		"Last.fm user " + argArr[2] + " set for Discord user " + event.user.name + "!"
    else
        puts "check 3"
        "No last.fm user found. Use \"!fm setuser <username>\" to set a username."
    end
end

bot.run