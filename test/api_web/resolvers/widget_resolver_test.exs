defmodule ApiWeb.WidgetResolverTest do
  @moduledoc false

  use ApiWeb.ConnCase

  import Ecto.Query

  alias ApiWeb.Auth.AccessToken
  alias Api.Repo.Seeder
  alias Api.Repo
  alias Api.System.{Category, Widget}
  alias Api.Accounts.{User}

  setup do
    Seeder.seed()

    admin = Repo.get_by!(User, email: "alexis.rinaldoni@lotta.schule")
    user = Repo.get_by!(User, email: "eike.wiewiorra@lotta.schule")

    {:ok, admin_jwt, _} =
      AccessToken.encode_and_sign(admin, %{email: admin.email, name: admin.name})

    {:ok, user_jwt, _} = AccessToken.encode_and_sign(user, %{email: user.email, name: user.name})

    widget = Repo.one!(from Widget, limit: 1)

    homepage = Repo.one!(from c in Category, where: c.is_homepage == true)

    {:ok,
     %{
       admin_account: admin,
       admin_jwt: admin_jwt,
       user_account: user,
       user_jwt: user_jwt,
       widget: widget,
       homepage: homepage
     }}
  end

  describe "widgets query" do
    @query """
    {
      widgets {
        title
        type
        groups {
          name
        }
      }
    }
    """

    test "returns widgets if user is admin", %{admin_jwt: admin_jwt} do
      res =
        build_conn()
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> get("/api", query: @query)
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "widgets" => [
                   %{"groups" => [], "title" => "Kalender", "type" => "CALENDAR"},
                   %{
                     "groups" => [%{"name" => "Verwaltung"}, %{"name" => "Lehrer"}],
                     "title" => "Kalender",
                     "type" => "CALENDAR"
                   },
                   %{
                     "groups" => [%{"name" => "Verwaltung"}, %{"name" => "Lehrer"}],
                     "title" => "Kalender",
                     "type" => "CALENDAR"
                   }
                 ]
               }
             }
    end

    test "returns widgets if user is not admin", %{user_jwt: user_jwt} do
      res =
        build_conn()
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> get("/api", query: @query)
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "widgets" => [
                   %{"groups" => [], "title" => "Kalender", "type" => "CALENDAR"},
                   %{
                     "groups" => [%{"name" => "Verwaltung"}, %{"name" => "Lehrer"}],
                     "title" => "Kalender",
                     "type" => "CALENDAR"
                   },
                   %{
                     "groups" => [%{"name" => "Verwaltung"}, %{"name" => "Lehrer"}],
                     "title" => "Kalender",
                     "type" => "CALENDAR"
                   }
                 ]
               }
             }
    end

    test "returns widgets if user is not logged in" do
      res =
        build_conn()
        |> get("/api", query: @query)
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "widgets" => [
                   %{"groups" => [], "title" => "Kalender", "type" => "CALENDAR"}
                 ]
               }
             }
    end
  end

  describe "widgets query with categoryId" do
    @query """
    query GetWidgets($categoryId: ID!) {
      widgets(categoryId: $categoryId) {
        title
        type
        groups {
          name
        }
      }
    }
    """

    test "returns widgets if user is admin", %{admin_jwt: admin_jwt, homepage: homepage} do
      res =
        build_conn()
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> get("/api", query: @query, variables: %{categoryId: homepage.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "widgets" => [
                   %{"groups" => [], "title" => "Kalender", "type" => "CALENDAR"},
                   %{
                     "groups" => [%{"name" => "Verwaltung"}, %{"name" => "Lehrer"}],
                     "title" => "Kalender",
                     "type" => "CALENDAR"
                   },
                   %{
                     "groups" => [%{"name" => "Verwaltung"}, %{"name" => "Lehrer"}],
                     "title" => "Kalender",
                     "type" => "CALENDAR"
                   }
                 ]
               }
             }
    end

    test "returns widgets if user is not admin", %{user_jwt: user_jwt, homepage: homepage} do
      res =
        build_conn()
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> get("/api", query: @query, variables: %{categoryId: homepage.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "widgets" => [
                   %{"groups" => [], "title" => "Kalender", "type" => "CALENDAR"},
                   %{
                     "groups" => [%{"name" => "Verwaltung"}, %{"name" => "Lehrer"}],
                     "title" => "Kalender",
                     "type" => "CALENDAR"
                   },
                   %{
                     "groups" => [%{"name" => "Verwaltung"}, %{"name" => "Lehrer"}],
                     "title" => "Kalender",
                     "type" => "CALENDAR"
                   }
                 ]
               }
             }
    end

    test "returns widgets if user is not logged in", %{homepage: homepage} do
      res =
        build_conn()
        |> get("/api", query: @query, variables: %{categoryId: homepage.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "widgets" => [
                   %{"groups" => [], "title" => "Kalender", "type" => "CALENDAR"}
                 ]
               }
             }
    end
  end

  describe "createWidget mutation" do
    @query """
    mutation createWidget($title: String!, $type: WidgetType!) {
      createWidget (title: $title, type: $type) {
        title
        type
      }
    }
    """

    test "creates a widget if user is admin", %{admin_jwt: admin_jwt} do
      res =
        build_conn()
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> post("/api", query: @query, variables: %{title: "New Widget", type: "CALENDAR"})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "createWidget" => %{
                   "title" => "New Widget",
                   "type" => "CALENDAR"
                 }
               }
             }
    end

    test "returns an error if user is not admin", %{user_jwt: user_jwt} do
      res =
        build_conn()
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> post("/api", query: @query, variables: %{title: "New Widget", type: "CALENDAR"})
        |> json_response(200)

      assert %{
               "data" => %{
                 "createWidget" => nil
               },
               "errors" => [
                 %{
                   "message" => "Du musst Administrator sein um das zu tun.",
                   "path" => ["createWidget"]
                 }
               ]
             } = res
    end

    test "returns an error if user is not logged in" do
      res =
        build_conn()
        |> post("/api", query: @query, variables: %{title: "New Widget", type: "CALENDAR"})
        |> json_response(200)

      assert %{
               "data" => %{
                 "createWidget" => nil
               },
               "errors" => [
                 %{
                   "message" => "Du musst Administrator sein um das zu tun.",
                   "path" => ["createWidget"]
                 }
               ]
             } = res
    end
  end

  describe "updateWidget mutation" do
    @query """
    mutation updateWidget($id: ID!, $widget: WidgetInput!) {
      updateWidget (id: $id, widget: $widget) {
        title
        type
      }
    }
    """

    test "creates a widget if user is admin", %{admin_jwt: admin_jwt, widget: widget} do
      res =
        build_conn()
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> post("/api",
          query: @query,
          variables: %{id: widget.id, widget: %{title: "Changed Widget"}}
        )
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateWidget" => %{
                   "title" => "Changed Widget",
                   "type" => "CALENDAR"
                 }
               }
             } = res
    end

    test "returns an error if user is not admin", %{user_jwt: user_jwt, widget: widget} do
      res =
        build_conn()
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> post("/api",
          query: @query,
          variables: %{id: widget.id, widget: %{title: "Changed Widget"}}
        )
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateWidget" => nil
               },
               "errors" => [
                 %{
                   "message" => "Du musst Administrator sein um das zu tun.",
                   "path" => ["updateWidget"]
                 }
               ]
             } = res
    end

    test "returns an error if user is not logged in", %{widget: widget} do
      res =
        build_conn()
        |> post("/api",
          query: @query,
          variables: %{id: widget.id, widget: %{title: "Changed Widget"}}
        )
        |> json_response(200)

      assert %{
               "data" => %{
                 "updateWidget" => nil
               },
               "errors" => [
                 %{
                   "message" => "Du musst Administrator sein um das zu tun.",
                   "path" => ["updateWidget"]
                 }
               ]
             } = res
    end
  end

  describe "deleteWidget mutation" do
    @query """
    mutation deleteWidget($id: ID!) {
      deleteWidget (id: $id) {
        id
      }
    }
    """

    test "deletes a widget if user is admin", %{admin_jwt: admin_jwt, widget: widget} do
      res =
        build_conn()
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> post("/api", query: @query, variables: %{id: widget.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "deleteWidget" => %{
                   "id" => Integer.to_string(widget.id)
                 }
               }
             }
    end

    test "returns an error if user is not admin", %{user_jwt: user_jwt} do
      res =
        build_conn()
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> post("/api", query: @query, variables: %{id: 0})
        |> json_response(200)

      assert %{
               "data" => %{
                 "deleteWidget" => nil
               },
               "errors" => [
                 %{
                   "message" => "Du musst Administrator sein um das zu tun.",
                   "path" => ["deleteWidget"]
                 }
               ]
             } = res
    end

    test "returns an error if user is not logged in" do
      res =
        build_conn()
        |> post("/api", query: @query, variables: %{id: 0})
        |> json_response(200)

      assert %{
               "data" => %{
                 "deleteWidget" => nil
               },
               "errors" => [
                 %{
                   "message" => "Du musst Administrator sein um das zu tun.",
                   "path" => ["deleteWidget"]
                 }
               ]
             } = res
    end
  end
end