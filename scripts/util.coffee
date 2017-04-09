# Description
#   random set of hubot utility scripts
#
# Commands:
#   in <delay><time unit (s/m/h)> <action> <arguments (optional depending on action)> - Perform any of the other actions, but with a delay.
#   weather - Reply with the current Vancouver weather
#   compute <math expression> - Reply with solution to mathematical expression
#   yt_add <alias name> <video url> - Associate a name to a given youtube url
#   yt_remove <alias name> - Remove the youtube entry name created by yt_add
#   yt_list - Reply with the list of all the current active youtube aliases
#   yt_url <alias name> - Reply with the video url for a given alias
#   yt <alias name> - Reply with the embedded video (might take a while to download the video)
#   meme - Reply with a picture of a random meme 
#   meme_list <number of memes> - Reply with the next number of memes in the list
#   meme_update - Updates the memes if necessary
#   define <word> - Reply with definition(s) of the provided word
#   let it go - Reply with a choice to build a snowman or nah
#   hue - Self-explanatory
#
# Author:
#   Paul Wang

mathjs = require("mathjs")
request = require("request") # some devious hackery to bypass the youtube-to-mp4url API's block against Hubot requests

module.exports = (robot) ->

  # Youtube
  google_api_key = process.env['GOOGLE_API_KEY']
  youtube_urls = {}

  # Word API definitions
  mashape_key = process.env['MASHAPE_KEY']
  definition_searches = 0
  definition_search_limit = 2500

  # Memes
  meme_index = 0
  stored_memes = []

  root = (exports ? this)

  robot.hear /^in\s+(\d+)([smh])\s+([^\s]+)\s?(.*)$/i, (msg) ->
    time_value = msg.match[1]
    time_unit = msg.match[2]
    action = msg.match[3]
    args = msg.match[4]

    switch time_unit
      when "s"
        time_base = 1000
        time_str = "second"
      when "m"
        time_base = 60000
        time_str = "minute"
      when "h"
        time_base = 3600000
        time_str = "hour"
    if time_value > 1
      time_str += "s"
    msg.send "Very well. I'll remind you in #{time_value} #{time_str}."
    setTimeout () ->
      root[action](msg, args)
    , time_value * time_base

  robot.hear /^weather$/, (msg) ->
    root.weather(msg)

  robot.hear /^compute (.*)/i, (msg) ->
    root.compute(msg, msg.match[1])

  robot.hear /^hue$/i, (msg) ->
    root.hue(msg)

  # Need two listeners for the same text since
  # the other one will modify the message envelope
  robot.hear /^yt (.*)/i, (msg) ->
    if (!youtube_urls.hasOwnProperty(msg.match[1]))
      msg.send "#{msg.match[1]} isn't an alias. If you want, you can use yt_add <alias> <youtube url> to create it."
      return
    msg.send "Fetching video information. Please wait a sec..."

  robot.hear /^yt (.*)/i, (msg) ->
    root.yt(msg, msg.match[1])

  robot.hear /^yt_add (.*) (.*)/i, (msg) ->
    root.yt_add(msg, msg.match)

  robot.hear /^yt_remove (.*)/i, (msg) ->
    root.yt_remove(msg, msg.match[1])

  robot.hear /^yt_url (.*)/i, (msg) ->
    root.yt_url(msg, msg.match[1])

  robot.hear /^yt_list$/i, (msg) ->
    root.yt_list(msg)

  robot.hear /^yt_update$/i, (msg) ->
    root.yt_update(msg)

  robot.hear /^yt_admin_list$/i, (msg) ->
    msg.send "Number of entries: #{Object.keys(youtube_urls).length}"
    for key, value of youtube_urls
      msg.send "#{key}: #{JSON.stringify(value)}"

  robot.hear /^meme_list (\d+)/i, (msg) ->
    root.meme_list(msg, msg.match[1])

  robot.hear /^meme$/i, (msg) ->
    root.meme(msg)

  robot.hear /^meme_update$/i, (msg) ->
    root.meme_update(msg)

  robot.hear /^define (.*)$/, (msg) ->
    root.define(msg, msg.match[1])

  root.say = (msg, args) ->
    msg.send args

  root.weather = (msg, args) ->
    msg.http("https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22vancouver%2C%20ca%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys")
      .get() (err, res, body) ->
        if err?
          msg.send "Um, Yahoo seems to be down..."
        data = JSON.parse body
        try
          temperature = ((data.query.results.channel.item.condition.temp - 32) / 1.8).toFixed(2)
          msg.send "Weather report for #{data.query.results.channel.location.city}!\n\n... #{data.query.results.channel.item.condition.text}.\n\nAlso, the temperature is #{temperature}C."
        catch error
          msg.send "Ahhh... I can't read the data."
          return
        if temperature < 10
          msg.send "It's pretty cold. I recommend wearing a jacket."

  root.hue = (msg, args) ->
    msg.send "huehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuejajajahuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehuehue"
    msg.send "Ahem. *hues silently*"

  root.compute = (msg, args) ->
    try
      if /^2\s?\+\s?2$/.test(args)
        msg.send "The answer to that, is 5."
        setTimeout () ->
          msg.send "Orwell, maybe that's just what I've been trained to say hehe."
        , 1000
        return
      result = mathjs.eval args
      msg.send "The answer to that, is #{result}."
    catch error
      msg.send "I think you screwed up somewhere..."

  get_youtube_video_id = (url) ->
    match = url.match(/^.*(youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/);
    if (match && match[2].length == 11)
      return match[2]
    else 
      return "Error: not a valid Youtube link."

  root.yt_add = (msg, args) ->
    alias_name = args[1]
    raw_url = args[2]

    uri = "https://helloacm.com/api/video/?cached&video=" + raw_url
    video_id = get_youtube_video_id(raw_url)
    title = ""

    msg.http("https://www.googleapis.com/youtube/v3/videos?id=" + video_id + "&key=" + google_api_key + "&part=snippet")
      .get() (err, res, body) ->
        if err?
          msg.send "Error: couldn't contact Youtube."
        data = JSON.parse body
        try
          title = data.items[0].snippet.title
        catch error
          msg.send "Error: failed to parse the data."
          return
    
    request.get {uri: uri, json : true}, (err, r, body) ->
      if err?
        msg.send "Um, the URL converter site seems to be down..."
      try
        youtube_urls[alias_name] = {
          "title": title,
          "raw_url": raw_url,
          "true_url": body.url
        }
        msg.send "Updated the following entry!"
        msg.send "#{alias_name}: #{title}!"
      catch error
        msg.send "Ahhh... I can't read the data."
        return

  root.yt_remove = (msg, args) ->
    if (!youtube_urls.hasOwnProperty(args))
      msg.send "#{args} isn't an alias. If you want, you can use yt_add <alias> <youtube url> to create it."
      return
    delete youtube_urls[args]
    msg.send "Removed #{args}."

  root.yt_url = (msg, args) ->
    if (!youtube_urls.hasOwnProperty(args))
      msg.send "#{args} isn't an alias. If you want, you can use yt_add <alias> <youtube url> to create it."
      return
    msg.send youtube_urls[args].raw_url
  
  root.yt = (msg, args) ->
    if (!youtube_urls.hasOwnProperty(args))
      return
    msg.envelope.fb = {
      richMsg: {
        "attachment":{
          "type":"video",
          "payload":{
            "url": youtube_urls[args].true_url
          }
        }
      }
    }
    msg.send()

  root.yt_list = (msg, args) ->
    msg.send "Number of entries: #{Object.keys(youtube_urls).length}"
    for key, value of youtube_urls
      msg.send "#{key}: #{value.title}"

  root.yt_update = (msg, args) ->
    for key, value of youtube_urls
      root.yt_add(msg, [null, key, value.raw_url])
      msg.send "Finished updating #{key}."

  root.meme_update = (msg, args) ->
    if stored_memes.length > 0
      msg.send "Already got #{stored_memes.length} dank memes."
      return
    msg.http("https://api.imgflip.com/get_memes")
      .get() (err, res, body) ->
        if err?
          msg.send "Couldn't contact imgflip. No memes today."
        data = JSON.parse body
        try
          stored_memes = data.data.memes
          msg.send "Updated the memes (#{stored_memes.length} in the meme bank)."
        catch error
          msg.send "Low quality memes."
          return

  root.meme_list = (msg, args) ->

    num_memes = parseInt(args, 10)

    if stored_memes.length == 0
      msg.send "No memes rip. You can probably get some by saying meme_update."
      return
    stored_memes[meme_index...(num_memes+meme_index)].forEach (element, index, array) ->
      msg.send "#{element.url}"
      if meme_index + index >= stored_memes.length
        meme_index = 0
      else
        meme_index += 1

  root.meme = (msg, args) ->
    if stored_memes.length == 0
      msg.send "No memes rip. You can probably get some by saying meme_update."
      return
    meme_images = stored_memes.map (meme) -> meme.url
    msg.send msg.random(meme_images)

  root.define = (msg, args) ->
    if definition_searches >= definition_search_limit
      msg.send "Uh oh, we already made #{definition_search_limit} dictionary searches.\nSkipping, or else I will get fined lel."
      return
    definition_searches += 1
    msg.http("https://wordsapiv1.p.mashape.com/words/"+ args + "/definitions")
      .header('X-Mashape-Key', mashape_key)
      .get() (err, res, body) ->
        if err?
          msg.send "Error: couldn't contact wordapi."
          return
        try
          msg.send "Define #{args}? Let me see..."
          data = JSON.parse body
          data.definitions.forEach (element, index, array) ->
            msg.send "(#{element.partOfSpeech}): #{element.definition}"
        catch error
          msg.send "Whoops, don't think that's English. Sorry."
          return

  robot.hear /let it go/i, (res) ->
    res.envelope.fb = {
      richMsg: {
        attachment: {
          type: "template",
          payload: {
            template_type: "button",
            text: "Doth thee wanteth to buildeth a snowman?",
            buttons: [
              {
                type: "web_url",
                url: "http://www.dailymotion.com/video/x1fa7w8_frozen-do-you-wanna-build-the-snowman-1080p-official-hd-music-video_music",
                title: "Oui"
              },
              {
                type: "web_url",
                title: "Nein",
                url: "https://m.popkey.co/0de76c/ZpkXO.gif"
              }
            ]
          }
        }
      }
    }
    res.send()
