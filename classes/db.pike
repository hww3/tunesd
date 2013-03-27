inherit Fins.FinsBase;

int in_processing_changes = 0;
int id = 100;
int gsc = 0;

string db_url;
object db;
object songc;
object playlistc;

object log = Tools.Logging.get_logger("model");

function did_revise = low_did_revise;

mapping revision_removals = ([]);

ADT.Queue change_queue = ADT.Queue();
ADT.Queue remove_queue = ADT.Queue();

constant songs_fields = ({
  ({"id", "integer primary key"}),
  ({"title", "string not null"}),
  ({"path", "string not null unique"}),
//  ({"hash", "string not null"}),
  ({"artist", "string"}),
  ({"album", "string"}),
  ({"composer", "string"}),
  ({"genre", "string"}),
  ({"length", "integer"}),
  ({"size", "integer"}),
  ({"modified", "integer"}),
  ({"year", "string"}),
  ({"format", "string"}),
  ({"track", "string"}),
  ({"trackcount", "string"}),
  ({"comment", "string"}),
  ({"added", "timestamp"}),
  ({"playcount", "int"}),
  ({"rating", "int"}),
  ({"batch", "int"}),
});

constant playlists_fields = ({
  ({"id", "integer not null primary key"}),
  ({"name", "string not null"}),
});

constant playlist_members_fields = ({
  ({"id", "integer not null primary key"}),
  ({"playlist_id", "integer not null"}),
  ({"song_id", "int not null"}),
});

mapping songs = ([]);

void start(/*string sqldb, function server_did_revise*/)
{
  string url = config["model"]["datasource"];
  did_revise = app->server_did_revise;
  
  start_db(url);  
  call_out(start_revision_checker, 10);  
  call_out(remove_stale_db_entries, 125);  
 
  playlists += ([
   "50":
    (["name": "MLibrary", "items": get_songs()[0..6], "id": 50, "persistentid": 50, "smart": 0]),
  "51":
  (["name": "MLibrary2", "items": get_songs()[7..20], "id": 51, "persistentid": 51, "smart": 1])

  ]);
  
}

void start_db(string url)
{
  log->info("Starting DB...");
  db_url = url;
  db = Database.EJDB.Database(db_url, Database.EJDB.JBOWRITER|Database.EJDB.JBOCREAT);
  
  if(db)
    check_tables(db);

  mixed r;
  mixed res = songc->find(([]), 0, (["$fields": (["batch": 1]), "$max": 1, "$orderby": (["batch": -1])]));
  if(sizeof(res)) r = res[0];
  else return;
  gsc = r->batch;
  gsc++;
  
  did_revise(gsc);
  
}

int collection_exists(object db, string coll)
{
  array c = db->get_collections();  
  return (search(c, coll) != -1);
}

void check_tables(Database.EJDB.Database db)
{
  log->info("Checking tables...");
  if(!collection_exists(db, "songs"))
  {
    songc = db->create_collection("songs");    
    // TODO create indexes.
  }
  else
  {
    songc = db->create_collection("songs");
  }
  
  if(!collection_exists(db, "playlists"))
  {
    playlistc = db->create_collection("playlists");
    // TODO create indexes.
  }
  else
  {
    playlistc = db->create_collection("playlists");
  }
}

void remove(string path)
{
  log->info("removing stale entry for %s", path);
  array r = songc->find((["path": path]))[0];
  
  if(r && sizeof(r))
  {
    foreach(r;;mapping row)
    {
      log->debug(" - entry %s was in db.", (string)row->_id);
      songc->delete(row->_id)[0];  
      remove_queue->write((string)row->_id);
    }
  }
}

void add(mapping ent)
{
//  log->debug("adding %O", ent);
  change_queue->write(ent);
}

int has_removed_in_revision(int revision)
{
  if(revision_removals[revision])
    return 1;
  else return 0;
}

array get_removed_in_revision(int revision)
{
  return revision_removals[revision];
}

void process_change_queue()
{
  int had_changes = 0;
  
  if(in_processing_changes) return;
  in_processing_changes = 1;
  log->info("flushing changes to db");
  array checks = ({});

  songc->begin_transaction();

  mixed err = catch {
  while(!change_queue->is_empty())
  {
     mapping ent = change_queue->read();
     checks += ({ent});
     if(sizeof(checks) >= 10 || change_queue->is_empty())
     {
       checks = has_entry(songc, checks);
       foreach(checks;; ent)
       {
         werror("adding " + ent->path + "\n");
         // ent->id = ++id;
         if(!ent->title) ent->title = basename(ent->path);
         ent->format = lower_case((ent->path/".")[-1] || "mp3");
       //  ent->hash = String.string2hex(Crypto.MD5()->hash(Stdio.read_file(ent->path)));
       //  songs[ent->id] = ent;
         ent->batch = gsc+1;
         write_entry_to_db(songc, ent);
         had_changes++;
       }
      checks = ({});
    }
  }
  while(!remove_queue->is_empty())
  {
    array r = ({});
      r += ({remove_queue->read()});
    revision_removals[gsc+1] = r;
    had_changes++;
  }
  if(had_changes)
  {
    did_revise(gsc+1);
    gsc++;
    had_changes = 0;
  }
  };
  if(err)
  {
    log->exception("Error occurred while processing additions.", err);
    songc->abort_transaction();
  }
  else
    songc->commit_transaction();
  in_processing_changes = 0;
}

array has_entry(object coll, array(mapping) entry)
{ 
  array paths = ({});


//  werror("query: %O\n", query);
  array a = coll->find((["path": (["$in": entry->path]) ]));

  if(sizeof(a) == sizeof(entry)) return ({});

  array res  = ({});

  foreach(entry;;mapping e)
  {
    int hadit = 0;
    foreach(a;; mapping row)
    {
//werror("%O, %O\n", e->path, row->path);
      if(e->path == row->path)
      {
        hadit++;
        break;
      }
    }
    if(!hadit) res += ({e});
//    else werror("disqualifying " + e->path + "\n");
  }
  return res;
}

void write_entry_to_db(object coll, mapping entry)
{
  int max;
  mixed res = songc->find(([]), 0, (["$fields": (["id": 1]), "$max": 1, "$orderby": (["id": -1])]));
  if(res && sizeof(res))
    max = res[0]->id + 1;
  else max = 1;
  entry->id = max;
  coll->save(entry);
}

void remove_stale_db_entries()
{
  foreach(songc->find(([]));; mapping s)
  {
    if(!file_stat(s->path))
    {
      werror("removing stale entry for %s", s->path);
      songc->delete(s->_id);
    }
  }  
}

void start_revision_checker()
{
  if(!change_queue->is_empty() || !remove_queue->is_empty())
  {
     process_change_queue();
  }
  call_out(start_revision_checker, 60);
}

void bump(string songid)
{
  songc->find((["_id": songid, "$inc": (["playcount" : 1])]));
}

mapping get_song(string id)
{
  array x = songc->find((["id": id]));
  if(sizeof(x)) return x[0];
  else
    return 0;
}

string get_song_path(string id)
{
  mapping m = get_song(id);
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

int get_song_count()
{
//  return 10 + gsc;
  int x = songc->find(([]), 0, (["$onlycount": 1]));
  return x;
}

array get_songs(int|void reva, int|void revb)
{
  int min_rev = min(reva, revb);
  int max_rev = max(reva, revb);

  array x;
  if(reva != UNDEFINED)
    x = songc->find((["batch": (["$bt": ({min_rev, max_rev}) ]) ]));
  else
    x = songc->find(([]));
  
  werror("fetched list of %d songs between %d and %d.\n", sizeof(x), min_rev, max_rev);
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

mapping playlists = ([]);


void low_did_revise(int revision)
{
  return 0;
}


