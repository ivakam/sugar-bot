require 'discordrb'
require 'rest-client'
require 'json'
require 'titleize'

discordKey = File.read('discord_api_key.txt')
fmAPIkey = File.read('fm_api_key.txt')
#userAgent = File.read('user_agent.txt')
bot = Discordrb::Commands::CommandBot.new token: discordKey, prefix: '!'
googleAPIkey = 'AIzaSyDtC4ustRkZdE_C7ppOi3pUTh9hHnQSXGg'
#RestClient.get 'http://localhost', :user_agent => userAgent

bot.message do |event|
    command = event.message.content.split(/\s+/)[0]
    commandList = ["!fm", "!yt", "!plasticlove", "!help", "!flapper"]
    if command[0] == '!'
        unless commandList.include?(command)
            event.respond "Unknown command. Please see \"!help\" for a list of available commands"
        end
    end
end

bot.command :help do |event|
    event.channel.send_embed do |embed|
        embed.title = "Preface all commands with \"!\""
        embed.thumbnail = Discordrb::Webhooks::EmbedImage.new(url: 'https://i.imgur.com/ceYNiDi.png')
        embed.colour = 'd3d3d3'
        embed.add_field(name: 'Last.fm: ', value: "!fm displays currently scrobbling track.")
        embed.add_field(name: 'Youtube: ', value: "!yt <search terms> displays first search result on Youtube.")
    end
end

bot.command :plasticlove do |event|
    event.respond 'https://i.kym-cdn.com/entries/icons/original/000/019/785/stopit.png'
end

bot.command :flapper do |event|
    event.respond 'https://cdn.discordapp.com/emojis/393439670475685888.png?v=1'
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
    if subCommand == 'setuser'
        @userList[event.user.name] = argArr[2]
        File.open('fmusers.dump', 'w') do |f|
			Marshal.dump(@userList, f)
		end
		"Last.fm user " + argArr[2] + " set for Discord user " + event.user.name + "!"
    elsif @userList != nil && @userList[event.user.name] != nil
        case subCommand
        when nil
            currentTrack = JSON.parse(
                RestClient.get 'http://ws.audioscrobbler.com/2.0/',
                {
                    params:
                    {
                        method: 'user.getrecenttracks',
                        user: @userList[event.user.name],
                        limit: 1,
                        api_key: fmAPIkey,
                        format: 'json'
                    }
                }
            )
            albumCover = currentTrack['recenttracks']['track'][0]['image'][3]['#text']
            event.channel.send_embed do |embed|
                embed.colour = '4286f4'
                embed.url = 'http://www.last.fm/user/' + @userList[event.user.name]
                embed.title = event.user.name + '\'s last.fm profile'
                embed.description = 'Currently scrobbling:'
                if albumCover != ''
                    embed.thumbnail = Discordrb::Webhooks::EmbedImage.new(url: albumCover)
                else
                    embed.thumbnail = Discordrb::Webhooks::EmbedImage.new(url: 'https://i.imgur.com/EJ9UpgY.jpg')
                end

                if extractTrackInfo(currentTrack, 'name') != ''
                    embed.add_field(name: 'Title: ', value: extractTrackInfo(currentTrack, 'name'), inline: true)
                else
                    embed.add_field(name: 'Title: ', value: '*Unknown title*', inline: true)
                end
                
                if extractTrackInfo(currentTrack, 'artist') != ''
                    embed.add_field(name: 'Artist: ', value: extractTrackInfo(currentTrack, 'artist'), inline: true)
                else
                    embed.add_field(name: 'Artist: ', value: '*Unknown artist*', inline: true)
                end
                
                if extractTrackInfo(currentTrack, 'album') != ''
                    embed.add_field(name: 'Album: ', value: extractTrackInfo(currentTrack, 'album'), inline: true)
                else
                    embed.add_field(name: 'Album: ', value: '*Unknown album*', inline: true)
                end
                
                embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: 'Sugar Bot by PorousBoat')
                embed.timestamp = Time.now
            end
        end
    else
        "No last.fm user found. Use \"!fm setuser <username>\" to set a username."
    end
end

bot.command :yt do |event|
    argArr = event.message.content.split(/^\w+\s+/)
    query = argArr[0]
    puts query
    if query != "!yt"
        searchResult = JSON.parse(
            RestClient.get 'https://www.googleapis.com/youtube/v3/search',
            {
                params:
                {
                    part: 'snippet',
                    maxResults: 1,
                    q: argArr[0],
                    type: 'video',
                    key: googleAPIkey
                }
            }
        )
        event.respond("https://youtube.com/watch/" + searchResult['items'][0]['id']['videoId'])
    else
        event.respond("Enter a search term to search.")
    end
end

#Helper for traversing track info

def extractTrackInfo(track, info)
    processedInfo = track['recenttracks']['track'][0][info]
    if processedInfo['#text'] != nil
        processedInfo = processedInfo['#text']
    end
    processedInfo.titleize
    return processedInfo
end

bot.run