inherit Fins.FinsBase;

int in_processing_changes = 0;
int id = 100;
int gsc = 0;

string sql_url;
Sql.Sql sql;
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
  string sqldb = config["model"]["datasource"];
  did_revise = app->server_did_revise;
  
  start_db(sqldb);  
  call_out(start_revision_checker, 10);  
  call_out(remove_stale_db_entries, 125);  
}

void start_db(string sqlurl)
{
  log->info("Starting DB...");
  sql_url = sqlurl;
  sql = Sql.Sql(sql_url);
  
  if(sql)
    check_tables(sql);  
    
  mapping r = sql->query("SELECT MAX(batch) as gsc FROM SONGS")[0];
  
  gsc = (int)r->gsc;
  gsc++;
  
  did_revise(gsc);
}

void check_tables(Sql.Sql sql)
{
  log->info("Checking tables...");
  process_table(sql, "songs", songs_fields);
  process_table(sql, "playlists", playlists_fields);
  process_table(sql, "playlist_members", playlist_members_fields);
}

void process_table(Sql.Sql sql, string table, array fields)
{
  if(!table_exists(sql, table))
  {
    create_table(sql, table, fields);
  }
  else
  {
    update_table(sql, table, fields);
  }
}

void update_table(Sql.Sql sql, string table, array fields)
{
  array f_list = sql->list_fields(table);
  
  foreach(fields;;array f)
  {
    int have_field = 0;
    
    foreach(f_list;;mapping field)
    {
      if(field->name == f[0])
      {
        have_field = 1;
        break;
      }
    }
    
    if(!have_field)
    {
      log->info("adding field " + f[0] + " to table " + table);
      sql->query("ALTER TABLE " + table + " ADD " + f[0] + " " + f[1]);
    }
  }
}

void create_table(Sql.Sql sql, string table, array fields)
{
  array fs = ({});
  
  foreach(fields;;array f)
    fs += ({f[0] + " " + f[1]});
    
  string q = "CREATE TABLE " + table + "(" + (fs*", ") + ")";
  log->info("query: " + q + "");
   sql->query(q);
}

int table_exists(Sql.Sql sql, string table)
{
  return (sizeof(sql->list_tables(table))>=1);
}

void remove(string path)
{
  log->info("removing stale entry for %s", path);
  array r = sql->query("SELECT id FROM songs WHERE path=%s", path);
  sql->query("DELETE FROM songs WHERE path=%s", path);  
  
  if(r && sizeof(r))
  {
    foreach(r;;mapping row)
    {
      log->debug(" - entry %d was in db.", (int)row->id);
      remove_queue->write((int)row->id);
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
  log->info("flushing changes to db\n");
  array checks = ({});

  sql->query("BEGIN TRANSACTION");

  while(!change_queue->is_empty())
  {
     mapping ent = change_queue->read();
     checks += ({ent});
     if(sizeof(checks) >= 10 || change_queue->is_empty())
     {
       checks = has_entry(sql, checks);
       foreach(checks;; ent)
       {
         werror("adding " + ent->path + "\n");
         // ent->id = ++id;
         if(!ent->title) ent->title = basename(ent->path);
         ent->format = lower_case((ent->path/".")[-1] || "mp3");
       //  ent->hash = String.string2hex(Crypto.MD5()->hash(Stdio.read_file(ent->path)));
       //  songs[ent->id] = ent;
         ent->batch = gsc+1;
         write_entry_to_db(sql, ent);
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
  sql->query("COMMIT");
  in_processing_changes = 0;
}

array has_entry(Sql.Sql sql, array(mapping) entry)
{ 
  array paths = ({});

  foreach(entry;;mapping e)
  {
    paths += ({ "'" + sql->quote(e->path) + "'" });
  }

//  werror("query: %O\n", query);
  array a = sql->query("select path from songs where path IN(" + ( paths * "," ) + ")");

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

void write_entry_to_db(Sql.Sql sql, mapping entry)
{
    array vc = ({});
    foreach(entry; string key; mixed val)
    {
   //   if(!val) m_delete(entry, key);
      if(intp(val))
        vc += ({(string)val});
      else
        vc += ({"'"  + sql->quote(val) + "'"});
    }
    string q = "INSERT INTO songs (" + (indices(entry)* ", ") + ", added) VALUES(" + (vc * ", ") + ", 'now')";
//werror("QUERY: %O\n", q);
//werror(q + sprintf("%O\n", values(entry)));
    sql->query(q /*, @values(entry)*/);
    //  werror("failed to write entry for %s: %O\n", entry->path, entry);
}

void remove_stale_db_entries()
{
  foreach(sql->query("SELECT path, id FROM songs");; mapping s)
  {
    if(!file_stat(s->path))
    {
      werror("removing stale entry for %s", s->path);
      sql->query("DELETE FROM songs WHERE id=%d", (int)s->id);
      
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

void bump(int songid)
{
  sql->query("UPDATE songs SET playcount = playcount+1 WHERE id = %d", songid);
}

mapping get_song(int id)
{
  array x = sql->query("SELECT * FROM SONGS WHERE id=%d", id);
  if(sizeof(x)) return x[0];
  else
    return 0;
}
string get_song_path(int id)
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
  array x = sql->query("SELECT COUNT(*) AS c FROM songs");
  return (int)x[0]->c;
}

array get_songs(int|void reva, int|void revb)
{
  int min_rev = min(reva, revb);
  int max_rev = max(reva, revb);

  string query = "SELECT * FROM songs";
  
  if(max_rev)
  {
    query += " WHERE batch >= " + min_rev + " AND batch <= " + max_rev;
  }

  array x = sql->query(query);
  
  werror("fetched list of %d songs.\n", sizeof(x));
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

mapping playlists =  ([]);
/*
([
 "40":
  (["name": "MLibrary", "items": get_songs()[0..6], "id": 40, "persistent_id": 40, "smart": 0])

]);
*/

void low_did_revise(int revision)
{
  return;
}


