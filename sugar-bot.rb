require 'discordrb'
require 'rest-client'
require 'json'
require 'titleize'

bot = Discordrb::Commands::CommandBot.new token: 'NDY5MjkzMTcxMzk5MTk2NzAy.DjIH5w.v4l7T1MaCxbnmVJlJUO5tJmYpJo', prefix: '!'
fmAPIkey = 'cb7be8fb2f185dbb396dcd1b8c28b32d'
googleAPIkey = 'AIzaSyDtC4ustRkZdE_C7ppOi3pUTh9hHnQSXGg'
#RestClient.get 'http://localhost', :user_agent => "PorousBoat"

bot.message do |event|
    command = event.message.content.split(/\s+/)[0]
    unless command[0] != '!' || command == "!fm" || command == "!yt" || command =="!plasticlove" || command == "!help"
        event.respond "Unknown command. Please see \"!help\" for a list of available commands"
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
    elsif @userList != nil && @userList.has_value?(event.user.name)
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
                embed.thumbnail = Discordrb::Webhooks::EmbedImage.new(url: albumCover)
                embed.colour = '4286f4'
                embed.add_field(name: 'Title: ', value: extractTrackInfo(currentTrack, 'name'))
                embed.add_field(name: 'Artist: ', value: extractTrackInfo(currentTrack, 'artist'))
                embed.add_field(name: 'Album: ', value: extractTrackInfo(currentTrack, 'album'))
            end
        end
    else
        "No last.fm user found. Use \"!fm setuser <username>\" to set a username."
    end
end

bot.command :yt do |event|
    argArr = event.message.content.split(/^\w+\s+/)
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