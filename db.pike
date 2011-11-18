string get_name()
{
  return "mytunes";
}

int get_pid()
{
  return 72;
}

int get_id()
{
  return 27;
}

int get_playlist_count()
{
  return sizeof(playlists);
}

int get_song_count()
{
  return 10;
}

array get_songs()
{
  array x = allocate(get_song_count());
  for(int i = 0 ; i < sizeof(x); i++)
    x[i] = (["name": "song " + i, "id": i, "length": i*5]);
  return x;
}

array get_playlists()
{
  return values(playlists);
}

mapping get_playlist(string plid)
{
  return playlists[plid];
}

mapping playlists =  ([
 "40":
  (["name": "MLibrary", "items": get_songs()[0..6], "id": 40, "persistent_id": 40, "smart": 0])

]);

