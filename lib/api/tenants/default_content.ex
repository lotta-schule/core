defmodule Api.Tenants.DefaultContent do
  @moduledoc """
  All the data for adding default content to a new tenant
  """

  import Ecto.Changeset
  alias Api.Repo
  alias Api.Accounts.{Directory, User}
  alias Api.UploadService
  alias Api.Tenants.Tenant
  alias Api.Content.{Article, ContentModule}

  alias __MODULE__.Context

  defmodule __MODULE__.Context do
    @moduledoc """
    This is the context that will be passed throughout the DefaultContent pipeline
    """

    @type changetuple() :: {:update, Changeset.t()} | {:insert, Changeset.t()}

    defstruct tenant: %Tenant{},
              user: %User{},
              files: [],
              public_directory: nil,
              admin_group: nil,
              home_category: nil,
              content_category: nil,
              article1: nil,
              article2: nil,
              article3: nil,
              error: nil,
              results: []

    def execute_change(context, changeset_or_schema)

    @spec execute_change(
            context :: %Context{},
            changetuple(),
            property_name_on_context :: atom()
          ) ::
            %Context{}
    def execute_change(ctx, {action, change}, context_key \\ nil) do
      case ctx do
        %{error: nil} ->
          execute =
            case action do
              :insert -> &Repo.insert/1
              :update -> &Repo.update/1
            end

          case execute.(change) do
            {:ok, result} ->
              if is_nil(context_key) do
                ctx
              else
                Map.put(ctx, context_key, result)
              end
              |> Map.put(:results, Enum.reverse([result | ctx.results]))

            {:error, reason} ->
              Repo.rollback(reason)
              ctx
          end

        %{error: _} ->
          # This error should have been already reported
          # So, do nothing and just pass the context along
          ctx
      end
    end

    @doc """
    Should be placen at the end of the manipulation pipeline
    in order to return {:error, reason} or :ok
    """
    @spec terminate(%Context{}) :: :ok | {:error, term()}
    def terminate(context)

    def terminate(%Context{error: nil}), do: :ok
    def terminate(%Context{error: reason}), do: {:error, reason}
  end

  @doc """
  Creates the default content for a new tenant.
  The tenant should already have been created, the user should be eligible to be administrator
  """
  @spec create_default_content(%Tenant{}, %User{}) :: :ok | {:error, term()}
  def create_default_content(tenant, user) do
    %Context{tenant: tenant, user: user}
    |> create_default_groups()
    |> create_default_categories()
    |> create_default_files()
    |> create_default_articles()
    |> Context.terminate()
  end

  defp create_default_groups(%Context{tenant: tenant, user: user} = ctx) do
    ctx =
      ctx
      |> Context.execute_change(
        {
          :insert,
          tenant
          |> Ecto.build_assoc(:groups, %{
            name: "Administrator",
            sort_key: 0,
            is_admin_group: true
          })
        },
        :admin_group
      )

    ctx =
      ctx
      |> Context.execute_change(
        {:update, User.set_users_tenant_groups_changeset(user, tenant, [ctx.admin_group])}
      )

    ["Lehrer", "Schüler"]
    |> Enum.with_index()
    |> Enum.reduce(ctx, fn {name, i}, ctx ->
      ctx
      |> Context.execute_change(
        {:insert,
         Ecto.build_assoc(tenant, :groups, %{
           name: name,
           sort_key: 10 + i * 10
         })}
      )
    end)
  end

  defp create_default_categories(%Context{tenant: tenant} = ctx) do
    ctx
    |> Context.execute_change(
      {:insert,
       Ecto.build_assoc(tenant, :categories, %{
         title: "Startseite",
         sort_key: 0,
         is_sidenav: false,
         is_homepage: true
       })},
      :home_category
    )
    |> Context.execute_change(
      {:insert,
       Ecto.build_assoc(tenant, :categories, %{
         title: "Erste Schritte",
         sort_key: 10,
         is_sidenav: false,
         is_homepage: false
       })},
      :content_category
    )
  end

  defp create_default_files(%Context{tenant: tenant, user: %User{id: user_id}} = ctx) do
    ctx =
      ctx
      |> Context.execute_change(
        {:insert, %Directory{tenant_id: tenant.id, name: "Öffentliche Dateien"}},
        :public_directory
      )

    shared_dir = Map.fetch!(ctx, :public_directory)

    files =
      available_assets()
      |> Enum.with_index()
      |> Enum.map(fn {{filename, type}, index} ->
        oid = "#{user_id}#{DateTime.to_unix(DateTime.utc_now())}#{index}#{:rand.uniform(9999)}"
        fullpath = "priv/default_content/files/#{filename}"
        %{size: filesize} = File.stat!(fullpath)

        {:ok, %{url: remote_location}} =
          UploadService.upload_to_space(%{
            localfilepath: fullpath,
            content_type: type,
            file_name: UUID.uuid5(:dns, "#{oid}.ugc.lotta.schule")
          })

        {:ok, file} =
          %Api.Accounts.File{
            user_id: user_id,
            tenant_id: tenant.id,
            parent_directory_id: shared_dir.id,
            remote_location: remote_location,
            filename: filename,
            filesize: filesize,
            file_type:
              case type do
                "image" <> _ -> "image"
                "application/pdf" -> "pdf"
              end,
            mime_type: type
          }
          |> Repo.insert()

        file
      end)

    Map.put(ctx, :files, files)
  end

  defp create_default_articles(
         %Context{tenant: tenant, user: user, content_category: category, files: files} = ctx
       ) do
    first_step_1_article_changeset =
      %Article{
        title: "Erste Schritte mit Lotta",
        is_pinned_to_top: false,
        topic: "Hilfe",
        preview: "Erstellen und bearbeiten Sie Kategorien"
      }
      |> change()
      |> put_assoc(:tenant, tenant)
      |> put_assoc(:category, category)
      |> put_assoc(:preview_image_file, Enum.find(files, &(&1.filename == "kinderleicht1.jpg")))
      |> put_assoc(:users, [user])
      |> put_assoc(:content_modules, [
        %ContentModule{
          type: "title",
          configuration: %{},
          content: %{title: "Einführung"},
          sort_key: 0
        },
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-categories-SK10"),
          sort_key: 10
        },
        %ContentModule{
          type: "title",
          configuration: %{},
          content: %{title: "Wie Sie Kategorien anlegen"},
          sort_key: 20
        },
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-categories-SK30"),
          sort_key: 30
        },
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-categories-SK40"),
          sort_key: 40
        },
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-categories-SK50"),
          sort_key: 50
        },
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-categories-SK60"),
          sort_key: 60
        },
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-categories-SK70"),
          sort_key: 70
        },
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-categories-SK80"),
          sort_key: 80
        },
        %ContentModule{
          type: "title",
          configuration: %{},
          content: %{title: "Einstellmöglichkeiten in Kategorien"},
          sort_key: 90
        },
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-categories-SK100"),
          sort_key: 100
        }
      ])

    ctx =
      ctx
      |> Context.execute_change({:insert, first_step_1_article_changeset}, :article1)

    first_step_2_article_changeset =
      %Article{
        title: "Erste Schritte mit Lotta",
        is_pinned_to_top: false,
        topic: "Hilfe",
        preview: "Nutzergruppen & Einschreibeschlüssel organisieren"
      }
      |> change()
      |> put_assoc(:tenant, tenant)
      |> put_assoc(:category, category)
      |> put_assoc(:preview_image_file, Enum.find(files, &(&1.filename == "kinderleicht2.jpg")))
      |> put_assoc(:users, [user])
      |> put_assoc(:content_modules, [
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-usergroups-SK0"),
          sort_key: 0
        },
        %ContentModule{
          type: "image",
          configuration: %{},
          content: %{caption: "Bild 1"},
          files: [Enum.find(files, &(&1.filename == "erste-schritte-gruppen-anlegen-s1.png"))],
          sort_key: 10
        },
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-usergroups-SK20"),
          sort_key: 20
        },
        %ContentModule{
          type: "image",
          configuration: %{},
          content: %{
            caption:
              "Bild 2: Eintragen von Einschreibeschlüssel im persönlichen Profil der Nutzer."
          },
          files: [Enum.find(files, &(&1.filename == "erste-schritte-gruppen-anlegen-s2.png"))],
          sort_key: 30
        },
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-usergroups-SK40"),
          sort_key: 40
        },
        %ContentModule{
          type: "image_collection",
          configuration: %{
            "files" => %{
              Enum.find(files, &(&1.filename == "homepage-oeffentlich.jpg")).id => %{
                "caption" => "",
                "sortKey" => 0
              },
              Enum.find(files, &(&1.filename == "homepage-schueler.jpg")).id => %{
                "caption" => "",
                "sortKey" => 10
              },
              Enum.find(files, &(&1.filename == "homepage-lehrer.jpg")).id => %{
                "caption" => "",
                "sortKey" => 20
              }
            },
            "imageStyle" => 2,
            "sorting" => 0
          },
          content: %{},
          files: [
            Enum.find(files, &(&1.filename == "homepage-oeffentlich.jpg")),
            Enum.find(files, &(&1.filename == "homepage-schueler.jpg")),
            Enum.find(files, &(&1.filename == "homepage-lehrer.jpg"))
          ],
          sort_key: 50
        },
        %ContentModule{
          type: "text",
          configuration: %{},
          content: read_json(ctx, "first-steps-usergroups-SK60"),
          sort_key: 60
        },
        %ContentModule{
          type: "download",
          configuration: %{
            Enum.find(files, &(&1.filename == "erste-schritte-nutzergruppen.pdf")).id => %{
              description: "Diesen Beitrag als PDF-Datei herunterladen.",
              sortKey: 0
            }
          },
          content: %{},
          files: [Enum.find(files, &(&1.filename == "erste-schritte-nutzergruppen.pdf"))],
          sort_key: 70
        }
      ])

    ctx =
      ctx
      |> Context.execute_change({:insert, first_step_2_article_changeset}, :article2)

    welcome_article_changeset =
      %Article{
        title: "Willkommen",
        is_pinned_to_top: true,
        topic: "Hilfe",
        preview: "Ihre ersten Schritte in Lotta"
      }
      |> change()
      |> put_assoc(:tenant, tenant)
      |> put_assoc(:category, category)
      |> put_assoc(
        :preview_image_file,
        Enum.find(files, &(&1.filename == "willkommen-bei-lotta.png"))
      )
      |> put_assoc(:users, [user])
      |> put_assoc(:content_modules, [
        %ContentModule{
          type: "text",
          configuration: %{},
          sort_key: 0,
          content: read_json(ctx, "welcome")
        }
      ])

    ctx
    |> Context.execute_change({:insert, welcome_article_changeset}, :article3)
  end

  defp available_assets() do
    [
      {"willkommen-bei-lotta.png", "image/png"},
      {"kinderleicht1.jpg", "image/jpg"},
      {"kinderleicht2.jpg", "image/jpg"},
      {"willkommen-persoenliches-menu.jpg", "image/jpg"},
      {"willkommen-admin-nav.png", "image/png"},
      {"kategorien-anlegen-s1.jpg", "image/jpg"},
      {"kategorien-anlegen-s2.jpg", "image/jpg"},
      {"kategorien-anlegen-s3.jpg", "image/jpg"},
      {"kategorien-anlegen-s4.jpg", "image/jpg"},
      {"kategorien-anlegen-s5.jpg", "image/jpg"},
      {"kategorien-anlegen-s6.jpg", "image/jpg"},
      {"homepage-oeffentlich.jpg", "image/jpg"},
      {"homepage-schueler.jpg", "image/jpg"},
      {"homepage-lehrer.jpg", "image/jpg"},
      {"erste-schritte-gruppen-anlegen-s1.png", "image/png"},
      {"erste-schritte-gruppen-anlegen-s2.png", "image/png"},
      {"erste-schritte-nutzergruppen.pdf", "application/pdf"}
    ]
  end

  defp read_json(%Context{files: files}, filename) do
    Application.app_dir(:api, "priv/default_content/text/#{filename}.json")
    |> File.read!()
    |> String.replace(~r/__REMOTE_URL____([[:word:]-\.]*)/, fn text ->
      filename = String.replace_leading(text, "__REMOTE_URL____", "")

      case Enum.find(files, &(&1.filename == filename)) do
        file when not is_nil(file) ->
          file.remote_location

        _ ->
          text
      end
    end)
    |> Poison.decode!()
  end
end