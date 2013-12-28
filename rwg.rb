require "json"
require "tempfile"

require "httparty"
require "growl"

Song = Struct.new :url, :title, :artist, :album, :image_url

class Rainwave
  def get_current_song
    resp = JSON.parse(HTTParty.get("http://rainwave.cc/async/4/get").body)
    resp_song = resp["sched_current"]["song_data"][0]
    url = resp_song["song_url"]
    title = resp_song["song_title"]
    artist = resp_song["artists"][0]["artist_name"]
    album = resp_song["album_name"]
    image_url = get_album_art_url resp_song["album_art"]
    Song.new url, title, artist, album, image_url
  end

  private
  def get_album_art_url absolute_path_to_image
    "http://chiptune.rainwave.cc" + absolute_path_to_image
  end
end

class Display
  def show_alert song
    notification = Growl.new
    # notification.url = song.url   Gemfiles version doesn't support this yet! :(
    notification.title = song.title
    notification.message = "#{song.artist} (#{song.album})"
    create_tempfile song.image_url do |path|
      notification.image = path
      notification.run
    end
  end

  private
  def create_tempfile url
    tempfile = Tempfile.new "growlicon"
    tempfile.write HTTParty.get(url).body
    tempfile.close
    begin
      yield tempfile.path
    ensure
      tempfile.unlink
    end
  end
end

def every_n_seconds n
  loop do
    yield
    sleep n
  end
end

display = Display.new
rainwave = Rainwave.new

last_song = nil

every_n_seconds 10 do
  song = rainwave.get_current_song
  display.show_alert rainwave.get_current_song if last_song != song
  last_song = song
end
