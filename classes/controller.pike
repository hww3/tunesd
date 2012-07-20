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

  response->set_view(v);
}
