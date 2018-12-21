require 'discordrb'
require 'rest-client'
require 'json'
require 'titleize'
require 'net/http'

secrets = File.read('secrets.json')
discordKey = JSON.parse(secrets)["discordAPIKey"]
fmKey =JSON.parse(secrets)["fmAPIKey"]
#userAgent = File.read('user_agent.txt')
bot = Discordrb::Commands::CommandBot.new token: discordKey, client_id: 469293171399196702, prefix: '!'
googleAPIkey = 'AIzaSyDtC4ustRkZdE_C7ppOi3pUTh9hHnQSXGg'
#RestClient.get 'http://localhost', :user_agent => userAgent

bot.message do |event|
    command = event.message.content.split(/\s+/)[0]
    commandList = ["!fm", "!yt", "!plasticlove", "!help", "!flapper", "!toomuchsun", "!va"]
    if command[0] == '!'
        unless commandList.include?(command) || command =~ /!\W+/ || command [1] == nil
            event.respond "Unknown command. Please see \"!help\" for a list of available commands"
        end
    end
end

bot.command :help do |event|
    event.channel.send_embed do |embed|
        embed.title = "Preface all commands with \"!\""
        embed.thumbnail = Discordrb::Webhooks::EmbedImage.new(url: 'https://i.imgur.com/ceYNiDi.png')
        embed.colour = 'd3d3d3'
        embed.add_field(name: 'varieti.es', value: "!va <album title> displays first search result on the archive.")
        embed.add_field(name: 'Last.fm: ', value: "!fm displays currently scrobbling track.")
        embed.add_field(name: 'Youtube: ', value: "!yt <search terms> displays first search result on Youtube.")
    end
end

bot.command :plasticlove do |event|
    event.respond 'https://media.discordapp.net/attachments/466025449026224131/497126548999110677/Untitled-1.png'
end

bot.command :toomuchsun do |event|
    event.respond 'https://cdn.discordapp.com/attachments/466025449026224131/493170372372332545/To.png'
end

bot.command :flapper do |event|
    event.respond 'https://cdn.discordapp.com/emojis/393439670475685888.png?v=1'
end

bot.command :va do |event|
    titleQ = event.message.content.gsub(/^!va\s+/, "")
    begin
        rawAlbum = RestClient.get("http://varieti.es/albums/fetch/?title=#{titleQ}")
        album = JSON.parse(rawAlbum)[0]
    rescue Exception => e
        p e
        event.respond "Could not access varieti.es API. Please ping my owner and tell him he's a lazy bum!"
        return
    end
    if album != "Out of albums to render!"
        event.channel.send_embed do |embed|
            title = if album["title"] != "" then album["title"] else '*Unknown title*' end
            artist = if album["romaji_artist"] != "" then album["romaji_artist"] else '*Unknown artist*' end
            year = if album["year"] != "" then album["year"] else '*Unknown year*' end
            flavor = if album["flavor"] != "" then album["flavor"] else '*Unknown flavor*' end
            description = if album["description"] != "" then album["description"] else '*Unknown description*' end
            thumbnail = if album["thumbnail"] != "" then album["thumbnail"] else 'https://i.imgur.com/EJ9UpgY.jpg' end
            embed.colour = '005cc5'
            embed.url = 'http://varieti.es'
            embed.title = "varieti.es"
            embed.description = "Search result for \"#{titleQ}\""
            embed.thumbnail = Discordrb::Webhooks::EmbedImage.new(url: thumbnail)
            embed.add_field(name: 'Title: ', value: title, inline: true)
            embed.add_field(name: 'Artist: ', value: artist, inline: true)
            embed.add_field(name: 'Year: ', value: year + "
            ----------", inline: true)
            embed.add_field(name: 'Flavor: ', value: flavor, inline: true)
            embed.add_field(name: 'Description: ', value: description)
            embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: 'Sugar Bot by PorousBoat')
            embed.timestamp = Time.now
        end
    else
        event.respond "No results for \"#{titleQ}\""
    end
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
                        api_key: fmKey,
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
                
                embed.add_field(name: 'Title: ', value: extractTrackInfo(track: currentTrack, info: 'name'), inline: true)
                embed.add_field(name: 'Artist: ', value: extractTrackInfo(track: currentTrack, info: 'artist'), inline: true)
                embed.add_field(name: 'Album: ', value: extractTrackInfo(track: currentTrack, info: 'album') + "
                    ----------")
                if extractTrackInfo(track: currentTrack, info: 'name', trackNr: 1)
                    if extractTrackInfo(track: currentTrack, info: 'name', trackNr: 1) != ''
                        embed.add_field(name: 'Previous track: ', value: extractTrackInfo(track: currentTrack, info: 'name', trackNr: 1), inline: true)
                    else
                        embed.add_field(name: 'Previous track: ', value: '*No previous track*', inline: true)
                    end
                    
                    if extractTrackInfo(track: currentTrack, info: 'name', trackNr: 1) != ''
                        embed.add_field(name: 'Album & Artist: ', value: extractTrackInfo(track: currentTrack, info: 'album', trackNr: 1) + " by *" + extractTrackInfo(track: currentTrack, info: 'artist', trackNr: 1) + "*", inline: true)
                    else
                        embed.add_field(name: 'Album & Artist: ', value: '*Could not find album/artist*', inline: true)
                    end
                else
                    embed.add_field(name: 'Previous Track:', value: 'Could not fetch previous track!')
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

def extractTrackInfo(track: nil, info: "", trackNr: 0)
    begin
        processedInfo = track['recenttracks']['track'][trackNr][info]
    rescue Exception => e
        p e
        return nil
    end
    if processedInfo['#text'] != nil
        processedInfo = processedInfo['#text']
        processedInfo.titleize
        return processedInfo
    end
    if processedInfo.empty? || processedInfo == ''
        return "*Unknown #{info}*"
    end
    return processedInfo
end

bot.run