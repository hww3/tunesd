inherit Fins.HTTPRequest;

void finish(int clean)
{
  array x;
  if((x = fins_app->connections[this]) && sizeof(x) > 1)
    x[1](clean);
  m_delete(fins_app->connections, this);
  ::finish(clean);
}