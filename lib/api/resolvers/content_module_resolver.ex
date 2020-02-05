defmodule Api.ContentModuleResolver do
  alias Api.Content
  alias Api.Accounts.User

  def send_form_response(%{content_module_id: content_module_id, response: response}, %{context: context}) do
    content_module = Content.get_content_module!(content_module_id)
    try do
      %{configuration: %{"elements" => elements} = configuration} = content_module
      responses =
        elements
        |> Enum.reduce(%{}, fn element, acc ->
          Map.put(acc, element["name"], response[element["name"]] || "(LEER)")
        end)
      if !is_nil(configuration["destination"]) do
          Api.EmailPublisherWorker.send_content_module_form_response(content_module, responses)
      end
      if !is_nil(configuration["save_internally"]) do
        Content.save_content_module_result!(content_module, context[:current_user], %{responses: responses})
      end
      {:ok, true}
    rescue
      MatchError ->
        {:error, "Formular ist falsch konfiguriert. Anfrage konnte nicht versendet werden."}
    end
  end

  def get_responses(%{content_module_id: content_module_id}, %{context: context}) do
    content_module =
      Content.get_content_module!(content_module_id)
      |> Api.Repo.preload([:results, :article])
    tenant =
      content_module
      |> Map.fetch!(:article)
      |> Api.Repo.preload(:tenant)
      |> Map.fetch!(:tenant)
    unless context[:current_user] && User.is_admin?(context.current_user, tenant) do
      {:error, "Nur Administratoren dürfen Modul-Ergebnisse abrufen."}
    else
      {:ok, content_module.results}
    end
  end
end