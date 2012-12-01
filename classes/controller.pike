inherit Fins.FinsController;
inherit Fins.RootController;

static void create(object application)
{
  ::create(application);
}

void index(object id, object response, mixed ... args)
{
  string req = sprintf("%O", mkmapping(indices(id), values(id)));
  string con = master()->describe_object(this);
  string method = function_name(backtrace()[-1][2]);
  object v = view->get_view("index");

  v->add("appname", "tunesd");
  v->add("request", req);
  v->add("controller", con);
  v->add("method", method);
  v->add("create_queue", (array)app->check->m->create_queue);
  v->add("exists_queue", (array)app->check->m->exists_queue);
  v->add("delete_queue", (array)app->check->m->delete_queue);
  v->add("history", values(app->check->m->history));
  v->add("songcount", app->db->get_song_count());
  response->set_view(v);
}
