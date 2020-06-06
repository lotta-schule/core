defmodule Api.FileResolverTest do
  @moduledoc """
    Test Module for FileResolver
  """

  use ApiWeb.ConnCase
  import Ecto.Query
  alias Api.Repo
  alias Api.Repo.Seeder
  alias Api.Tenants
  alias Api.Guardian
  alias Api.Accounts.{User, File, Directory}

  setup do
    Seeder.seed()

    web_tenant = Tenants.get_tenant_by_slug!("web")
    admin = Repo.get_by!(User, email: "alexis.rinaldoni@lotta.schule")
    user2 = Repo.get_by!(User, email: "eike.wiewiorra@lotta.schule")
    user = Repo.get_by!(User, email: "billy@lotta.schule")
    {:ok, admin_jwt, _} = Guardian.encode_and_sign(admin, %{email: admin.email, name: admin.name})
    {:ok, user2_jwt, _} = Guardian.encode_and_sign(user2, %{email: user2.email, name: user2.name})
    {:ok, user_jwt, _} = Guardian.encode_and_sign(user, %{email: user.email, name: user.name})
    admin_file = Repo.get_by!(File, filename: "ich_schoen.jpg")
    user_file = Repo.get_by!(File, filename: "ich_schoen.jpg")
    user2_file = Repo.get_by!(File, filename: "wieartig1.jpg")

    public_directory =
      Repo.one!(
        from d in Directory,
          where:
            d.name == "logos" and d.tenant_id == ^web_tenant.id and is_nil(d.user_id) and
              is_nil(d.parent_directory_id)
      )

    public_file =
      Repo.get_by!(File, filename: "logo1.jpg", parent_directory_id: public_directory.id)

    {:ok,
     %{
       web_tenant: web_tenant,
       admin_account: admin,
       admin_jwt: admin_jwt,
       user2_account: user2,
       user2_jwt: user2_jwt,
       user_account: user,
       user_jwt: user_jwt,
       admin_file: admin_file,
       user_file: user_file,
       user2_file: user2_file,
       public_directory: public_directory,
       public_file: public_file
     }}
  end

  describe "file query" do
    @query """
    query getFile($id: ID) {
      file(id: $id) {
        filename
        user {
          nickname
          name
        }
        parentDirectory {
          name
        }
      }
    }
    """

    test "returns own file for own directory of admin user", %{
      admin_jwt: admin_jwt,
      admin_file: admin_file
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> get("/api", query: @query, variables: %{id: admin_file.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "file" => %{
                   "filename" => "ich_schoen.jpg",
                   "user" => %{
                     "name" => "Alexis Rinaldoni",
                     "nickname" => "Der Meister"
                   },
                   "parentDirectory" => %{"name" => "logos"}
                 }
               }
             }
    end

    test "returns public file for public directory of admin user", %{
      admin_jwt: admin_jwt,
      public_file: public_file
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> get("/api", query: @query, variables: %{id: public_file.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "file" => %{
                   "filename" => "logo1.jpg",
                   "user" => %{
                     "name" => "Alexis Rinaldoni",
                     "nickname" => "Der Meister"
                   },
                   "parentDirectory" => %{
                     "name" => "logos"
                   }
                 }
               }
             }
    end

    test "returns public file for public directory for non admin user", %{
      user_jwt: user_jwt,
      public_file: public_file
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> post("/api", query: @query, variables: %{id: public_file.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "file" => %{
                   "filename" => "logo1.jpg",
                   "user" => %{
                     # full name not given to other users
                     "name" => nil,
                     "nickname" => "Der Meister"
                   },
                   "parentDirectory" => %{
                     "name" => "logos"
                   }
                 }
               }
             }
    end

    test "returns error when user is not owner of private directory and user is not admin", %{
      user_jwt: user_jwt,
      user2_file: user2_file
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> post("/api", query: @query, variables: %{id: user2_file.id})
        |> json_response(200)

      assert res == %{
               "data" => %{"file" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Du hast nicht die Berechtigung, diese Datei zu lesen.",
                   "path" => ["file"]
                 }
               ]
             }
    end

    test "returns error when user is not owner of private directory and user is admin", %{
      admin_jwt: admin_jwt,
      user2_file: user2_file
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> post("/api", query: @query, variables: %{id: user2_file.id})
        |> json_response(200)

      assert res == %{
               "data" => %{"file" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Du hast nicht die Berechtigung, diese Datei zu lesen.",
                   "path" => ["file"]
                 }
               ]
             }
    end
  end

  describe "resolve file usage" do
    @query """
    query getFileUsage($id: ID) {
      file(id: $id) {
        filename
        usage {
          ... on FileCategoryUsageLocation {
            usage
            category {
              title
            }
          }
          ... on FileArticleUsageLocation {
            usage
            article {
              title
              previewImageFile {
                remoteLocation
              }
            }
          }
          ... on FileContentModuleUsageLocation {
            usage
            article {
              title
              previewImageFile {
                remoteLocation
              }
            }
          }
          ... on FileTenantUsageLocation {
            usage
            tenant {
              slug
            }
          }
          ... on FileUserUsageLocation {
            usage
            user {
              name
              nickname
              avatarImageFile {
                remoteLocation
              }
            }
          }
        }
      }
    }
    """

    test "returns own file's usage for admin user", %{
      admin_jwt: admin_jwt,
      admin_file: admin_file
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> get("/api", query: @query, variables: %{id: admin_file.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "file" => %{
                   "filename" => "ich_schoen.jpg",
                   "usage" => [
                     %{
                       "usage" => "avatar",
                       "user" => %{
                         "avatarImageFile" => %{"remoteLocation" => "http://a.de/0801801"},
                         "name" => "Alexis Rinaldoni",
                         "nickname" => "Der Meister"
                       }
                     }
                   ]
                 }
               }
             }
    end

    test "returns own file's usage for non-admin user", %{
      user2_jwt: user2_jwt,
      user2_file: user2_file
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user2_jwt}")
        |> get("/api", query: @query, variables: %{id: user2_file.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "file" => %{
                   "filename" => "wieartig1.jpg",
                   "usage" => [
                     %{
                       "article" => %{
                         "previewImageFile" => %{"remoteLocation" => "http://a.de/0801345801"},
                         "title" => "Fertiger Artikel zum Konzert"
                       },
                       "usage" => "preview"
                     },
                     %{
                       "article" => %{
                         "previewImageFile" => %{"remoteLocation" => "http://a.de/0801345801"},
                         "title" => "Draft2"
                       },
                       "usage" => "preview"
                     },
                     %{
                       "article" => %{
                         "previewImageFile" => %{"remoteLocation" => "http://a.de/0801345801"},
                         "title" => "Draft1"
                       },
                       "usage" => "preview"
                     }
                   ]
                 }
               }
             }
    end

    test "returns public file's usage for admin user", %{
      admin_jwt: admin_jwt,
      public_file: public_file
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> get("/api", query: @query, variables: %{id: public_file.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "file" => %{
                   "filename" => "logo1.jpg",
                   "usage" => [
                     %{"category" => %{"title" => "Fächer"}, "usage" => "banner"},
                     %{"category" => %{"title" => "GTA"}, "usage" => "banner"},
                     %{"category" => %{"title" => "Profil"}, "usage" => "banner"},
                     %{"category" => %{"title" => "Projekt"}, "usage" => "banner"}
                   ]
                 }
               }
             }
    end

    test "returns public file's usage for non-admin user", %{
      user2_jwt: user2_jwt,
      public_file: public_file
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user2_jwt}")
        |> get("/api", query: @query, variables: %{id: public_file.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "file" => %{
                   "filename" => "logo1.jpg",
                   "usage" => [
                     %{"category" => %{"title" => "Fächer"}, "usage" => "banner"},
                     %{"category" => %{"title" => "GTA"}, "usage" => "banner"},
                     %{"category" => %{"title" => "Profil"}, "usage" => "banner"},
                     %{"category" => %{"title" => "Projekt"}, "usage" => "banner"}
                   ]
                 }
               }
             }
    end
  end

  describe "files query" do
    @query """
    query getDirectoriesAndFiles($parentDirectoryId: ID) {
      files(parentDirectoryId: $parentDirectoryId) {
        filename
        userId
        parentDirectory {
          name
        }
      }
    }
    """

    test "returns own files for own directory of admin user", %{
      admin_jwt: admin_jwt,
      admin_account: admin_account
    } do
      admin_dir =
        Api.Repo.get_by!(Api.Accounts.Directory, name: "podcast", user_id: admin_account.id)

      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> get("/api", query: @query, variables: %{parentDirectoryId: admin_dir.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "files" => [
                   %{
                     "filename" => "pc3.m4v",
                     "userId" => admin_account.id,
                     "parentDirectory" => %{"name" => "podcast"}
                   },
                   %{
                     "filename" => "podcast1.mp4",
                     "userId" => admin_account.id,
                     "parentDirectory" => %{"name" => "podcast"}
                   },
                   %{
                     "filename" => "podcast2.mov",
                     "userId" => admin_account.id,
                     "parentDirectory" => %{"name" => "podcast"}
                   }
                 ]
               }
             }
    end

    test "returns public files for public directory of admin user", %{
      admin_jwt: admin_jwt,
      admin_account: admin_account,
      public_directory: public_directory
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> get("/api", query: @query, variables: %{parentDirectoryId: public_directory.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "files" => [
                   %{
                     "filename" => "logo1.jpg",
                     "userId" => admin_account.id,
                     "parentDirectory" => %{"name" => "logos"}
                   },
                   %{
                     "filename" => "logo2.jpg",
                     "userId" => admin_account.id,
                     "parentDirectory" => %{"name" => "logos"}
                   },
                   %{
                     "filename" => "logo3.png",
                     "userId" => admin_account.id,
                     "parentDirectory" => %{"name" => "logos"}
                   },
                   %{
                     "filename" => "logo4.png",
                     "userId" => admin_account.id,
                     "parentDirectory" => %{"name" => "logos"}
                   }
                 ]
               }
             }
    end

    test "returns public files for public directory for non admin user", %{
      user_jwt: user_jwt,
      admin_account: admin_account,
      public_directory: public_directory
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> post("/api", query: @query, variables: %{parentDirectoryId: public_directory.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "files" => [
                   %{
                     "filename" => "logo1.jpg",
                     "userId" => admin_account.id,
                     "parentDirectory" => %{"name" => "logos"}
                   },
                   %{
                     "filename" => "logo2.jpg",
                     "userId" => admin_account.id,
                     "parentDirectory" => %{"name" => "logos"}
                   },
                   %{
                     "filename" => "logo3.png",
                     "userId" => admin_account.id,
                     "parentDirectory" => %{"name" => "logos"}
                   },
                   %{
                     "filename" => "logo4.png",
                     "userId" => admin_account.id,
                     "parentDirectory" => %{"name" => "logos"}
                   }
                 ]
               }
             }
    end

    test "returns error when user is not owner of private directory and user is not admin", %{
      user_jwt: user_jwt,
      user2_account: user2_account,
      web_tenant: web_tenant
    } do
      user2_directory =
        Repo.get_by!(Directory,
          name: "avatar",
          tenant_id: web_tenant.id,
          user_id: user2_account.id
        )

      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> post("/api", query: @query, variables: %{parentDirectoryId: user2_directory.id})
        |> json_response(200)

      assert res == %{
               "data" => %{"files" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Du hast nicht die Berechtigung, diesen Ordner zu lesen.",
                   "path" => ["files"]
                 }
               ]
             }
    end

    test "returns error when user is not owner of private directory and user is admin", %{
      admin_jwt: admin_jwt,
      user2_account: user2_account,
      web_tenant: web_tenant
    } do
      user2_directory =
        Repo.get_by!(Directory,
          name: "avatar",
          tenant_id: web_tenant.id,
          user_id: user2_account.id
        )

      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> post("/api", query: @query, variables: %{parentDirectoryId: user2_directory.id})
        |> json_response(200)

      assert res == %{
               "data" => %{"files" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Du hast nicht die Berechtigung, diesen Ordner zu lesen.",
                   "path" => ["files"]
                 }
               ]
             }
    end
  end

  describe "update file mutation" do
    @query """
    mutation updateFile($id: ID!, $parentDirectoryId: ID, $filename: String) {
      updateFile(id: $id, parentDirectoryId: $parentDirectoryId, filename: $filename) {
        filename
        parentDirectory {
          name
        }
      }
    }
    """
    test "move a user's own file to own directory", %{
      user2_file: user2_file,
      user2_jwt: user2_jwt,
      user2_account: user2_account
    } do
      target_dir = Repo.get_by!(Directory, name: "podcast", user_id: user2_account.id)

      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user2_jwt}")
        |> post("/api",
          query: @query,
          variables: %{id: user2_file.id, parentDirectoryId: target_dir.id}
        )
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "updateFile" => %{
                   "filename" => "wieartig1.jpg",
                   "parentDirectory" => %{"name" => "podcast"}
                 }
               }
             }
    end

    test "returns error when user is not owner of private source directory and user is not admin",
         %{user2_file: user2_file, user_jwt: user_jwt} do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user_jwt}")
        |> post("/api",
          query: @query,
          variables: %{id: user2_file.id, filename: "newfilename.file"}
        )
        |> json_response(200)

      assert res == %{
               "data" => %{"updateFile" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Du darfst diese Datei nicht bearbeiten.",
                   "path" => ["updateFile"]
                 }
               ]
             }
    end

    test "returns error when user is not owner of private source directory and user is admin", %{
      user2_file: user2_file,
      admin_jwt: admin_jwt
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> post("/api",
          query: @query,
          variables: %{id: user2_file.id, filename: "newfilename.file"}
        )
        |> json_response(200)

      assert res == %{
               "data" => %{"updateFile" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Du darfst diese Datei nicht bearbeiten.",
                   "path" => ["updateFile"]
                 }
               ]
             }
    end

    test "returns error when file does not exist", %{admin_jwt: admin_jwt} do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> post("/api", query: @query, variables: %{id: 0, filename: "neuername.test"})
        |> json_response(200)

      assert res == %{
               "data" => %{"updateFile" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Datei oder Ordner nicht gefunden.",
                   "path" => ["updateFile"]
                 }
               ]
             }
    end

    test "move a file in public directory as admin", %{
      public_file: public_file,
      admin_jwt: admin_jwt
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> post("/api",
          query: @query,
          variables: %{id: public_file.id, filename: "newfilename.jpg"}
        )
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "updateFile" => %{
                   "filename" => "newfilename.jpg",
                   "parentDirectory" => %{"name" => "logos"}
                 }
               }
             }
    end

    test "returns error when trying to move a file from public directory as non-admin", %{
      public_file: public_file,
      user2_jwt: user2_jwt,
      user2_account: user2_account
    } do
      target_dir = Repo.get_by!(Directory, name: "podcast", user_id: user2_account.id)

      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user2_jwt}")
        |> post("/api",
          query: @query,
          variables: %{id: public_file.id, parentDirectoryId: target_dir.id}
        )
        |> json_response(200)

      assert res == %{
               "data" => %{"updateFile" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Du darfst diese Datei nicht bearbeiten.",
                   "path" => ["updateFile"]
                 }
               ]
             }
    end

    test "returns error when trying to move a file to public directory as non-admin", %{
      user2_file: user2_file,
      user2_jwt: user2_jwt,
      public_directory: public_directory
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user2_jwt}")
        |> post("/api",
          query: @query,
          variables: %{id: user2_file.id, parentDirectoryId: public_directory.id}
        )
        |> json_response(200)

      assert res == %{
               "data" => %{"updateFile" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Du darfst diese Datei nicht bearbeiten.",
                   "path" => ["updateFile"]
                 }
               ]
             }
    end
  end

  describe "delete file mutation" do
    @query """
    mutation deleteFile($id: ID!) {
      deleteFile(id: $id) {
        filename
      }
    }
    """
    test "delete a user's own file", %{user2_file: user2_file, user2_jwt: user2_jwt} do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{user2_jwt}")
        |> post("/api", query: @query, variables: %{id: user2_file.id})
        |> json_response(200)

      assert res == %{
               "data" => %{
                 "deleteFile" => %{"filename" => "wieartig1.jpg"}
               }
             }
    end

    test "returns error when user is not owner of file", %{
      user2_file: user2_file,
      admin_jwt: admin_jwt
    } do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> post("/api", query: @query, variables: %{id: user2_file.id})
        |> json_response(200)

      assert res == %{
               "data" => %{"deleteFile" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Du darfst diese Datei nicht löschen.",
                   "path" => ["deleteFile"]
                 }
               ]
             }
    end

    test "returns error when file does not exist", %{admin_jwt: admin_jwt} do
      res =
        build_conn()
        |> put_req_header("tenant", "slug:web")
        |> put_req_header("authorization", "Bearer #{admin_jwt}")
        |> post("/api", query: @query, variables: %{id: 0})
        |> json_response(200)

      assert res == %{
               "data" => %{"deleteFile" => nil},
               "errors" => [
                 %{
                   "locations" => [%{"column" => 0, "line" => 2}],
                   "message" => "Datei nicht gefunden.",
                   "path" => ["deleteFile"]
                 }
               ]
             }
    end
  end

  test "deletes a public file as admin", %{public_file: public_file, admin_jwt: admin_jwt} do
    res =
      build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{admin_jwt}")
      |> post("/api", query: @query, variables: %{id: public_file.id})
      |> json_response(200)

    assert res == %{
             "data" => %{
               "deleteFile" => %{"filename" => "logo1.jpg"}
             }
           }
  end

  test "returns error when trying to delete a public file as non-admin", %{
    public_file: public_file,
    user2_jwt: user2_jwt
  } do
    res =
      build_conn()
      |> put_req_header("tenant", "slug:web")
      |> put_req_header("authorization", "Bearer #{user2_jwt}")
      |> post("/api", query: @query, variables: %{id: public_file.id})
      |> json_response(200)

    assert res == %{
             "data" => %{"deleteFile" => nil},
             "errors" => [
               %{
                 "locations" => [%{"column" => 0, "line" => 2}],
                 "message" => "Du darfst diese Datei nicht löschen.",
                 "path" => ["deleteFile"]
               }
             ]
           }
  end
end
