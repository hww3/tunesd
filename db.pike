int in_processing_changes = 0;
int id = 100;
int gsc = 0;

string sql_url;
Sql.Sql sql;

ADT.Queue change_queue = ADT.Queue();

constant songs_fields = ({
  ({"id", "integer not null primary key"}),
  ({"title", "string not null"}),
  ({"path", "string not null"}),
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
  
static void create(string sqldb)
{
  start_db(sqldb);  
  call_out(start_revision_checker, 10);  
  call_out(remove_stale_db_entries, 125);  
}

void start_db(string sqlurl)
{
  werror("Starting DB...\n");
  sql_url = sqlurl;
  sql = Sql.Sql(sql_url);
  
  if(sql)
    check_tables(sql);  
    
  mapping r = sql->query("SELECT MAX(batch) as gsc FROM SONGS")[0];
  
  gsc = (int)r->gsc || 1;
}

void check_tables(Sql.Sql sql)
{
  werror("Checking tables...\n");
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
      write("adding field " + f[0] + " to table " + table + "\n");
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
werror("query: " + q + "\n");
   sql->query(q);
}

int table_exists(Sql.Sql sql, string table)
{
  return (sizeof(sql->list_tables(table))>=1);
}

void remove(string path)
{
  werror("removing stale entry for %s", path);
  sql->query("DELETE FROM songs WHERE path=%s", path);  
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
     if(has_entry(sql, ent)) {werror("skipping %s\n", ent->path); continue; }
    // werror("adding " + ent->path + "\n");
     // ent->id = ++id;
     if(!ent->title) ent->title = basename(ent->path);
     ent->format = lower_case((ent->path/".")[-1] || "mp3");
   //  ent->hash = String.string2hex(Crypto.MD5()->hash(Stdio.read_file(ent->path)));
   //  songs[ent->id] = ent;
     ent->batch = gsc;
     write_entry_to_db(sql, ent);
  }
  gsc++;
  did_revise(gsc);
  in_processing_changes = 0;
}

int has_entry(Sql.Sql sql, mapping entry)
{
  array a = sql->query("select * from songs where path = %s", entry->path);  
  if(sizeof(a)) return 1;
  else return 0;
}

void write_entry_to_db(Sql.Sql sql, mapping entry)
{
  
    array vc = ({});
    foreach(entry; string key; mixed val)
    {
   //   if(!val) m_delete(entry, key);
      if(intp(val))
        vc += ({"%d"});
      else
        vc += ({"%s"});
    }
    string q = "INSERT INTO songs (" + (indices(entry)* ", ") + ") VALUES(" + (vc * ", ") + ")";
//werror(q + sprintf("%O\n", values(entry)));
    sql->query(q, @values(entry));
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
  if(!change_queue->is_empty())
  {
     process_change_queue();
  }
  call_out(start_revision_checker, 120);
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


