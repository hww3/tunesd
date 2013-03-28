
inherit Fins.FinsView;

inherit Fins.Helpers.Macros.Basic;
inherit Fins.Helpers.Macros.Pagination;

protected void create(object application)
{
  ::create(application);
}

string simple_macro_format_length(Fins.Template.TemplateData data, mapping|void args)
{
  object r = data->get_request();

  if(!args || !args->var) return "";

  int secs = ((int)args->var)/1000;
  if(secs >= 3600)
  {
    int h = secs / 3600;
    secs = secs % 3600;
    return sprintf("%d.%02d.%02d", h, secs/60, secs%60);
  }
  else
    return sprintf("%d.%02d", secs/60, secs%60);
}