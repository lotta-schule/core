defmodule Api.Repo.Seeder do

  def seed() do
    web_tenant = Api.Repo.insert!(%Api.Tenants.Tenant{slug: "web", title: "Web Beispiel"})
    web_tenant
    |> Ecto.build_assoc(:custom_domains, %{ host: "lotta.web", is_main_domain: true })
    |> Api.Repo.insert!() # add "lotta.web" as custom domain
    lotta_tenant = Api.Repo.insert!(%Api.Tenants.Tenant{slug: "lotta", title: "Lotta"})

    admin_group = Api.Repo.insert!(%Api.Accounts.UserGroup{tenant_id: web_tenant.id, name: "Administration", is_admin_group: true, sort_key: 1000})
    verwaltung_group = Api.Repo.insert!(%Api.Accounts.UserGroup{tenant_id: web_tenant.id, name: "Verwaltung", sort_key: 800})
    lehrer_group = Api.Repo.insert!(%Api.Accounts.UserGroup{tenant_id: web_tenant.id, name: "Lehrer", sort_key: 600})
    schueler_group = Api.Repo.insert!(%Api.Accounts.UserGroup{tenant_id: web_tenant.id, name: "Schüler", sort_key: 400})
    Ecto.build_assoc(lehrer_group, :enrollment_tokens)
    |> Map.put(:token, "LEb0815Hp!1969")
    |> Api.Repo.insert!
    Ecto.build_assoc(schueler_group, :enrollment_tokens)
    |> Map.put(:token, "Seb034hP2?019")
    |> Api.Repo.insert!

    {:ok, alexis} = Api.Accounts.register_user(%{
        name: "Alexis Rinaldoni",
        nickname: "Der Meister",
        email: "alexis.rinaldoni@einsa.net",
        password: "test123",
        tenant_id: web_tenant.id
    })
    {:ok, _billy} = Api.Accounts.register_user(%{
        name: "Christopher Bill",
        nickname: "Billy",
        email: "billy@einsa.net",
        password: "test123",
        tenant_id: web_tenant.id,
        enrollment_tokens: ["Seb034hP2?019"]
    })
    {:ok, eike} = Api.Accounts.register_user(%{
        name: "Eike Wiewiorra",
        nickname: "Chef",
        email: "eike.wiewiorra@einsa.net",
        password: "test123",
        tenant_id: web_tenant.id
    })
    {:ok, dr_evil} = Api.Accounts.register_user(%{
        name: "Dr Evil",
        nickname: "drEvil",
        email: "drevil@lotta.schule",
        password: "test123",
        tenant_id: web_tenant.id
    })
    Api.Accounts.register_user(%{name: "Max Mustermann", nickname: "MaXi", email: "maxi@einsa.net", password: "test123", tenant_id: web_tenant.id})
    Api.Accounts.register_user(%{name: "Dorothea Musterfrau", nickname: "Doro", email: "doro@einsa.net", password: "test123", tenant_id: web_tenant.id})
    Api.Accounts.register_user(%{name: "Marie Curie", nickname: "Polonium", email: "mcurie@lotta.schule", password: "test456", tenant_id: lotta_tenant.id})

    Api.Accounts.set_user_groups(alexis, web_tenant, [admin_group])
    Api.Accounts.set_user_groups(eike, web_tenant, [lehrer_group])

    Api.Accounts.set_user_blocked(dr_evil, web_tenant, true)

    # public files
    public_logos = %Api.Accounts.Directory{name: "logos", tenant_id: web_tenant.id} |> Api.Repo.insert!()
    public_logos_podcast = %Api.Accounts.Directory{name: "podcast", tenant_id: web_tenant.id, parent_directory_id: public_logos.id} |> Api.Repo.insert!()
    public_logos_chamaeleon = %Api.Accounts.Directory{name: "chamaeleon", tenant_id: web_tenant.id, parent_directory_id: public_logos.id} |> Api.Repo.insert!()
    public_hintergrund = %Api.Accounts.Directory{name: "hintergrund", tenant_id: web_tenant.id} |> Api.Repo.insert!()
    [
      %Api.Accounts.File{parent_directory_id: public_logos.id, filename: "logo1.jpg", remote_location: "http://a.de/logo1.jpg", filesize: 12288, file_type: "image", mime_type: "image/jpg"},
      %Api.Accounts.File{parent_directory_id: public_logos.id, filename: "logo2.jpg", remote_location: "http://a.de/logo2.jpg", filesize: 12288, file_type: "image", mime_type: "image/jpg"},
      %Api.Accounts.File{parent_directory_id: public_logos.id, filename: "logo3.png", remote_location: "http://a.de/logo3.png", filesize: 12288, file_type: "image", mime_type: "image/png"},
      %Api.Accounts.File{parent_directory_id: public_logos.id, filename: "logo4.png", remote_location: "http://a.de/logo4.png", filesize: 12288, file_type: "image", mime_type: "image/png"},
      %Api.Accounts.File{parent_directory_id: public_logos_podcast.id, filename: "podcast1.png", remote_location: "http://a.de/podcast1.png", filesize: 12288, file_type: "image", mime_type: "image/png"},
      %Api.Accounts.File{parent_directory_id: public_logos_podcast.id, filename: "podcast2.png", remote_location: "http://a.de/podcast2.png", filesize: 12288, file_type: "image", mime_type: "image/png"},
      %Api.Accounts.File{parent_directory_id: public_logos_chamaeleon.id, filename: "chamaeleon.png", remote_location: "http://a.de/chamaeleon.png", filesize: 12288, file_type: "image", mime_type: "image/png"},
      %Api.Accounts.File{parent_directory_id: public_hintergrund, filename: "hg_dunkel.jpg", remote_location: "http://a.de/hg_dunkel.jpg", filesize: 12288, file_type: "image", mime_type: "image/jpg"},
      %Api.Accounts.File{parent_directory_id: public_hintergrund, filename: "hg_hell.jpg", remote_location: "http://a.de/hg_hell.jpg", filesize: 12288, file_type: "image", mime_type: "image/jpg"},
      %Api.Accounts.File{parent_directory_id: public_hintergrund, filename: "hg_comic.png", remote_location: "http://a.de/hg_comic.png", filesize: 12288, file_type: "image", mime_type: "image/png"},
      %Api.Accounts.File{parent_directory_id: public_hintergrund, filename: "hg_grafik.png", remote_location: "http://a.de/hg_grafik.png", filesize: 12288, file_type: "image", mime_type: "image/png"}
    ]
    |> Enum.each(fn file ->
      file
      |> Map.put(:user_id, alexis.id)
      |> Map.put(:tenant_id, web_tenant.id)
      |> Api.Repo.insert()
    end)
    # alexis' files
    avatar_directory = %Api.Accounts.Directory{name: "logos", tenant_id: web_tenant.id, user_id: alexis.id} |> Api.Repo.insert!()
    irgendwas_directory = %Api.Accounts.Directory{name: "irgendwas", tenant_id: web_tenant.id, user_id: alexis.id} |> Api.Repo.insert!()
    podcast_directory = %Api.Accounts.Directory{name: "podcast", tenant_id: web_tenant.id, user_id: alexis.id} |> Api.Repo.insert!()
    [
      %Api.Accounts.File{parent_directory_id: avatar_directory.id, filename: "ich_schoen.jpg", remote_location: "http://a.de/0801801", filesize: 12288, file_type: "image", mime_type: "image/jpg"},
      %Api.Accounts.File{parent_directory_id: avatar_directory.id, filename: "ich_haesslich.jpg", remote_location: "http://a.de/828382383", filesize: 12288, file_type: "image", mime_type: "image/jpg"},
      %Api.Accounts.File{parent_directory_id: irgendwas_directory.id, filename: "irgendwas.png", remote_location: "http://a.de/08234980239", filesize: 12288, file_type: "image", mime_type: "image/png"},
      %Api.Accounts.File{parent_directory_id: irgendwas_directory.id, filename: "wasanderes.png", remote_location: "http://a.de/28374892374", filesize: 12288, file_type: "image", mime_type: "image/png"},
      %Api.Accounts.File{parent_directory_id: podcast_directory.id, filename: "podcast1.mp4", remote_location: "http://a.de/82734897238497", filesize: 12288, file_type: "video", mime_type: "video/mp4"},
      %Api.Accounts.File{parent_directory_id: podcast_directory.id, filename: "podcast2.mov", remote_location: "http://a.de/82734897238498", filesize: 12288, file_type: "video", mime_type: "video/mov"},
      %Api.Accounts.File{parent_directory_id: podcast_directory.id, filename: "pc3.m4v", remote_location: "http://a.de/82734897238499", filesize: 12288, file_type: "video", mime_type: "video/m4v"},
    ]
    |> Enum.each(fn file ->
      file
      |> Map.put(:user_id, alexis.id)
      |> Map.put(:tenant_id, web_tenant.id)
      |> Api.Repo.insert!()
    end)
    # Eike' files
    avatar_directory = %Api.Accounts.Directory{name: "avatar", tenant_id: web_tenant.id, user_id: eike.id} |> Api.Repo.insert!()
    eoa_directory = %Api.Accounts.Directory{name: "ehrenberg-on-air", tenant_id: web_tenant.id, user_id: eike.id} |> Api.Repo.insert!()
    podcast_directory = %Api.Accounts.Directory{name: "podcast", tenant_id: web_tenant.id, user_id: eike.id} |> Api.Repo.insert!()
    [
      %Api.Accounts.File{parent_directory_id: avatar_directory.id, filename: "wieartig1.jpg", remote_location: "http://a.de/0801345801", filesize: 12288, file_type: "image", mime_type: "image/jpg"},
      %Api.Accounts.File{parent_directory_id: avatar_directory.id, filename: "wieartig2.jpg", remote_location: "http://a.de/828382123383", filesize: 12288, file_type: "image", mime_type: "image/jpg"},
      %Api.Accounts.File{parent_directory_id: eoa_directory.id, filename: "eoa2.mp3", remote_location: "http://a.de/08234980234239", filesize: 12288, file_type: "audio", mime_type: "audio/mp3"},
      %Api.Accounts.File{parent_directory_id: eoa_directory.id, filename: "eoa3.mp3", remote_location: "http://a.de/28374234892374", filesize: 12288, file_type: "audio", mime_type: "audio/mp3"},
      %Api.Accounts.File{parent_directory_id: podcast_directory.id, filename: "podcast5.mp4", remote_location: "http://a.de/7238497", filesize: 12288, file_type: "video", mime_type: "video/mp4"},
      %Api.Accounts.File{parent_directory_id: podcast_directory.id, filename: "podcast6.mov", remote_location: "http://a.de/97238498", filesize: 12288, file_type: "video", mime_type: "video/mov"},
      %Api.Accounts.File{parent_directory_id: podcast_directory.id, filename: "pocst7.m4v", remote_location: "http://a.de/8238499", filesize: 12288, file_type: "video", mime_type: "video/m4v"},
    ]
    |> Enum.each(fn file ->
      file
      |> Map.put(:user_id, eike.id)
      |> Map.put(:tenant_id, web_tenant.id)
      |> Api.Repo.insert!()
    end)

    homepage = Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, title: "Start", is_homepage: true})
    profil = Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 10, title: "Profil"})
    gta = Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 20, title: "GTA"})
    projekt = Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 30, title: "Projekt"})
    faecher = Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 40, title: "Fächer"})
    material = Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 50, title: "Material"})
    Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 60, title: "Galerien"})
    Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 70, title: "Impressum", is_sidenav: true})
    assign_groups(profil, [verwaltung_group])
    assign_groups(gta, [verwaltung_group, lehrer_group, schueler_group])
    assign_groups(faecher, [verwaltung_group, lehrer_group, schueler_group])
    assign_groups(material, [verwaltung_group, lehrer_group])

    # Fächer
    Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 10, title: "Sport", category_id: faecher.id})
    Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 20, title: "Kunst", category_id: faecher.id})
    Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 30, title: "Sprache", category_id: faecher.id})
    |> assign_groups([verwaltung_group, lehrer_group])

    # Profil
    Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 10, title: "Podcast", category_id: profil.id})
    Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 20, title: "Offene Kunst-AG", category_id: profil.id})
    Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 30, title: "Schülerzeitung", category_id: profil.id})
    Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 40, title: "Oskar-Reime-Chor", category_id: profil.id})
    Api.Repo.insert!(%Api.Tenants.Category{tenant_id: web_tenant.id, sort_key: 50, title: "Schüler-Radio", category_id: profil.id})

    # Kalender-Widgets
    widget1 = Api.Repo.insert!(%Api.Tenants.Widget{tenant_id: web_tenant.id, title: "Kalender", type: "calendar"})
    widget2 = Api.Repo.insert!(%Api.Tenants.Widget{tenant_id: web_tenant.id, title: "Kalender", type: "calendar"})
    widget3 = Api.Repo.insert!(%Api.Tenants.Widget{tenant_id: web_tenant.id, title: "Kalender", type: "calendar"})
    assign_groups(widget2, [verwaltung_group, lehrer_group])
    assign_groups(widget3, [verwaltung_group, lehrer_group])

    homepage
    |> Api.Repo.preload(:widgets)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:widgets, [widget1, widget2, widget3])
    |> Api.Repo.update()

    # Articles

    Api.Repo.insert(%Api.Content.Article{
      tenant_id: web_tenant.id,
      title: "Draft1",
      preview: "Entwurf Artikel zu I",
      inserted_at: ~N[2019-09-01 10:00:00],
      updated_at: ~N[2019-09-01 10:00:00]
    })
    |> elem(1)
    |> Api.Repo.preload(:users)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:users, [eike])
    |> Api.Repo.update()
    Api.Repo.insert(%Api.Content.Article{
      tenant_id: web_tenant.id,
      title: "Draft2",
      preview: "Entwurf Artikel zu XYZ",
      inserted_at: ~N[2019-09-01 10:05:00],
      updated_at: ~N[2019-09-01 10:05:00]
    })
    |> elem(1)
    |> Api.Repo.preload(:users)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:users, [eike])
    |> Api.Repo.update()
    Api.Repo.insert(%Api.Content.Article{
      tenant_id: web_tenant.id,
      title: "Fertiger Artikel zum Konzert",
      preview: "Entwurf Artikel zu XYZ",
      ready_to_publish: true,
      inserted_at: ~N[2019-09-01 10:06:00],
      updated_at: ~N[2019-09-01 10:06:00]
    })
    |> elem(1)
    |> Api.Repo.preload(:users)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:users, [eike])
    |> Api.Repo.update()

    oskar_goes_to = Api.Repo.insert!(%Api.Content.Article{
        tenant_id: web_tenant.id,
        category_id: profil.id,
        title: "And the oskar goes to ...",
        preview: "Hallo hallo hallo",
        inserted_at: ~N[2019-09-01 10:08:00],
        updated_at: ~N[2019-09-01 10:08:00]
    })
    Api.Repo.insert!(%Api.Content.ContentModule{article_id: oskar_goes_to.id, type: "text", text: "JTdCJTIyb2JqZWN0JTIyJTNBJTIydmFsdWUlMjIlMkMlMjJkb2N1bWVudCUyMiUzQSU3QiUyMm9iamVjdCUyMiUzQSUyMmRvY3VtZW50JTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIyYmxvY2slMjIlMkMlMjJ0eXBlJTIyJTNBJTIycGFyYWdyYXBoJTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIydGV4dCUyMiUyQyUyMnRleHQlMjIlM0ElMjJMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0JTJDJTIwY29uc2V0ZXR1ciUyMHNhZGlwc2NpbmclMjBlbGl0ciUyQyUyMHNlZCUyMGRpYW0lMjBub251bXklMjBlaXJtb2QlMjB0ZW1wb3IlMjBpbnZpZHVudCUyMHV0JTIwbGFib3JlJTIwZXQlMjBkb2xvcmUlMjBtYWduYSUyMGFsaXF1eWFtJTIwZXJhdCUyQyUyMHNlZCUyMGRpYW0lMjB2b2x1cHR1YS4lMjBBdCUyMHZlcm8lMjBlb3MlMjBldCUyMGFjY3VzYW0lMjBldCUyMGp1c3RvJTIwZHVvJTIwZG9sb3JlcyUyMGV0JTIwZWElMjByZWJ1bS4lMjBTdGV0JTIwY2xpdGElMjBrYXNkJTIwZ3ViZXJncmVuJTJDJTIwbm8lMjBzZWElMjB0YWtpbWF0YSUyMHNhbmN0dXMlMjBlc3QlMjBMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0LiUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQlMkMlMjBjb25zZXRldHVyJTIwc2FkaXBzY2luZyUyMGVsaXRyJTJDJTIwc2VkJTIwZGlhbSUyMG5vbnVteSUyMGVpcm1vZCUyMHRlbXBvciUyMGludmlkdW50JTIwdXQlMjBsYWJvcmUlMjBldCUyMGRvbG9yZSUyMG1hZ25hJTIwYWxpcXV5YW0lMjBlcmF0JTJDJTIwc2VkJTIwZGlhbSUyMHZvbHVwdHVhLiUyMEF0JTIwdmVybyUyMGVvcyUyMGV0JTIwYWNjdXNhbSUyMGV0JTIwanVzdG8lMjBkdW8lMjBkb2xvcmVzJTIwZXQlMjBlYSUyMHJlYnVtLiUyMFN0ZXQlMjBjbGl0YSUyMGthc2QlMjBndWJlcmdyZW4lMkMlMjBubyUyMHNlYSUyMHRha2ltYXRhJTIwc2FuY3R1cyUyMGVzdCUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQuJTIyJTJDJTIybWFya3MlMjIlM0ElNUIlNUQlN0QlNUQlN0QlNUQlN0QlN0Q="})
    Api.Repo.insert!(%Api.Content.ContentModule{article_id: oskar_goes_to.id, type: "text", text: "JTdCJTIyb2JqZWN0JTIyJTNBJTIydmFsdWUlMjIlMkMlMjJkb2N1bWVudCUyMiUzQSU3QiUyMm9iamVjdCUyMiUzQSUyMmRvY3VtZW50JTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIyYmxvY2slMjIlMkMlMjJ0eXBlJTIyJTNBJTIycGFyYWdyYXBoJTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIydGV4dCUyMiUyQyUyMnRleHQlMjIlM0ElMjJMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0JTJDJTIwY29uc2V0ZXR1ciUyMHNhZGlwc2NpbmclMjBlbGl0ciUyQyUyMHNlZCUyMGRpYW0lMjBub251bXklMjBlaXJtb2QlMjB0ZW1wb3IlMjBpbnZpZHVudCUyMHV0JTIwbGFib3JlJTIwZXQlMjBkb2xvcmUlMjBtYWduYSUyMGFsaXF1eWFtJTIwZXJhdCUyQyUyMHNlZCUyMGRpYW0lMjB2b2x1cHR1YS4lMjBBdCUyMHZlcm8lMjBlb3MlMjBldCUyMGFjY3VzYW0lMjBldCUyMGp1c3RvJTIwZHVvJTIwZG9sb3JlcyUyMGV0JTIwZWElMjByZWJ1bS4lMjBTdGV0JTIwY2xpdGElMjBrYXNkJTIwZ3ViZXJncmVuJTJDJTIwbm8lMjBzZWElMjB0YWtpbWF0YSUyMHNhbmN0dXMlMjBlc3QlMjBMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0LiUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQlMkMlMjBjb25zZXRldHVyJTIwc2FkaXBzY2luZyUyMGVsaXRyJTJDJTIwc2VkJTIwZGlhbSUyMG5vbnVteSUyMGVpcm1vZCUyMHRlbXBvciUyMGludmlkdW50JTIwdXQlMjBsYWJvcmUlMjBldCUyMGRvbG9yZSUyMG1hZ25hJTIwYWxpcXV5YW0lMjBlcmF0JTJDJTIwc2VkJTIwZGlhbSUyMHZvbHVwdHVhLiUyMEF0JTIwdmVybyUyMGVvcyUyMGV0JTIwYWNjdXNhbSUyMGV0JTIwanVzdG8lMjBkdW8lMjBkb2xvcmVzJTIwZXQlMjBlYSUyMHJlYnVtLiUyMFN0ZXQlMjBjbGl0YSUyMGthc2QlMjBndWJlcmdyZW4lMkMlMjBubyUyMHNlYSUyMHRha2ltYXRhJTIwc2FuY3R1cyUyMGVzdCUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQuJTIyJTJDJTIybWFya3MlMjIlM0ElNUIlNUQlN0QlNUQlN0QlNUQlN0QlN0Q="})
    form = Api.Repo.insert!(%Api.Content.ContentModule{
      article_id: oskar_goes_to.id,
      type: "text",
      text: "Pizza Test-Formular",
      configuration: %{
        "destination" => "alexis.rinaldoni@einsa.net",
        "save_internally" => true,
        "elements" => [
          %{ "descriptionText" => "Halli, hallo, wir sind da, du bist hier, dadub dadumm.", "element" => "input", "label" => "Name", "name" => "name", "required" => true, "type" => "text" },
          %{ "descriptionText" => "", "element" => "selection", "label" => "PizzaGröße", "name" => "größe", "required" => true, "type" => "radio", "options" => [ %{ "label" => "klein (22cm Durchmesser)", "selected" => true, "value" => "klein" }, %{ "label" => "groß (28cm Durchmesser)", "selected" => false, "value" => "groß" }, %{ "label" => "Familienpizza (50x60cm)", "selected" => false, "value" => "familie" }] },
          %{ "descriptionText" => "", "element" => "selection", "label" => "Zutat", "name" => "feld3", "required" => true, "type" => "checkbox", "options" => [ %{ "label" => "zusätzliche Peperoni", "selected" => false, "value" => "peperoni" }, %{ "label" => "Zusätzlicher Käse", "selected" => true, "value" => "käse" }, %{ "label" => "Pilze", "selected" => true, "value" => "pilze" }, %{ "label" => "Gorgonzola", "value" => "gorgonzola" }, %{ "label" => "Ananas (Bestellung wird sofort verworfen)", "value" => "ananas" }] },
          %{ "descriptionText" => "", "element" => "selection", "label" => "Bei Abholung 10% Rabat", "name" => "transport", "required" => true, "type" => "select", "options" => [ %{ "label" => "Abholung", "selected" => false, "value" => "abholung" }, %{ "label" => "Lieferung", "selected" => true, "value" => "lieferung" } ] },
          %{ "element" => "input", "label" => "Weitere Informationen", "multiline" => true, "name" => "beschreibung", "type" => "text" }
        ]
      }
    })
    form
    |> Ecto.build_assoc(:results, result: %{
      "responses" => %{
        "beschreibung" => "",
        "feld3" => ["käse", "pilze"],
        "größe" => "klein",
        "name" => "Test",
        "transport" => "lieferung"
      }
    })
    |> Api.Repo.insert!()
    landesfinale = Api.Repo.insert!(%Api.Content.Article{
        tenant_id: web_tenant.id,
        category_id: profil.id,
        title: "Landesfinale Volleyball WK IV",
        preview: "Zweimal Silber für die Mannschaften des Christian-Gottfried-Ehrenberg-Gymnasium Delitzsch beim Landesfinale \"Jugend trainiert für Europa\" im Volleyball. Nach beherztem Kampf im Finale unterlegen ...",
        inserted_at: ~N[2019-09-01 10:09:00],
        updated_at: ~N[2019-09-01 10:09:00]
    })
    Api.Repo.insert!(%Api.Content.ContentModule{article_id: landesfinale.id, type: "text", text: "JTdCJTIyb2JqZWN0JTIyJTNBJTIydmFsdWUlMjIlMkMlMjJkb2N1bWVudCUyMiUzQSU3QiUyMm9iamVjdCUyMiUzQSUyMmRvY3VtZW50JTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIyYmxvY2slMjIlMkMlMjJ0eXBlJTIyJTNBJTIycGFyYWdyYXBoJTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIydGV4dCUyMiUyQyUyMnRleHQlMjIlM0ElMjJMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0JTJDJTIwY29uc2V0ZXR1ciUyMHNhZGlwc2NpbmclMjBlbGl0ciUyQyUyMHNlZCUyMGRpYW0lMjBub251bXklMjBlaXJtb2QlMjB0ZW1wb3IlMjBpbnZpZHVudCUyMHV0JTIwbGFib3JlJTIwZXQlMjBkb2xvcmUlMjBtYWduYSUyMGFsaXF1eWFtJTIwZXJhdCUyQyUyMHNlZCUyMGRpYW0lMjB2b2x1cHR1YS4lMjBBdCUyMHZlcm8lMjBlb3MlMjBldCUyMGFjY3VzYW0lMjBldCUyMGp1c3RvJTIwZHVvJTIwZG9sb3JlcyUyMGV0JTIwZWElMjByZWJ1bS4lMjBTdGV0JTIwY2xpdGElMjBrYXNkJTIwZ3ViZXJncmVuJTJDJTIwbm8lMjBzZWElMjB0YWtpbWF0YSUyMHNhbmN0dXMlMjBlc3QlMjBMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0LiUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQlMkMlMjBjb25zZXRldHVyJTIwc2FkaXBzY2luZyUyMGVsaXRyJTJDJTIwc2VkJTIwZGlhbSUyMG5vbnVteSUyMGVpcm1vZCUyMHRlbXBvciUyMGludmlkdW50JTIwdXQlMjBsYWJvcmUlMjBldCUyMGRvbG9yZSUyMG1hZ25hJTIwYWxpcXV5YW0lMjBlcmF0JTJDJTIwc2VkJTIwZGlhbSUyMHZvbHVwdHVhLiUyMEF0JTIwdmVybyUyMGVvcyUyMGV0JTIwYWNjdXNhbSUyMGV0JTIwanVzdG8lMjBkdW8lMjBkb2xvcmVzJTIwZXQlMjBlYSUyMHJlYnVtLiUyMFN0ZXQlMjBjbGl0YSUyMGthc2QlMjBndWJlcmdyZW4lMkMlMjBubyUyMHNlYSUyMHRha2ltYXRhJTIwc2FuY3R1cyUyMGVzdCUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQuJTIyJTJDJTIybWFya3MlMjIlM0ElNUIlNUQlN0QlNUQlN0QlNUQlN0QlN0Q="})
    Api.Repo.insert!(%Api.Content.ContentModule{article_id: landesfinale.id, type: "text", text: "JTdCJTIyb2JqZWN0JTIyJTNBJTIydmFsdWUlMjIlMkMlMjJkb2N1bWVudCUyMiUzQSU3QiUyMm9iamVjdCUyMiUzQSUyMmRvY3VtZW50JTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIyYmxvY2slMjIlMkMlMjJ0eXBlJTIyJTNBJTIycGFyYWdyYXBoJTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIydGV4dCUyMiUyQyUyMnRleHQlMjIlM0ElMjJMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0JTJDJTIwY29uc2V0ZXR1ciUyMHNhZGlwc2NpbmclMjBlbGl0ciUyQyUyMHNlZCUyMGRpYW0lMjBub251bXklMjBlaXJtb2QlMjB0ZW1wb3IlMjBpbnZpZHVudCUyMHV0JTIwbGFib3JlJTIwZXQlMjBkb2xvcmUlMjBtYWduYSUyMGFsaXF1eWFtJTIwZXJhdCUyQyUyMHNlZCUyMGRpYW0lMjB2b2x1cHR1YS4lMjBBdCUyMHZlcm8lMjBlb3MlMjBldCUyMGFjY3VzYW0lMjBldCUyMGp1c3RvJTIwZHVvJTIwZG9sb3JlcyUyMGV0JTIwZWElMjByZWJ1bS4lMjBTdGV0JTIwY2xpdGElMjBrYXNkJTIwZ3ViZXJncmVuJTJDJTIwbm8lMjBzZWElMjB0YWtpbWF0YSUyMHNhbmN0dXMlMjBlc3QlMjBMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0LiUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQlMkMlMjBjb25zZXRldHVyJTIwc2FkaXBzY2luZyUyMGVsaXRyJTJDJTIwc2VkJTIwZGlhbSUyMG5vbnVteSUyMGVpcm1vZCUyMHRlbXBvciUyMGludmlkdW50JTIwdXQlMjBsYWJvcmUlMjBldCUyMGRvbG9yZSUyMG1hZ25hJTIwYWxpcXV5YW0lMjBlcmF0JTJDJTIwc2VkJTIwZGlhbSUyMHZvbHVwdHVhLiUyMEF0JTIwdmVybyUyMGVvcyUyMGV0JTIwYWNjdXNhbSUyMGV0JTIwanVzdG8lMjBkdW8lMjBkb2xvcmVzJTIwZXQlMjBlYSUyMHJlYnVtLiUyMFN0ZXQlMjBjbGl0YSUyMGthc2QlMjBndWJlcmdyZW4lMkMlMjBubyUyMHNlYSUyMHRha2ltYXRhJTIwc2FuY3R1cyUyMGVzdCUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQuJTIyJTJDJTIybWFya3MlMjIlM0ElNUIlNUQlN0QlNUQlN0QlNUQlN0QlN0Q="})
    kleinkunst_wb2 = Api.Repo.insert!(%Api.Content.Article{
        tenant_id: web_tenant.id,
        category_id: profil.id,
        title: "Der Podcast zum WB 2",
        preview: "Das Podcastteam hat alle Hochlichter der Veranstaltung in einem originellen Film zusammengeschnitten. Wir beglückwünschen die Sieger und haben unseren Sieger gesondert gefeiert.",
        topic: "KleinKunst 2018",
        inserted_at: ~N[2019-09-01 10:11:00],
        updated_at: ~N[2019-09-01 10:11:00]
    })
    assign_groups(kleinkunst_wb2, [verwaltung_group, lehrer_group, schueler_group])
    Api.Repo.insert!(%Api.Content.ContentModule{article_id: kleinkunst_wb2.id, type: "text", text: "JTdCJTIyb2JqZWN0JTIyJTNBJTIydmFsdWUlMjIlMkMlMjJkb2N1bWVudCUyMiUzQSU3QiUyMm9iamVjdCUyMiUzQSUyMmRvY3VtZW50JTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIyYmxvY2slMjIlMkMlMjJ0eXBlJTIyJTNBJTIycGFyYWdyYXBoJTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIydGV4dCUyMiUyQyUyMnRleHQlMjIlM0ElMjJMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0JTJDJTIwY29uc2V0ZXR1ciUyMHNhZGlwc2NpbmclMjBlbGl0ciUyQyUyMHNlZCUyMGRpYW0lMjBub251bXklMjBlaXJtb2QlMjB0ZW1wb3IlMjBpbnZpZHVudCUyMHV0JTIwbGFib3JlJTIwZXQlMjBkb2xvcmUlMjBtYWduYSUyMGFsaXF1eWFtJTIwZXJhdCUyQyUyMHNlZCUyMGRpYW0lMjB2b2x1cHR1YS4lMjBBdCUyMHZlcm8lMjBlb3MlMjBldCUyMGFjY3VzYW0lMjBldCUyMGp1c3RvJTIwZHVvJTIwZG9sb3JlcyUyMGV0JTIwZWElMjByZWJ1bS4lMjBTdGV0JTIwY2xpdGElMjBrYXNkJTIwZ3ViZXJncmVuJTJDJTIwbm8lMjBzZWElMjB0YWtpbWF0YSUyMHNhbmN0dXMlMjBlc3QlMjBMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0LiUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQlMkMlMjBjb25zZXRldHVyJTIwc2FkaXBzY2luZyUyMGVsaXRyJTJDJTIwc2VkJTIwZGlhbSUyMG5vbnVteSUyMGVpcm1vZCUyMHRlbXBvciUyMGludmlkdW50JTIwdXQlMjBsYWJvcmUlMjBldCUyMGRvbG9yZSUyMG1hZ25hJTIwYWxpcXV5YW0lMjBlcmF0JTJDJTIwc2VkJTIwZGlhbSUyMHZvbHVwdHVhLiUyMEF0JTIwdmVybyUyMGVvcyUyMGV0JTIwYWNjdXNhbSUyMGV0JTIwanVzdG8lMjBkdW8lMjBkb2xvcmVzJTIwZXQlMjBlYSUyMHJlYnVtLiUyMFN0ZXQlMjBjbGl0YSUyMGthc2QlMjBndWJlcmdyZW4lMkMlMjBubyUyMHNlYSUyMHRha2ltYXRhJTIwc2FuY3R1cyUyMGVzdCUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQuJTIyJTJDJTIybWFya3MlMjIlM0ElNUIlNUQlN0QlNUQlN0QlNUQlN0QlN0Q="})
    Api.Repo.insert!(%Api.Content.ContentModule{article_id: kleinkunst_wb2.id, type: "text", text: "JTdCJTIyb2JqZWN0JTIyJTNBJTIydmFsdWUlMjIlMkMlMjJkb2N1bWVudCUyMiUzQSU3QiUyMm9iamVjdCUyMiUzQSUyMmRvY3VtZW50JTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIyYmxvY2slMjIlMkMlMjJ0eXBlJTIyJTNBJTIycGFyYWdyYXBoJTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIydGV4dCUyMiUyQyUyMnRleHQlMjIlM0ElMjJMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0JTJDJTIwY29uc2V0ZXR1ciUyMHNhZGlwc2NpbmclMjBlbGl0ciUyQyUyMHNlZCUyMGRpYW0lMjBub251bXklMjBlaXJtb2QlMjB0ZW1wb3IlMjBpbnZpZHVudCUyMHV0JTIwbGFib3JlJTIwZXQlMjBkb2xvcmUlMjBtYWduYSUyMGFsaXF1eWFtJTIwZXJhdCUyQyUyMHNlZCUyMGRpYW0lMjB2b2x1cHR1YS4lMjBBdCUyMHZlcm8lMjBlb3MlMjBldCUyMGFjY3VzYW0lMjBldCUyMGp1c3RvJTIwZHVvJTIwZG9sb3JlcyUyMGV0JTIwZWElMjByZWJ1bS4lMjBTdGV0JTIwY2xpdGElMjBrYXNkJTIwZ3ViZXJncmVuJTJDJTIwbm8lMjBzZWElMjB0YWtpbWF0YSUyMHNhbmN0dXMlMjBlc3QlMjBMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0LiUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQlMkMlMjBjb25zZXRldHVyJTIwc2FkaXBzY2luZyUyMGVsaXRyJTJDJTIwc2VkJTIwZGlhbSUyMG5vbnVteSUyMGVpcm1vZCUyMHRlbXBvciUyMGludmlkdW50JTIwdXQlMjBsYWJvcmUlMjBldCUyMGRvbG9yZSUyMG1hZ25hJTIwYWxpcXV5YW0lMjBlcmF0JTJDJTIwc2VkJTIwZGlhbSUyMHZvbHVwdHVhLiUyMEF0JTIwdmVybyUyMGVvcyUyMGV0JTIwYWNjdXNhbSUyMGV0JTIwanVzdG8lMjBkdW8lMjBkb2xvcmVzJTIwZXQlMjBlYSUyMHJlYnVtLiUyMFN0ZXQlMjBjbGl0YSUyMGthc2QlMjBndWJlcmdyZW4lMkMlMjBubyUyMHNlYSUyMHRha2ltYXRhJTIwc2FuY3R1cyUyMGVzdCUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQuJTIyJTJDJTIybWFya3MlMjIlM0ElNUIlNUQlN0QlNUQlN0QlNUQlN0QlN0Q="})
    vorausscheid = Api.Repo.insert!(%Api.Content.Article{
        tenant_id: web_tenant.id,
        category_id: profil.id,
        title: "Der Vorausscheid",
        preview: "Singen, Schauspielern, Instrumente Spielen - Die Kerndisziplinen von Klienkunst waren auch diese Jahr beim Vorausscheid am 14. Februar vertreten. Wir mischten uns unter die Kandidaten, Techniker und die Jury.",
        topic: "KleinKunst 2018",
        inserted_at: ~N[2019-09-01 10:12:00],
        updated_at: ~N[2019-09-01 10:12:00]
    })
    assign_groups(vorausscheid, [verwaltung_group, lehrer_group])
    Api.Repo.insert!(%Api.Content.ContentModule{article_id: vorausscheid.id, type: "text", text: "JTdCJTIyb2JqZWN0JTIyJTNBJTIydmFsdWUlMjIlMkMlMjJkb2N1bWVudCUyMiUzQSU3QiUyMm9iamVjdCUyMiUzQSUyMmRvY3VtZW50JTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIyYmxvY2slMjIlMkMlMjJ0eXBlJTIyJTNBJTIycGFyYWdyYXBoJTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIydGV4dCUyMiUyQyUyMnRleHQlMjIlM0ElMjJMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0JTJDJTIwY29uc2V0ZXR1ciUyMHNhZGlwc2NpbmclMjBlbGl0ciUyQyUyMHNlZCUyMGRpYW0lMjBub251bXklMjBlaXJtb2QlMjB0ZW1wb3IlMjBpbnZpZHVudCUyMHV0JTIwbGFib3JlJTIwZXQlMjBkb2xvcmUlMjBtYWduYSUyMGFsaXF1eWFtJTIwZXJhdCUyQyUyMHNlZCUyMGRpYW0lMjB2b2x1cHR1YS4lMjBBdCUyMHZlcm8lMjBlb3MlMjBldCUyMGFjY3VzYW0lMjBldCUyMGp1c3RvJTIwZHVvJTIwZG9sb3JlcyUyMGV0JTIwZWElMjByZWJ1bS4lMjBTdGV0JTIwY2xpdGElMjBrYXNkJTIwZ3ViZXJncmVuJTJDJTIwbm8lMjBzZWElMjB0YWtpbWF0YSUyMHNhbmN0dXMlMjBlc3QlMjBMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0LiUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQlMkMlMjBjb25zZXRldHVyJTIwc2FkaXBzY2luZyUyMGVsaXRyJTJDJTIwc2VkJTIwZGlhbSUyMG5vbnVteSUyMGVpcm1vZCUyMHRlbXBvciUyMGludmlkdW50JTIwdXQlMjBsYWJvcmUlMjBldCUyMGRvbG9yZSUyMG1hZ25hJTIwYWxpcXV5YW0lMjBlcmF0JTJDJTIwc2VkJTIwZGlhbSUyMHZvbHVwdHVhLiUyMEF0JTIwdmVybyUyMGVvcyUyMGV0JTIwYWNjdXNhbSUyMGV0JTIwanVzdG8lMjBkdW8lMjBkb2xvcmVzJTIwZXQlMjBlYSUyMHJlYnVtLiUyMFN0ZXQlMjBjbGl0YSUyMGthc2QlMjBndWJlcmdyZW4lMkMlMjBubyUyMHNlYSUyMHRha2ltYXRhJTIwc2FuY3R1cyUyMGVzdCUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQuJTIyJTJDJTIybWFya3MlMjIlM0ElNUIlNUQlN0QlNUQlN0QlNUQlN0QlN0Q="})
    Api.Repo.insert!(%Api.Content.ContentModule{article_id: vorausscheid.id, type: "text", text: "JTdCJTIyb2JqZWN0JTIyJTNBJTIydmFsdWUlMjIlMkMlMjJkb2N1bWVudCUyMiUzQSU3QiUyMm9iamVjdCUyMiUzQSUyMmRvY3VtZW50JTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIyYmxvY2slMjIlMkMlMjJ0eXBlJTIyJTNBJTIycGFyYWdyYXBoJTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIydGV4dCUyMiUyQyUyMnRleHQlMjIlM0ElMjJMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0JTJDJTIwY29uc2V0ZXR1ciUyMHNhZGlwc2NpbmclMjBlbGl0ciUyQyUyMHNlZCUyMGRpYW0lMjBub251bXklMjBlaXJtb2QlMjB0ZW1wb3IlMjBpbnZpZHVudCUyMHV0JTIwbGFib3JlJTIwZXQlMjBkb2xvcmUlMjBtYWduYSUyMGFsaXF1eWFtJTIwZXJhdCUyQyUyMHNlZCUyMGRpYW0lMjB2b2x1cHR1YS4lMjBBdCUyMHZlcm8lMjBlb3MlMjBldCUyMGFjY3VzYW0lMjBldCUyMGp1c3RvJTIwZHVvJTIwZG9sb3JlcyUyMGV0JTIwZWElMjByZWJ1bS4lMjBTdGV0JTIwY2xpdGElMjBrYXNkJTIwZ3ViZXJncmVuJTJDJTIwbm8lMjBzZWElMjB0YWtpbWF0YSUyMHNhbmN0dXMlMjBlc3QlMjBMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0LiUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQlMkMlMjBjb25zZXRldHVyJTIwc2FkaXBzY2luZyUyMGVsaXRyJTJDJTIwc2VkJTIwZGlhbSUyMG5vbnVteSUyMGVpcm1vZCUyMHRlbXBvciUyMGludmlkdW50JTIwdXQlMjBsYWJvcmUlMjBldCUyMGRvbG9yZSUyMG1hZ25hJTIwYWxpcXV5YW0lMjBlcmF0JTJDJTIwc2VkJTIwZGlhbSUyMHZvbHVwdHVhLiUyMEF0JTIwdmVybyUyMGVvcyUyMGV0JTIwYWNjdXNhbSUyMGV0JTIwanVzdG8lMjBkdW8lMjBkb2xvcmVzJTIwZXQlMjBlYSUyMHJlYnVtLiUyMFN0ZXQlMjBjbGl0YSUyMGthc2QlMjBndWJlcmdyZW4lMkMlMjBubyUyMHNlYSUyMHRha2ltYXRhJTIwc2FuY3R1cyUyMGVzdCUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQuJTIyJTJDJTIybWFya3MlMjIlM0ElNUIlNUQlN0QlNUQlN0QlNUQlN0QlN0Q="})
    nipplejesus = Api.Repo.insert!(%Api.Content.Article{
        tenant_id: web_tenant.id,
        category_id: projekt.id,
        title: "„Nipple Jesus“- eine extreme Erfahrung",
        preview: "Das Theaterstück „Nipple Jesus“, welches am 08.02.2019 im Museum der Bildenden Künste aufgeführt wurde, hat bei mir noch lange nach der Aufführung große Aufmerksamkeit hinterlassen.",
        inserted_at: ~N[2019-09-01 10:13:00],
        updated_at: ~N[2019-09-01 10:13:00]
    })
    Api.Repo.insert!(%Api.Content.ContentModule{article_id: nipplejesus.id, type: "text", text: "JTdCJTIyb2JqZWN0JTIyJTNBJTIydmFsdWUlMjIlMkMlMjJkb2N1bWVudCUyMiUzQSU3QiUyMm9iamVjdCUyMiUzQSUyMmRvY3VtZW50JTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIyYmxvY2slMjIlMkMlMjJ0eXBlJTIyJTNBJTIycGFyYWdyYXBoJTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIydGV4dCUyMiUyQyUyMnRleHQlMjIlM0ElMjJMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0JTJDJTIwY29uc2V0ZXR1ciUyMHNhZGlwc2NpbmclMjBlbGl0ciUyQyUyMHNlZCUyMGRpYW0lMjBub251bXklMjBlaXJtb2QlMjB0ZW1wb3IlMjBpbnZpZHVudCUyMHV0JTIwbGFib3JlJTIwZXQlMjBkb2xvcmUlMjBtYWduYSUyMGFsaXF1eWFtJTIwZXJhdCUyQyUyMHNlZCUyMGRpYW0lMjB2b2x1cHR1YS4lMjBBdCUyMHZlcm8lMjBlb3MlMjBldCUyMGFjY3VzYW0lMjBldCUyMGp1c3RvJTIwZHVvJTIwZG9sb3JlcyUyMGV0JTIwZWElMjByZWJ1bS4lMjBTdGV0JTIwY2xpdGElMjBrYXNkJTIwZ3ViZXJncmVuJTJDJTIwbm8lMjBzZWElMjB0YWtpbWF0YSUyMHNhbmN0dXMlMjBlc3QlMjBMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0LiUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQlMkMlMjBjb25zZXRldHVyJTIwc2FkaXBzY2luZyUyMGVsaXRyJTJDJTIwc2VkJTIwZGlhbSUyMG5vbnVteSUyMGVpcm1vZCUyMHRlbXBvciUyMGludmlkdW50JTIwdXQlMjBsYWJvcmUlMjBldCUyMGRvbG9yZSUyMG1hZ25hJTIwYWxpcXV5YW0lMjBlcmF0JTJDJTIwc2VkJTIwZGlhbSUyMHZvbHVwdHVhLiUyMEF0JTIwdmVybyUyMGVvcyUyMGV0JTIwYWNjdXNhbSUyMGV0JTIwanVzdG8lMjBkdW8lMjBkb2xvcmVzJTIwZXQlMjBlYSUyMHJlYnVtLiUyMFN0ZXQlMjBjbGl0YSUyMGthc2QlMjBndWJlcmdyZW4lMkMlMjBubyUyMHNlYSUyMHRha2ltYXRhJTIwc2FuY3R1cyUyMGVzdCUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQuJTIyJTJDJTIybWFya3MlMjIlM0ElNUIlNUQlN0QlNUQlN0QlNUQlN0QlN0Q="})
    Api.Repo.insert!(%Api.Content.ContentModule{article_id: nipplejesus.id, type: "text", text: "JTdCJTIyb2JqZWN0JTIyJTNBJTIydmFsdWUlMjIlMkMlMjJkb2N1bWVudCUyMiUzQSU3QiUyMm9iamVjdCUyMiUzQSUyMmRvY3VtZW50JTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIyYmxvY2slMjIlMkMlMjJ0eXBlJTIyJTNBJTIycGFyYWdyYXBoJTIyJTJDJTIyZGF0YSUyMiUzQSU3QiU3RCUyQyUyMm5vZGVzJTIyJTNBJTVCJTdCJTIyb2JqZWN0JTIyJTNBJTIydGV4dCUyMiUyQyUyMnRleHQlMjIlM0ElMjJMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0JTJDJTIwY29uc2V0ZXR1ciUyMHNhZGlwc2NpbmclMjBlbGl0ciUyQyUyMHNlZCUyMGRpYW0lMjBub251bXklMjBlaXJtb2QlMjB0ZW1wb3IlMjBpbnZpZHVudCUyMHV0JTIwbGFib3JlJTIwZXQlMjBkb2xvcmUlMjBtYWduYSUyMGFsaXF1eWFtJTIwZXJhdCUyQyUyMHNlZCUyMGRpYW0lMjB2b2x1cHR1YS4lMjBBdCUyMHZlcm8lMjBlb3MlMjBldCUyMGFjY3VzYW0lMjBldCUyMGp1c3RvJTIwZHVvJTIwZG9sb3JlcyUyMGV0JTIwZWElMjByZWJ1bS4lMjBTdGV0JTIwY2xpdGElMjBrYXNkJTIwZ3ViZXJncmVuJTJDJTIwbm8lMjBzZWElMjB0YWtpbWF0YSUyMHNhbmN0dXMlMjBlc3QlMjBMb3JlbSUyMGlwc3VtJTIwZG9sb3IlMjBzaXQlMjBhbWV0LiUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQlMkMlMjBjb25zZXRldHVyJTIwc2FkaXBzY2luZyUyMGVsaXRyJTJDJTIwc2VkJTIwZGlhbSUyMG5vbnVteSUyMGVpcm1vZCUyMHRlbXBvciUyMGludmlkdW50JTIwdXQlMjBsYWJvcmUlMjBldCUyMGRvbG9yZSUyMG1hZ25hJTIwYWxpcXV5YW0lMjBlcmF0JTJDJTIwc2VkJTIwZGlhbSUyMHZvbHVwdHVhLiUyMEF0JTIwdmVybyUyMGVvcyUyMGV0JTIwYWNjdXNhbSUyMGV0JTIwanVzdG8lMjBkdW8lMjBkb2xvcmVzJTIwZXQlMjBlYSUyMHJlYnVtLiUyMFN0ZXQlMjBjbGl0YSUyMGthc2QlMjBndWJlcmdyZW4lMkMlMjBubyUyMHNlYSUyMHRha2ltYXRhJTIwc2FuY3R1cyUyMGVzdCUyMExvcmVtJTIwaXBzdW0lMjBkb2xvciUyMHNpdCUyMGFtZXQuJTIyJTJDJTIybWFya3MlMjIlM0ElNUIlNUQlN0QlNUQlN0QlNUQlN0QlN0Q="})

    Api.Repo.insert!(%Api.Content.Article{
        tenant_id: web_tenant.id,
        category_id: projekt.id,
        title: "Beitrag Projekt 1",
        preview: "Lorem ipsum dolor sit amet.",
        inserted_at: ~N[2019-09-01 10:14:00],
        updated_at: ~N[2019-09-01 10:14:00]
    })
    Api.Repo.insert!(%Api.Content.Article{
        tenant_id: web_tenant.id,
        category_id: projekt.id,
        title: "Beitrag Projekt 2",
        preview: "Lorem ipsum dolor sit amet.",
        inserted_at: ~N[2019-09-01 10:15:00],
        updated_at: ~N[2019-09-01 10:15:00]
    })
    Api.Repo.insert!(%Api.Content.Article{
        tenant_id: web_tenant.id,
        category_id: projekt.id,
        title: "Beitrag Projekt 3",
        preview: "Lorem ipsum dolor sit amet.",
        inserted_at: ~N[2019-09-01 10:16:00],
        updated_at: ~N[2019-09-01 10:16:00]
    })
    Enum.map(4..30, fn i ->
      art1 = Api.Repo.insert!(%Api.Content.Article{
          tenant_id: web_tenant.id,
          category_id: projekt.id,
          title: "Beitrag Projekt #{i} - nur für Lehrer",
          preview: "Lorem ipsum dolor sit amet.",
          inserted_at: NaiveDateTime.add(~N[2019-09-02 18:12:00], 60 * (i + 1), :second),
          updated_at: NaiveDateTime.add(~N[2019-09-02 18:12:00], 60 * (i + 1), :second)
      })
      art2 = Api.Repo.insert!(%Api.Content.Article{
          tenant_id: web_tenant.id,
          category_id: projekt.id,
          title: "Beitrag Projekt #{i} - nur für Schüler",
          preview: "Lorem ipsum dolor sit amet.",
          inserted_at: NaiveDateTime.add(~N[2019-09-02 18:12:00], 60 * (i + 1), :second),
          updated_at: NaiveDateTime.add(~N[2019-09-02 18:12:00], 60 * (i + 1), :second)
      })
      assign_groups(art1, [verwaltung_group, lehrer_group])
      assign_groups(art2, [verwaltung_group, lehrer_group, schueler_group])
    end)
    :ok
  end

  defp assign_groups(model, groups) do
    model
    |> Api.Repo.preload(:groups)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:groups, groups)
    |> Api.Repo.update()
  end
end
