defmodule ChatWeb.Helpers do
  def convert_links_to_html(text) do
    regex = ~r/(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?/ix
    sanitized_text = HtmlSanitizeEx.sanitize(text)
    String.replace(sanitized_text, regex, fn url ->
      "<a href=\"#{url}\" target=\"_blank\">#{url}</a>"
    end)
  end
end
