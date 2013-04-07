inherit Fins.FinsBase;

int in_processing_changes = 0;
int id = 100;
int gsc = 0;

string db_url;
object db;
object songc;
object playlistc;
int dbid;

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

void start(/*string sqldb, function server_did_revise*/)
{
  string url = config["model"]["datasource"];
  did_revise = app->server_did_revise;
  
  start_db(url);  
  start_cleanup();
  call_out(start_revision_checker, 10);  
}

void start_cleanup()
{
  call_out(remove_stale_db_entries, 125);    
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

string relativize_path(string path)
{
  if(path[0] == '/')
  {
    if(has_prefix(path, app->get_musicpath()))
      path = path[sizeof(app->get_musicpath())..];
      
    while(path[0] == '/' && sizeof(path) > 1)
      path = path[1..];
  }
  
  return path;
}

string absolutify_path(string path)
{
  if(path[0] != '/')
  {
    path = Stdio.append_path(app->get_musicpath(), path);
  }
  
  return path;
}

void remove(string path)
{
  log->info("removing entry for %s", path);
  
  path = relativize_path(path);
  
  array r = songc->find((["path": path]));
  
  if(r && sizeof(r))
  {
    foreach(r;;mapping row)
    {
      log->debug(" - entry %s was in db.", (string)row->_id);
      songc->delete_bson((string)row->_id);  
      remove_queue->write(row->id);
    }
  }
}

void add(mapping ent)
{
//  log->debug("adding %O", ent);
//  ent->path = relativize_path(ent->path);
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
     ent->path = relativize_path(ent->path);
     checks += ({ent});
     if(sizeof(checks) < 10 || change_queue->is_empty())
     {
       checks = has_entry(songc, checks);
       foreach(checks;; ent)
       {
         werror("adding %s (" + ent->path + ")\n", ent->title);
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
    did_revise(++gsc);
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

//werror("entry: %O\n", entry);

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
  
  entry->encoded = app->daap->encode_dmap(({"dmap.listingitem", 
         ({
           ({"dmap.itemkind", 2}),
           ({"dmap.itemid", entry["id"]}),
           ({"dmap.itemname", entry["title"]||"---"}),
            ({"dmap.persistentid", entry["id"]}),
            ({"dmap.mediakind", 1}),
            ({"daap.songartist", entry["artist"]||""}),
            ({"daap.songalbum", entry["album"]||""}),
            ({"daap.songtracknumber", (int)entry["track"]||0}),
            ({"daap.songtrackcount", (int)entry["trackcount"]||0}),
            ({"daap.songgenre", entry["genre"]||"Unknown"}),
            ({"daap.songyear", ((int)entry["year"]) || 0}),
            ({"daap.songtime", ((int)entry["length"] || 0)}),
            ({"daap.songsize", ((int)entry["size"] || 0)}),
            ({"daap.songdatemodified", ((int)entry["modified"] || 0)}),
            ({"daap.songformat", entry["format"]}),
            ({"daap.songdatakind", 0})
         })
     }));
  coll->save(entry);
}

void remove_stale_db_entries()
{
  log->info("Checking library for missing files.");
  foreach(songc->find(([]));; mapping s)
  {
    s->path = absolutify_path(s->path);
    
    if(!file_stat(s->path))
    {
      log->info("Removing stale entry for song file <%s>.", s->path);
      remove(s->path);
    }
  }  
}

void start_revision_checker()
{
  if(!change_queue->is_empty() || !remove_queue->is_empty())
  {
     process_change_queue();
  }
  call_out(start_revision_checker, 10);
}

void bump(int songid)
{
  werror("bump! (%O)", songid);
  
  mixed s = songc->find((["id": songid, "playcount": (["$exists": Standards.BSON.True]),  "$inc": (["playcount" : 1])]));
  
  if(!sizeof(s))
    s = songc->find((["id": songid, "$set": (["playcount" : 1])]));
    
    werror("=> %O\n", s);
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
    return absolutify_path(m->path);

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

int reset_id()
{
  dbid = 0;
}

int get_id()
{
  if(!dbid)
    dbid = random(0xffff);
  return dbid;
}

int get_playlist_count()
{
  return playlistc->find(([]), 0, (["$onlycount": 1]));
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
  array pls = playlistc->find(([]));
  foreach(pls; int x; mapping pl)
  {    
    werror("playlist: %O\n", pl);
    if(pl->smart && pl->query)
    {
        mapping q = eval_query(pl->query);
        werror("query: %O\n", q);
        pl->items = songc->find(q)["id"];
    }
  }
  
  return pls;
}

mapping get_playlist(string plid)
{
  array plr = playlistc->find((["id": (int)plid]));
  
  if(!plr || !sizeof(plr))
    throw(Error.Generic("Playlist id " + plid + " does not exist.\n"));

  mapping pl = plr[0];

  werror("playlist: %O\n", pl);
  
  if(pl->smart && pl->query)
  {
      mapping q = eval_query(pl->query);
      werror("query: %O\n", q);
      pl->items = songc->find(q)["id"];
  } 
  return pl;
}

int add_playlist(string name, int smart, string|void query, array|void songs)
{
  mixed err;
  mixed q2;
  int id;
  
  if(smart && !query)
    throw(Error.Generic("No query provided for smart playlist."));

  if(!smart && !songs)
    throw(Error.Generic("No songs provided for playlist."));
  
  name = String.trim_all_whites(name);
  query = String.trim_all_whites(query);

  if(!name || !sizeof(name))
    throw(Error.Generic("No name provided for playlist."));
  
  if(sizeof(playlistc->find((["name": name]))))
    throw(Error.Generic("Playlist " + name + " already exists."));
  
  id = max_playlist_id() + 1;
  
  if(smart)
  {
    if(err = catch(q2 = eval_query(query)))
      throw(Error.Generic("Invalid query provided for playlist: " + err[0]));     

    log->info("playlist query: %O\n", q2);
    
    mapping playlist_def = (["name": name, "query": query, "id": id, "persistent_id": id, "smart": smart]);
    werror("playlist_def: %O\n", playlist_def);
    playlistc->save(playlist_def);
  }
  
  return id;
}

void low_did_revise(int revision)
{
  return 0;
}

int max_playlist_id()
{
  mixed res = playlistc->find(([]), 0, (["$fields": (["id": 1]), "$max": 1, "$orderby": (["id": -1])]));
   if(sizeof(res)) return res[0]->id;
   else return 0x100000;
}

mixed eval_query(string query)
{
  string cls = "mixed e(){ return (" + query + ");}";
  program p = compile_string(cls);
//  werror("query: " + Tools.JSON.serialize(p()->e()));
  return p()->e();
}
