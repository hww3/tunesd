int in_processing_changes = 0;
int id = 100;

ADT.Queue change_queue = ADT.Queue();

mapping songs = ([]);
  
static void create()
{
  call_out(start_revision_checker, 10);  
}

void add(mapping ent)
{
  change_queue->write(ent);
}

void process_change_queue()
{
  if(in_processing_changes) return;
  in_processing_changes = 1;
werror("flushing changes to db\n");
  while(!change_queue->is_empty())
  {
     mapping ent = change_queue->read();
     ent->id = ++id;
     if(!ent->title) ent->title = basename(ent->path);
     ent->format = lower_case((ent->path/".")[-1] || "mp3");
     songs[ent->id] = ent;
  }
  gsc++;
  did_revise(gsc);
  in_processing_changes = 0;
}

void start_revision_checker()
{
  if(!change_queue->is_empty())
  {
     process_change_queue();
  }
  call_out(start_revision_checker, 30);
}

mapping get_song(int id)
{
  return songs[id];
}
string get_song_path(int id)
{
  mapping m = songs[id];
  if(m && m->path)
    return m->path;

  else return 0;    
}

string get_name()
{
  return "tunesd on " + gethostname();
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
//  return 10 + gsc;
  return sizeof(songs);
}

array get_songs()
{
/*
  array x = allocate(get_song_count());
  for(int i = 0 ; i < sizeof(x); i++)
    x[i] = (["name": "song " + i, "id": i, "length": i*5]);
  return x;
*/
  return values(songs);
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


