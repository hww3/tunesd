inherit Fins.DocController;
inherit Fins.RootController;

object auth;

int __quiet = 1;

static void create(object application)
{
  ::create(application);
}

void start()
{
  auth = load_controller("auth/controller");
}

void populate_template(object id, object response, object v, mixed ... args)
{
  if(!v) return;
  
  v->add("request", id);
  v->add("action", id->event_name);
  v->add("version", app->version);  
  v->add("appname", "tunesd");
  v->add("songcount", app->db->get_song_count());
}

void index(object id, object response, object v, mixed ... args)
{
  v->add("action", "home");
  v->add("connections", app->connections);
  
  werror("connections: %O\n", app->connections);
}

void playlists(object id, object response, object v, mixed ... args)
{
  v->add("playlists", app->db->get_playlists());
}

void library(object id, object response, object v, mixed ... args)
{
  mixed songs = app->db->get_songs();
  v->add("library", songs);
  werror("song: %O\n", songs[0]);
}

void status(object id, object response, object v, mixed ... args)
{
  v->add("create_queue", (array)app->check->m->create_queue);
  v->add("exists_queue", (array)app->check->m->exists_queue);
  v->add("delete_queue", (array)app->check->m->delete_queue);
  v->add("history", values(app->check->m->history));
}


void search(object id, object response, object v, mixed ... args)
{
}

void add_playlist(object id, object response, object v, mixed ... args)
{
  int rv;
  
  int smart = (int)id->variables->smart;
  string name = id->variables->name;
  string query = id->variables->query;  
  
  mixed err = catch(rv = app->db->add_playlist(id->variables->name, smart, query));

  if(err)
    response->flash("msg", err[0]);
  else if(rv)
    response->flash("msg", "Playlist added.");
  else
    response->flash("msg", "Playlist not added.");
    
  response->redirect(playlists);
}