static void create()
{
  start_revision_checker();  
}


// this is not necessary, it's only purpouse is to generate "fake" updates
// to the database so that we can demonstrate library updating.
void start_revision_checker()
{
  gsc++;
  did_revise(gsc);
  call_out(start_revision_checker, 600);
}

string get_name()
{
  return "Firefly2x";
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

int gsc = 0;

int get_song_count()
{
  return 10 + gsc;
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



function did_revise = low_did_revise;

void low_did_revise(int revision)
{
  return;
}


