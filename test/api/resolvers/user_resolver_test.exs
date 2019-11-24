defmodule Api.UserResolverTest do
  use ApiWeb.ConnCase
  
  setup do
    Api.Repo.Seeder.seed()

    web_tenant = Api.Tenants.get_tenant_by_slug!("web")
    admin = Api.Repo.get_by!(Api.Accounts.User, [email: "alexis.rinaldoni@einsa.net"])
    user = Api.Repo.get_by!(Api.Accounts.User, [email: "eike.wiewiorra@einsa.net"])
    {:ok, admin_jwt, _} = Api.Guardian.encode_and_sign(admin, %{ email: admin.email, name: admin.name })
    {:ok, user_jwt, _} = Api.Guardian.encode_and_sign(user, %{ email: user.email, name: user.name })

    {:ok, %{
      web_tenant: web_tenant,
      admin: admin,
      admin_jwt: admin_jwt,
      user: user,
      user_jwt: user_jwt,
    }}
  end

  describe "currentUser query" do
    @query """
    {
      currentUser {
        id
        email
        name
        nickname
      }
    }
    """

    test "returns current_user if user is logged in", %{admin: admin, admin_jwt: admin_jwt} do
      res = build_conn()
      |> put_req_header("authorization", "Bearer #{admin_jwt}")
      |> get("/api", query: @query)
      |> json_response(200)

      assert res == %{
        "data" => %{
          "currentUser" => %{
              "id" => admin.id,
              "email" => "alexis.rinaldoni@einsa.net",
              "name" => "Alexis Rinaldoni",
              "nickname" => "Der Meister"
          }
        }
      }
    end
    test "returns null if user is not logged in" do
      res = build_conn()
      |> get("/api", query: @query)
      |> json_response(200)

      assert res == %{
        "data" => %{
          "currentUser" => nil
        }
      }
    end
  end


  describe "users query" do
    @query """
    {
      users {
        email
        name
        nickname
      }
    }
    """

    test "returns users list if user is admin", %{admin_jwt: admin_jwt} do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{admin_jwt}")
      |> get("/api", query: @query)
      |> json_response(200)

      assert res == %{
        "data" => %{
          "users" => [
              %{"email" => "alexis.rinaldoni@einsa.net", "name" => "Alexis Rinaldoni", "nickname" => "Der Meister"},
              %{"email" => "billy@einsa.net", "name" => "Christopher Bill", "nickname" => "Billy"},
              %{"email" => "eike.wiewiorra@einsa.net", "name" => "Eike Wiewiorra", "nickname" => "Chef"}
          ]
        }
      }
    end

    test "returns error if user is not admin", %{user_jwt: user_jwt} do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{user_jwt}")
      |> get("/api", query: @query)
      |> json_response(200)

      assert res == %{
        "data" => %{
          "users" => nil,
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Nur Administrator dürfen auf Benutzer auflisten.",
            "path" => ["users"]
          }
        ]
      }
    end
  end


  describe "searchUsers query" do
    @query """
    query searchUsers($searchtext: String!) {
      searchUsers(searchtext: $searchtext) {
        email
        name
        nickname
      }
    }
    """

    test "should find users of same tenant by name is user is admin", %{admin_jwt: admin_jwt} do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{admin_jwt}")
      |> get("/api", query: @query, variables: %{searchtext: "alexis"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "searchUsers" => [
              %{"email" => "alexis.rinaldoni@einsa.net", "name" => "Alexis Rinaldoni", "nickname" => "Der Meister"},
          ]
        }
      }
    end

    test "should find users of same tenant by nickname is user is admin", %{admin_jwt: admin_jwt} do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{admin_jwt}")
      |> get("/api", query: @query, variables: %{searchtext: "Meister"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "searchUsers" => [
              %{"email" => "alexis.rinaldoni@einsa.net", "name" => "Alexis Rinaldoni", "nickname" => "Der Meister"},
          ]
        }
      }
    end

    test "should find users of same tenant by exact email is user is admin", %{admin_jwt: admin_jwt} do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{admin_jwt}")
      |> get("/api", query: @query, variables: %{searchtext: "mcurie@lotta.schule"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "searchUsers" => [
              %{"email" => "mcurie@lotta.schule", "name" => "Marie Curie", "nickname" => "Polonium"}
          ]
        }
      }
    end

    test "should return an empty results array if there is no match", %{admin_jwt: admin_jwt} do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{admin_jwt}")
      |> get("/api", query: @query, variables: %{searchtext: "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "searchUsers" => []
        }
      }
    end

    test "should return an empty results array if there is a two-characters input", %{admin_jwt: admin_jwt} do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{admin_jwt}")
      |> get("/api", query: @query, variables: %{searchtext: "De"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "searchUsers" => []
        }
      }
    end

    test "should throw an error if user is not admin", %{user_jwt: user_jwt} do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{user_jwt}")
      |> get("/api", query: @query, variables: %{searchtext: "De"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "searchUsers" => nil,
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Nur Administrator dürfen auf Benutzer auflisten.",
            "path" => ["searchUsers"]
          }
        ]
      }
    end

    test "should throw an error if user is not logged in" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> get("/api", query: @query, variables: %{searchtext: "De"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "searchUsers" => nil,
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Nur Administrator dürfen auf Benutzer auflisten.",
            "path" => ["searchUsers"]
          }
        ]
      }
    end
  end


  describe "user query" do
    @query """
    query user($id: ID!) {
      user(id: $id) {
        email
        name
        nickname
      }
    }
    """

    test "should return user with requested id if user is admin", %{admin_jwt: admin_jwt, user: user} do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{admin_jwt}")
      |> get("/api", query: @query, variables: %{id: user.id})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "user" => %{"email" => "eike.wiewiorra@einsa.net", "name" => "Eike Wiewiorra", "nickname" => "Chef"}
        }
      }
    end

    test "should return nil if user is admin, but requested id does not exist", %{admin_jwt: admin_jwt} do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{admin_jwt}")
      |> get("/api", query: @query, variables: %{id: 0})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "user" => nil,
        }
      }
    end

    test "should return an error if user is not an admin", %{user_jwt: user_jwt} do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{user_jwt}")
      |> get("/api", query: @query, variables: %{id: 0})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "user" => nil,
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Nur Administrator dürfen auf Benutzer auflisten.",
            "path" => ["user"]
          }
        ]
      }
    end

    test "should return an error if user is not logged in" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> get("/api", query: @query, variables: %{id: 0})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "user" => nil,
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Nur Administrator dürfen auf Benutzer auflisten.",
            "path" => ["user"]
          }
        ]
      }
    end
  end


  describe "register mutation" do
    @query """
    mutation register($user: RegisterUserParams!, $groupKey: String) {
      register(user: $user, groupKey: $groupKey) {
        token
      }
    }
    """

    test "register the user if data is entered correctly" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{user: %{ name: "Neuer Nutzer", email: "neuernutzer@example.com", password: "test123" }})
      |> json_response(200)

      assert String.valid?(res["data"]["register"]["token"])
    end

    test "register the user and put him into groupkey's group" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{user: %{ name: "Neuer Nutzer", email: "neuernutzer@example.com", password: "test123" }, groupKey: "LEb0815Hp!1969"})
      |> json_response(200)

      assert String.valid?(res["data"]["register"]["token"])
    end

    test "returns error when email is already taken" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{user: %{ name: "Neuer Nutzer", email: "alexis.rinaldoni@einsa.net", password: "test123" }, groupKey: "LEb0815Hp!1969"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "register" => nil,
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Registrierung fehlgeschlagen.",
            "details" => %{"email" => ["has already been taken"]},
            "path" => ["register"]
          }
        ]
      }
    end
    
    test "returns error when no password is given" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{user: %{ name: "Neuer Nutzer", email: "alexis.rinaldoni@einsa.net", password: "" }, groupKey: "LEb0815Hp!1969"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "register" => nil,
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Registrierung fehlgeschlagen.",
            "details" => %{"password" => ["can't be blank"]},
            "path" => ["register"]
          }
        ]
      }
    end
    
    test "returns error when no name is given" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{user: %{ name: "", email: "alexis.rinaldoni@einsa.net", password: "test123" }, groupKey: "LEb0815Hp!1969"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "register" => nil,
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Registrierung fehlgeschlagen.",
            "details" => %{"name" => ["can't be blank"]},
            "path" => ["register"]
          }
        ]
      }
    end
    
    test "returns error when hide_full_name is selected but no nickname is given" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{user: %{ name: "Napoleon Bonaparte", email: "napoleon@bonaparte.fr", password: "test123", hide_full_name: true }})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "register" => nil,
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Registrierung fehlgeschlagen.",
            "details" => %{"nickname" => ["can't be blank"]},
            "path" => ["register"]
          }
        ]
      }
    end
  end


  describe "login mutation" do
    @query """
    mutation login($username: String!, $password: String!) {
      login(username: $username, password: $password) {
        token
      }
    }
    """

    test "returns the user if data is entered correctly" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{username: "alexis.rinaldoni@einsa.net", password: "test123"})
      |> json_response(200)
      
      assert String.valid?(res["data"]["login"]["token"])
    end
    
    test "returns an error if the username is non-existent" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{username: "zzzzzzzzzzzzzzzzzzzz@bbbbbbbbbbbbbbb.ddd", password: "test123"})
      |> json_response(200)
      
      assert res == %{
        "data" => %{
          "login" => nil
          },
          "errors" => [
            %{
              "locations" => [%{"column" => 0, "line" => 2}],
              "message" => "Falsche Zugangsdaten.",
              "path" => ["login"]
            }
          ]
        }
      end
      
    test "returns an error if the password is wrong" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{username: "alexis.rinaldoni@einsa.net", password: "abcdef999"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "login" => nil
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Falsche Zugangsdaten.",
            "path" => ["login"]
          }
        ]
      }
    end
  end
  
  describe "requestPasswordResetMutation" do
    @query """
    mutation requestPasswordReset($email: String!) {
      requestPasswordReset(email: $email)
    }
    """

    test "returns true if the user exists" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{email: "alexis.rinaldoni@einsa.net"})
      |> json_response(200)
      
      assert res == %{
        "data" => %{
          "requestPasswordReset" => true
        }
      }
      assert {:ok, 1} = Redix.command(:redix, ["EXISTS", "user-email-verify-token-alexis.rinaldoni@einsa.net"])
      Redix.command(:redix, ["FLUSHALL"])
    end
    
    test "returns true if the user does not exist" do
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{email: "abcZZa@invalid.email"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "requestPasswordReset" => true
        }
      }
      assert {:ok, 0} = Redix.command(:redix, ["EXISTS", "user-email-verify-token-abcZZa@invalid.email"])
      Redix.command(:redix, ["FLUSHALL"])
    end
  end
  
  describe "resetPassword mutation" do
    @query """
    mutation resetPassword($email: String!, $token: String!, $password: String!) {
      resetPassword(email: $email, token: $token, password: $password) {
        token
      }
    }
    """

    test "returns an auth token if given user info is correct" do
      token = "abcdef123"
      Redix.command(:redix, ["SET", "user-email-verify-token-alexis.rinaldoni@einsa.net", token])
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{email: "alexis.rinaldoni@einsa.net", token: token, password: "abcdef"})
      |> json_response(200)

      user = Api.Repo.get_by!(Api.Accounts.User, [email: "alexis.rinaldoni@einsa.net"])
      
      assert String.valid?(res["data"]["resetPassword"]["token"])
      assert true = Bcrypt.verify_pass("abcdef", user.password_hash)
      Redix.command(:redix, ["FLUSHALL"])
    end
    
    test "returns an error if given token is not correct" do
      token = "abcdef123"
      Redix.command(:redix, ["SET", "user-email-verify-token-alexis.rinaldoni@einsa.net", token <> "blub"])
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{email: "alexis.rinaldoni@einsa.net", token: token, password: "abcdef"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "resetPassword" => nil
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Die Seite ist nicht mehr gültig. Starte den Vorgang erneut.",
            "path" => ["resetPassword"]
          }
        ]
      }
      Redix.command(:redix, ["FLUSHALL"])
    end
    
    test "returns an error if given email is not correct" do
      token = "abcdef123"
      Redix.command(:redix, ["SET", "user-email-verify-token-alexis.rinaldoni@einsa.net", token])
      res = build_conn()
      |> put_req_header("tenant", "slug:web")
      |> post("/api", query: @query, variables: %{email: "alexis.rinaldoni@blub.einsa.net", token: token, password: "abcdef"})
      |> json_response(200)

      assert res == %{
        "data" => %{
          "resetPassword" => nil
        },
        "errors" => [
          %{
            "locations" => [%{"column" => 0, "line" => 2}],
            "message" => "Die Seite ist nicht mehr gültig. Starte den Vorgang erneut.",
            "path" => ["resetPassword"]
          }
        ]
      }
      Redix.command(:redix, ["FLUSHALL"])
    end
  end
end