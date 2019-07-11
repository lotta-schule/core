defmodule ApiWeb.Schema do
  use Absinthe.Schema
  import_types ApiWeb.Schema.Types
  import_types Absinthe.Plug.Types

  query do
    field :tenants, list_of(:tenant) do
      resolve &Api.TenantResolver.all/2
    end

    field :tenant, :tenant do
      resolve &Api.TenantResolver.current/2
    end
    
    field :categories, list_of(:category) do
      resolve &Api.CategoryResolver.all/2
    end

    field :article, :article do
      arg :id, non_null(:id)
      resolve &Api.ArticleResolver.get/2
    end

    field :articles, list_of(:article) do
      arg :category_id, :id
      resolve &Api.ArticleResolver.all/2
    end

    field :page, list_of(:article) do
      arg :name, non_null(:string)
      resolve &Api.ArticleResolver.by_page/2
    end

    field :users, list_of(:user) do
      resolve &Api.UserResolver.all/2
    end

    field :user, type: :user do
      arg :id, non_null(:id)
      resolve &Api.UserResolver.find/2
    end
  end

  mutation do
    field :register, type: :authresult do
      arg :user, non_null(:update_user_params)

      resolve &Api.UserResolver.register/2
    end

    field :login, type: :authresult do
      arg :username, :string
      arg :password, :string

      resolve &Api.UserResolver.login/2
    end

    field :update_user, type: :user do
      arg :id, non_null(:id)
      arg :user, non_null(:update_user_params)

      resolve &Api.UserResolver.update/2
    end
    
    field :create_article, type: :article do
      arg :article, non_null(:create_article_input)
  
      resolve &Api.ArticleResolver.create/2
    end
    
    field :update_article, type: :article do
      arg :id, non_null(:id)
      arg :article, non_null(:update_article_input)
  
      resolve &Api.ArticleResolver.update/2
    end

    field :upload_file, type: :file do
      arg :path, :string, default_value: "/"
      arg :file, non_null(:upload)

      resolve &Api.FileResolver.upload/2
    end

  end

  input_object :update_user_params do
    field :name, :string
    field :email, :string
    field :password, :string
  end
  
  input_object :create_article_input do
    field :title, non_null(:string)
    field :preview, :string
    field :preview_image_url, :string
    field :page_name, :string
    field :category_id, :id
    field :content_modules, list_of(:content_module_input)
  end

  input_object :update_article_input do
    field :title, :string
    field :preview, :string
    field :preview_image_url, :string
    field :page_name, :string
    field :content_modules, list_of(:content_module_input)
  end
  
  input_object :content_module_input do
    field :type, :content_module_type, default_value: "text"
    field :text, :string
    field :sort_key, :integer
  end

  def context(ctx) do
    loader =
      Dataloader.new
      |> Dataloader.add_source(Api.Content, Api.Content.data())
      |> Dataloader.add_source(Api.Tenants, Api.Tenants.data())
      |> Dataloader.add_source(Api.Accounts, Api.Accounts.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end