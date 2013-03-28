inherit Fins.DocController;
inherit Fins.RootController;

object auth;

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
  v->add("request", id);
  v->add("action", id->event_name);
  v->add("version", app->version);  
  v->add("appname", "tunesd");
  v->add("songcount", app->db->get_song_count());
}

void index(object id, object response, object v, mixed ... args)
{
  v->add("action", "home");
}


void library(object id, object response, object v, mixed ... args)
{
  mixed songs = app->db->get_songs();
  v->add("library", songs);
}

void queue(object id, object response, object v, mixed ... args)
{
  v->add("create_queue", (array)app->check->m->create_queue);
  v->add("exists_queue", (array)app->check->m->exists_queue);
  v->add("delete_queue", (array)app->check->m->delete_queue);
  v->add("history", values(app->check->m->history));
}


void search(object id, object response, object v, mixed ... args)
{
}
